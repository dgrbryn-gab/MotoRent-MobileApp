enum BookingStatus {
  pending,
  documentsSubmitted,
  waitingApproval,
  approved,
  rejected,
  paymentPending,
  confirmed,
  active,
  completed,
  cancelled,
}

enum PaymentMethod {
  cash,
}

class Booking {
  final String id;
  final String userId;
  final String motorcycleId;
  final String motorcycleName;
  final DateTime startDate;
  final DateTime endDate;
  final double totalAmount;
  final BookingStatus status;
  final PaymentMethod paymentMethod;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? notes;
  final List<String> documentUrls;
  final String? rejectionReason;
  final int currentStep;

  const Booking({
    required this.id,
    required this.userId,
    required this.motorcycleId,
    required this.motorcycleName,
    required this.startDate,
    required this.endDate,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    this.updatedAt,
    this.notes,
    required this.documentUrls,
    this.rejectionReason,
    required this.currentStep,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      userId: json['userId'] ?? json['user_id'],
      motorcycleId: json['motorcycleId'] ?? json['motorcycle_id'],
      motorcycleName: json['motorcycleName'] ?? json['motorcycle_name'],
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.parse(json['start_date']),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : DateTime.parse(json['end_date']),
      totalAmount:
          (json['totalAmount'] ?? json['total_amount'] ?? json['total_price'])
              .toDouble(),
      status: BookingStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => BookingStatus.pending,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) =>
            e.toString().split('.').last ==
            (json['paymentMethod'] ?? json['payment_method'] ?? 'cash'),
        orElse: () => PaymentMethod.cash,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.parse(json['created_at']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : (json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null),
      notes: json['notes'] ?? json['special_requests'],
      documentUrls: List<String>.from(
          json['documentUrls'] ?? json['document_urls'] ?? []),
      rejectionReason: json['rejectionReason'] ??
          json['rejection_reason'] ??
          json['cancellation_reason'],
      currentStep: json['currentStep'] ?? json['current_step'] ?? 1,
    );
  }

  Map<String, dynamic> toJson({bool forDatabase = false}) {
    if (forDatabase) {
      // Use snake_case for database
      return {
        'id': id,
        'user_id': userId,
        'motorcycle_id': motorcycleId,
        'motorcycle_name': motorcycleName,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'total_price': totalAmount,
        'status': status.toString().split('.').last,
        'payment_method': paymentMethod.toString().split('.').last,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'special_requests': notes,
        'cancellation_reason': rejectionReason,
        'current_step': currentStep,
      };
    }

    // Use camelCase for app
    return {
      'id': id,
      'userId': userId,
      'motorcycleId': motorcycleId,
      'motorcycleName': motorcycleName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalAmount': totalAmount,
      'status': status.toString().split('.').last,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'notes': notes,
      'documentUrls': documentUrls,
      'rejectionReason': rejectionReason,
      'currentStep': currentStep,
    };
  }

  Booking copyWith({
    String? id,
    String? userId,
    String? motorcycleId,
    String? motorcycleName,
    DateTime? startDate,
    DateTime? endDate,
    double? totalAmount,
    BookingStatus? status,
    PaymentMethod? paymentMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    List<String>? documentUrls,
    String? rejectionReason,
    int? currentStep,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      motorcycleId: motorcycleId ?? this.motorcycleId,
      motorcycleName: motorcycleName ?? this.motorcycleName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      documentUrls: documentUrls ?? this.documentUrls,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      currentStep: currentStep ?? this.currentStep,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.documentsSubmitted:
        return 'Documents Submitted';
      case BookingStatus.waitingApproval:
        return 'Waiting Approval';
      case BookingStatus.approved:
        return 'Approved';
      case BookingStatus.rejected:
        return 'Rejected';
      case BookingStatus.paymentPending:
        return 'Payment Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.active:
        return 'Active';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get paymentMethodDisplayName {
    return 'Cash';
  }

  int get duration {
    final days = endDate.difference(startDate).inDays;
    return days == 0 ? 1 : days;
  }

  // Calculate overdue penalty: 100 pesos per hour
  double calculateOverduePenalty(DateTime returnDate) {
    if (returnDate.isBefore(endDate) || returnDate.isAtSameMomentAs(endDate)) {
      return 0.0; // No penalty if returned on time
    }

    final overdueHours = returnDate.difference(endDate).inHours;
    return overdueHours * 100.0; // 100 pesos per hour
  }

  // Get total amount including overdue penalty
  double getTotalWithPenalty(DateTime returnDate) {
    return totalAmount + calculateOverduePenalty(returnDate);
  }
}
