// Reservation model matching web application schema

// Import BookingStatus enum for backward compatibility
import 'package:moto_rent_dumaguete/models/booking.dart'
    show BookingStatus, PaymentMethod;

class Reservation {
  final String id;
  final String userId;
  final String motorcycleId;
  final DateTime startDate;
  final DateTime endDate;
  final String? pickupTime;
  final String? returnTime;
  final double totalPrice;
  final String status; // 'pending', 'confirmed', 'cancelled', 'completed'
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String? paymentMethod; // 'cash', 'gcash'
  final String? gcashReferenceNumber;
  final String? gcashProofUrl;
  final String? adminNotes;
  final String? licenseImageUrl;
  final String
      paymentStatus; // 'unpaid', 'pending', 'paid', 'refunded', 'failed'
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Reservation({
    required this.id,
    required this.userId,
    required this.motorcycleId,
    required this.startDate,
    required this.endDate,
    this.pickupTime,
    this.returnTime,
    required this.totalPrice,
    required this.status,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    this.paymentMethod,
    this.gcashReferenceNumber,
    this.gcashProofUrl,
    this.adminNotes,
    this.licenseImageUrl,
    required this.paymentStatus,
    required this.createdAt,
    this.updatedAt,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'],
      userId: json['user_id'],
      motorcycleId: json['motorcycle_id'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      pickupTime: json['pickup_time'],
      returnTime: json['return_time'],
      totalPrice: (json['total_price']).toDouble(),
      status: json['status'] ?? 'pending',
      customerName: json['customer_name'],
      customerEmail: json['customer_email'],
      customerPhone: json['customer_phone'],
      paymentMethod: json['payment_method'],
      gcashReferenceNumber: json['gcash_reference_number'],
      gcashProofUrl: json['gcash_proof_url'],
      adminNotes: json['admin_notes'],
      licenseImageUrl: json['license_image_url'],
      paymentStatus: json['payment_status'] ?? 'unpaid',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'motorcycle_id': motorcycleId,
      'start_date': startDate.toIso8601String().split('T')[0], // Date only
      'end_date': endDate.toIso8601String().split('T')[0], // Date only
      'pickup_time': pickupTime,
      'return_time': returnTime,
      'total_price': totalPrice,
      'status': status,
      'customer_name': customerName,
      'customer_email': customerEmail,
      'customer_phone': customerPhone,
      'payment_method': paymentMethod,
      'gcash_reference_number': gcashReferenceNumber,
      'gcash_proof_url': gcashProofUrl,
      'admin_notes': adminNotes,
      'license_image_url': licenseImageUrl,
      'payment_status': paymentStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Reservation copyWith({
    String? id,
    String? userId,
    String? motorcycleId,
    DateTime? startDate,
    DateTime? endDate,
    String? pickupTime,
    String? returnTime,
    double? totalPrice,
    String? status,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? paymentMethod,
    String? gcashReferenceNumber,
    String? gcashProofUrl,
    String? adminNotes,
    String? licenseImageUrl,
    String? paymentStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reservation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      motorcycleId: motorcycleId ?? this.motorcycleId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      pickupTime: pickupTime ?? this.pickupTime,
      returnTime: returnTime ?? this.returnTime,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      gcashReferenceNumber: gcashReferenceNumber ?? this.gcashReferenceNumber,
      gcashProofUrl: gcashProofUrl ?? this.gcashProofUrl,
      adminNotes: adminNotes ?? this.adminNotes,
      licenseImageUrl: licenseImageUrl ?? this.licenseImageUrl,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods for compatibility with existing UI
  String get motorcycleName => ''; // Would need to fetch from motorcycles table
  int get duration => endDate.difference(startDate).inDays;

  // Alias for backward compatibility with old Booking model
  double get totalAmount => totalPrice;

  // Backward compatibility with BookingStatus enum
  BookingStatus get bookingStatus {
    switch (status.toLowerCase()) {
      case 'pending':
        return BookingStatus.pending;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'completed':
        return BookingStatus.completed;
      case 'approved':
        return BookingStatus.approved;
      case 'rejected':
        return BookingStatus.rejected;
      case 'active':
        return BookingStatus.active;
      default:
        return BookingStatus.pending;
    }
  }

  // Backward compatibility with PaymentMethod enum
  PaymentMethod? get paymentMethodEnum {
    if (paymentMethod == null) return null;
    switch (paymentMethod!.toLowerCase()) {
      case 'cash':
        return PaymentMethod.cash;
      default:
        return PaymentMethod.cash;
    }
  }

  // Additional compatibility fields
  String? get rejectionReason =>
      adminNotes; // Map adminNotes to rejectionReason

  // Current step for booking flow UI (simplified - based on status)
  int get currentStep {
    switch (status.toLowerCase()) {
      case 'pending':
        return 1;
      case 'confirmed':
      case 'active':
        return 4;
      case 'completed':
      case 'cancelled':
      case 'rejected':
        return 4;
      default:
        return 1;
    }
  }

  String get paymentMethodDisplayName {
    if (paymentMethod == null) return 'Not specified';
    switch (paymentMethod!.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'gcash':
        return 'GCash';
      default:
        return paymentMethod!;
    }
  }

  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }
}
