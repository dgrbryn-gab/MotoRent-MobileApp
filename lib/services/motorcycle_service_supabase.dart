import 'package:flutter/foundation.dart';
import 'package:moto_rent_dumaguete/models/motorcycle.dart';
import 'package:moto_rent_dumaguete/services/supabase_service.dart';
import 'package:moto_rent_dumaguete/services/storage_service_supabase.dart';
import 'package:moto_rent_dumaguete/config/supabase_config.dart';

class MotorcycleServiceSupabase extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService.instance;

  List<Motorcycle> _motorcycles = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'name';

  List<Motorcycle> get motorcycles => _filteredMotorcycles;
  List<Motorcycle> get allMotorcycles => _motorcycles;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;

  List<String> get categories => [
        'All',
        'Yamaha',
        'Honda',
        'Suzuki',
      ];

  List<String> get sortOptions => [
        'name',
        'price_low',
        'price_high',
        'rating',
      ];

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Load all motorcycles from Supabase
  Future<void> loadMotorcycles() async {
    _setLoading(true);
    _setError(null);

    try {
      final data = await _supabaseService.getAll(
        SupabaseConfig.motorcyclesTable,
      );

      _motorcycles = data.map((json) => Motorcycle.fromJson(json)).toList();
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load motorcycles: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Filtered and sorted motorcycles
  List<Motorcycle> get _filteredMotorcycles {
    List<Motorcycle> filtered = _motorcycles;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((motorcycle) {
        return motorcycle.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            (motorcycle.brand?.toLowerCase() ?? '')
                .contains(_searchQuery.toLowerCase()) ||
            (motorcycle.model?.toLowerCase() ?? '')
                .contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply category filter (filtering by brand)
    if (_selectedCategory != 'All') {
      filtered = filtered.where((motorcycle) {
        return (motorcycle.brand?.toLowerCase() ?? '') ==
            _selectedCategory.toLowerCase();
      }).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'price_low':
        filtered.sort((a, b) => a.pricePerDay.compareTo(b.pricePerDay));
        break;
      case 'price_high':
        filtered.sort((a, b) => b.pricePerDay.compareTo(a.pricePerDay));
        break;
      case 'rating':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'name':
      default:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    return filtered;
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void updateCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void updateSortBy(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';
    _sortBy = 'name';
    notifyListeners();
  }

  /// Get a specific motorcycle by ID
  Motorcycle? getMotorcycleById(String id) {
    try {
      return _motorcycles.firstWhere((motorcycle) => motorcycle.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Fetch a motorcycle by ID from database if not in local list
  Future<Motorcycle?> fetchMotorcycleById(String id) async {
    // First check if we already have it
    final local = getMotorcycleById(id);
    if (local != null) return local;

    try {
      final data = await _supabaseService.getById(
        SupabaseConfig.motorcyclesTable,
        id,
      );

      if (data != null) {
        return Motorcycle.fromJson(data);
      }
      return null;
    } catch (e) {
      _setError('Failed to fetch motorcycle: ${e.toString()}');
      return null;
    }
  }

  /// Get only available motorcycles
  List<Motorcycle> getAvailableMotorcycles() {
    return _motorcycles.where((motorcycle) => motorcycle.isAvailable).toList();
  }

  /// Get recommended motorcycles (rating >= 4.0)
  List<Motorcycle> getRecommendedMotorcycles() {
    return _motorcycles
        .where((motorcycle) => motorcycle.rating >= 4.0)
        .take(5)
        .toList();
  }

  /// Update motorcycle availability (Admin only)
  Future<bool> updateMotorcycleAvailability(String id, bool isAvailable) async {
    _setLoading(true);
    _setError(null);

    try {
      await _supabaseService.update(
        SupabaseConfig.motorcyclesTable,
        id,
        {'is_available': isAvailable},
      );

      // Update local cache
      final index =
          _motorcycles.indexWhere((motorcycle) => motorcycle.id == id);
      if (index != -1) {
        _motorcycles[index] = _motorcycles[index]
            .copyWith(availability: isAvailable ? 'Available' : 'Reserved');
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update motorcycle: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Add a new motorcycle (Admin only)
  Future<bool> addMotorcycle(Motorcycle motorcycle) async {
    _setLoading(true);
    _setError(null);

    try {
      final data = await _supabaseService.insert(
        SupabaseConfig.motorcyclesTable,
        motorcycle.toJson(),
      );

      _motorcycles.add(Motorcycle.fromJson(data));
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add motorcycle: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Add a new motorcycle with image upload (Admin only)
  Future<bool> addMotorcycleWithImage({
    required Motorcycle motorcycle,
    required String imagePath,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      // Upload image to storage first
      final storageService = StorageServiceSupabase();
      final imageUrl = await storageService.uploadMotorcycleImage(
        filePath: imagePath,
        motorcycleId: motorcycle.plateNumber ??
            'temp_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (imageUrl == null) {
        _setError('Failed to upload motorcycle image');
        _setLoading(false);
        return false;
      }

      // Create motorcycle with image URL using copyWith
      final motorcycleWithImage = motorcycle.copyWith(
        image: imageUrl,
      );

      final data = await _supabaseService.insert(
        SupabaseConfig.motorcyclesTable,
        motorcycleWithImage.toJson(),
      );

      _motorcycles.add(Motorcycle.fromJson(data));
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add motorcycle: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Update motorcycle details (Admin only)
  Future<bool> updateMotorcycle(String id, Motorcycle motorcycle) async {
    _setLoading(true);
    _setError(null);

    try {
      await _supabaseService.update(
        SupabaseConfig.motorcyclesTable,
        id,
        motorcycle.toJson(),
      );

      // Update local cache
      final index = _motorcycles.indexWhere((m) => m.id == id);
      if (index != -1) {
        _motorcycles[index] = motorcycle;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update motorcycle: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Update motorcycle with image upload (Admin only)
  Future<bool> updateMotorcycleWithImage({
    required String id,
    required Motorcycle motorcycle,
    required String imagePath,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      // Delete old image if exists
      if (motorcycle.image.isNotEmpty &&
          motorcycle.image.contains('motorcycle-images/')) {
        final storageService = StorageServiceSupabase();
        // Extract filename from URL
        final uri = Uri.parse(motorcycle.image);
        final pathSegments = uri.pathSegments;
        if (pathSegments.length >= 2) {
          final fileName = pathSegments.last;
          await storageService.deleteFile(
            storagePath: fileName,
            bucketName: 'motorcycle-images',
          );
        }
      }

      // Upload new image
      final storageService = StorageServiceSupabase();
      final imageUrl = await storageService.uploadMotorcycleImage(
        filePath: imagePath,
        motorcycleId: motorcycle.plateNumber ??
            'temp_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (imageUrl == null) {
        _setError('Failed to upload motorcycle image');
        _setLoading(false);
        return false;
      }

      // Update motorcycle with new image URL
      final motorcycleWithImage = motorcycle.copyWith(
        image: imageUrl,
      );

      await _supabaseService.update(
        SupabaseConfig.motorcyclesTable,
        id,
        motorcycleWithImage.toJson(),
      );

      // Update local cache
      final index = _motorcycles.indexWhere((m) => m.id == id);
      if (index != -1) {
        _motorcycles[index] = motorcycleWithImage;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update motorcycle: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Delete motorcycle (Admin only)
  Future<bool> deleteMotorcycle(String id) async {
    _setLoading(true);
    _setError(null);

    try {
      // Get motorcycle to access image URL
      final motorcycle = _motorcycles.firstWhere(
        (m) => m.id == id,
        orElse: () => throw Exception('Motorcycle not found'),
      );

      // Delete image from storage if exists
      if (motorcycle.image.isNotEmpty &&
          motorcycle.image.contains('motorcycle-images/')) {
        final storageService = StorageServiceSupabase();
        final uri = Uri.parse(motorcycle.image);
        final pathSegments = uri.pathSegments;
        if (pathSegments.length >= 2) {
          final fileName = pathSegments.last;
          await storageService.deleteFile(
            storagePath: fileName,
            bucketName: 'motorcycle-images',
          );
        }
      }

      // Delete from database
      await _supabaseService.delete(
        SupabaseConfig.motorcyclesTable,
        id,
      );

      // Remove from local cache
      _motorcycles.removeWhere((m) => m.id == id);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete motorcycle: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Check motorcycle availability for specific dates
  Future<bool> checkAvailability(
    String motorcycleId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Check if motorcycle has any active bookings during the requested period
      final bookings = await _supabaseService.getWhere(
        SupabaseConfig.bookingsTable,
        'motorcycle_id',
        motorcycleId,
      );

      // Filter bookings that overlap with requested dates
      final conflicts = bookings.where((booking) {
        final bookingStart = DateTime.parse(booking['start_date']);
        final bookingEnd = DateTime.parse(booking['end_date']);
        final status = booking['status'];

        // Only consider active bookings
        if (status == 'cancelled' || status == 'rejected') {
          return false;
        }

        // Check for date overlap
        return (bookingStart.isBefore(endDate) &&
            bookingEnd.isAfter(startDate));
      }).toList();

      return conflicts.isEmpty;
    } catch (e) {
      _setError('Failed to check availability: ${e.toString()}');
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
