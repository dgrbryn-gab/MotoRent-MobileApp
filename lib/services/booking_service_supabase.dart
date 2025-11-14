import 'package:flutter/foundation.dart';
import 'package:moto_rent_dumaguete/models/booking.dart';
import 'package:moto_rent_dumaguete/services/supabase_service.dart';
import 'package:moto_rent_dumaguete/config/supabase_config.dart';

class BookingServiceSupabase extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService.instance;

  List<Booking> _bookings = [];
  bool _isLoading = false;
  String? _error;
  Booking? _currentBooking;

  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Booking? get currentBooking => _currentBooking;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Load all bookings from Supabase
  Future<void> loadBookings() async {
    _setLoading(true);
    _setError(null);

    try {
      final data = await _supabaseService.getAll(
        SupabaseConfig.bookingsTable,
      );

      _bookings = data.map((json) => Booking.fromJson(json)).toList();

      // Sort by creation date (newest first)
      _bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _setLoading(false);
    } catch (e) {
      _setError('Failed to load bookings: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Load bookings for a specific user
  Future<void> loadUserBookings(String userId) async {
    _setLoading(true);
    _setError(null);

    try {
      final data = await _supabaseService.getWhere(
        SupabaseConfig.bookingsTable,
        'user_id',
        userId,
      );

      _bookings = data.map((json) => Booking.fromJson(json)).toList();

      // Sort by creation date (newest first)
      _bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _setLoading(false);
    } catch (e) {
      _setError('Failed to load user bookings: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Get user bookings from already loaded bookings
  List<Booking> getUserBookings(String userId) {
    return _bookings.where((b) => b.userId == userId).toList();
  }

  /// Create a new booking
  Future<bool> createBooking({
    required String userId,
    required String motorcycleId,
    required String motorcycleName,
    required DateTime startDate,
    required DateTime endDate,
    required double totalAmount,
    required PaymentMethod paymentMethod,
    String? notes,
    // Additional booking details
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String customerAddress,
    required DateTime dateOfBirth,
    required String licenseNumber,
    String? licenseImageUrl,
    String? validIdType,
    String? validIdImageUrl,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final bookingData = {
        'user_id': userId,
        'motorcycle_id': motorcycleId,
        'motorcycle_name': motorcycleName,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'pickup_date': startDate.toIso8601String().split('T')[0],
        'pickup_time':
            '${startDate.hour.toString().padLeft(2, '0')}:${startDate.minute.toString().padLeft(2, '0')}',
        'return_date': endDate.toIso8601String().split('T')[0],
        'duration': endDate.difference(startDate).inDays,
        'total_price': totalAmount,
        'security_deposit': 0.0,
        'customer_name': customerName,
        'customer_email': customerEmail,
        'customer_phone': customerPhone,
        'customer_address': customerAddress,
        'date_of_birth': dateOfBirth.toIso8601String().split('T')[0],
        'license_number': licenseNumber,
        'license_image_url': licenseImageUrl,
        'valid_id_type': validIdType,
        'valid_id_image_url': validIdImageUrl,
        'status': 'pending',
        'current_step': 1,
        'payment_status': 'pending',
        'payment_method': paymentMethod.toString().split('.').last,
        'special_requests': notes,
      };

      final data = await _supabaseService.insert(
        SupabaseConfig.bookingsTable,
        bookingData,
      );

      final booking = Booking.fromJson(data);
      _bookings.insert(0, booking);
      _currentBooking = booking;

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create booking: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Upload documents for a booking
  Future<bool> uploadDocuments({
    required String bookingId,
    required List<String> documentUrls,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      await _supabaseService.update(
        SupabaseConfig.bookingsTable,
        bookingId,
        {
          'license_image_url': documentUrls.isNotEmpty ? documentUrls[0] : null,
          'valid_id_image_url':
              documentUrls.length > 1 ? documentUrls[1] : null,
          'status': 'waiting_approval',
          'current_step': 2,
        },
      );

      // Update local cache
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _bookings[index] = _bookings[index].copyWith(
          documentUrls: documentUrls,
          status: BookingStatus.waitingApproval,
          currentStep: 2,
          updatedAt: DateTime.now(),
        );

        if (_currentBooking?.id == bookingId) {
          _currentBooking = _bookings[index];
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

  /// Update booking status (Admin)
  Future<bool> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
    String? rejectionReason,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      int currentStep = 1;
      String dbStatus = status.toString().split('.').last;

      // Map Flutter enum to database status
      switch (status) {
        case BookingStatus.pending:
          currentStep = 1;
          break;
        case BookingStatus.documentsSubmitted:
          currentStep = 2;
          dbStatus = 'waiting_approval';
          break;
        case BookingStatus.waitingApproval:
          currentStep = 3;
          dbStatus = 'waiting_approval';
          break;
        case BookingStatus.approved:
          currentStep = 4;
          dbStatus = 'confirmed';
          break;
        case BookingStatus.confirmed:
          currentStep = 4;
          dbStatus = 'confirmed';
          break;
        case BookingStatus.active:
          currentStep = 4;
          dbStatus = 'active';
          break;
        case BookingStatus.completed:
          currentStep = 4;
          dbStatus = 'completed';
          break;
        case BookingStatus.rejected:
          currentStep = 1;
          dbStatus = 'rejected';
          break;
        case BookingStatus.cancelled:
          dbStatus = 'cancelled';
          break;
        default:
          break;
      }

      final updateData = {
        'status': dbStatus,
        'current_step': currentStep,
      };

      if (rejectionReason != null) {
        updateData['cancellation_reason'] = rejectionReason;
      }

      if (status == BookingStatus.confirmed) {
        updateData['confirmed_at'] = DateTime.now().toIso8601String();
      }

      if (status == BookingStatus.cancelled) {
        updateData['cancelled_at'] = DateTime.now().toIso8601String();
      }

      await _supabaseService.update(
        SupabaseConfig.bookingsTable,
        bookingId,
        updateData,
      );

      // Update local cache
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _bookings[index] = _bookings[index].copyWith(
          status: status,
          currentStep: currentStep,
          rejectionReason: rejectionReason,
          updatedAt: DateTime.now(),
        );

        if (_currentBooking?.id == bookingId) {
          _currentBooking = _bookings[index];
        }
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update booking status: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Confirm payment
  Future<bool> confirmPayment(String bookingId) async {
    _setLoading(true);
    _setError(null);

    try {
      await _supabaseService.update(
        SupabaseConfig.bookingsTable,
        bookingId,
        {
          'payment_status': 'paid',
          'payment_date': DateTime.now().toIso8601String(),
          'status': 'confirmed',
        },
      );

      // Update local cache
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _bookings[index] = _bookings[index].copyWith(
          status: BookingStatus.confirmed,
          updatedAt: DateTime.now(),
        );

        if (_currentBooking?.id == bookingId) {
          _currentBooking = _bookings[index];
        }
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to confirm payment: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Cancel booking
  Future<bool> cancelBooking(String bookingId, {String? reason}) async {
    return updateBookingStatus(
      bookingId: bookingId,
      status: BookingStatus.cancelled,
      rejectionReason: reason,
    );
  }

  /// Get a specific booking by ID
  Future<Booking?> getBookingById(String id) async {
    // Check local cache first
    try {
      return _bookings.firstWhere((b) => b.id == id);
    } catch (e) {
      // Not in cache, fetch from database
      try {
        final data = await _supabaseService.getById(
          SupabaseConfig.bookingsTable,
          id,
        );

        if (data != null) {
          return Booking.fromJson(data);
        }
        return null;
      } catch (e) {
        _setError('Failed to fetch booking: ${e.toString()}');
        return null;
      }
    }
  }

  /// Get bookings by status
  List<Booking> getBookingsByStatus(BookingStatus status) {
    return _bookings.where((booking) => booking.status == status).toList();
  }

  /// Get active bookings
  List<Booking> getActiveBookings() {
    return _bookings
        .where((booking) =>
            booking.status == BookingStatus.confirmed ||
            booking.status == BookingStatus.active)
        .toList();
  }

  /// Get bookings for a specific motorcycle
  Future<List<Booking>> getMotorcycleBookings(String motorcycleId) async {
    try {
      final data = await _supabaseService.getWhere(
        SupabaseConfig.bookingsTable,
        'motorcycle_id',
        motorcycleId,
      );

      return data.map((json) => Booking.fromJson(json)).toList();
    } catch (e) {
      _setError('Failed to fetch motorcycle bookings: ${e.toString()}');
      return [];
    }
  }

  void setCurrentBooking(Booking? booking) {
    _currentBooking = booking;
    notifyListeners();
  }

  void clearCurrentBooking() {
    _currentBooking = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
