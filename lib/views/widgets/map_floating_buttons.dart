import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Floating action buttons for map controls
class MapFloatingButtons extends StatelessWidget {
  final VoidCallback? onLayersTap;
  final VoidCallback? onMyLocationTap;
  final VoidCallback? onDirectionsTap;
  final bool showDirections;
  final EdgeInsetsGeometry? padding;

  const MapFloatingButtons({
    super.key,
    this.onLayersTap,
    this.onMyLocationTap,
    this.onDirectionsTap,
    this.showDirections = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.only(right: 16, bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Layers button
          MapFloatingButton(
            icon: Icons.layers_outlined,
            onTap: onLayersTap,
            tooltip: 'Map layers',
          ),
          const SizedBox(height: 12),

          // My location button
          MapFloatingButton(
            icon: Icons.my_location,
            onTap: onMyLocationTap,
            tooltip: 'My location',
            iconColor: AppTheme.primaryColor,
          ),
          const SizedBox(height: 12),

          // Directions button
          if (showDirections)
            MapFloatingButton(
              icon: Icons.directions,
              onTap: onDirectionsTap,
              tooltip: 'Directions',
              backgroundColor: const Color(0xFF0D7377),
              iconColor: Colors.white,
              size: 56,
            ),
        ],
      ),
    );
  }
}

/// Individual floating button
class MapFloatingButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final double iconSize;
  final double borderRadius;

  const MapFloatingButton({
    super.key,
    required this.icon,
    this.onTap,
    this.tooltip,
    this.backgroundColor,
    this.iconColor,
    this.size = 48,
    this.iconSize = 24,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: backgroundColor ?? Colors.white,
      borderRadius: BorderRadius.circular(borderRadius),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: iconSize,
            color: iconColor ?? AppTheme.textSecondary,
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
