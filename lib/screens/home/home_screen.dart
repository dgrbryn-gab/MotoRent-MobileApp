import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moto_rent_dumaguete/services/motorcycle_service_supabase.dart';
import 'package:moto_rent_dumaguete/services/auth_service_supabase.dart';
import 'package:moto_rent_dumaguete/screens/motorcycle/motorcycle_detail_screen.dart';
import 'package:moto_rent_dumaguete/screens/auth/auth_screen.dart';
import 'package:moto_rent_dumaguete/screens/main_navigation_screen.dart';
import 'package:moto_rent_dumaguete/theme/app_theme.dart';
import 'package:moto_rent_dumaguete/widgets/motorcycle_card.dart';
import 'package:moto_rent_dumaguete/widgets/search_bar.dart';
import 'package:moto_rent_dumaguete/widgets/filter_chips.dart';
import 'package:moto_rent_dumaguete/widgets/glass_container.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load motorcycles when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MotorcycleServiceSupabase>(context, listen: false)
          .loadMotorcycles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppTheme.backgroundColor : AppTheme.lightBackgroundColor;
    final bgSecondary = isDark
        ? AppTheme.backgroundSecondary
        : AppTheme.lightBackgroundSecondary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              bgColor,
              bgSecondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Search and filters
              _buildSearchAndFilters(),

              // Motorcycles grid
              Expanded(
                child: _buildMotorcycleGrid(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<AuthServiceSupabase>(
      builder: (context, authService, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textPrimary =
            isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
        final textSecondary =
            isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authService.isAuthenticated
                          ? 'Welcome back, ${authService.currentUser?.username ?? authService.currentUser?.firstName ?? 'User'}!'
                          : 'Welcome to MotoRent',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Find your perfect ride',
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Profile/Login button
              GestureDetector(
                onTap: () {
                  // Navigate to profile or auth screen
                  if (authService.isAuthenticated) {
                    // Navigate to profile tab (index 3)
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) =>
                            const MainNavigationScreen(initialIndex: 3),
                      ),
                      (route) => false,
                    );
                  } else {
                    // Navigate to auth screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AuthScreen(),
                      ),
                    );
                  }
                },
                child: GlassContainer(
                  width: 40,
                  height: 40,
                  padding: EdgeInsets.zero,
                  borderRadius: 20,
                  opacity: isDark ? 0.1 : 0.3,
                  child: authService.isAuthenticated &&
                          authService.currentUser?.profileImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            authService.currentUser!.profileImageUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                color: AppTheme.primaryColor,
                                size: 20,
                              );
                            },
                          ),
                        )
                      : Icon(
                          authService.isAuthenticated
                              ? Icons.person
                              : Icons.login,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Search bar
          Consumer<MotorcycleServiceSupabase>(
            builder: (context, motorcycleService, child) {
              return CustomSearchBar(
                hintText: 'Search motorcycles...',
                onChanged: motorcycleService.updateSearchQuery,
              );
            },
          ),

          const SizedBox(height: 16),

          // Filter chips
          Consumer<MotorcycleServiceSupabase>(
            builder: (context, motorcycleService, child) {
              return FilterChips(
                categories: motorcycleService.categories,
                selectedCategory: motorcycleService.selectedCategory,
                onCategorySelected: motorcycleService.updateCategory,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMotorcycleGrid(BuildContext context) {
    return Consumer<MotorcycleServiceSupabase>(
      builder: (context, motorcycleService, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textPrimary =
            isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
        final textSecondary =
            isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

        if (motorcycleService.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          );
        }

        if (motorcycleService.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading motorcycles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  motorcycleService.error!,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    motorcycleService.clearError();
                    motorcycleService.loadMotorcycles();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final motorcycles = motorcycleService.motorcycles;

        if (motorcycles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.two_wheeler,
                  size: 64,
                  color: textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No motorcycles found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your search or filters',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: RefreshIndicator(
            onRefresh: motorcycleService.loadMotorcycles,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: motorcycles.length,
              itemBuilder: (context, index) {
                final motorcycle = motorcycles[index];
                return MotorcycleCard(
                  motorcycle: motorcycle,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            MotorcycleDetailScreen(motorcycle: motorcycle),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
