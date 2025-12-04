import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moto_rent_dumaguete/services/auth_service_supabase.dart';
import 'package:moto_rent_dumaguete/theme/app_theme.dart';
import 'package:moto_rent_dumaguete/widgets/custom_text_field.dart';
import 'package:moto_rent_dumaguete/widgets/loading_button.dart';
import 'package:moto_rent_dumaguete/screens/auth/otp_verification_screen.dart';

class SignUpScreen extends StatefulWidget {
  final VoidCallback onSignUpSuccess;
  final VoidCallback onSwitchToLogin;

  const SignUpScreen({
    super.key,
    required this.onSignUpSuccess,
    required this.onSwitchToLogin,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your full name';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a username';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters long';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService =
          Provider.of<AuthServiceSupabase>(context, listen: false);

      final success = await authService.signUp(
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        name: _fullNameController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _passwordController.text,
        phone: _phoneController.text.trim(),
      );

      if (success && mounted) {
        final email = _emailController.text.trim();
        final userId = authService.currentUser?.id;

        // Signup successful - show OTP verification screen
        // User must verify their email with OTP before they can access the app
        if (userId != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                email: email,
                userId: userId,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to get user ID. Please try again.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authService.error ??
                'Failed to create account. Please try again.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create account: ${error.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // Welcome text
              const Text(
                'Sign Up',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Create your account',
                style: TextStyle(
                  fontSize: 16,
                  color: textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Full Name field
              CustomTextField(
                controller: _fullNameController,
                label: 'Full Name',
                hintText: 'Enter your full name',
                prefixIcon: Icons.person,
                validator: _validateFullName,
              ),

              const SizedBox(height: 20),

              // Username field
              CustomTextField(
                controller: _usernameController,
                label: 'Username',
                hintText: 'Choose a username',
                prefixIcon: Icons.alternate_email,
                validator: _validateUsername,
              ),

              const SizedBox(height: 4),

              // Username hint
              Text(
                'Alphanumeric and underscores only, min. 3 characters',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary.withOpacity(0.8),
                ),
              ),

              const SizedBox(height: 16),

              // Email field
              CustomTextField(
                controller: _emailController,
                label: 'Email',
                hintText: 'Enter your email',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email,
                validator: _validateEmail,
              ),

              const SizedBox(height: 20),

              // Phone field
              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hintText: 'Enter your phone number',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone,
                validator: _validatePhone,
              ),

              const SizedBox(height: 20),

              // Password field
              CustomTextField(
                controller: _passwordController,
                label: 'Password',
                hintText: 'Create a password',
                obscureText: _obscurePassword,
                prefixIcon: Icons.lock,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                validator: _validatePassword,
              ),

              const SizedBox(height: 32),

              // Sign up button
              LoadingButton(
                onPressed: _handleSignUp,
                isLoading: _isLoading,
                text: 'Sign Up',
              ),

              const SizedBox(height: 24),

              // Already have account
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onSwitchToLogin,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Login here',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
