import 'package:flutter/foundation.dart';
import 'package:moto_rent_dumaguete/models/reservation.dart';
import 'package:moto_rent_dumaguete/services/supabase_service.dart';
import 'package:moto_rent_dumaguete/config/supabase_config.dart';

class ReservationServiceSupabase extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService.instance;

  List<Reservation> _reservations = [];
  bool _isLoading = false;
  String? _error;
  Reservation? _currentReservation;
  String? _currentUserId; // Track current user for filtering

  List<Reservation> get reservations => _reservations;
  List<Reservation> get userReservations => _currentUserId != null
      ? _reservations.where((r) => r.userId == _currentUserId).toList()
      : [];
  bool get isLoading => _isLoading;
  String? get error => _error;
  Reservation? get currentReservation => _currentReservation;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Load all reservations from Supabase
  Future<void> loadReservations() async {
    _setLoading(true);
    _setError(null);

    try {
      final data = await _supabaseService.getAll(
        SupabaseConfig.reservationsTable,
      );

      _reservations = data.map((json) => Reservation.fromJson(json)).toList();

      // Sort by creation date (newest first)
      _reservations.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _setLoading(false);
    } catch (e) {
      _setError('Failed to load reservations: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Load reservations for a specific user
  Future<void> loadUserReservations(String userId) async {
    _setLoading(true);
    _setError(null);
    _currentUserId = userId;

    try {
      final data = await _supabaseService.getWhere(
        SupabaseConfig.reservationsTable,
        'user_id',
        userId,
      );

      _reservations = data.map((json) => Reservation.fromJson(json)).toList();

      // Sort by creation date (newest first)
      _reservations.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _setLoading(false);
    } catch (e) {
      _setError('Failed to load user reservations: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Get user reservations from already loaded reservations
  List<Reservation> getUserReservations(String userId) {
    return _reservations.where((r) => r.userId == userId).toList();
  }

  /// Create a new reservation
  Future<bool> createReservation({
    required String userId,
    required String motorcycleId,
    required DateTime startDate,
    required DateTime endDate,
    String? pickupTime,
    String? returnTime,
    required double totalPrice,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    String? paymentMethod,
    String? gcashReferenceNumber,
    String? gcashProofUrl,
    String? adminNotes,
    String? licenseImageUrl,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      // Validate pickup time is not after 5 PM (17:00)
      if (pickupTime != null && pickupTime.isNotEmpty) {
        try {
          final timeParts = pickupTime.split(':');
          final hour = int.parse(timeParts[0]);

          if (hour >= 17) {
            _setError(
                'Motorcycles cannot be picked up after 5:00 PM. Please select an earlier time.');
            _setLoading(false);
            return false;
          }
        } catch (e) {
          print('Warning: Could not parse pickup time: $pickupTime');
          // Continue if time parsing fails, as it might be handled elsewhere
        }
      }

      final reservationData = {
        'user_id': userId,
        'motorcycle_id': motorcycleId,
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
        'pickup_time': pickupTime,
        'return_time': returnTime,
        'total_price': totalPrice,
        'status': 'pending',
        'customer_name': customerName,
        'customer_email': customerEmail,
        'customer_phone': customerPhone,
        'payment_method': paymentMethod ?? 'cash',
        'gcash_reference_number': gcashReferenceNumber,
        'gcash_proof_url': gcashProofUrl,
        'payment_status': 'unpaid',
        'admin_notes': adminNotes,
        'license_image_url': licenseImageUrl,
      };

      print('DEBUG: Creating reservation with data: $reservationData');
      print('DEBUG: License Image URL: $licenseImageUrl');

      final data = await _supabaseService.insert(
        SupabaseConfig.reservationsTable,
        reservationData,
      );

      final reservation = Reservation.fromJson(data);
      _reservations.insert(0, reservation);
      _currentReservation = reservation;

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create reservation: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Update reservation status (Admin)
  Future<bool> updateReservationStatus({
    required String reservationId,
    required String status,
    String? adminNotes,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final updateData = {
        'status': status,
      };

      if (adminNotes != null) {
        updateData['admin_notes'] = adminNotes;
      }

      await _supabaseService.update(
        SupabaseConfig.reservationsTable,
        reservationId,
        updateData,
      );

      // Reload the reservation from database to get the updated data
      final updatedData = await _supabaseService.getById(
        SupabaseConfig.reservationsTable,
        reservationId,
      );

      if (updatedData != null) {
        final updatedReservation = Reservation.fromJson(updatedData);

        // Update local cache
        final index = _reservations.indexWhere((r) => r.id == reservationId);
        if (index != -1) {
          _reservations[index] = updatedReservation;

          if (_currentReservation?.id == reservationId) {
            _currentReservation = updatedReservation;
          }

          // Update motorcycle availability based on reservation status
          await _updateMotorcycleAvailability(
            updatedReservation.motorcycleId,
            status,
          );

          // Create notification for status changes
          await _createStatusNotification(
              updatedReservation.userId, status, reservationId, adminNotes);
        }
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update reservation status: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Update motorcycle availability based on reservation status
  Future<void> _updateMotorcycleAvailability(
    String motorcycleId,
    String reservationStatus,
  ) async {
    try {
      String motorcycleAvailability;

      switch (reservationStatus.toLowerCase()) {
        case 'confirmed':
        case 'approved':
        case 'waiting_approval':
        case 'active':
          motorcycleAvailability = 'Reserved';
          print(
              'Setting motorcycle $motorcycleId to Reserved (status: $reservationStatus)');
          break;
        case 'completed':
        case 'cancelled':
        case 'rejected':
          // Check if there are other active reservations for this motorcycle
          final activeReservations = _reservations.where((r) =>
              r.motorcycleId == motorcycleId &&
              (r.status == 'confirmed' ||
                  r.status == 'approved' ||
                  r.status == 'waiting_approval' ||
                  r.status == 'active'));

          motorcycleAvailability =
              activeReservations.isEmpty ? 'Available' : 'Reserved';
          print(
              'Setting motorcycle $motorcycleId to $motorcycleAvailability (status: $reservationStatus, active reservations: ${activeReservations.length})');
          break;
        default:
          // For pending status, don't change availability
          print(
              'Skipping motorcycle availability update for status: $reservationStatus');
          return;
      }

      // Update motorcycle availability in database
      await _supabaseService.update(
        SupabaseConfig.motorcyclesTable,
        motorcycleId,
        {'availability': motorcycleAvailability},
      );

      print(
          'Successfully updated motorcycle $motorcycleId availability to $motorcycleAvailability');
    } catch (e) {
      print('Failed to update motorcycle availability: ${e.toString()}');
      // Don't throw error, just log it
    }
  }

  /// Update payment status
  Future<bool> updatePaymentStatus({
    required String reservationId,
    required String paymentStatus,
    String? gcashReferenceNumber,
    String? gcashProofUrl,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final updateData = {
        'payment_status': paymentStatus,
      };

      if (gcashReferenceNumber != null) {
        updateData['gcash_reference_number'] = gcashReferenceNumber;
      }
      if (gcashProofUrl != null) {
        updateData['gcash_proof_url'] = gcashProofUrl;
      }

      await _supabaseService.update(
        SupabaseConfig.reservationsTable,
        reservationId,
        updateData,
      );

      // Update local cache
      final index = _reservations.indexWhere((r) => r.id == reservationId);
      if (index != -1) {
        _reservations[index] = _reservations[index].copyWith(
          paymentStatus: paymentStatus,
          gcashReferenceNumber: gcashReferenceNumber,
          gcashProofUrl: gcashProofUrl,
          updatedAt: DateTime.now(),
        );

        if (_currentReservation?.id == reservationId) {
          _currentReservation = _reservations[index];
        }
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update payment status: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Confirm payment
  Future<bool> confirmPayment(String reservationId) async {
    return updatePaymentStatus(
      reservationId: reservationId,
      paymentStatus: 'paid',
    );
  }

  /// Cancel reservation
  Future<bool> cancelReservation(String reservationId, {String? reason}) async {
    return updateReservationStatus(
      reservationId: reservationId,
      status: 'cancelled',
      adminNotes: reason,
    );
  }

  /// Delete a reservation (permanent)
  /// Returns true if deletion succeeded and local cache updated.
  Future<bool> deleteReservation(String reservationId) async {
    _setLoading(true);
    _setError(null);

    try {
      await _supabaseService.delete(
        SupabaseConfig.reservationsTable,
        reservationId,
      );

      // Remove from local cache
      _reservations.removeWhere((r) => r.id == reservationId);
      if (_currentReservation?.id == reservationId) {
        _currentReservation = null;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete reservation: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Delete multiple reservations (permanent)
  /// Returns true if deletion succeeded for all supplied IDs and local cache updated.
  Future<bool> deleteReservations(List<String> reservationIds) async {
    if (reservationIds.isEmpty) return true;

    _setLoading(true);
    _setError(null);

    try {
      for (final id in reservationIds) {
        await _supabaseService.delete(
          SupabaseConfig.reservationsTable,
          id,
        );
      }

      // Remove from local cache
      _reservations.removeWhere((r) => reservationIds.contains(r.id));
      if (_currentReservation != null &&
          reservationIds.contains(_currentReservation!.id)) {
        _currentReservation = null;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete reservations: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Get a specific reservation by ID
  Future<Reservation?> getReservationById(String id) async {
    // Check local cache first
    try {
      return _reservations.firstWhere((r) => r.id == id);
    } catch (e) {
      // Not in cache, fetch from database
      try {
        final data = await _supabaseService.getById(
          SupabaseConfig.reservationsTable,
          id,
        );

        if (data != null) {
          return Reservation.fromJson(data);
        }
        return null;
      } catch (e) {
        _setError('Failed to fetch reservation: ${e.toString()}');
        return null;
      }
    }
  }

  /// Get reservations by status
  List<Reservation> getReservationsByStatus(String status) {
    return _reservations
        .where((reservation) => reservation.status == status)
        .toList();
  }

  /// Get active reservations
  List<Reservation> getActiveReservations() {
    return _reservations
        .where((reservation) =>
            reservation.status == 'confirmed' ||
            reservation.status == 'pending')
        .toList();
  }

  /// Get reservations for a specific motorcycle
  Future<List<Reservation>> getMotorcycleReservations(
      String motorcycleId) async {
    try {
      final data = await _supabaseService.getWhere(
        SupabaseConfig.reservationsTable,
        'motorcycle_id',
        motorcycleId,
      );

      return data.map((json) => Reservation.fromJson(json)).toList();
    } catch (e) {
      _setError('Failed to fetch motorcycle reservations: ${e.toString()}');
      return [];
    }
  }

  void setCurrentReservation(Reservation? reservation) {
    _currentReservation = reservation;
    notifyListeners();
  }

  void clearCurrentReservation() {
    _currentReservation = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void setCurrentUserId(String? userId) {
    _currentUserId = userId;
    notifyListeners();
  }

  /// Create notification for reservation status changes
  Future<void> _createStatusNotification(
    String userId,
    String status,
    String reservationId,
    String? adminNotes,
  ) async {
    String title = '';
    String message = '';
    String type = 'reservation_update';

    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'approved':
        title = 'Reservation Approved! 🎉';
        message =
            'Your reservation has been approved. You can now proceed with payment.';
        type = 'reservation_approved';
        break;
      case 'rejected':
      case 'cancelled':
        title = 'Reservation Rejected';
        message =
            adminNotes ?? 'Unfortunately, your reservation has been rejected.';
        type = 'reservation_rejected';
        break;
      case 'completed':
        title = 'Reservation Completed';
        message = 'Your rental has been completed. Thank you for choosing us!';
        type = 'reservation_completed';
        break;
      default:
        title = 'Reservation Updated';
        message = 'Your reservation status has been updated to: $status';
        type = 'reservation_update';
    }

    try {
      final notificationData = {
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'is_read': false,
        'related_id': reservationId,
      };

      // Insert directly to notifications table so other clients' realtime
      // subscriptions receive the change.
      await _supabaseService.insert(
        SupabaseConfig.notificationsTable,
        notificationData,
      );
    } catch (e) {
      // Non-fatal: log and continue
      print('Failed to create status notification: ${e.toString()}');
    }
  }

  // ========== Backward Compatibility Aliases ==========
  // These methods provide compatibility with the old BookingService interface

  /// Alias for reservations getter
  List<Reservation> get bookings => _reservations;

  /// Alias for loadUserReservations() - loads bookings for a specific user
  Future<void> loadBookings({String? userId}) async {
    if (userId != null) {
      await loadUserReservations(userId);
    } else if (_currentUserId != null) {
      await loadUserReservations(_currentUserId!);
    } else {
      await loadReservations();
    }
  }

  /// Alias for userReservations getter
  List<Reservation> get userBookings => userReservations;

  /// Alias for currentReservation getter
  Reservation? get currentBooking => _currentReservation;

  /// Alias for setCurrentReservation
  void setCurrentBooking(Reservation? reservation) {
    setCurrentReservation(reservation);
  }

  /// Alias for clearCurrentReservation
  void clearCurrentBooking() {
    clearCurrentReservation();
  }

  /// Alias for cancelReservation
  Future<bool> cancelBooking(String bookingId) async {
    return await cancelReservation(bookingId);
  }

  /// Alias for createReservation - maps Booking parameters to Reservation
  Future<bool> createBooking({
    required String userId,
    required String motorcycleId,
    required String motorcycleName,
    required DateTime startDate,
    required DateTime endDate,
    required double totalAmount,
    required dynamic paymentMethod, // Can be PaymentMethod enum or String
    String? notes,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? licenseImageUrl,
  }) async {
    // Convert paymentMethod to string if it's an enum
    String paymentMethodStr;
    if (paymentMethod is String) {
      paymentMethodStr = paymentMethod;
    } else {
      paymentMethodStr =
          paymentMethod.toString().split('.').last; // enum to string
    }

    return await createReservation(
      motorcycleId: motorcycleId,
      startDate: startDate,
      endDate: endDate,
      totalPrice: totalAmount,
      customerName: customerName ?? 'Customer',
      customerEmail: customerEmail ?? '',
      customerPhone: customerPhone ?? '',
      paymentMethod: paymentMethodStr,
      userId: userId,
      adminNotes: notes,
      licenseImageUrl: licenseImageUrl,
    );
  }

  /// Upload documents for a booking - stores URLs in admin_notes temporarily
  Future<bool> uploadDocuments({
    required String bookingId,
    required List<String> documentUrls,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      // Store document URLs in admin_notes field (temporary solution)
      final docInfo = 'Documents uploaded: ${documentUrls.join(', ')}';

      await _supabaseService.update(
        SupabaseConfig.reservationsTable,
        bookingId,
        {
          'admin_notes': docInfo,
          'status': 'pending', // Update status to indicate documents submitted
        },
      );

      // Update local cache
      final index = _reservations.indexWhere((r) => r.id == bookingId);
      if (index != -1) {
        _reservations[index] = _reservations[index].copyWith(
          adminNotes: docInfo,
          status: 'pending',
          updatedAt: DateTime.now(),
        );

        if (_currentReservation?.id == bookingId) {
          _currentReservation = _reservations[index];
        }
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to upload documents: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Update booking status - maps to updateReservationStatus
  Future<bool> updateBookingStatus({
    required String bookingId,
    required dynamic status, // Can be BookingStatus enum or String
    String? rejectionReason,
  }) async {
    // Convert status to string if it's an enum
    String statusStr;
    if (status is String) {
      statusStr = status;
    } else {
      statusStr = status.toString().split('.').last; // enum to string
    }

    return await updateReservationStatus(
      reservationId: bookingId,
      status: statusStr,
    );
  }
}
