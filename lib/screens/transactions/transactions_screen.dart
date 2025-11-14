import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moto_rent_dumaguete/services/booking_service.dart';
import 'package:moto_rent_dumaguete/services/auth_service_supabase.dart';
import 'package:moto_rent_dumaguete/models/reservation.dart';
import 'package:moto_rent_dumaguete/models/booking.dart' show BookingStatus;
import 'package:moto_rent_dumaguete/theme/app_theme.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  // Selected transaction IDs for bulk actions
  final Set<String> _selectedIds = {};

  bool get _selectionMode => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTransactions());
  }

  Future<void> _loadTransactions() async {
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

    final all = bookingService.bookings;

    // Active: confirmed or active
    final active = all
        .where((b) =>
            b.bookingStatus == BookingStatus.confirmed ||
            b.bookingStatus == BookingStatus.active)
        .toList();

    // History: completed, cancelled, rejected
    final history = all
        .where((b) =>
            b.bookingStatus == BookingStatus.completed ||
            b.bookingStatus == BookingStatus.cancelled ||
            b.bookingStatus == BookingStatus.rejected)
        .toList();

    Widget emptyState(String title, String subtitle) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: _selectionMode
              ? Text('${_selectedIds.length} selected')
              : const Text('Transactions'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'History'),
            ],
          ),
          actions: [
            if (_selectionMode) ...[
              IconButton(
                tooltip: 'Delete selected',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Selected Transactions'),
                      content: const Text(
                          'Are you sure you want to permanently delete the selected transactions? This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm != true) return;

                  final ids = _selectedIds.toList();
                  final success = await bookingService.deleteReservations(ids);

                  if (success) {
                    setState(() {
                      _selectedIds.clear();
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Transactions deleted'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(bookingService.error ??
                              'Failed to delete transactions'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                    }
                  }
                },
              ),
              IconButton(
                tooltip: 'Clear selection',
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _selectedIds.clear();
                  });
                },
              ),
            ]
          ],
        ),
        body: TabBarView(
          children: [
            // Active tab
            RefreshIndicator(
              onRefresh: _loadTransactions,
              child: active.isEmpty
                  ? emptyState(
                      'No active transactions',
                      'Your confirmed or active bookings will appear here',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: active.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildTransactionCard(active[index]);
                      },
                    ),
            ),

            // History tab
            RefreshIndicator(
              onRefresh: _loadTransactions,
              child: history.isEmpty
                  ? emptyState(
                      'No transactions yet',
                      'Your completed and cancelled bookings will appear here',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: history.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildTransactionCard(history[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Reservation transaction) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

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
            // Header with selection checkbox, motorcycle name, status and actions
            Row(
              children: [
                // Selection checkbox
                Checkbox(
                  value: _selectedIds.contains(transaction.id),
                  onChanged: (selected) {
                    setState(() {
                      if (selected == true) {
                        _selectedIds.add(transaction.id);
                      } else {
                        _selectedIds.remove(transaction.id);
                      }
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    transaction.motorcycleName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                _buildStatusChip(transaction.bookingStatus),
                const SizedBox(width: 8),
                // Delete button for transactions
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.redAccent,
                  tooltip: 'Delete transaction',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Transaction'),
                        content: const Text(
                            'Are you sure you want to permanently delete this transaction? This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm != true) return;

                    // Call the booking/reservation service to delete
                    final bookingService =
                        Provider.of<BookingService>(context, listen: false);

                    final success = await bookingService.deleteReservation(
                      transaction.id,
                    );

                    if (success) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Transaction deleted'),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(bookingService.error ??
                                'Failed to delete transaction'),
                            backgroundColor: AppTheme.errorColor,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Transaction details
            _buildDetailRow(
              icon: Icons.calendar_today,
              label: 'Pickup',
              value:
                  '${dateFormat.format(transaction.startDate)} at ${timeFormat.format(transaction.startDate)}',
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              icon: Icons.event,
              label: 'Return',
              value:
                  '${dateFormat.format(transaction.endDate)} at ${timeFormat.format(transaction.endDate)}',
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              icon: Icons.access_time,
              label: 'Duration',
              value:
                  '${transaction.duration} ${transaction.duration > 1 ? 'days' : 'day'}',
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              icon: Icons.payments,
              label: 'Total Amount',
              value: '₱${transaction.totalPrice.toStringAsFixed(2)}',
              valueColor: AppTheme.primaryColor,
              valueBold: true,
            ),

            if (transaction.bookingStatus == BookingStatus.completed) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                icon: Icons.check_circle,
                label: 'Completed On',
                value: dateFormat
                    .format(transaction.updatedAt ?? transaction.createdAt),
                valueColor: AppTheme.successColor,
              ),
            ],

            if (transaction.bookingStatus == BookingStatus.cancelled ||
                transaction.bookingStatus == BookingStatus.rejected) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                icon: Icons.cancel,
                label: transaction.bookingStatus == BookingStatus.rejected
                    ? 'Rejected On'
                    : 'Cancelled On',
                value: dateFormat
                    .format(transaction.updatedAt ?? transaction.createdAt),
                valueColor: AppTheme.errorColor,
              ),
              if (transaction.adminNotes != null &&
                  transaction.adminNotes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.errorColor.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: AppTheme.errorColor,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Reason',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.errorColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        transaction.adminNotes!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Transaction ID
            Text(
              'Transaction ID: ${transaction.id.substring(0, 8)}',
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
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool valueBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
                    color: valueColor ?? AppTheme.textPrimary,
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
      case BookingStatus.cancelled:
        backgroundColor = AppTheme.warningColor;
        label = 'CANCELLED';
        break;
      case BookingStatus.rejected:
        backgroundColor = AppTheme.errorColor;
        label = 'REJECTED';
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
