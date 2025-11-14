import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moto_rent_dumaguete/theme/app_theme.dart';
import 'package:moto_rent_dumaguete/screens/main_navigation_screen.dart';
import 'package:moto_rent_dumaguete/screens/motorcycle/motorcycle_detail_screen.dart';
import 'package:moto_rent_dumaguete/services/motorcycle_service_supabase.dart';
import 'package:moto_rent_dumaguete/models/motorcycle.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<String> _favoriteIds = [];
  List<Motorcycle> _favoriteMotorcycles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = prefs.getStringList('favorites') ?? [];

    if (favoriteIds.isEmpty) {
      setState(() {
        _favoriteIds = [];
        _favoriteMotorcycles = [];
        _isLoading = false;
      });
      return;
    }

    final motorcycleService =
        Provider.of<MotorcycleServiceSupabase>(context, listen: false);
    final List<Motorcycle> motorcycles = [];

    for (final id in favoriteIds) {
      final motorcycle = await motorcycleService.fetchMotorcycleById(id);
      if (motorcycle != null) {
        motorcycles.add(motorcycle);
      }
    }

    setState(() {
      _favoriteIds = favoriteIds;
      _favoriteMotorcycles = motorcycles;
      _isLoading = false;
    });
  }

  Future<void> _removeFavorite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    _favoriteIds.remove(id);
    await prefs.setStringList('favorites', _favoriteIds);

    setState(() {
      _favoriteMotorcycles.removeWhere((m) => m.id == id);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removed from favorites'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppTheme.backgroundColor : AppTheme.lightBackgroundColor;
    final bgSecondary = isDark
        ? AppTheme.backgroundSecondary
        : AppTheme.lightBackgroundSecondary;
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final cardColor = isDark ? AppTheme.cardColor : AppTheme.lightCardColor;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgColor, bgSecondary],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: textPrimary),
                    ),
                    Text(
                      'Favorites',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (_favoriteIds.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_favoriteIds.length} ${_favoriteIds.length == 1 ? 'item' : 'items'}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _favoriteMotorcycles.isEmpty
                        ? _buildEmptyState(textPrimary, textSecondary)
                        : _buildFavoritesList(
                            cardColor, textPrimary, textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textPrimary, Color textSecondary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Favorites Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start adding motorcycles to your favorites by tapping the heart icon on motorcycle details',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to home screen (index 0) in main navigation
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) =>
                        const MainNavigationScreen(initialIndex: 0),
                  ),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.explore),
              label: const Text('Browse Motorcycles'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList(
      Color cardColor, Color textPrimary, Color textSecondary) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoriteMotorcycles.length,
      itemBuilder: (context, index) {
        final motorcycle = _favoriteMotorcycles[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    MotorcycleDetailScreen(motorcycle: motorcycle),
              ),
            ).then((_) => _loadFavorites()); // Reload after returning
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.borderColor
                    : AppTheme.lightBorderColor,
              ),
            ),
            child: Row(
              children: [
                // Motorcycle image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: motorcycle.image.isNotEmpty
                      ? Image.network(
                          motorcycle.image,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.two_wheeler,
                                size: 40,
                                color: AppTheme.primaryColor,
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.two_wheeler,
                            size: 40,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        motorcycle.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${motorcycle.brand} • ${motorcycle.category}',
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            motorcycle.isAvailable
                                ? Icons.check_circle
                                : Icons.cancel,
                            size: 16,
                            color: motorcycle.isAvailable
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            motorcycle.isAvailable ? 'Available' : 'Rented',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: motorcycle.isAvailable
                                  ? AppTheme.successColor
                                  : AppTheme.errorColor,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '₱${motorcycle.pricePerDay.toStringAsFixed(0)}/day',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _removeFavorite(motorcycle.id),
                  icon: const Icon(Icons.delete_outline),
                  color: AppTheme.errorColor,
                  tooltip: 'Remove',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
