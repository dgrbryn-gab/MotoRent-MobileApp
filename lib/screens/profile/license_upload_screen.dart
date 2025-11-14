import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moto_rent_dumaguete/services/auth_service_supabase.dart';
import 'package:moto_rent_dumaguete/services/storage_service_supabase.dart';
import 'package:moto_rent_dumaguete/theme/app_theme.dart';
import 'package:moto_rent_dumaguete/widgets/custom_text_field.dart';
import 'package:moto_rent_dumaguete/widgets/loading_button.dart';

class LicenseUploadScreen extends StatefulWidget {
  const LicenseUploadScreen({super.key});

  @override
  State<LicenseUploadScreen> createState() => _LicenseUploadScreenState();
}

class _LicenseUploadScreenState extends State<LicenseUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _licenseNumberController = TextEditingController();
  String? _licenseImageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill existing license data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService =
          Provider.of<AuthServiceSupabase>(context, listen: false);
      if (authService.currentUser != null) {
        final user = authService.currentUser!;
        if (user.licenseNumber != null) {
          _licenseNumberController.text = user.licenseNumber!;
        }
        if (user.licenseImageUrl != null) {
          setState(() {
            _licenseImageUrl = user.licenseImageUrl;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _licenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickLicenseImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null && mounted) {
      setState(() {
        _isUploading = true;
      });

      try {
        final storageService =
            Provider.of<StorageServiceSupabase>(context, listen: false);
        final authService =
            Provider.of<AuthServiceSupabase>(context, listen: false);

        print('DEBUG: Starting license upload...');
        print('DEBUG: Image path: ${image.path}');
        print('DEBUG: User ID: ${authService.currentUser!.id}');

        // Upload to Supabase Storage
        final imageUrl = await storageService.uploadLicense(
          filePath: image.path,
          userId: authService.currentUser!.id,
        );

        print('DEBUG: Upload result: $imageUrl');

        if (imageUrl != null) {
          setState(() {
            _licenseImageUrl = imageUrl;
            _isUploading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('License image uploaded successfully'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }
        } else {
          throw Exception(
              'Upload returned null - check Supabase Storage permissions');
        }
      } catch (e) {
        print('ERROR in license upload: $e');
        setState(() {
          _isUploading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Future<void> _saveLicenseInfo() async {
    if (!_formKey.currentState!.validate()) return;

    if (_licenseImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your license image'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final authService =
          Provider.of<AuthServiceSupabase>(context, listen: false);

      // Update user profile with license information
      await authService.updateUserLicense(
        licenseNumber: _licenseNumberController.text.trim(),
        licenseImageUrl: _licenseImageUrl!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('License information saved successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppTheme.backgroundColor : AppTheme.lightBackgroundColor;
    final bgSecondary = isDark
        ? AppTheme.backgroundSecondary
        : AppTheme.lightBackgroundSecondary;
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final cardColor = isDark ? AppTheme.cardColor : AppTheme.lightCardColor;
    final borderColor =
        isDark ? AppTheme.borderColor : AppTheme.lightBorderColor;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgColor, bgSecondary],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: textPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Driver\'s License',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            'Upload your license for faster bookings',
                            style: TextStyle(
                              fontSize: 14,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Info Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: AppTheme.primaryColor,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Your license will be automatically used when making reservations',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // License Number Field
                        CustomTextField(
                          controller: _licenseNumberController,
                          label: 'License Number *',
                          keyboardType: TextInputType.text,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your license number';
                            }
                            if (value.length < 8) {
                              return 'License number must be at least 8 characters';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // License Image Upload
                        Text(
                          'License Image *',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        GestureDetector(
                          onTap: _isUploading ? null : _pickLicenseImage,
                          child: Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: _isUploading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: AppTheme.primaryColor,
                                    ),
                                  )
                                : _licenseImageUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Stack(
                                          children: [
                                            Image.network(
                                              _licenseImageUrl!,
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.error_outline,
                                                        size: 48,
                                                        color: textSecondary,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'Failed to load image',
                                                        style: TextStyle(
                                                            color:
                                                                textSecondary),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: AppTheme.errorColor,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: IconButton(
                                                  icon: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      _licenseImageUrl = null;
                                                    });
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.cloud_upload_outlined,
                                            size: 48,
                                            color: textSecondary,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Tap to upload license image',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Clear photo of your driver\'s license',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Requirements
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppTheme.warningColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info,
                                color: AppTheme.warningColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Requirements:\n• Valid driver\'s license\n• Clear and readable photo\n• Not expired',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: LoadingButton(
                            onPressed: _saveLicenseInfo,
                            isLoading: _isUploading,
                            text: 'Save License Information',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
