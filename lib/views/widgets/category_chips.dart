import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/category_item.dart';

/// Horizontal scrollable category chips similar to Google Maps
class CategoryChips extends StatelessWidget {
  final List<CategoryItem> categories;
  final ValueChanged<CategoryItem>? onCategoryTap;
  final EdgeInsetsGeometry? padding;
  final double spacing;
  final double height;

  const CategoryChips({
    super.key,
    required this.categories,
    this.onCategoryTap,
    this.padding,
    this.spacing = 8,
    this.height = 36,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, _) => SizedBox(width: spacing),
        itemBuilder: (context, index) {
          final category = categories[index];
          return CategoryChip(
            category: category,
            onTap: () => onCategoryTap?.call(category),
          );
        },
      ),
    );
  }
}

/// Individual category chip
class CategoryChip extends StatelessWidget {
  final CategoryItem category;
  final VoidCallback? onTap;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double iconSize;
  final double borderRadius;

  const CategoryChip({
    super.key,
    required this.category,
    this.onTap,
    this.height,
    this.padding,
    this.iconSize = 18,
    this.borderRadius = AppTheme.borderRadiusLarge,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = category.isSelected;

    return Material(
      color: isSelected
          ? AppTheme.chipSelectedBackground
          : AppTheme.chipBackground,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          height: height,
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.5)
                  : AppTheme.chipBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                category.icon,
                size: iconSize,
                color: category.iconColor ?? AppTheme.textPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                category.label,
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
