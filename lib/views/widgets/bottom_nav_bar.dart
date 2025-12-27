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

/// Custom bottom navigation bar with sliding indicator animation
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

  /// Default navigation items - Explore and Matches
  static List<BottomNavItem> get defaultItems => [
    const BottomNavItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      label: 'Explore',
      activeColor: AppTheme.primaryColor,
    ),
    const BottomNavItem(
      icon: Icons.sports_tennis_outlined,
      activeIcon: Icons.sports_tennis,
      label: 'Matches',
      activeColor: AppTheme.primaryColor,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final itemWidth = MediaQuery.of(context).size.width / items.length;

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
        padding: EdgeInsets.only(bottom: bottomPadding, top: 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated sliding indicator
            Stack(
              children: [
                // Indicator background line
                Container(
                  height: 3,
                  color: Colors.transparent,
                ),
                // Animated indicator
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  left: itemWidth * currentIndex + (itemWidth - 24) / 2,
                  child: Container(
                    height: 3,
                    width: 24,
                    decoration: BoxDecoration(
                      color: items[currentIndex].activeColor ?? selectedColor ?? AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Navigation items row
            Row(
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
                  itemWidth: itemWidth,
                );
              }),
            ),
          ],
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
  final double itemWidth;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.iconSize,
    required this.fontSize,
    required this.itemWidth,
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
      child: SizedBox(
        width: itemWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated icon with scale effect
              AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: isSelected ? 1.1 : 1.0,
                child: Icon(
                  isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                  size: iconSize,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              // Label with animated color
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: color,
                  fontSize: fontSize,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                child: Text(item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
