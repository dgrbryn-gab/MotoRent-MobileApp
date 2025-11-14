import 'package:flutter/material.dart';
import 'package:moto_rent_dumaguete/theme/app_theme.dart';
import 'package:moto_rent_dumaguete/widgets/glass_container.dart';

class FilterChips extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final void Function(String) onCategorySelected;

  const FilterChips({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;

          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 16 : 8,
              right: index == categories.length - 1 ? 16 : 0,
            ),
            child: _AnimatedFilterChip(
              category: category,
              isSelected: isSelected,
              textSecondary: textSecondary,
              isDark: isDark,
              onTap: () => onCategorySelected(category),
            ),
          );
        },
      ),
    );
  }
}

class _AnimatedFilterChip extends StatefulWidget {
  final String category;
  final bool isSelected;
  final Color textSecondary;
  final bool isDark;
  final VoidCallback onTap;

  const _AnimatedFilterChip({
    required this.category,
    required this.isSelected,
    required this.textSecondary,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_AnimatedFilterChip> createState() => _AnimatedFilterChipState();
}

class _AnimatedFilterChipState extends State<_AnimatedFilterChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        borderRadius: 20,
        opacity: widget.isSelected ? 0 : (widget.isDark ? 0.1 : 0.3),
        color: widget.isSelected ? AppTheme.secondaryColor : null,
        border: Border.all(
          color: widget.isSelected
              ? AppTheme.secondaryColor
              : Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) => _controller.reverse(),
          onTapCancel: () => _controller.reverse(),
          child: Text(
            widget.category,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: widget.isSelected ? Colors.white : widget.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
