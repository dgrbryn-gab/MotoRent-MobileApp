import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moto_rent_dumaguete/models/motorcycle.dart';
import 'package:moto_rent_dumaguete/models/reservation.dart';
import 'package:moto_rent_dumaguete/models/booking.dart'
    show BookingStatus, PaymentMethod;
import 'package:moto_rent_dumaguete/services/booking_service.dart';
import 'package:moto_rent_dumaguete/services/auth_service_supabase.dart';
import 'package:moto_rent_dumaguete/services/storage_service_supabase.dart';
import 'package:moto_rent_dumaguete/screens/main_navigation_screen.dart';
import 'package:moto_rent_dumaguete/theme/app_theme.dart';
import 'package:moto_rent_dumaguete/widgets/custom_text_field.dart';
import 'package:moto_rent_dumaguete/widgets/loading_button.dart';

class BookingScreen extends StatefulWidget {
  final Motorcycle motorcycle;

  const BookingScreen({
    super.key,
    required this.motorcycle,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 1; // Track current step (1-4)

  // Customer Information
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _licenseNumberController = TextEditingController();

  // Emergency Contact
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  // Additional Information
  final _notesController = TextEditingController();

  DateTime? _dateOfBirth;
  DateTime? _pickupDate;
  TimeOfDay? _pickupTime;
  DateTime? _returnDate;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  String? _licenseImageUrl;

  double get _totalDays {
    if (_pickupDate == null || _returnDate == null) return 1;
    final days = _returnDate!.difference(_pickupDate!).inDays;
    return days == 0 ? 1 : days.toDouble();
  }

  double get _subtotal {
    return _totalDays * widget.motorcycle.pricePerDay;
  }

  double get _securityDeposit {
    return _subtotal * 0.20; // 20% of subtotal
  }

  double get _totalAmount {
    return _subtotal + _securityDeposit;
  }

  @override
  void initState() {
    super.initState();
    // Pre-fill customer information from auth service if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService =
          Provider.of<AuthServiceSupabase>(context, listen: false);
      if (authService.isAuthenticated && authService.currentUser != null) {
        final user = authService.currentUser!;
        _fullNameController.text = user.name;
        _emailController.text = user.email;
        _phoneController.text = user.phone;

        // Auto-fill birthday if available
        if (user.birthday != null) {
          setState(() {
            _dateOfBirth = user.birthday;
          });
        }

        // Auto-fill address if available
        if (user.address != null && user.address!.isNotEmpty) {
          _addressController.text = user.address!;
        }

        // Auto-fill license information if already uploaded
        if (user.licenseNumber != null && user.licenseNumber!.isNotEmpty) {
          _licenseNumberController.text = user.licenseNumber!;
        }
        if (user.licenseImageUrl != null && user.licenseImageUrl!.isNotEmpty) {
          setState(() {
            _licenseImageUrl = user.licenseImageUrl;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _licenseNumberController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.cardColor : AppTheme.lightCardColor;
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: cardColor,
              onSurface: textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _dateOfBirth = date;
      });
    }
  }

  Future<void> _selectPickupDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.cardColor : AppTheme.lightCardColor;
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

    // Get current time
    final now = DateTime.now();
    final currentHour = now.hour;

    // If it's after 5 PM, start from tomorrow
    final minDate = currentHour >= 17 ? now.add(const Duration(days: 1)) : now;

    final date = await showDatePicker(
      context: context,
      initialDate: minDate.add(const Duration(days: 1)),
      firstDate: minDate,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: cardColor,
              onSurface: textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _pickupDate = date;
        if (_returnDate != null && _returnDate!.isBefore(date)) {
          _returnDate = null;
        }
      });
    }
  }

  void _showPickupTimeDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.cardColor : AppTheme.lightCardColor;
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Pickup Time',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Available: 8:00 AM - 5:00 PM',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: 10, // 8 AM to 5 PM (10 hours)
                  itemBuilder: (context, index) {
                    final hour = 8 + index;
                    final time = TimeOfDay(hour: hour, minute: 0);
                    final timeString = _formatTimeOfDay(time);

                    return ListTile(
                      leading: const Icon(
                        Icons.access_time,
                        color: AppTheme.primaryColor,
                      ),
                      title: Text(
                        timeString,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                      trailing: _pickupTime?.hour == hour
                          ? const Icon(
                              Icons.check_circle,
                              color: AppTheme.primaryColor,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _pickupTime = time;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:00 $period';
  }

  Future<void> _selectReturnDate() async {
    if (_pickupDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select pickup date first'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.cardColor : AppTheme.lightCardColor;
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

    final date = await showDatePicker(
      context: context,
      initialDate: _pickupDate!.add(const Duration(days: 1)),
      firstDate: _pickupDate!
          .add(const Duration(days: 1)), // Must be at least 1 day after pickup
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: cardColor,
              onSurface: textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _returnDate = date;
      });
    }
  }

  Future<void> _handleBooking() async {
    if (_currentStep == 1) {
      // Step 1: Validate form
      if (!_formKey.currentState!.validate()) return;

      if (_pickupDate == null || _returnDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select pickup and return dates'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      // Validate return date is different from pickup date
      if (_returnDate!.isAtSameMomentAs(_pickupDate!) ||
          _returnDate!.isBefore(_pickupDate!.add(const Duration(days: 1)))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Return date must be at least 1 day after pickup date'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      if (_pickupTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select pickup time'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      if (_dateOfBirth == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your date of birth'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      // Move to step 2 (Document Upload)
      setState(() {
        _currentStep = 2;
      });
      return;
    }

    if (_currentStep == 2) {
      // Step 2: Validate document upload
      if (_licenseImageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload your driver\'s license to continue'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      // Validate license information matches user profile
      final authService =
          Provider.of<AuthServiceSupabase>(context, listen: false);
      final currentUser = authService.currentUser!;

      print('=== VALIDATION DEBUG ===');
      print('Profile Name: "${currentUser.name}"');
      print('Form Name: "${_fullNameController.text.trim()}"');
      print('Profile Email: "${currentUser.email}"');
      print('Form Email: "${_emailController.text.trim()}"');
      print('Profile Phone: "${currentUser.phone}"');
      print('Form Phone: "${_phoneController.text.trim()}"');
      print('Profile License: "${currentUser.licenseNumber}"');
      print('Form License: "${_licenseNumberController.text.trim()}"');

      // Check if license number matches
      if (currentUser.licenseNumber != null &&
          currentUser.licenseNumber!.isNotEmpty) {
        final profileLicense = currentUser.licenseNumber!.trim();
        final formLicense = _licenseNumberController.text.trim();

        print('Comparing licenses: "$profileLicense" vs "$formLicense"');

        if (formLicense != profileLicense) {
          print('❌ License mismatch!');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'License number does not match!\nProfile: "$profileLicense"\nForm: "$formLicense"',
              ),
              backgroundColor: AppTheme.errorColor,
              duration: const Duration(seconds: 5),
            ),
          );
          return;
        }
        print('✅ License matches');
      }

      // Check if name matches (case-insensitive comparison)
      final formName = _fullNameController.text.trim().toLowerCase();
      final userName = currentUser.name.toLowerCase();

      print('Comparing names: "$userName" vs "$formName"');

      if (formName != userName) {
        print('❌ Name mismatch!');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Name mismatch!\nProfile: "${currentUser.name}"\nForm: "${_fullNameController.text.trim()}"',
            ),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }
      print('✅ Name matches');

      // Check if email matches
      final formEmail = _emailController.text.trim().toLowerCase();
      final userEmail = currentUser.email.toLowerCase();

      print('Comparing emails: "$userEmail" vs "$formEmail"');

      if (formEmail != userEmail) {
        print('❌ Email mismatch!');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Email mismatch!\nProfile: "${currentUser.email}"\nForm: "${_emailController.text.trim()}"',
            ),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }
      print('✅ Email matches');

      // Check if phone matches
      final formPhone =
          _phoneController.text.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
      final userPhone = currentUser.phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

      print('Comparing phones: "$userPhone" vs "$formPhone"');

      if (formPhone != userPhone) {
        print('❌ Phone mismatch!');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Phone mismatch!\nProfile: "${currentUser.phone}"\nForm: "${_phoneController.text.trim()}"',
            ),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }
      print('✅ Phone matches');
      print('=== ALL VALIDATIONS PASSED ===');

      // All validations passed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Information verified successfully!'),
          backgroundColor: AppTheme.successColor,
          duration: Duration(seconds: 2),
        ),
      );

      // Move to step 3 (Payment)
      setState(() {
        _currentStep = 3;
      });
      return;
    }

    if (_currentStep == 3) {
      // Step 3: Payment - Move to step 4 (Confirm)
      setState(() {
        _currentStep = 4;
      });
      return;
    }

    if (_currentStep == 4) {
      // Step 4: Create booking
      final authService =
          Provider.of<AuthServiceSupabase>(context, listen: false);
      final bookingService =
          Provider.of<BookingService>(context, listen: false);

      final currentUser = authService.currentUser!;

      final success = await bookingService.createBooking(
        userId: currentUser.id,
        motorcycleId: widget.motorcycle.id,
        motorcycleName: widget.motorcycle.name,
        startDate: _pickupDate!,
        endDate: _returnDate!,
        totalAmount: _totalAmount,
        paymentMethod: _selectedPaymentMethod,
        customerName: currentUser.name,
        customerEmail: currentUser.email,
        customerPhone: currentUser.phone,
        licenseImageUrl: _licenseImageUrl,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (success) {
        if (mounted) {
          // Navigate to reservations tab
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const MainNavigationScreen(initialIndex: 1),
            ),
            (route) => false,
          );

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking created successfully!'),
              backgroundColor: AppTheme.successColor,
              duration: Duration(seconds: 2),
            ),
          );

          // Navigate to reservations tab (index 1 in main navigation)
          // The MainNavigationScreen should handle this
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(bookingService.error ?? 'Booking failed'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  void _showUploadDocumentsDialog(Reservation booking) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.successColor, size: 28),
              SizedBox(width: 12),
              Text(
                'Booking Created!',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your booking has been created successfully.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Step: Upload Documents',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please upload a clear photo of your valid driver\'s license to proceed.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Requirements:',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '• Valid driver\'s license\n• Clear and readable photo\n• Not expired',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('You can upload documents later from My Bookings'),
                    backgroundColor: AppTheme.warningColor,
                  ),
                );
              },
              child: const Text('Later'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await _pickAndUploadDocument(booking);
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Upload Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickAndUploadDocument(Reservation booking) async {
    try {
      final ImagePicker picker = ImagePicker();

      // Show options for camera or gallery
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.cardColor,
          title: const Text(
            'Choose Image Source',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                title: const Text(
                  'Camera',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library,
                    color: AppTheme.primaryColor),
                title: const Text(
                  'Gallery',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      // Pick image
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      if (!mounted) return;

      // Show uploading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Uploading document...'),
            ],
          ),
          backgroundColor: AppTheme.primaryColor,
          duration: Duration(seconds: 30),
        ),
      );

      // In a real implementation, you would upload to Supabase Storage
      // For now, we'll use the file path as a document URL
      final bookingService =
          Provider.of<BookingService>(context, listen: false);

      final success = await bookingService.uploadDocuments(
        bookingId: booking.id,
        documentUrls: [
          image.path
        ], // In production, this would be the Supabase Storage URL
      );

      if (!mounted) return;

      // Clear the uploading snackbar
      ScaffoldMessenger.of(context).clearSnackBars();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Document uploaded successfully! Waiting for admin approval.',
            ),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              bookingService.error ?? 'Failed to upload document',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentStep == 1
            ? 'Reserve Motorcycle'
            : _currentStep == 2
                ? 'Upload License'
                : _currentStep == 3
                    ? 'Payment Method'
                    : 'Confirm Reservation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 1) {
              setState(() {
                _currentStep--;
              });
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: _buildProgressBar(_currentStep),
        ),
      ),
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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress Steps Indicator
                      _buildStepsIndicator(),
                      const SizedBox(height: 24),

                      // Show content based on current step
                      if (_currentStep == 1) _buildStep1Form(),
                      if (_currentStep == 2) _buildStep2DocumentUpload(),
                      if (_currentStep == 3) _buildStep3Payment(),
                      if (_currentStep == 4) _buildStep4Confirm(),
                    ],
                  ),
                ),
              ),

              // Bottom Button
              _buildBottomButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1Form() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Booking process info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Booking Process',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '1. Fill booking form\n2. Upload required documents\n3. Review booking\n4. Confirm booking',
                style: TextStyle(
                  fontSize: 12,
                  color: textPrimary.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Motorcycle info card
        _buildMotorcycleCard(),

        const SizedBox(height: 24),

        // Customer information section
        _buildCustomerInformation(),

        const SizedBox(height: 24),

        // Emergency contact section
        _buildEmergencyContact(),

        const SizedBox(height: 24),

        // Rental schedule section
        _buildRentalSchedule(),

        const SizedBox(height: 24),

        // Payment method
        _buildPaymentMethodSelection(),

        const SizedBox(height: 24),

        // Additional notes
        CustomTextField(
          controller: _notesController,
          label: 'Additional Notes (Optional)',
          hintText: 'Any special requests or notes...',
          maxLines: 3,
        ),

        const SizedBox(height: 24),

        // Important rental information
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.warningColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.warningColor.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.warning_outlined,
                    color: AppTheme.warningColor,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Important Rental Information',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.warningColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '• A 20% security deposit is required (refundable)\n'
                '• Valid driver\'s license is mandatory\n'
                '• Late returns incur ₱100/hour penalty\n'
                '• You must upload license & ID after booking\n'
                '• Booking must be approved by admin',
                style: TextStyle(
                  fontSize: 12,
                  color: textPrimary.withOpacity(0.8),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Price breakdown
        _buildPriceBreakdown(),
      ],
    );
  }

  Widget _buildMotorcycleCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.cardColor : AppTheme.lightCardColor;
    final borderColor =
        isDark ? AppTheme.borderColor : AppTheme.lightBorderColor;
    final bgSecondary = isDark
        ? AppTheme.backgroundSecondary
        : AppTheme.lightBackgroundSecondary;
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: widget.motorcycle.image.isNotEmpty
                ? Image.network(
                    widget.motorcycle.image,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: bgSecondary,
                        child: Icon(
                          Icons.two_wheeler,
                          size: 40,
                          color: textSecondary,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 80,
                        height: 80,
                        color: bgSecondary,
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: bgSecondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.two_wheeler,
                      size: 40,
                      color: textSecondary,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.motorcycle.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.motorcycle.brand} • ${widget.motorcycle.category}',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₱${widget.motorcycle.pricePerDay.toStringAsFixed(0)}/day',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int currentStep) {
    return LinearProgressIndicator(
      value: currentStep / 4, // 4 total steps
      backgroundColor: AppTheme.backgroundSecondary.withOpacity(0.3),
      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
      minHeight: 6,
    );
  }

  Widget _buildStepsIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.cardColor : AppTheme.lightCardColor;
    final borderColor =
        isDark ? AppTheme.borderColor : AppTheme.lightBorderColor;
    final bgSecondary = isDark
        ? AppTheme.backgroundSecondary
        : AppTheme.lightBackgroundSecondary;
    final textSecondary =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          _buildStepItem(
              1, 'Details', _currentStep >= 1, bgSecondary, textSecondary),
          _buildStepConnector(_currentStep > 1),
          _buildStepItem(
              2, 'License', _currentStep >= 2, bgSecondary, textSecondary),
          _buildStepConnector(_currentStep > 2),
          _buildStepItem(
              3, 'Payment', _currentStep >= 3, bgSecondary, textSecondary),
          _buildStepConnector(_currentStep > 3),
          _buildStepItem(
              4, 'Confirm', _currentStep >= 4, bgSecondary, textSecondary),
        ],
      ),
    );
  }

  Widget _buildStepItem(int step, String label, bool isActive,
      Color bgSecondary, Color textSecondary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? AppTheme.borderColor : AppTheme.lightBorderColor;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primaryColor : bgSecondary,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? AppTheme.primaryColor : borderColor,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: TextStyle(
                  color: isActive ? Colors.white : textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? AppTheme.primaryColor : textSecondary,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isActive ? AppTheme.primaryColor : AppTheme.borderColor,
      ),
    );
  }

  Widget _buildCustomerInformation() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _fullNameController,
          label: 'Full Name *',
          hintText: 'Enter your full name',
          prefixIcon: Icons.person,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _emailController,
          label: 'Email Address *',
          hintText: 'your.email@example.com',
          prefixIcon: Icons.email,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _phoneController,
          label: 'Phone Number *',
          hintText: '+63 XXX XXX XXXX',
          prefixIcon: Icons.phone,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _buildDateField(
          label: 'Date of Birth *',
          date: _dateOfBirth,
          onTap: _selectDateOfBirth,
          icon: Icons.cake,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _addressController,
          label: 'Address *',
          hintText: 'Complete address',
          prefixIcon: Icons.home,
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _licenseNumberController,
          label: 'Driver\'s License Number *',
          hintText: 'A00-00-000000',
          prefixIcon: Icons.credit_card,
        ),
      ],
    );
  }

  Widget _buildEmergencyContact() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emergency Contact',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _emergencyNameController,
          label: 'Contact Name *',
          hintText: 'Emergency contact person',
          prefixIcon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _emergencyPhoneController,
          label: 'Contact Phone *',
          hintText: '+63 XXX XXX XXXX',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildRentalSchedule() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rental Schedule',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _buildDateField(
          label: 'Pickup Date *',
          date: _pickupDate,
          onTap: _selectPickupDate,
          icon: Icons.calendar_today,
        ),
        const SizedBox(height: 16),
        _buildTimeField(
          label: 'Pickup Time *',
          time: _pickupTime,
          onTap: _showPickupTimeDropdown,
        ),
        const SizedBox(height: 16),
        _buildDateField(
          label: 'Return Date *',
          date: _returnDate,
          onTap: _selectReturnDate,
          icon: Icons.calendar_today,
        ),
        if (_pickupDate != null && _returnDate != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Duration: ${_totalDays.toInt()} ${_totalDays == 1 ? 'day' : 'days'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.cardColor : AppTheme.lightCardColor;
    final borderColor =
        isDark ? AppTheme.borderColor : AppTheme.lightBorderColor;
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  icon ?? Icons.calendar_today,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  date != null
                      ? '${date.day}/${date.month}/${date.year}'
                      : 'Select date',
                  style: TextStyle(
                    fontSize: 16,
                    color: date != null ? textPrimary : textSecondary,
                    fontWeight:
                        date != null ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeField({
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.cardColor : AppTheme.lightCardColor;
    final borderColor =
        isDark ? AppTheme.borderColor : AppTheme.lightBorderColor;
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  time != null ? time.format(context) : 'Select time',
                  style: TextStyle(
                    fontSize: 16,
                    color: time != null ? textPrimary : textSecondary,
                    fontWeight:
                        time != null ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final cardColor = isDark ? AppTheme.cardColor : AppTheme.lightCardColor;
    final borderColor =
        isDark ? AppTheme.borderColor : AppTheme.lightBorderColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...PaymentMethod.values.map(
          (method) => GestureDetector(
            onTap: () {
              setState(() {
                _selectedPaymentMethod = method;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedPaymentMethod == method
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedPaymentMethod == method
                      ? AppTheme.primaryColor
                      : borderColor,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.money,
                    color: _selectedPaymentMethod == method
                        ? AppTheme.primaryColor
                        : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cash on Pickup',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _selectedPaymentMethod == method
                            ? AppTheme.primaryColor
                            : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  if (_selectedPaymentMethod == method)
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.primaryColor,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceBreakdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.cardColor : AppTheme.lightCardColor;
    final borderColor =
        isDark ? AppTheme.borderColor : AppTheme.lightBorderColor;
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (_pickupDate != null && _returnDate != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rate per day',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
                Text(
                  '₱${widget.motorcycle.pricePerDay.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal (${_totalDays.toInt()} ${_totalDays == 1 ? 'day' : 'days'})',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
                Text(
                  '₱${_subtotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Security Deposit (20%)',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
                Text(
                  '₱${_securityDeposit.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.warningColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Divider(color: borderColor, height: 24),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              Text(
                '₱${_totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '* Security deposit is refundable upon safe return',
            style: TextStyle(
              fontSize: 11,
              color: textSecondary.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '* ₱100 penalty per hour for late returns',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.errorColor.withOpacity(0.8),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2DocumentUpload() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Driver\'s License',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.errorColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.errorColor.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_outlined, color: AppTheme.errorColor),
                  SizedBox(width: 12),
                  Text(
                    'Required Document',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.errorColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'You must upload your driver\'s license to proceed with the booking. Make sure the photo is clear and all details are readable.',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Driver's License Upload (Required)
        _buildDocumentUploadCard(
          title: 'Driver\'s License',
          icon: Icons.credit_card,
          imageUrl: _licenseImageUrl,
          onUpload: () => _pickDocument(isLicense: true),
          onRemove: () {
            setState(() {
              _licenseImageUrl = null;
            });
          },
        ),

        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Requirements:\n• Valid, non-expired license\n• Clear and readable photo\n• All corners visible',
                  style: TextStyle(
                    fontSize: 12,
                    color: textPrimary.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentUploadCard({
    required String title,
    required IconData icon,
    required String? imageUrl,
    required VoidCallback onUpload,
    required VoidCallback onRemove,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.cardColor : AppTheme.lightCardColor;
    final borderColor =
        isDark ? AppTheme.borderColor : AppTheme.lightBorderColor;
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (imageUrl == null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onUpload,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Upload Photo'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            )
          else
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundSecondary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundSecondary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.errorColor),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppTheme.errorColor,
                              size: 48,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Failed to load image',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Status indicator
                const Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppTheme.successColor,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Document uploaded',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onUpload,
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Change'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: const BorderSide(color: AppTheme.primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onRemove,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Remove'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                          side: const BorderSide(color: AppTheme.errorColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _pickDocument({required bool isLicense}) async {
    try {
      final ImagePicker picker = ImagePicker();

      // Show options for camera or gallery
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.cardColor,
          title: const Text(
            'Choose Image Source',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                title: const Text(
                  'Camera',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library,
                    color: AppTheme.primaryColor),
                title: const Text(
                  'Gallery',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      // Pick image
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      if (!mounted) return;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get current user ID for storage path
      final authService =
          Provider.of<AuthServiceSupabase>(context, listen: false);
      final userId = authService.currentUser?.id;

      if (userId == null) {
        if (mounted) Navigator.pop(context); // Close loading
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: User not authenticated'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }

      // Upload to Supabase Storage
      final storageService = StorageServiceSupabase();
      final publicUrl = await storageService.uploadLicense(
        filePath: image.path,
        userId: userId,
      );

      if (mounted) Navigator.pop(context); // Close loading

      if (publicUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload image. Please try again.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }

      if (!mounted) return;

      // Store the public URL (not local path)
      setState(() {
        _licenseImageUrl = publicUrl;
      });

      print('DEBUG: License uploaded to Supabase Storage');
      print('DEBUG: Public URL: $publicUrl');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Driver\'s license uploaded successfully!'),
          backgroundColor: AppTheme.successColor,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Widget _buildStep3Payment() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Payment Method',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 24),

        // Payment Method Selection
        _buildPaymentMethodCard(
          title: 'Cash Payment',
          subtitle: 'Pay in cash when you pick up the motorcycle',
          icon: Icons.money,
          value: 'cash',
          isSelected: _selectedPaymentMethod == PaymentMethod.cash,
          onTap: () {
            setState(() {
              _selectedPaymentMethod = PaymentMethod.cash;
            });
          },
        ),

        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Payment will be collected when you pick up the motorcycle. Please bring exact amount if possible.',
                  style: TextStyle(
                    fontSize: 13,
                    color: textPrimary.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),

        // Booking Summary
        Text(
          'Booking Summary',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildReviewItem('Customer Name', _fullNameController.text),
        _buildReviewItem('Phone', _phoneController.text),
        if (_pickupDate != null)
          _buildReviewItem(
            'Pickup Date',
            '${_pickupDate!.day}/${_pickupDate!.month}/${_pickupDate!.year}',
          ),
        if (_returnDate != null)
          _buildReviewItem(
            'Return Date',
            '${_returnDate!.day}/${_returnDate!.month}/${_returnDate!.year}',
          ),
        if (_pickupTime != null)
          _buildReviewItem('Pickup Time', _formatTimeOfDay(_pickupTime!)),
        _buildReviewItem(
          'Duration',
          '${_returnDate?.difference(_pickupDate ?? DateTime.now()).inDays ?? 0} days',
        ),
        _buildReviewItem(
          'Daily Rate',
          '₱${widget.motorcycle.pricePerDay.toStringAsFixed(2)}',
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              Text(
                '₱${_totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.cardColor : AppTheme.lightCardColor;
    final borderColor =
        isDark ? AppTheme.borderColor : AppTheme.lightBorderColor;
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : borderColor.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : cardColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppTheme.primaryColor : textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep4Confirm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirm Your Booking',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.successColor.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: AppTheme.successColor,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Ready to Confirm',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'By confirming, you agree to our terms and conditions.',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildPriceBreakdown(),
      ],
    );
  }

  Widget _buildReviewItem(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.cardColor : AppTheme.lightCardColor;
    final borderColor =
        isDark ? AppTheme.borderColor : AppTheme.lightBorderColor;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(
          top: BorderSide(color: borderColor),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 1)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentStep--;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Back'),
                ),
              ),
            if (_currentStep > 1) const SizedBox(width: 16),
            Expanded(
              flex: _currentStep == 1 ? 3 : 2,
              child: Consumer<BookingService>(
                builder: (context, bookingService, child) {
                  return LoadingButton(
                    onPressed: _handleBooking,
                    isLoading: bookingService.isLoading,
                    text: _currentStep == 1
                        ? 'Continue to Upload License'
                        : _currentStep == 2
                            ? 'Continue to Payment'
                            : _currentStep == 3
                                ? 'Continue to Confirm'
                                : 'Reserve Motorcycle',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
