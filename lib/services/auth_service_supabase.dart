import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moto_rent_dumaguete/models/user.dart' as models;
import 'package:moto_rent_dumaguete/services/supabase_service.dart';
import 'package:moto_rent_dumaguete/services/resend_service.dart';
import 'package:moto_rent_dumaguete/services/otp_service.dart';
import 'package:moto_rent_dumaguete/config/supabase_config.dart';

class AuthServiceSupabase extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService.instance;
  final ResendService _resendService = ResendService();

  models.User? _currentUser;
  String? _error;
  bool _isLoading = false;

  models.User? get currentUser => _currentUser;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  // Note: Your web app uses admin_users table for admins
  // Regular users don't have a role field, so this always returns false
  bool get isAdmin => false;

  AuthServiceSupabase() {
    _initAuthListener();
    _loadCurrentUser();
  }

  // Listen to auth state changes
  void _initAuthListener() {
    _supabase.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        _loadCurrentUser();
      } else if (event == AuthChangeEvent.signedOut) {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  // Load current user from Supabase
  Future<void> _loadCurrentUser() async {
    final user = _supabase.currentUser;
    if (user == null) {
      _currentUser = null;
      notifyListeners();
      return;
    }

    try {
      // Fetch user profile from database
      final userData =
          await _supabase.getById(SupabaseConfig.usersTable, user.id);

      if (userData != null) {
        // Check if email is verified in Supabase Auth
        final isEmailVerifiedInAuth = user.emailConfirmedAt != null;
        // If email is verified in Supabase Auth, mark as verified in local user
        final emailVerified =
            userData['email_verified'] ?? isEmailVerifiedInAuth;

        _currentUser = models.User.fromJson({
          ...userData,
          'id': user.id,
          'email': user.email,
          'email_verified':
              emailVerified, // Use Supabase Auth status if available
        });
        print('DEBUG: User loaded from database');
        print('DEBUG: email_verified from DB: ${userData['email_verified']}');
        print(
            'DEBUG: email confirmed in Supabase Auth: $isEmailVerifiedInAuth');
        print('DEBUG: User.emailVerified: ${_currentUser?.emailVerified}');
      } else {
        // User profile doesn't exist in database
        // Check if this is a new user or a deleted account
        final authUser = _supabase.client.auth.currentUser;

        if (authUser != null) {
          final createdAt = DateTime.parse(authUser.createdAt);
          final accountAge = DateTime.now().difference(createdAt);

          // If account is older than 5 minutes but no profile exists,
          // it was likely deleted - sign out the user
          if (accountAge.inMinutes > 5) {
            print(
                'DEBUG: User profile not found for existing account - signing out');
            await _supabase.client.auth.signOut();
            _currentUser = null;
            notifyListeners();
            return;
          }
        }

        // Create user profile for new accounts
        _currentUser = models.User(
          id: user.id,
          name: user.userMetadata?['name'] ?? user.email?.split('@')[0] ?? '',
          email: user.email ?? '',
          username: user.userMetadata?['username'],
          phone: user.userMetadata?['phone'] ?? '',
          createdAt: DateTime.now(),
        );

        // Save to database
        await _supabase.insert(
            SupabaseConfig.usersTable, _currentUser!.toJson());
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Send OTP verification email
  Future<bool> sendOtpEmail(String email, String otp) async {
    try {
      print('🔷 [AuthService] sendOtpEmail called for $email');
      print('🔷 [AuthService] OTP: $otp');

      final emailSent = await _resendService.sendOtpEmail(
        email: email,
        otp: otp,
      );

      if (emailSent) {
        print('🔷 [AuthService] ✅ OTP email sent successfully!');
        return true;
      } else {
        print('🔷 [AuthService] ⚠️ Warning: Failed to send OTP email');
        return false;
      }
    } catch (e) {
      print('🔷 [AuthService] ❌ Error sending OTP email: $e');
      return false;
    }
  }

  /// Check if email is truly verified in Supabase Auth
  /// This checks emailConfirmedAt timestamp which is the source of truth
  /// Returns true only if email is confirmed in Supabase Auth
  bool isEmailVerifiedInAuth() {
    final user = _supabase.currentUser;
    return user != null && user.emailConfirmedAt != null;
  }

  /// Check if user needs email verification on mobile app
  /// Returns true only if:
  /// 1. Email is not verified
  /// 2. User signed up from mobile app
  /// Returns false if:
  /// 1. Email is already verified (either from web signup or mobile signup)
  /// 2. User signed up from web app (not mobile)
  bool shouldRequireEmailVerificationOnMobile() {
    if (_currentUser == null) {
      return false;
    }

    // If email is already verified, no need to verify
    if (_currentUser!.emailVerified) {
      return false;
    }

    // Check if user signed up from mobile (has signup_source metadata)
    final signupSource = _supabase.currentUser?.userMetadata?['signup_source'];
    final signedUpFromMobile = signupSource == 'mobile';

    return signedUpFromMobile;
  }

  // Resend OTP verification email
  Future<bool> resendOtpEmail({
    required String email,
    required String otp,
  }) async {
    try {
      print('🔷 [AuthService] resendOtpEmail called for $email');
      print('🔷 [AuthService] OTP: $otp');

      final emailSent = await _resendService.sendOtpEmail(
        email: email,
        otp: otp,
      );

      if (emailSent) {
        print('🔷 [AuthService] ✅ OTP email resent successfully!');
        return true;
      } else {
        print('🔷 [AuthService] ⚠️ Warning: Failed to resend OTP email');
        return false;
      }
    } catch (e) {
      print('🔷 [AuthService] ❌ Error resending OTP email: $e');
      return false;
    }
  }

  // Save user profile to database (called after OTP verification)
  Future<bool> saveUserProfile(String userId) async {
    try {
      if (_currentUser == null) {
        _error = 'User data not found';
        return false;
      }

      final userProfile = {
        'id': userId,
        'name': _currentUser!.name,
        'email': _currentUser!.email,
        'username': _currentUser!.username,
        'phone': _currentUser!.phone,
        'phone_number': _currentUser!.phone, // Also set web app column
        'created_at': _currentUser!.createdAt.toIso8601String(),
        'email_verified': true, // User has verified their email with OTP
      };

      // Use upsert to handle both insert and update cases
      // This prevents "duplicate key" errors if user record already exists
      await _supabase.client
          .from(SupabaseConfig.usersTable)
          .upsert(userProfile);

      print('✅ User profile saved to database');
      return true;
    } catch (e) {
      print('❌ Error saving user profile: $e');
      _error = 'Failed to save user profile: ${e.toString()}';
      return false;
    }
  }

  // Refresh current user data from database
  Future<void> refreshCurrentUser() async {
    await _loadCurrentUser();
  }

  // Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String username,
    required String name,
    required String password,
    required String confirmPassword,
    required String phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Validate inputs
      if (password != confirmPassword) {
        _error = 'Passwords do not match';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check if username already exists
      final existingUsers = await _supabase.getWhere(
        SupabaseConfig.usersTable,
        'username',
        username,
      );

      if (existingUsers.isNotEmpty) {
        _error = 'Username already exists';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Sign up with Supabase Auth
      // Note: For mobile signups, we'll require OTP verification
      // The app will send verification email, and user must verify before accessing app
      final response = await _supabase.signUp(
        email: email,
        password: password,
        userData: {
          'name': name,
          'username': username,
          'phone': phone,
          'signup_source': 'mobile', // Track that signup came from mobile app
        },
      );

      if (response.user == null) {
        _error = 'Failed to create account';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Store user data in memory for OTP verification flow
      // User profile will be saved to database ONLY after successful OTP verification
      _currentUser = models.User(
        id: response.user!.id,
        name: name,
        email: email,
        username: username,
        phone: phone,
        createdAt: DateTime.now(),
        emailVerified: false,
      );

      // Send verification via OTP
      try {
        final otp = OtpService.generateOtp();
        final stored = await OtpService.storeOtp(
          email,
          otp,
          userId: response.user!.id,
        );

        if (stored == null) {
          throw Exception('Failed to store OTP in database');
        }

        print('🔷 [SignUp] Generated OTP: $otp');
        print('🔷 [SignUp] Sending OTP to $email...');
        final emailSent = await sendOtpEmail(email, otp);
        if (emailSent) {
          print('🔷 [SignUp] ✅ OTP email sent successfully!');
        } else {
          print(
              '🔷 [SignUp] ⚠️ Warning: Failed to send OTP email, but continuing...');
          // Continue anyway - user can request resend later
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } catch (e) {
        print('🔷 [SignUp] ❌ Exception in OTP sending: $e');
        // If OTP sending fails, delete the auth user to prevent orphaned accounts
        try {
          await _supabase.client.auth.admin.deleteUser(response.user!.id);
        } catch (deleteError) {
          print('Failed to cleanup auth user: $deleteError');
        }

        // Sign out to clear the session
        await _supabase.signOut();
        _currentUser = null;

        _error = 'Failed to send verification code: ${e.toString()}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on AuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login with email/username and password
  Future<bool> login({
    required String identifier, // Can be email or username
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String email = identifier;

      // If identifier is not an email, look up email by username
      if (!identifier.contains('@')) {
        final users = await _supabase.getWhere(
          SupabaseConfig.usersTable,
          'username',
          identifier,
        );

        if (users.isEmpty) {
          _error = 'User not found';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        email = users.first['email'];
      }

      // Sign in with Supabase Auth
      final response = await _supabase.signIn(
        email: email,
        password: password,
      );

      if (response.user == null) {
        _error = 'Invalid credentials';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _loadCurrentUser();
      _isLoading = false;
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _supabase.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Forgot password
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Request email confirmation
  // Supabase Auth will send confirmation email automatically when emailRedirectTo is set
  // Users click the link in the email to confirm their account
  Future<bool> confirmEmail({required String email}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Update user as verified in database
      await _supabase.client.from(SupabaseConfig.usersTable).update({
        'email_verified': true,
        'updated_at': DateTime.now().toIso8601String()
      }).eq('email', email);

      // Reload current user
      await _loadCurrentUser();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to confirm email: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? address,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedData = <String, dynamic>{};

      if (firstName != null) updatedData['first_name'] = firstName;
      if (lastName != null) updatedData['last_name'] = lastName;
      if (phoneNumber != null) updatedData['phone_number'] = phoneNumber;
      if (address != null) updatedData['address'] = address;

      updatedData['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.update(
        SupabaseConfig.usersTable,
        _currentUser!.id,
        updatedData,
      );

      await _loadCurrentUser();
      _isLoading = false;
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update user license information
  Future<bool> updateUserLicense({
    required String licenseNumber,
    required String licenseImageUrl,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedData = {
        'license_number': licenseNumber,
        'driver_license_url': licenseImageUrl, // Use web column
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.update(
        SupabaseConfig.usersTable,
        _currentUser!.id,
        updatedData,
      );

      await _loadCurrentUser();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update user profile (name, username, phone, birthday, address)
  Future<bool> updateUserProfile({
    String? name,
    String? username,
    String? phoneNumber,
    DateTime? birthday,
    String? address,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('DEBUG: Updating user profile...');
      print('DEBUG: Name: $name');
      print('DEBUG: Username: $username');
      print('DEBUG: Phone: $phoneNumber');
      print('DEBUG: Birthday: $birthday');
      print('DEBUG: Address: $address');
      print('DEBUG: User ID: ${_currentUser!.id}');

      final updatedData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updatedData['name'] = name;
      if (username != null) updatedData['username'] = username;
      if (phoneNumber != null) {
        updatedData['phone_number'] = phoneNumber;
        updatedData['phone'] = phoneNumber; // Also update web app column
      }
      if (birthday != null) {
        updatedData['birthday'] = birthday.toIso8601String();
      }
      if (address != null) updatedData['address'] = address;

      print('DEBUG: Update data: $updatedData');

      await _supabase.update(
        SupabaseConfig.usersTable,
        _currentUser!.id,
        updatedData,
      );

      print('DEBUG: Database update successful, reloading user...');
      await _loadCurrentUser();

      print('DEBUG: Profile updated successfully');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('ERROR: Failed to update profile: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Change password
  Future<bool> changePassword({
    required String newPassword,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update password (for password reset flow)
  Future<bool> updatePassword({
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Update password using Supabase auth
      await _supabase.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete account
  Future<bool> deleteAccount({
    required String password,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Verify password by attempting to sign in
      final email = _currentUser!.email;
      try {
        await _supabase.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } catch (e) {
        _error = 'Incorrect password';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 2. Call Edge Function to delete user account
      final userId = _currentUser!.id;

      try {
        final response = await _supabase.client.functions.invoke(
          'delete-user-account',
          body: {'userId': userId},
        );

        if (response.status != 200) {
          throw Exception('Failed to delete account: ${response.data}');
        }

        print('DEBUG: Account deleted successfully');
      } catch (e) {
        print('ERROR: Edge Function call failed: $e');
        // Fallback: Delete user profile from database and sign out
        await _supabase.delete(SupabaseConfig.usersTable, userId);
        await _supabase.client.auth.signOut();
      }

      // 3. Clear current user and sign out
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update profile picture
  Future<bool> updateProfilePicture({
    required String profileImageUrl,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('DEBUG: Updating profile picture URL: $profileImageUrl');
      print('DEBUG: User ID: ${_currentUser!.id}');

      final updatedData = {
        'profile_picture_url': profileImageUrl, // Use web column
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('DEBUG: Update data: $updatedData');

      await _supabase.update(
        SupabaseConfig.usersTable,
        _currentUser!.id,
        updatedData,
      );

      print('DEBUG: Database update successful, reloading user...');
      await _loadCurrentUser();

      print('DEBUG: Profile picture updated successfully');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('ERROR: Failed to update profile picture: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
