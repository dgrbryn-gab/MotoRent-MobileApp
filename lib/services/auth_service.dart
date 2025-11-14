import 'package:flutter/foundation.dart';
import 'package:moto_rent_dumaguete/models/user.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<bool> login({
    required String identifier, // Can be email or username
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      // Temporary demo authentication for development/testing
      // TODO: Replace with actual backend API authentication
      if (identifier == 'admin' && password == 'admin123') {
        _currentUser = User(
          id: 'admin-1',
          email: 'admin@motorent.com',
          username: 'admin',
          name: 'Admin User',
          phone: '+63 123 456 7890',
          createdAt: DateTime.now(),
        );
        _setLoading(false);
        notifyListeners();
        return true;
      } else if (identifier == 'demo' && password == 'demo123') {
        _currentUser = User(
          id: 'user-demo',
          email: 'demo@motorent.com',
          username: 'demo',
          name: 'Demo User',
          phone: '+63 123 456 7890',
          createdAt: DateTime.now(),
        );
        _setLoading(false);
        notifyListeners();
        return true;
      }

      // Authentication logic
      // In a real app, this would make an API call to your backend
      // TODO: Implement actual authentication with your backend API
      _setError(
          'Invalid credentials. Use demo accounts or connect to your backend API.');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String username,
    required String firstName,
    required String lastName,
    required String password,
    required String confirmPassword,
    String? phoneNumber,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      if (password != confirmPassword) {
        _setError('Passwords do not match');
        _setLoading(false);
        return false;
      }

      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      // Mock user creation
      _currentUser = User(
        id: 'user-${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        name: '$firstName $lastName',
        username: username,
        phone: phoneNumber ?? '',
        createdAt: DateTime.now(),
      );

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Sign up failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _setError(null);

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      // Mock password reset
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Password reset failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? address,
    String? profileImageUrl,
  }) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    _setError(null);

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      _currentUser = _currentUser!.copyWith(
        name: firstName != null && lastName != null
            ? '$firstName $lastName'
            : _currentUser!.name,
        phone: phoneNumber ?? _currentUser!.phone,
        updatedAt: DateTime.now(),
      );

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Profile update failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> uploadLicense({
    required String licenseNumber,
    required String licenseImageUrl,
  }) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    _setError(null);

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));

      // Note: Web app uses document_verifications table for license verification
      // This is a mock implementation
      _currentUser = _currentUser!.copyWith(
        updatedAt: DateTime.now(),
      );

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('License upload failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
