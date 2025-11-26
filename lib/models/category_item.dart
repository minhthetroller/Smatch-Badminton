import 'package:flutter/material.dart';

/// Model for category filter chips
class CategoryItem {
  final String id;
  final String label;
  final IconData icon;
  final Color? iconColor;
  final bool isSelected;

  const CategoryItem({
    required this.id,
    required this.label,
    required this.icon,
    this.iconColor,
    this.isSelected = false,
  });

  CategoryItem copyWith({
    String? id,
    String? label,
    IconData? icon,
    Color? iconColor,
    bool? isSelected,
  }) {
    return CategoryItem(
      id: id ?? this.id,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  /// Predefined categories similar to Google Maps
  static List<CategoryItem> get defaultCategories => [
    const CategoryItem(
      id: 'restaurants',
      label: 'Restaurants',
      icon: Icons.restaurant,
      iconColor: Color(0xFF34A853),
    ),
    const CategoryItem(
      id: 'coffee',
      label: 'Coffee',
      icon: Icons.coffee,
      iconColor: Color(0xFF795548),
    ),
    const CategoryItem(
      id: 'hotels',
      label: 'Hotels',
      icon: Icons.hotel,
      iconColor: Color(0xFF673AB7),
    ),
    const CategoryItem(
      id: 'shopping',
      label: 'Shopping',
      icon: Icons.shopping_bag,
      iconColor: Color(0xFF2196F3),
    ),
    const CategoryItem(
      id: 'badminton',
      label: 'Badminton',
      icon: Icons.sports_tennis,
      iconColor: Color(0xFFFF5722),
    ),
  ];
}
