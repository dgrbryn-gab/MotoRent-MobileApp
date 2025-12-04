import 'package:dio/dio.dart';

class ResendService {
  static const String _apiKey = 're_SyCJDxpK_4tzv6m16rRUL5sgUPJisPMu1';
  // Using verified custom domain for production
  // Domain verified and configured in Resend dashboard
  static const String _fromEmail = 'noreply@motorent-dumaguete.site';
  static const String _appName = 'MotoRent Dumaguete';
  static const String _baseUrl = 'https://api.resend.com';

  late final Dio _dio;

  ResendService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
    ));
  }

  /// Send email verification to user
  Future<bool> sendVerificationEmail({
    required String email,
    required String userName,
    required String verificationLink,
  }) async {
    try {
      final response = await _dio.post(
        '/emails',
        data: {
          'from': _fromEmail,
          'to': email,
          'subject': 'Verify Your Email - $_appName',
          'html': _buildVerificationEmailHtml(
            userName: userName,
            verificationLink: verificationLink,
          ),
        },
      );

      return response.statusCode == 200 && response.data['id'] != null;
    } catch (e) {
      print('Error sending verification email: $e');
      return false;
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail({
    required String email,
    required String resetLink,
  }) async {
    try {
      final response = await _dio.post(
        '/emails',
        data: {
          'from': _fromEmail,
          'to': email,
          'subject': 'Reset Your Password - $_appName',
          'html': _buildPasswordResetEmailHtml(resetLink: resetLink),
        },
      );

      return response.statusCode == 200 && response.data['id'] != null;
    } catch (e) {
      print('Error sending password reset email: $e');
      return false;
    }
  }

  /// Send OTP verification email
  Future<bool> sendOtpEmail({
    required String email,
    required String otp,
  }) async {
    try {
      print('📧 [Resend] Sending OTP to $email');
      print('📧 [Resend] Using from address: $_fromEmail');

      final response = await _dio.post(
        '/emails',
        data: {
          'from': _fromEmail,
          'to': email,
          'subject': 'Your OTP Code - $_appName',
          'html': _buildOtpEmailHtml(otp: otp),
        },
      );

      print('📧 [Resend] Response status: ${response.statusCode}');
      print('📧 [Resend] Response data: ${response.data}');

      final success = response.statusCode == 200 && response.data['id'] != null;
      if (success) {
        print(
            '✅ [Resend] OTP email sent successfully! ID: ${response.data['id']}');
      } else {
        print('❌ [Resend] Failed to send OTP - invalid response');
      }

      return success;
    } on DioException catch (e) {
      print('❌ [Resend] DioException: ${e.message}');
      print('❌ [Resend] Response: ${e.response?.data}');
      print('❌ [Resend] Status Code: ${e.response?.statusCode}');
      return false;
    } catch (e) {
      print('❌ [Resend] Error sending OTP email: $e');
      print('❌ [Resend] Error type: ${e.runtimeType}');
      return false;
    }
  }

  /// Build HTML for verification email
  String _buildVerificationEmailHtml({
    required String userName,
    required String verificationLink,
  }) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <style>
        body {
          font-family: Arial, sans-serif;
          background-color: #0f172a;
          color: #e2e8f0;
          margin: 0;
          padding: 0;
        }
        .container {
          max-width: 600px;
          margin: 0 auto;
          padding: 20px;
          background-color: #1e293b;
          border-radius: 8px;
          margin-top: 20px;
        }
        .header {
          text-align: center;
          padding-bottom: 20px;
          border-bottom: 2px solid #ff7a00;
        }
        .header h1 {
          color: #ff7a00;
          margin: 0;
          font-size: 24px;
        }
        .content {
          padding: 30px 0;
        }
        .button-container {
          text-align: center;
          margin: 30px 0;
        }
        .button {
          background-color: #ff7a00;
          color: #0f172a;
          padding: 12px 30px;
          text-decoration: none;
          border-radius: 4px;
          font-weight: bold;
          display: inline-block;
        }
        .button:hover {
          background-color: #ff6b00;
        }
        .footer {
          text-align: center;
          padding-top: 20px;
          border-top: 1px solid #334155;
          font-size: 12px;
          color: #94a3b8;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>$_appName</h1>
        </div>
        <div class="content">
          <p>Hi $userName,</p>
          <p>Thank you for signing up! Please verify your email address by clicking the button below:</p>
          <div class="button-container">
            <a href="$verificationLink" class="button">Verify Email</a>
          </div>
          <p>Or copy and paste this link in your browser:</p>
          <p style="word-break: break-all; color: #cbd5e1;">$verificationLink</p>
          <p>This verification link will expire in 24 hours.</p>
          <p>If you didn't create this account, you can safely ignore this email.</p>
        </div>
        <div class="footer">
          <p>&copy; 2024 $_appName. All rights reserved.</p>
        </div>
      </div>
    </body>
    </html>
    ''';
  }

  /// Build HTML for password reset email
  String _buildPasswordResetEmailHtml({required String resetLink}) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <style>
        body {
          font-family: Arial, sans-serif;
          background-color: #0f172a;
          color: #e2e8f0;
          margin: 0;
          padding: 0;
        }
        .container {
          max-width: 600px;
          margin: 0 auto;
          padding: 20px;
          background-color: #1e293b;
          border-radius: 8px;
          margin-top: 20px;
        }
        .header {
          text-align: center;
          padding-bottom: 20px;
          border-bottom: 2px solid #ff7a00;
        }
        .header h1 {
          color: #ff7a00;
          margin: 0;
          font-size: 24px;
        }
        .content {
          padding: 30px 0;
        }
        .button-container {
          text-align: center;
          margin: 30px 0;
        }
        .button {
          background-color: #ff7a00;
          color: #0f172a;
          padding: 12px 30px;
          text-decoration: none;
          border-radius: 4px;
          font-weight: bold;
          display: inline-block;
        }
        .button:hover {
          background-color: #ff6b00;
        }
        .footer {
          text-align: center;
          padding-top: 20px;
          border-top: 1px solid #334155;
          font-size: 12px;
          color: #94a3b8;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>$_appName</h1>
        </div>
        <div class="content">
          <p>We received a request to reset your password.</p>
          <p>Click the button below to reset your password:</p>
          <div class="button-container">
            <a href="$resetLink" class="button">Reset Password</a>
          </div>
          <p>Or copy and paste this link in your browser:</p>
          <p style="word-break: break-all; color: #cbd5e1;">$resetLink</p>
          <p>This link will expire in 1 hour.</p>
          <p>If you didn't request a password reset, you can safely ignore this email.</p>
        </div>
        <div class="footer">
          <p>&copy; 2024 $_appName. All rights reserved.</p>
        </div>
      </div>
    </body>
    </html>
    ''';
  }

  /// Build HTML for OTP verification email
  String _buildOtpEmailHtml({required String otp}) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <style>
        body {
          font-family: Arial, sans-serif;
          background-color: #0f172a;
          color: #e2e8f0;
          margin: 0;
          padding: 0;
        }
        .container {
          max-width: 600px;
          margin: 0 auto;
          padding: 20px;
          background-color: #1e293b;
          border-radius: 8px;
          margin-top: 20px;
        }
        .header {
          text-align: center;
          padding-bottom: 20px;
          border-bottom: 2px solid #ff7a00;
        }
        .header h1 {
          color: #ff7a00;
          margin: 0;
          font-size: 24px;
        }
        .content {
          padding: 30px 0;
        }
        .otp-container {
          text-align: center;
          margin: 30px 0;
        }
        .otp-code {
          background-color: #334155;
          border: 2px solid #ff7a00;
          padding: 20px;
          border-radius: 8px;
          font-size: 36px;
          font-weight: bold;
          letter-spacing: 8px;
          color: #ff7a00;
          font-family: 'Courier New', monospace;
          word-spacing: 10px;
        }
        .expiry-notice {
          text-align: center;
          color: #ff6b6b;
          font-weight: bold;
          margin-top: 15px;
        }
        .footer {
          text-align: center;
          padding-top: 20px;
          border-top: 1px solid #334155;
          font-size: 12px;
          color: #94a3b8;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>$_appName</h1>
        </div>
        <div class="content">
          <p>Your OTP verification code is:</p>
          <div class="otp-container">
            <div class="otp-code">$otp</div>
            <div class="expiry-notice">⏱ Valid for 15 minutes</div>
          </div>
          <p style="text-align: center; color: #cbd5e1;">
            Don't share this code with anyone. $_appName staff will never ask you for this code.
          </p>
          <p>If you didn't request this code, you can safely ignore this email.</p>
        </div>
        <div class="footer">
          <p>&copy; 2024 $_appName. All rights reserved.</p>
        </div>
      </div>
    </body>
    </html>
    ''';
  }
}
