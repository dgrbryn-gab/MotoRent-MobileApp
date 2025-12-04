import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:moto_rent_dumaguete/theme/app_theme.dart';
import 'package:moto_rent_dumaguete/services/auth_service_supabase.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isVerified = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _setupVerificationListener();
    _checkVerificationStatus();
  }

  /// Listen for auth state changes (email verification via deeplink)
  void _setupVerificationListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      print('🔐 Auth event in email verification: $event');

      if (event == AuthChangeEvent.userUpdated) {
        // User was updated - might be email verification
        _checkVerificationStatus();
      }
    });
  }

  /// Check if the user's email has been verified
  Future<void> _checkVerificationStatus() async {
    if (!mounted) return;

    setState(() {
      _isChecking = true;
    });

    try {
      // Refresh auth state
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        print('User email confirmed: ${user.emailConfirmedAt}');

        if (user.emailConfirmedAt != null) {
          // Email is verified!
          setState(() {
            _isVerified = true;
            _isChecking = false;
          });

          // Update the user profile in database
          final authService =
              Provider.of<AuthServiceSupabase>(context, listen: false);
          await authService.refreshCurrentUser();

          // Wait a moment for UI to update, then navigate to home
          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            // Navigate to home - the app will automatically handle this
            // when it detects the user is authenticated and email is verified
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/',
              (route) => false,
            );
          }
        }
      }

      setState(() {
        _isChecking = false;
      });
    } catch (e) {
      print('Error checking verification: $e');
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isVerified) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.backgroundColor,
                AppTheme.backgroundSecondary,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.successColor.withOpacity(0.1),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_circle,
                        size: 48,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Email Verified!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your email has been successfully verified.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Redirecting to home...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.backgroundColor,
              AppTheme.backgroundSecondary,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Check email icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryColor.withOpacity(0.1),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.mark_email_unread_outlined,
                      size: 48,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                const Text(
                  'Verify Your Email',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Description
                Text(
                  'We\'ve sent a verification link to',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Email display
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    widget.email,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 24),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'To verify your email:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildStep(
                        number: '1',
                        text: 'Check your email inbox',
                      ),
                      const SizedBox(height: 8),
                      _buildStep(
                        number: '2',
                        text: 'Click the verification link',
                      ),
                      const SizedBox(height: 8),
                      _buildStep(
                        number: '3',
                        text: 'Return to the app (will auto-redirect)',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Troubleshooting
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    border: Border.all(
                      color: Colors.amber.withOpacity(0.3),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Check your spam or junk folder if you don\'t see the email.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Check button
                ElevatedButton(
                  onPressed: _isChecking ? null : _checkVerificationStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    disabledBackgroundColor:
                        AppTheme.primaryColor.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isChecking
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'I\'ve Verified My Email',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.backgroundColor,
                          ),
                        ),
                ),

                const SizedBox(height: 16),

                // Back button
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Back to Sign Up',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep({required String number, required String text}) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryColor,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.backgroundColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }
}
