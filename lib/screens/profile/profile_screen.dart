import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moto_rent_dumaguete/services/auth_service_supabase.dart';
import 'package:moto_rent_dumaguete/services/theme_service.dart';
import 'package:moto_rent_dumaguete/services/locale_service.dart';
import 'package:moto_rent_dumaguete/screens/auth/auth_screen.dart';
import 'package:moto_rent_dumaguete/screens/profile/license_upload_screen.dart';
import 'package:moto_rent_dumaguete/screens/profile/edit_profile_screen.dart';
import 'package:moto_rent_dumaguete/screens/profile/security_settings_screen.dart';
import 'package:moto_rent_dumaguete/screens/profile/language_selection_screen.dart';
import 'package:moto_rent_dumaguete/screens/profile/favorites_screen.dart';
import 'package:moto_rent_dumaguete/screens/profile/contact_screen.dart';
import 'package:moto_rent_dumaguete/theme/app_theme.dart';
import 'package:moto_rent_dumaguete/widgets/loading_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh user data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('DEBUG: ProfileScreen loaded, refreshing user data...');
      final authService = context.read<AuthServiceSupabase>();
      if (authService.isAuthenticated) {
        authService.refreshCurrentUser().then((_) {
          print('DEBUG: User data refreshed');
          print(
              'DEBUG: Email verified: ${authService.currentUser?.emailVerified}');
          print(
              'DEBUG: Profile image URL: ${authService.currentUser?.profileImageUrl}');
          print(
              'DEBUG: License image URL: ${authService.currentUser?.licenseImageUrl}');
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppTheme.backgroundColor : AppTheme.lightBackgroundColor;
    final bgSecondary = isDark
        ? AppTheme.backgroundSecondary
        : AppTheme.lightBackgroundSecondary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              bgColor,
              bgSecondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<AuthServiceSupabase>(
            builder: (context, authService, child) {
              if (!authService.isAuthenticated) {
                return _buildGuestView(context);
              }
              return _buildProfileView(context, authService);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGuestView(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final cardColor = isDark ? AppTheme.cardColor : AppTheme.lightCardColor;
    final borderColor =
        isDark ? AppTheme.borderColor : AppTheme.lightBorderColor;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cardColor,
              border: Border.all(color: borderColor),
            ),
            child: Icon(
              Icons.person_outline,
              size: 60,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Welcome to MotoRent',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sign in to access your profile, bookings, and exclusive features.',
            style: TextStyle(
              fontSize: 16,
              color: textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AuthScreen(),
                  ),
                );
              },
              child: const Text('Sign In'),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AuthScreen(),
                  ),
                );
              },
              child: const Text('Create Account'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView(
      BuildContext context, AuthServiceSupabase authService) {
    final user = authService.currentUser!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final cardColor = isDark ? AppTheme.cardColor : AppTheme.lightCardColor;
    final borderColor =
        isDark ? AppTheme.borderColor : AppTheme.lightBorderColor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Profile header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: user.profileImageUrl != null
                      ? ClipOval(
                          child: Image.network(
                            user.profileImageUrl!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                size: 50,
                                color: AppTheme.primaryColor,
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          size: 50,
                          color: AppTheme.primaryColor,
                        ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.fullName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: user.isVerified
                        ? AppTheme.successColor
                        : AppTheme.warningColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    user.isVerified ? 'Verified' : 'Pending Verification',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Menu items
          _buildMenuItem(
            context: context,
            icon: Icons.person_outline,
            title: 'Edit Profile',
            subtitle: 'Update your personal information',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),

          _buildMenuItem(
            context: context,
            icon: Icons.badge_outlined,
            title: 'Driver\'s License',
            subtitle: user.hasLicense
                ? 'License uploaded ✓'
                : 'Upload or update license information',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LicenseUploadScreen(),
                ),
              );
            },
          ),

          _buildMenuItem(
            context: context,
            icon: Icons.favorite_outline,
            title: 'Favorites',
            subtitle: 'Your saved motorcycles',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FavoritesScreen(),
                ),
              );
            },
          ),

          Consumer<LocaleService>(
            builder: (context, localeService, child) {
              final currentLanguage =
                  localeService.getLanguageName(localeService.languageCode);
              return _buildMenuItem(
                context: context,
                icon: Icons.language_outlined,
                title: 'Language',
                subtitle: 'Current: $currentLanguage',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const LanguageSelectionScreen(),
                    ),
                  );
                },
              );
            },
          ),

          _buildMenuItem(
            context: context,
            icon: Icons.security_outlined,
            title: 'Security',
            subtitle: 'Password and security settings',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SecuritySettingsScreen(),
                ),
              );
            },
          ),

          // Dark/Light Mode Toggle
          Consumer<ThemeService>(
            builder: (context, themeService, child) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.borderColor
                          : AppTheme.lightBorderColor,
                    ),
                  ),
                  tileColor: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.cardColor
                      : AppTheme.lightCardColor,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      themeService.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Appearance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.textPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  subtitle: Text(
                    themeService.isDarkMode ? 'Dark Mode' : 'Light Mode',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.textSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  trailing: Switch(
                    value: themeService.isDarkMode,
                    onChanged: (value) {
                      themeService.toggleTheme();
                    },
                    activeThumbColor: AppTheme.primaryColor,
                  ),
                ),
              );
            },
          ),

          _buildMenuItem(
            context: context,
            icon: Icons.contact_support_outlined,
            title: 'Contact Us',
            subtitle: 'Get in touch with us for any inquiries',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ContactScreen(),
                ),
              );
            },
          ),

          _buildMenuItem(
            context: context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'FAQs and support resources',
            onTap: () {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor:
                      isDark ? AppTheme.cardColor : AppTheme.lightCardColor,
                  title: Text(
                    'Help & Support',
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.textPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  content: Text(
                    'Need help? Visit our Contact Us page for direct communication with our team.\n\nEmail: support@motorent.com\nPhone: +63 123 456 7890\n\nOperating Hours:\nMon-Sat: 8AM - 6PM',
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.textSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),

          _buildMenuItem(
            context: context,
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'App version and information',
            onTap: () {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor:
                      isDark ? AppTheme.cardColor : AppTheme.lightCardColor,
                  title: Text(
                    'MotoRent Dumaguete',
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.textPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  content: Text(
                    'Version 1.0.0\n\nPremium motorcycle rental service in Dumaguete City.\n\n© 2025 MotoRent Dumaguete',
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.textSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Logout button
          SizedBox(
            width: double.infinity,
            child: Consumer<AuthServiceSupabase>(
              builder: (context, authService, child) {
                return LoadingButton(
                  onPressed: () async {
                    await authService.logout();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Logged out successfully'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  },
                  isLoading: authService.isLoading,
                  text: 'Logout',
                  backgroundColor: AppTheme.errorColor,
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'MotoRent Dumaguete v1.0.0',
            style: TextStyle(
              fontSize: 12,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final cardColor = isDark ? AppTheme.cardColor : AppTheme.lightCardColor;
    final borderColor =
        isDark ? AppTheme.borderColor : AppTheme.lightBorderColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor),
        ),
        tileColor: cardColor,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: textSecondary,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: textSecondary,
        ),
      ),
    );
  }
}
