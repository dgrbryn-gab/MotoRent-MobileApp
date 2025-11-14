import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moto_rent_dumaguete/services/booking_service.dart';
import 'package:moto_rent_dumaguete/services/auth_service_supabase.dart';
import 'package:moto_rent_dumaguete/services/motorcycle_service_supabase.dart';
import 'package:moto_rent_dumaguete/models/reservation.dart';
import 'package:moto_rent_dumaguete/models/booking.dart' show BookingStatus;
import 'package:moto_rent_dumaguete/screens/auth/auth_screen.dart';
import 'package:moto_rent_dumaguete/screens/main_navigation_screen.dart';
import 'package:moto_rent_dumaguete/theme/app_theme.dart';

class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key});

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
  Reservation? _selectedBooking;
  bool _showDetailsDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService =
          Provider.of<AuthServiceSupabase>(context, listen: false);
      if (authService.isAuthenticated) {
        final bookingService =
            Provider.of<BookingService>(context, listen: false);
        // Set current user ID for filtering
        bookingService.setCurrentUserId(authService.currentUser!.id);
        // Load user's bookings
        bookingService.loadBookings(userId: authService.currentUser!.id);
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
      appBar: AppBar(
        title: const Text('My Reservations'),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Container(
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
            child: Consumer<AuthServiceSupabase>(
              builder: (context, authService, child) {
                if (!authService.isAuthenticated) {
                  return _buildGuestView(context);
                }
                return _buildBookingsList();
              },
            ),
          ),
          if (_showDetailsDialog && _selectedBooking != null)
            _buildDetailsDialog(),
        ],
      ),
    );
  }

  Widget _buildGuestView(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.cardColor : AppTheme.lightCardColor;
    final borderColor =
        isDark ? AppTheme.borderColor : AppTheme.lightBorderColor;
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

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
              Icons.receipt_long_outlined,
              size: 60,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Sign in to view bookings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Please sign in to view your motorcycle rental bookings and history.',
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
        ],
      ),
    );
  }

  Widget _buildBookingsList() {
    return Consumer<BookingService>(
      builder: (context, bookingService, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardColor = isDark ? AppTheme.cardColor : AppTheme.lightCardColor;
        final borderColor =
            isDark ? AppTheme.borderColor : AppTheme.lightBorderColor;
        final textPrimary =
            isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
        final textSecondary =
            isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

        if (bookingService.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          );
        }

        if (bookingService.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading bookings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  bookingService.error!,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    bookingService.clearError();
                    bookingService.loadBookings();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final bookings = bookingService.userBookings;

        if (bookings.isEmpty) {
          return Center(
            child: Padding(
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
                      Icons.receipt_long_outlined,
                      size: 60,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'No Reservations',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You don\'t have any reservations at the moment.',
                    style: TextStyle(
                      fontSize: 16,
                      color: textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to home screen (index 0) in main navigation
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) =>
                              const MainNavigationScreen(initialIndex: 0),
                        ),
                        (route) => false,
                      );
                    },
                    child: const Text('Browse Motorcycles'),
                  ),
                ],
              ),
            ),
          );
        }

        // Separate active and past bookings
        final activeBookings = bookings
            .where((b) =>
                b.bookingStatus == BookingStatus.pending ||
                b.bookingStatus == BookingStatus.documentsSubmitted ||
                b.bookingStatus == BookingStatus.waitingApproval ||
                b.bookingStatus == BookingStatus.approved ||
                b.bookingStatus == BookingStatus.confirmed ||
                b.bookingStatus == BookingStatus.active)
            .toList();

        final pastBookings = bookings
            .where((b) =>
                b.bookingStatus == BookingStatus.completed ||
                b.bookingStatus == BookingStatus.cancelled ||
                b.bookingStatus == BookingStatus.rejected)
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page description
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Manage your motorcycle rental bookings',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Active Reservations Section
              Text(
                'Active Reservations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),

              const SizedBox(height: 16),

              if (activeBookings.isEmpty)
                _buildEmptySection(
                  icon: Icons.calendar_today,
                  title: 'No Active Reservations',
                  subtitle:
                      'You don\'t have any active reservations at the moment.',
                  cardColor: cardColor,
                  borderColor: borderColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                )
              else
                ...activeBookings.map((booking) => _buildBookingCard(
                      booking,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    )),

              const SizedBox(height: 32),

              // Past Reservations Section
              Text(
                'Past Reservations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),

              const SizedBox(height: 16),

              if (pastBookings.isEmpty)
                _buildEmptySection(
                  icon: Icons.access_time,
                  title: 'No Past Reservations',
                  subtitle: 'Your rental history will appear here.',
                  cardColor: cardColor,
                  borderColor: borderColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                )
              else
                ...pastBookings.map((booking) => _buildBookingCard(
                      booking,
                      isPast: true,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptySection({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(
    Reservation booking, {
    bool isPast = false,
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with motorcycle name and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  booking.motorcycleName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              _buildStatusChip(booking.bookingStatus),
            ],
          ),

          const SizedBox(height: 12),

          // Show step indicator for pending bookings
          if (booking.bookingStatus == BookingStatus.pending) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppTheme.warningColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Step ${booking.currentStep}/4: Upload your driver\'s license to proceed',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.warningColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Booking details
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                '${_formatDate(booking.startDate)} - ${_formatDate(booking.endDate)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(
                Icons.access_time,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                '${booking.duration} ${booking.duration == 1 ? 'day' : 'days'}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(
                Icons.payment,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                booking.paymentMethodDisplayName,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Total amount and booking date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₱${booking.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryColor,
                ),
              ),
              Text(
                'Booked ${_formatDate(booking.createdAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),

          // Show rejection reason if rejected
          if (booking.bookingStatus == BookingStatus.rejected &&
              booking.rejectionReason != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 16,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reason: ${booking.rejectionReason}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action buttons based on status
          const SizedBox(height: 12),
          // Only Details button
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _selectedBooking = booking;
                _showDetailsDialog = true;
              });
            },
            icon: const Icon(Icons.info_outline, size: 16),
            label: const Text('View Details'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              minimumSize: const Size(double.infinity, 36),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BookingStatus status) {
    Color backgroundColor;
    Color textColor = Colors.white;

    switch (status) {
      case BookingStatus.pending:
        backgroundColor = AppTheme.warningColor;
        break;
      case BookingStatus.documentsSubmitted:
      case BookingStatus.waitingApproval:
        backgroundColor = AppTheme.primaryColor;
        break;
      case BookingStatus.approved:
      case BookingStatus.confirmed:
        backgroundColor = AppTheme.successColor;
        break;
      case BookingStatus.rejected:
      case BookingStatus.cancelled:
        backgroundColor = AppTheme.errorColor;
        break;
      case BookingStatus.active:
        backgroundColor = AppTheme.secondaryColor;
        break;
      case BookingStatus.completed:
        backgroundColor = AppTheme.completedStepColor;
        break;
      default:
        backgroundColor = AppTheme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _uploadDocuments(Reservation booking) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          title: const Text(
            'Upload Driver\'s License',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please upload a clear photo of your valid driver\'s license.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              SizedBox(height: 16),
              Text(
                'Requirements:',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '• Valid driver\'s license\n• Clear and readable photo\n• Not expired',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                // Simulate document upload
                final bookingService =
                    Provider.of<BookingService>(context, listen: false);

                // Show uploading message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Uploading documents...'),
                    backgroundColor: AppTheme.primaryColor,
                    duration: Duration(seconds: 2),
                  ),
                );

                // Simulate upload with mock data
                await Future.delayed(const Duration(seconds: 2));

                final success = await bookingService.uploadDocuments(
                  bookingId: booking.id,
                  documentUrls: [
                    'mock_license_url_${DateTime.now().millisecondsSinceEpoch}'
                  ],
                );

                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Documents uploaded successfully! Waiting for admin approval.'),
                      backgroundColor: AppTheme.successColor,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Photo'),
            ),
          ],
        );
      },
    );
  }

  void _cancelBooking(Reservation booking) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          title: const Text(
            'Cancel Booking',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          content: const Text(
            'Are you sure you want to cancel this booking?',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Provider.of<BookingService>(context, listen: false)
                    .cancelBooking(booking.id);
              },
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailsDialog() {
    final booking = _selectedBooking!;

    return GestureDetector(
      onTap: () {
        setState(() {
          _showDetailsDialog = false;
          _selectedBooking = null;
        });
      },
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping the dialog
            child: Container(
              margin: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxHeight: 600),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Reservation Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _showDetailsDialog = false;
                              _selectedBooking = null;
                            });
                          },
                          icon: const Icon(Icons.close),
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Scrollable content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Motorcycle info
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Consumer<MotorcycleServiceSupabase>(
                                builder: (context, motorcycleService, child) {
                                  final motorcycle = motorcycleService
                                      .getMotorcycleById(booking.motorcycleId);
                                  final imageUrl = motorcycle?.image ?? '';

                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: imageUrl.isNotEmpty
                                        ? Image.network(
                                            imageUrl,
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                width: 80,
                                                height: 80,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[300],
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.two_wheeler,
                                                    size: 40,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              );
                                            },
                                          )
                                        : Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.two_wheeler,
                                                size: 40,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Consumer<MotorcycleServiceSupabase>(
                                      builder:
                                          (context, motorcycleService, child) {
                                        final motorcycle =
                                            motorcycleService.getMotorcycleById(
                                                booking.motorcycleId);
                                        return Text(
                                          motorcycle?.name ??
                                              booking.motorcycleName,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary,
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    _buildStatusChip(booking.bookingStatus),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),

                          // Booking Information
                          const Text(
                            'Booking Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),

                          const SizedBox(height: 12),

                          _buildDetailRow(
                              'Reservation ID', booking.id.substring(0, 8)),
                          _buildDetailRow('Booking Date',
                              _formatDetailDate(booking.createdAt)),
                          _buildDetailRow('Pick-up Date',
                              _formatDetailDate(booking.startDate)),
                          _buildDetailRow('Return Date',
                              _formatDetailDate(booking.endDate)),
                          _buildDetailRow('Duration',
                              '${booking.duration} ${booking.duration == 1 ? 'day' : 'days'}'),

                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),

                          // Payment Details
                          const Text(
                            'Payment Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundSecondary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Payment Method',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      '💵 ${booking.paymentMethodDisplayName}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total Amount',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '₱${booking.totalAmount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Show rejection reason if applicable
                          if (booking.bookingStatus == BookingStatus.rejected &&
                              booking.rejectionReason != null) ...[
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.errorColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.errorColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: AppTheme.errorColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Rejection Reason',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.errorColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          booking.rejectionReason!,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.errorColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Action buttons
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppTheme.borderColor),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _showDetailsDialog = false;
                                _selectedBooking = null;
                              });
                            },
                            child: const Text('Close'),
                          ),
                        ),
                        if (booking.bookingStatus == BookingStatus.pending ||
                            booking.bookingStatus ==
                                BookingStatus.documentsSubmitted) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _showDetailsDialog = false;
                                });
                                _cancelBooking(booking);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.errorColor,
                              ),
                              child: const Text('Cancel Booking'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDetailDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
