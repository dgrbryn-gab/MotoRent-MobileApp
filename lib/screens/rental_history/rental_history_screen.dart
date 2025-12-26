import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moto_rent_dumaguete/services/booking_service.dart';
import 'package:moto_rent_dumaguete/services/auth_service_supabase.dart';
import 'package:moto_rent_dumaguete/models/reservation.dart';
import 'package:moto_rent_dumaguete/models/booking.dart' show BookingStatus;
import 'package:moto_rent_dumaguete/theme/app_theme.dart';
import 'package:intl/intl.dart';

class RentalHistoryScreen extends StatefulWidget {
  const RentalHistoryScreen({super.key});

  @override
  State<RentalHistoryScreen> createState() => _RentalHistoryScreenState();
}

class _RentalHistoryScreenState extends State<RentalHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRentalHistory());
  }

  Future<void> _loadRentalHistory() async {
    final authService =
        Provider.of<AuthServiceSupabase>(context, listen: false);
    final bookingService = Provider.of<BookingService>(context, listen: false);

    if (authService.isAuthenticated && authService.currentUser != null) {
      await bookingService.loadBookings(userId: authService.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingService = Provider.of<BookingService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter only completed rentals
    final completedRentals = bookingService.bookings
        .where((b) => b.bookingStatus == BookingStatus.completed)
        .toList();

    // Calculate analytics
    final totalRentals = completedRentals.length;
    final totalAmountSpent = completedRentals.fold<double>(
        0.0, (sum, rental) => sum + rental.totalPrice);
    final averageRentalCost =
        totalRentals > 0 ? totalAmountSpent / totalRentals : 0.0;

    Widget emptyState(String title, String subtitle) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history_outlined,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadRentalHistory,
        child: completedRentals.isEmpty
            ? emptyState(
                'No rental history',
                'Your completed rentals will appear here',
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Analytics Cards
                  _buildAnalyticsSection(
                    context,
                    totalRentals,
                    totalAmountSpent,
                    averageRentalCost,
                    isDark,
                  ),
                  const SizedBox(height: 24),
                  // Rental History List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: completedRentals.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildRentalCard(
                        completedRentals[index],
                        isDark,
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAnalyticsSection(
    BuildContext context,
    int totalRentals,
    double totalAmountSpent,
    double averageRentalCost,
    bool isDark,
  ) {
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final cardColor = isDark ? AppTheme.cardColor : AppTheme.lightCardColor;
    final borderColor =
        isDark ? AppTheme.borderColor : AppTheme.lightBorderColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rental Statistics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsCard(
                context,
                icon: Icons.two_wheeler,
                title: 'Total Rentals',
                value: totalRentals.toString(),
                isDark: isDark,
                cardColor: cardColor,
                borderColor: borderColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAnalyticsCard(
                context,
                icon: Icons.attach_money,
                title: 'Total Spent',
                value: '₱${totalAmountSpent.toStringAsFixed(2)}',
                isDark: isDark,
                cardColor: cardColor,
                borderColor: borderColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildAnalyticsCard(
          context,
          icon: Icons.trending_up,
          title: 'Average Rental Cost',
          value: '₱${averageRentalCost.toStringAsFixed(2)}',
          isDark: isDark,
          cardColor: cardColor,
          borderColor: borderColor,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
    bool fullWidth = false,
  }) {
    final textSecondary =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalCard(Reservation rental, bool isDark) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with motorcycle name, status and delete action
            Row(
              children: [
                Expanded(
                  child: Text(
                    rental.motorcycleName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ),
                _buildStatusChip(rental.bookingStatus),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Rental details
            _buildDetailRow(
              isDark: isDark,
              icon: Icons.calendar_today,
              label: 'Pickup',
              value:
                  '${dateFormat.format(rental.startDate)} at ${timeFormat.format(rental.startDate)}',
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              isDark: isDark,
              icon: Icons.event,
              label: 'Return',
              value:
                  '${dateFormat.format(rental.endDate)} at ${timeFormat.format(rental.endDate)}',
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              isDark: isDark,
              icon: Icons.access_time,
              label: 'Duration',
              value:
                  '${rental.duration} ${rental.duration > 1 ? 'days' : 'day'}',
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              isDark: isDark,
              icon: Icons.payments,
              label: 'Total Amount',
              value: '₱${rental.totalPrice.toStringAsFixed(2)}',
              valueColor: AppTheme.primaryColor,
              valueBold: true,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              isDark: isDark,
              icon: Icons.check_circle,
              label: 'Completed On',
              value: dateFormat.format(rental.updatedAt ?? rental.createdAt),
              valueColor: AppTheme.successColor,
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Rental ID
            Text(
              'Rental ID: ${rental.id.substring(0, 8)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool valueBold = false,
  }) {
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
                    color: valueColor ?? textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(BookingStatus status) {
    Color backgroundColor;
    Color textColor = Colors.white;
    String label;

    switch (status) {
      case BookingStatus.completed:
        backgroundColor = AppTheme.successColor;
        label = 'COMPLETED';
        break;
      default:
        backgroundColor = AppTheme.textSecondary;
        label = status.name.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
