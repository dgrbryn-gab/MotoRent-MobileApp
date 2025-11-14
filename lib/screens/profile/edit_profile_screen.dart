import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moto_rent_dumaguete/services/auth_service_supabase.dart';
import 'package:moto_rent_dumaguete/services/storage_service_supabase.dart';
import 'package:moto_rent_dumaguete/theme/app_theme.dart';
import 'package:moto_rent_dumaguete/widgets/loading_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  DateTime? _selectedBirthday;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthServiceSupabase>();
    final user = authService.currentUser!;
    _nameController = TextEditingController(text: user.name);
    _phoneController = TextEditingController(text: user.phoneNumber);
    _addressController = TextEditingController(text: user.address ?? '');
    _selectedBirthday = user.birthday;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _uploadProfilePicture() async {
    try {
      // Show image source dialog
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor:
                isDark ? AppTheme.cardColor : AppTheme.lightCardColor,
            title: Text(
              'Choose Image Source',
              style: TextStyle(
                color:
                    isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library,
                      color: AppTheme.primaryColor),
                  title: Text(
                    'Gallery',
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.textPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt,
                      color: AppTheme.primaryColor),
                  title: Text(
                    'Camera',
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.textPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      // Pick image
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploadingImage = true);

      // Upload to Supabase Storage
      final authService = context.read<AuthServiceSupabase>();
      final storageService = context.read<StorageServiceSupabase>();

      final imageUrl = await storageService.uploadProfilePicture(
        filePath: image.path,
        userId: authService.currentUser!.id,
      );

      if (imageUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload image to storage'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        setState(() => _isUploadingImage = false);
        return;
      }

      print('DEBUG: Image uploaded successfully: $imageUrl');

      // Update profile with new image URL
      final success = await authService.updateProfilePicture(
        profileImageUrl: imageUrl,
      );

      if (mounted) {
        setState(() => _isUploadingImage = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else {
          // Show the actual error from auth service
          final errorMsg =
              authService.error ?? 'Failed to update profile picture';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $errorMsg'),
              backgroundColor: AppTheme.errorColor,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthServiceSupabase>();

      print('DEBUG: Saving profile...');
      print('DEBUG: Name: ${_nameController.text.trim()}');
      print('DEBUG: Phone: ${_phoneController.text.trim()}');
      print('DEBUG: Birthday: $_selectedBirthday');
      print('DEBUG: Address: ${_addressController.text.trim()}');

      final success = await authService.updateUserProfile(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        birthday: _selectedBirthday,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          Navigator.pop(context);
        } else {
          // Show the actual error from auth service
          final errorMsg = authService.error ?? 'Failed to update profile';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $errorMsg'),
              backgroundColor: AppTheme.errorColor,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 5),
          ),
        );
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
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: textPrimary),
                    ),
                    Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Picture Section
                        Center(
                          child: Stack(
                            children: [
                              Consumer<AuthServiceSupabase>(
                                builder: (context, authService, child) {
                                  final user = authService.currentUser!;
                                  return CircleAvatar(
                                    radius: 60,
                                    backgroundColor:
                                        AppTheme.primaryColor.withOpacity(0.1),
                                    child: user.profileImageUrl != null
                                        ? ClipOval(
                                            child: Image.network(
                                              user.profileImageUrl!,
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
                                                if (loadingProgress == null) {
                                                  return child;
                                                }
                                                return Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                    value: loadingProgress
                                                                .expectedTotalBytes !=
                                                            null
                                                        ? loadingProgress
                                                                .cumulativeBytesLoaded /
                                                            loadingProgress
                                                                .expectedTotalBytes!
                                                        : null,
                                                  ),
                                                );
                                              },
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return const Icon(
                                                  Icons.person,
                                                  size: 60,
                                                  color: AppTheme.primaryColor,
                                                );
                                              },
                                            ),
                                          )
                                        : const Icon(
                                            Icons.person,
                                            size: 60,
                                            color: AppTheme.primaryColor,
                                          ),
                                  );
                                },
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: cardColor,
                                      width: 3,
                                    ),
                                  ),
                                  child: _isUploadingImage
                                      ? const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          ),
                                        )
                                      : IconButton(
                                          icon: const Icon(Icons.camera_alt,
                                              size: 20),
                                          color: Colors.white,
                                          onPressed: _uploadProfilePicture,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Email (Read-only)
                        Consumer<AuthServiceSupabase>(
                          builder: (context, authService, child) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Email',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: cardColor.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark
                                          ? AppTheme.borderColor
                                          : AppTheme.lightBorderColor,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.email_outlined,
                                          color: textSecondary, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          authService.currentUser!.email,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Cannot be changed',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // Full Name
                        Text(
                          'Full Name',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          style: TextStyle(color: textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Enter your full name',
                            hintStyle: TextStyle(
                                color: textSecondary.withOpacity(0.5)),
                            prefixIcon: Icon(Icons.person_outline,
                                color: textSecondary),
                            filled: true,
                            fillColor: cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppTheme.borderColor
                                    : AppTheme.lightBorderColor,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppTheme.borderColor
                                    : AppTheme.lightBorderColor,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppTheme.primaryColor, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your name';
                            }
                            if (value.trim().length < 2) {
                              return 'Name must be at least 2 characters';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Phone Number
                        Text(
                          'Phone Number',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(color: textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Enter your phone number',
                            hintStyle: TextStyle(
                                color: textSecondary.withOpacity(0.5)),
                            prefixIcon: Icon(Icons.phone_outlined,
                                color: textSecondary),
                            filled: true,
                            fillColor: cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppTheme.borderColor
                                    : AppTheme.lightBorderColor,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppTheme.borderColor
                                    : AppTheme.lightBorderColor,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppTheme.primaryColor, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your phone number';
                            }
                            if (value.trim().length < 10) {
                              return 'Please enter a valid phone number';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Birthday
                        Text(
                          'Birthday',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedBirthday ?? DateTime(2000),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: AppTheme.primaryColor,
                                      onPrimary: Colors.white,
                                      surface: isDark
                                          ? AppTheme.cardColor
                                          : Colors.white,
                                      onSurface: isDark
                                          ? AppTheme.textPrimary
                                          : Colors.black,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedBirthday = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? AppTheme.borderColor
                                    : AppTheme.lightBorderColor,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.cake_outlined, color: textSecondary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _selectedBirthday != null
                                        ? '${_selectedBirthday!.month}/${_selectedBirthday!.day}/${_selectedBirthday!.year}'
                                        : 'Select your birthday',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _selectedBirthday != null
                                          ? textPrimary
                                          : textSecondary.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                                Icon(Icons.calendar_today,
                                    color: textSecondary, size: 20),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Address
                        Text(
                          'Address',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _addressController,
                          maxLines: 3,
                          style: TextStyle(color: textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Enter your complete address',
                            hintStyle: TextStyle(
                                color: textSecondary.withOpacity(0.5)),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(bottom: 50),
                              child: Icon(Icons.location_on_outlined,
                                  color: textSecondary),
                            ),
                            filled: true,
                            fillColor: cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppTheme.borderColor
                                    : AppTheme.lightBorderColor,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppTheme.borderColor
                                    : AppTheme.lightBorderColor,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppTheme.primaryColor, width: 2),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: LoadingButton(
                            onPressed: _saveProfile,
                            isLoading: _isLoading,
                            text: 'Save Changes',
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
