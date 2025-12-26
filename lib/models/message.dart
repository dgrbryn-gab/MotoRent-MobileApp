class ContactMessage {
  final String id;
  final String name;
  final String email;
  final String message;
  final String status; // 'new', 'replied', 'resolved'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? replyMessage;
  final DateTime? repliedAt;

  const ContactMessage({
    required this.id,
    required this.name,
    required this.email,
    required this.message,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.replyMessage,
    this.repliedAt,
  });

  factory ContactMessage.fromJson(Map<String, dynamic> json) {
    return ContactMessage(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      message: json['message'] ?? '',
      status: json['status'] ?? 'new',
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      replyMessage: json['reply_message'],
      repliedAt: json['replied_at'] != null
          ? DateTime.parse(json['replied_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'message': message,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'reply_message': replyMessage,
      'replied_at': repliedAt?.toIso8601String(),
    };
  }
}
