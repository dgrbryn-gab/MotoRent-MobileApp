import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moto_rent_dumaguete/models/user.dart' as models;
import 'package:moto_rent_dumaguete/services/supabase_service.dart';
import 'package:moto_rent_dumaguete/config/supabase_config.dart';

class AuthServiceSupabase extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService.instance;

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
        _currentUser = models.User.fromJson({
          ...userData,
          'id': user.id,
          'email': user.email,
        });
        print('DEBUG: User loaded from database');
        print('DEBUG: email_verified from DB: ${userData['email_verified']}');
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
          username: user.email?.split('@')[0],
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
      final response = await _supabase.signUp(
        email: email,
        password: password,
        userData: {
          'name': name,
          'username': username,
          'phone': phone,
        },
      );

      if (response.user == null) {
        _error = 'Failed to create account';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Create user profile in database
      try {
        final userProfile = {
          'id': response.user!.id, // Use Supabase Auth user ID
          'name': name,
          'email': email,
          'username': username,
          'phone': phone,
          'phone_number': phone, // Also set web app column
          'created_at': DateTime.now().toIso8601String(),
          'email_verified': false, // Will be set to true after OTP verification
        };

        await _supabase.insert(SupabaseConfig.usersTable, userProfile);

        _currentUser = models.User(
          id: response.user!.id,
          name: name,
          email: email,
          username: username,
          phone: phone,
          createdAt: DateTime.now(),
          emailVerified: false,
        );
        _isLoading = false;
        notifyListeners();
        return true;
      } catch (e) {
        // If profile creation fails, delete the auth user to prevent orphaned accounts
        try {
          await _supabase.client.auth.admin.deleteUser(response.user!.id);
        } catch (deleteError) {
          print('Failed to cleanup auth user: $deleteError');
        }

        // Sign out to clear the session
        await _supabase.signOut();

        _error = 'Failed to create user profile: ${e.toString()}';
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

  // Generate and send OTP code to email
  Future<bool> sendOTP({required String email, required String userId}) async {
    try {
      // Generate 6-digit OTP
      final otp = _generateOTP();
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));

      print('========================================');
      print('Sending OTP to: $email');
      print('OTP CODE: $otp');
      print('User ID: $userId');
      print('========================================');

      // Store OTP in database
      try {
        await _supabase.insert('otp_codes', {
          'user_id': userId,
          'email': email,
          'otp_code': otp,
          'expires_at': expiresAt.toIso8601String(),
          'is_used': false,
        });
        print('✅ OTP saved to database');
      } catch (dbError) {
        print('❌ Database error: $dbError');
        throw Exception('Failed to save OTP to database: $dbError');
      }

      // Send OTP email via Resend Edge Function
      try {
        final response = await _supabase.client.functions.invoke(
          'send-otp-email',
          body: {
            'email': email,
            'otp': otp,
          },
        );

        print('✅ Edge Function response: ${response.data}');
        print('✅ OTP email sent to $email');
      } catch (emailError) {
        print('❌ Edge Function error: $emailError');
        print('📧 Check if RESEND_API_KEY is set in Supabase Dashboard');
        print('📱 For now, use this OTP to verify: $otp');
        // Don't throw - OTP is still in database and can be used
      }

      return true;
    } catch (e) {
      print('❌ SEND OTP ERROR: ${e.toString()}');
      _error = 'Failed to send OTP: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Verify OTP code
  Future<bool> verifyOTP(
      {required String email, required String otpCode}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get the latest unused OTP for this email
      final otpRecords = await _supabase.client
          .from('otp_codes')
          .select()
          .eq('email', email)
          .eq('otp_code', otpCode)
          .eq('is_used', false)
          .order('created_at', ascending: false)
          .limit(1);

      if (otpRecords.isEmpty) {
        _error = 'Invalid OTP code';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final otpRecord = otpRecords.first;
      final expiresAt = DateTime.parse(otpRecord['expires_at']);

      // Check if OTP is expired
      if (DateTime.now().isAfter(expiresAt)) {
        _error = 'OTP code has expired';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Mark OTP as used
      await _supabase.client
          .from('otp_codes')
          .update({'is_used': true}).eq('id', otpRecord['id']);

      // Update user as verified
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
      _error = 'Failed to verify OTP: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Resend OTP code
  Future<bool> resendOTP({required String email}) async {
    try {
      // Get user ID from email
      final users = await _supabase.getWhere(
        SupabaseConfig.usersTable,
        'email',
        email,
      );

      if (users.isEmpty) {
        _error = 'User not found';
        return false;
      }

      final userId = users.first['id'];

      // Invalidate all previous OTPs for this user
      await _supabase.client
          .from('otp_codes')
          .update({'is_used': true})
          .eq('user_id', userId)
          .eq('is_used', false);

      // Send new OTP
      return await sendOTP(email: email, userId: userId);
    } catch (e) {
      _error = 'Failed to resend OTP: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Generate random 6-digit OTP
  String _generateOTP() {
    final random = DateTime.now().millisecondsSinceEpoch % 1000000;
    return random.toString().padLeft(6, '0');
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

  // Update user profile (name and phone)
  Future<bool> updateUserProfile({
    String? name,
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
      print('DEBUG: Phone: $phoneNumber');
      print('DEBUG: Birthday: $birthday');
      print('DEBUG: Address: $address');
      print('DEBUG: User ID: ${_currentUser!.id}');

      final updatedData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updatedData['name'] = name;
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
