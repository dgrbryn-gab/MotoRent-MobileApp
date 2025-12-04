import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:moto_rent_dumaguete/theme/app_theme.dart';

class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const BottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? AppTheme.backgroundColor : Colors.white)
                .withOpacity(0.7),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
          ),
          child: SafeArea(
            child: SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _AnimatedNavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: 'Home',
                    isSelected: currentIndex == 0,
                    textSecondary: textSecondary,
                    onTap: () => onTap(0),
                  ),
                  _AnimatedNavItem(
                    icon: Icons.bookmark_outline,
                    activeIcon: Icons.bookmark,
                    label: 'Reservations',
                    isSelected: currentIndex == 1,
                    textSecondary: textSecondary,
                    onTap: () => onTap(1),
                  ),
                  _AnimatedNavItem(
                    icon: Icons.receipt_long_outlined,
                    activeIcon: Icons.receipt_long,
                    label: 'Transactions',
                    isSelected: currentIndex == 2,
                    textSecondary: textSecondary,
                    onTap: () => onTap(2),
                  ),
                  _AnimatedNavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Profile',
                    isSelected: currentIndex == 3,
                    textSecondary: textSecondary,
                    onTap: () => onTap(3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedNavItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final Color textSecondary;
  final VoidCallback onTap;

  const _AnimatedNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.textSecondary,
    required this.onTap,
  });

  @override
  State<_AnimatedNavItem> createState() => _AnimatedNavItemState();
}

class _AnimatedNavItemState extends State<_AnimatedNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
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
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  widget.isSelected ? widget.activeIcon : widget.icon,
                  key: ValueKey(widget.isSelected),
                  color: widget.isSelected
                      ? AppTheme.secondaryColor
                      : widget.textSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isSelected
                      ? AppTheme.secondaryColor
                      : widget.textSecondary,
                  fontWeight:
                      widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
