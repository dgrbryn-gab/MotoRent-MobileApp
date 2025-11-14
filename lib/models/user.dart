class User {
  final String id;
  final String name; // Combined name from web app
  final String email;
  final String? username;
  final String phone;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool emailVerified;
  final String? licenseNumber;
  final String? licenseImageUrl;
  final String? profileImageUrl;
  final DateTime? birthday;
  final String? address;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.username,
    required this.phone,
    required this.createdAt,
    this.updatedAt,
    this.emailVerified = false,
    this.licenseNumber,
    this.licenseImageUrl,
    this.profileImageUrl,
    this.birthday,
    this.address,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      username: json['username'],
      phone: json['phone_number'] ?? json['phone'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      emailVerified: json['email_verified'] ?? false,
      licenseNumber: json['license_number'],
      licenseImageUrl: json['driver_license_url'], // Use web column
      profileImageUrl: json['profile_picture_url'], // Use web column
      birthday:
          json['birthday'] != null ? DateTime.parse(json['birthday']) : null,
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson({bool forDatabase = false}) {
    return {
      'id': id,
      'name': name,
      'email': email,
      'username': username,
      'phone_number': phone,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'email_verified': emailVerified,
      'license_number': licenseNumber,
      'driver_license_url': licenseImageUrl, // Use web column
      'profile_picture_url': profileImageUrl, // Use web column
      'birthday': birthday?.toIso8601String(),
      'address': address,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? username,
    String? phone,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? emailVerified,
    String? licenseNumber,
    String? licenseImageUrl,
    String? profileImageUrl,
    DateTime? birthday,
    String? address,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      emailVerified: emailVerified ?? this.emailVerified,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseImageUrl: licenseImageUrl ?? this.licenseImageUrl,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      birthday: birthday ?? this.birthday,
      address: address ?? this.address,
    );
  }

  String get displayName => username ?? name;

  // Compatibility getters for old code
  String get firstName => name.split(' ').first;
  String get lastName => name.split(' ').length > 1 ? name.split(' ').last : '';
  String get fullName => name;
  String get phoneNumber => phone;
  bool get isAdmin => false; // Web app uses separate admin_users table
  bool get isVerified => emailVerified; // Now uses email_verified from database
  bool get hasLicense => licenseNumber != null && licenseNumber!.isNotEmpty;
}
