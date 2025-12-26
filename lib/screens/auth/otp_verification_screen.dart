import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:moto_rent_dumaguete/theme/app_theme.dart';
import 'package:moto_rent_dumaguete/services/auth_service_supabase.dart';
import 'package:moto_rent_dumaguete/services/otp_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String userId;
  final bool isMobileSignup;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.userId,
    this.isMobileSignup = true,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  late List<TextEditingController> _otpControllers;
  late List<FocusNode> _focusNodes;
  bool _isVerifying = false;
  String? _error;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _otpControllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());
    _startTimer();
  }

  void _startTimer() {
    _runTimer();
  }

  Future<void> _runTimer() async {
    // Query database to get actual remaining time for display
    // Note: OTP no longer expires - it only becomes invalid when user requests resend
    while (mounted) {
      final remaining = await OtpService.getRemainingTime(widget.email);

      if (remaining == null) {
        // No OTP found for this email
        if (mounted) {
          setState(() {
            _remainingSeconds = 0;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _remainingSeconds = remaining.inSeconds;
        });
      }

      // Update every second
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  Duration? _getRemainingTime() {
    return Duration(seconds: _remainingSeconds);
  }

  void _handleOtpInput(int index, String value) {
    if (value.isEmpty && index > 0) {
      // Backspace pressed - move to previous field
      _focusNodes[index - 1].requestFocus();
    } else if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        // Auto-verify when all digits are entered
        _verifyOtp();
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_isVerifying) return;

    final otp = _otpControllers.map((c) => c.text).join();

    if (otp.length != 6) {
      setState(() {
        _error = 'Please enter all 6 digits';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      // Verify OTP from database
      final isValid = await OtpService.verifyOtp(widget.email, otp);

      if (!isValid) {
        setState(() {
          _error = 'Invalid OTP code. Please try again.';
          _isVerifying = false;
        });
        return;
      }

      // OTP is valid - save user profile and mark email as verified
      if (mounted) {
        final authService =
            Provider.of<AuthServiceSupabase>(context, listen: false);

        try {
          // Save user profile to database (first time)
          final saved = await authService.saveUserProfile(widget.userId);

          if (!saved) {
            setState(() {
              _error = 'Error saving user profile. Please try again.';
              _isVerifying = false;
            });
            return;
          }

          print('✅ User profile saved to database with verified email');

          // Refresh user data from database
          await authService.refreshCurrentUser();

          if (mounted) {
            // Navigate to home
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/',
              (route) => false,
            );
          }
        } catch (e) {
          print('Error saving user profile: $e');
          setState(() {
            _error = 'Error completing registration. Please try again.';
            _isVerifying = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isVerifying = false;
      });
    }
  }

  void _resendOtp() async {
    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      final authService =
          Provider.of<AuthServiceSupabase>(context, listen: false);

      // Generate new OTP and store in database
      final newOtp =
          await OtpService.resendOtp(widget.email, userId: widget.userId);

      if (newOtp == null) {
        if (mounted) {
          setState(() {
            _error = 'Failed to generate new OTP. Please try again.';
            _isVerifying = false;
          });
        }
        return;
      }

      // Send new OTP via email
      final emailSent = await authService.resendOtpEmail(
        email: widget.email,
        otp: newOtp,
      );

      if (mounted) {
        if (emailSent) {
          setState(() {
            _isVerifying = false;
            _error = null;
          });
          // Clear OTP fields
          for (var controller in _otpControllers) {
            controller.clear();
          }
          // Restart timer
          _startTimer();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('New OTP sent to your email!'),
              backgroundColor: AppTheme.successColor,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          setState(() {
            _error = 'Failed to send OTP. Please try again.';
            _isVerifying = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isVerifying = false;
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remainingTime = _getRemainingTime();
    final minutes = remainingTime?.inMinutes ?? 0;
    final seconds = (remainingTime?.inSeconds ?? 0) % 60;

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

                // Lock icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryColor.withOpacity(0.1),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lock_outline,
                      size: 48,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                const Text(
                  'Enter Verification Code',
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
                  'We sent a 6-digit code to',
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

                const SizedBox(height: 32),

                // OTP Input Fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    6,
                    (index) => SizedBox(
                      width: 50,
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        enabled: !_isVerifying && remainingTime != null,
                        onChanged: (value) => _handleOtpInput(index, value),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 8,
                          ),
                          filled: true,
                          fillColor: AppTheme.cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppTheme.primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Error message
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      border: Border.all(
                        color: AppTheme.errorColor.withOpacity(0.3),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.errorColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 24),

                // Timer
                if (remainingTime != null)
                  Center(
                    child: Text(
                      'Expires in ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 14,
                        color: seconds < 30
                            ? AppTheme.warningColor
                            : Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                // Verify Button
                ElevatedButton(
                  onPressed:
                      _isVerifying || remainingTime == null ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    disabledBackgroundColor:
                        AppTheme.primaryColor.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isVerifying
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
                          'Verify Code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.backgroundColor,
                          ),
                        ),
                ),

                const SizedBox(height: 16),

                // Resend Button
                TextButton(
                  onPressed: _isVerifying ? null : _resendOtp,
                  child: Text(
                    'Didn\'t receive the code? Resend',
                    style: TextStyle(
                      fontSize: 14,
                      color: _isVerifying
                          ? Colors.white.withOpacity(0.5)
                          : AppTheme.primaryColor,
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
                      color: Colors.white54,
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
}
