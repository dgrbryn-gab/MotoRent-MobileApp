import 'package:flutter/material.dart';
import 'package:moto_rent_dumaguete/theme/app_theme.dart';
import 'package:moto_rent_dumaguete/widgets/glass_container.dart';

class CustomSearchBar extends StatefulWidget {
  final String hintText;
  final void Function(String) onChanged;
  final VoidCallback? onFilterTap;

  const CustomSearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.onFilterTap,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final borderColor =
        isDark ? AppTheme.borderColor : AppTheme.lightBorderColor;

    return GlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: 12,
      opacity: isDark ? 0.1 : 0.3,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: widget.onChanged,
              style: TextStyle(
                fontSize: 16,
                color: textPrimary,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: textSecondary,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: textSecondary,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
          if (widget.onFilterTap != null) ...[
            Container(
              width: 1,
              height: 24,
              color: borderColor,
            ),
            IconButton(
              onPressed: widget.onFilterTap,
              icon: Icon(
                Icons.tune,
                color: textSecondary,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
