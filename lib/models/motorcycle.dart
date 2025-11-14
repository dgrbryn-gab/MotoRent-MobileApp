class Motorcycle {
  final String id;
  final String name;
  final String? model;
  final String? brand;
  final String type; // From web schema
  final int engineCapacity; // From web schema
  final double pricePerDay;
  final String image;
  final List<String> features;
  final double fuelCapacity; // Changed to double
  final String transmission;
  final String
      availability; // From web schema: 'Available', 'Reserved', 'In Maintenance'
  final String description;
  final double rating;
  final int reviewCount; // Changed from totalReviews
  final String fuelType; // From web schema: 'Gasoline', 'Electric'
  final String color;
  final int year;
  final String? plateNumber;
  final int? mileage;

  const Motorcycle({
    required this.id,
    required this.name,
    this.model,
    this.brand,
    required this.type,
    required this.engineCapacity,
    required this.pricePerDay,
    required this.image,
    required this.features,
    required this.fuelCapacity,
    required this.transmission,
    required this.availability,
    required this.description,
    required this.rating,
    required this.reviewCount,
    required this.fuelType,
    required this.color,
    required this.year,
    this.plateNumber,
    this.mileage,
  });

  // Helper getter for compatibility
  bool get isAvailable => availability == 'Available';
  int get totalReviews => reviewCount;
  String get category => type;
  String get engine => '${engineCapacity}cc';

  factory Motorcycle.fromJson(Map<String, dynamic> json) {
    return Motorcycle(
      id: json['id'],
      name: json['name'],
      model: json['model'],
      brand: json['brand'],
      type: json['type'],
      engineCapacity: json['engine_capacity'],
      pricePerDay: (json['price_per_day']).toDouble(),
      image: json['image'] ?? '',
      features: List<String>.from(json['features'] ?? []),
      fuelCapacity: (json['fuel_capacity']).toDouble(),
      transmission: json['transmission'],
      availability: json['availability'] ?? 'Available',
      description: json['description'] ?? '',
      rating: (json['rating'] ?? 5.0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      fuelType: json['fuel_type'],
      color: json['color'],
      year: json['year'],
      plateNumber: json['plate_number'],
      mileage: json['mileage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'model': model,
      'brand': brand,
      'type': type,
      'engine_capacity': engineCapacity,
      'price_per_day': pricePerDay,
      'image': image,
      'features': features,
      'fuel_capacity': fuelCapacity,
      'transmission': transmission,
      'availability': availability,
      'description': description,
      'rating': rating,
      'review_count': reviewCount,
      'fuel_type': fuelType,
      'color': color,
      'year': year,
      'plate_number': plateNumber,
      'mileage': mileage,
    };
  }

  Motorcycle copyWith({
    String? id,
    String? name,
    String? model,
    String? brand,
    String? type,
    int? engineCapacity,
    double? pricePerDay,
    String? image,
    List<String>? features,
    double? fuelCapacity,
    String? transmission,
    String? availability,
    String? description,
    double? rating,
    int? reviewCount,
    String? fuelType,
    String? color,
    int? year,
    String? plateNumber,
    int? mileage,
  }) {
    return Motorcycle(
      id: id ?? this.id,
      name: name ?? this.name,
      model: model ?? this.model,
      brand: brand ?? this.brand,
      type: type ?? this.type,
      engineCapacity: engineCapacity ?? this.engineCapacity,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      image: image ?? this.image,
      features: features ?? this.features,
      fuelCapacity: fuelCapacity ?? this.fuelCapacity,
      transmission: transmission ?? this.transmission,
      availability: availability ?? this.availability,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      fuelType: fuelType ?? this.fuelType,
      color: color ?? this.color,
      year: year ?? this.year,
      plateNumber: plateNumber ?? this.plateNumber,
      mileage: mileage ?? this.mileage,
    );
  }
}
