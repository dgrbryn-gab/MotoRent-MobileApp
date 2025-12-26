import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moto_rent_dumaguete/models/motorcycle.dart';
import 'package:moto_rent_dumaguete/services/auth_service_supabase.dart';
import 'package:moto_rent_dumaguete/screens/booking/booking_screen.dart';
import 'package:moto_rent_dumaguete/screens/auth/auth_screen.dart';
import 'package:moto_rent_dumaguete/theme/app_theme.dart';
import 'package:moto_rent_dumaguete/widgets/loading_button.dart';

class MotorcycleDetailScreen extends StatefulWidget {
  final Motorcycle motorcycle;

  const MotorcycleDetailScreen({
    super.key,
    required this.motorcycle,
  });

  @override
  State<MotorcycleDetailScreen> createState() => _MotorcycleDetailScreenState();
}

class _MotorcycleDetailScreenState extends State<MotorcycleDetailScreen> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorites') ?? [];
    setState(() {
      _isFavorite = favorites.contains(widget.motorcycle.id);
    });
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList('favorites') ?? [];

    if (_isFavorite) {
      favorites.remove(widget.motorcycle.id);
      await prefs.setStringList('favorites', favorites);
      setState(() {
        _isFavorite = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.motorcycle.model} removed from favorites'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      favorites.add(widget.motorcycle.id);
      await prefs.setStringList('favorites', favorites);
      setState(() {
        _isFavorite = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.motorcycle.model} added to favorites'),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
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
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            SliverToBoxAdapter(
              child: _buildContent(context),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildAppBar(BuildContext context) {
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

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: bgColor,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? AppTheme.errorColor : textPrimary,
          ),
          onPressed: _toggleFavorite,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Motorcycle Image
            widget.motorcycle.image.isNotEmpty
                ? Image.network(
                    widget.motorcycle.image,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: bgSecondary,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.two_wheeler,
                            size: 120,
                            color: textSecondary.withOpacity(0.3),
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        decoration: BoxDecoration(
                          color: bgSecondary,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: bgSecondary,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.two_wheeler,
                        size: 120,
                        color: textSecondary.withOpacity(0.3),
                      ),
                    ),
                  ),
            // Gradient overlay for better text visibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final cardColor = isDark ? AppTheme.cardColor : AppTheme.lightCardColor;
    final borderColor =
        isDark ? AppTheme.borderColor : AppTheme.lightBorderColor;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Availability Status Badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: widget.motorcycle.isAvailable
                    ? AppTheme.successColor
                    : AppTheme.errorColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.motorcycle.isAvailable
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.motorcycle.isAvailable ? 'Available' : 'Rented',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Header info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.motorcycle.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.motorcycle.brand} • ${widget.motorcycle.category}',
                      style: TextStyle(
                        fontSize: 16,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            color: AppTheme.warningColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.motorcycle.rating} (${widget.motorcycle.totalReviews} reviews)',
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₱${widget.motorcycle.pricePerDay.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  Text(
                    'per day',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Description
          Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.motorcycle.description,
            style: TextStyle(
              fontSize: 16,
              color: textSecondary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          // Specifications
          Text(
            'Specifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSpecificationItem(
              'Engine', widget.motorcycle.engine, textPrimary, textSecondary),
          _buildSpecificationItem('Transmission',
              widget.motorcycle.transmission, textPrimary, textSecondary),
          _buildSpecificationItem('Fuel Capacity',
              '${widget.motorcycle.fuelCapacity}L', textPrimary, textSecondary),
          _buildSpecificationItem(
              'Color', widget.motorcycle.color, textPrimary, textSecondary),
          _buildSpecificationItem('Year', widget.motorcycle.year.toString(),
              textPrimary, textSecondary),
          _buildSpecificationItem(
              'Plate Number',
              widget.motorcycle.plateNumber ?? 'N/A',
              textPrimary,
              textSecondary),

          const SizedBox(height: 24),

          // Features
          Text(
            'Features',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.motorcycle.features
                .map(
                  (feature) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      feature,
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 100), // Bottom padding for fixed button
        ],
      ),
    );
  }

  Widget _buildSpecificationItem(
      String label, String value, Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.cardColor : AppTheme.lightCardColor;
    final borderColor =
        isDark ? AppTheme.borderColor : AppTheme.lightBorderColor;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(
          top: BorderSide(color: borderColor),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Price',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '₱${widget.motorcycle.pricePerDay.toStringAsFixed(0)}/day',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Consumer<AuthServiceSupabase>(
                builder: (context, authService, child) {
                  return LoadingButton(
                    onPressed: widget.motorcycle.isAvailable
                        ? () {
                            if (authService.isAuthenticated) {
                              // Check if email is verified in Supabase Auth
                              final isEmailVerified =
                                  authService.isEmailVerifiedInAuth();

                              if (!isEmailVerified) {
                                // Email not verified
                                final needsVerification = authService
                                    .shouldRequireEmailVerificationOnMobile();

                                if (needsVerification) {
                                  // Mobile signup - show verification reminder
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Please verify your email before booking',
                                      ),
                                      backgroundColor: AppTheme.warningColor,
                                      duration: const Duration(seconds: 3),
                                      action: SnackBarAction(
                                        label: 'Verify',
                                        textColor: Colors.white,
                                        onPressed: () {
                                          Navigator.of(context)
                                              .pushNamedAndRemoveUntil(
                                            '/',
                                            (route) => false,
                                          );
                                          Navigator.of(context)
                                              .pushNamed('/profile');
                                        },
                                      ),
                                    ),
                                  );
                                } else {
                                  // Web signup but not yet verified on web either
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Please verify your email before booking',
                                      ),
                                      backgroundColor: AppTheme.warningColor,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                                return;
                              }

                              // Email is verified - allow booking
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookingScreen(
                                      motorcycle: widget.motorcycle),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AuthScreen(),
                                ),
                              );
                            }
                          }
                        : null,
                    isLoading: false,
                    text: widget.motorcycle.isAvailable
                        ? (authService.isAuthenticated
                            ? (authService.isEmailVerifiedInAuth()
                                ? 'Book Now'
                                : 'Verify Email')
                            : 'Login to Book')
                        : 'Not Available',
                    backgroundColor: widget.motorcycle.isAvailable
                        ? (authService.isAuthenticated &&
                                !authService.isEmailVerifiedInAuth()
                            ? AppTheme.warningColor
                            : AppTheme.secondaryColor)
                        : AppTheme.textSecondary,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
