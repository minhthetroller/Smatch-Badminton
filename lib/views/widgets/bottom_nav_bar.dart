import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Bottom navigation bar item data
class BottomNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final Color? activeColor;

  const BottomNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.activeColor,
  });
}

/// Custom bottom navigation bar similar to Google Maps
class MapBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final List<BottomNavItem> items;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? unselectedColor;
  final double iconSize;
  final double fontSize;

  const MapBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.items,
    this.onTap,
    this.backgroundColor,
    this.selectedColor,
    this.unselectedColor,
    this.iconSize = 24,
    this.fontSize = 11,
  });

  /// Default navigation items similar to Google Maps
  static List<BottomNavItem> get defaultItems => [
    const BottomNavItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      label: 'Explore',
      activeColor: AppTheme.primaryColor,
    ),
    const BottomNavItem(
      icon: Icons.bookmark_outline,
      activeIcon: Icons.bookmark,
      label: 'You',
    ),
    const BottomNavItem(
      icon: Icons.add_circle_outline,
      activeIcon: Icons.add_circle,
      label: 'Contribute',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding, top: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = currentIndex == index;

            return _NavBarItem(
              item: item,
              isSelected: isSelected,
              selectedColor: selectedColor ?? AppTheme.primaryColor,
              unselectedColor: unselectedColor ?? AppTheme.textSecondary,
              iconSize: iconSize,
              fontSize: fontSize,
              onTap: () => onTap?.call(index),
            );
          }),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final BottomNavItem item;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final double iconSize;
  final double fontSize;
  final VoidCallback? onTap;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.iconSize,
    required this.fontSize,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? (item.activeColor ?? selectedColor)
        : unselectedColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selection indicator
            if (isSelected)
              Container(
                height: 3,
                width: 20,
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            // Icon
            Icon(
              isSelected ? (item.activeIcon ?? item.icon) : item.icon,
              size: iconSize,
              color: color,
            ),
            const SizedBox(height: 2),
            // Label
            Text(
              item.label,
              style: TextStyle(
                color: color,
                fontSize: fontSize,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
