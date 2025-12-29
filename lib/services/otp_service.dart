import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class OtpService {
  static const int _otpLength = 6;
  static const int _otpExpirationMinutes = 10;

  // Cache for in-memory lookups to reduce database queries
  static final Map<String, OtpData> _otpCache = {};

  /// Generate a random OTP code
  static String generateOtp() {
    final random = Random();
    String otp = '';
    for (int i = 0; i < _otpLength; i++) {
      otp += random.nextInt(10).toString();
    }
    return otp;
  }

  /// Store OTP for a user email in Supabase database
  /// Returns the OTP code if successful, null otherwise
  static Future<String?> storeOtp(String email, String otp,
      {String? userId}) async {
    try {
      final expiresAt = DateTime.now().toUtc().add(
            const Duration(minutes: _otpExpirationMinutes),
          );

      // First, invalidate any previous OTPs for this email
      await _invalidatePreviousOtps(email);

      // Insert new OTP into database
      await Supabase.instance.client.from('otp_codes').insert({
        'email': email,
        'otp_code': otp,
        'is_used': false,
        'expires_at': expiresAt.toIso8601String(),
      });

      // Cache for quick lookups
      _otpCache[email] = OtpData(
        code: otp,
        createdAt: DateTime.now().toUtc(),
        expiresAt: expiresAt,
      );

      print(
          '📝 OTP stored in database for $email: $otp (expires in $_otpExpirationMinutes minutes)');
      return otp;
    } catch (e) {
      print('❌ Error storing OTP in database: $e');
      return null;
    }
  }

  /// Invalidate all previous unused OTPs for an email
  static Future<void> _invalidatePreviousOtps(String email) async {
    try {
      await Supabase.instance.client
          .from('otp_codes')
          .update({'is_used': true})
          .eq('email', email)
          .eq('is_used', false);
    } catch (e) {
      print('⚠️ Error invalidating previous OTPs: $e');
    }
  }

  /// Verify OTP for a user email by checking the database
  /// Only checks if OTP code is correct and hasn't been used
  /// Does NOT check expiration to allow users to check email and return
  static Future<bool> verifyOtp(String email, String code) async {
    try {
      // Query the database for the OTP
      final otpRecords = await Supabase.instance.client
          .from('otp_codes')
          .select()
          .eq('email', email)
          .eq('otp_code', code)
          .eq('is_used', false)
          .order('created_at', ascending: false)
          .limit(1);

      if (otpRecords.isEmpty) {
        print('❌ No valid OTP found for $email with code $code');
        return false;
      }

      final otpRecord = otpRecords.first;

      // Mark OTP as used
      await Supabase.instance.client
          .from('otp_codes')
          .update({'is_used': true}).eq('id', otpRecord['id']);

      // Clear from cache
      _otpCache.remove(email);

      print('✅ OTP verified successfully for $email');
      return true;
    } catch (e) {
      print('❌ Error verifying OTP: $e');
      return false;
    }
  }

  /// Get remaining time for OTP display only (informational, not enforced)
  /// This shows the expiration time but doesn't prevent verification
  static Future<Duration?> getRemainingTime(String email) async {
    try {
      // Check cache first
      final cachedData = _otpCache[email];
      if (cachedData != null) {
        final remaining =
            cachedData.expiresAt.difference(DateTime.now().toUtc());
        return remaining.isNegative ? Duration.zero : remaining;
      }

      // Query database if not in cache
      final otpRecords = await Supabase.instance.client
          .from('otp_codes')
          .select()
          .eq('email', email)
          .eq('is_used', false)
          .order('created_at', ascending: false)
          .limit(1);

      if (otpRecords.isEmpty) {
        return null;
      }

      final otpRecord = otpRecords.first;
      final expiresAt = DateTime.parse(otpRecord['expires_at']).toUtc();

      // Cache it for next time
      _otpCache[email] = OtpData(
        code: otpRecord['otp_code'],
        createdAt: DateTime.parse(otpRecord['created_at']).toUtc(),
        expiresAt: expiresAt,
      );

      final remaining = expiresAt.difference(DateTime.now().toUtc());
      return remaining.isNegative ? Duration.zero : remaining;
    } catch (e) {
      print('⚠️ Error getting remaining time: $e');
      return null;
    }
  }

  /// Resend OTP (generate new one and store in database)
  static Future<String?> resendOtp(String email, {String? userId}) async {
    final newOtp = generateOtp();
    return await storeOtp(email, newOtp, userId: userId);
  }

  /// Clear cache (useful for testing)
  static void clearCache() {
    _otpCache.clear();
  }
}

class OtpData {
  final String code;
  final DateTime createdAt;
  final DateTime expiresAt;

  OtpData({
    required this.code,
    required this.createdAt,
    required this.expiresAt,
  });
}
