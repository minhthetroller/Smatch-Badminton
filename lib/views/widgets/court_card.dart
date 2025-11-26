import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/court.dart';

/// Card widget for displaying court information
class CourtCard extends StatelessWidget {
  final Court court;
  final VoidCallback? onTap;
  final VoidCallback? onDirectionsTap;
  final VoidCallback? onCallTap;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final bool showDistance;
  final bool showActions;

  const CourtCard({
    super.key,
    required this.court,
    this.onTap,
    this.onDirectionsTap,
    this.onCallTap,
    this.width,
    this.height,
    this.margin,
    this.showDistance = true,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 280,
      height: height,
      margin: margin ?? const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header row
                Row(
                  children: [
                    // Court icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5722).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.sports_tennis,
                        color: Color(0xFFFF5722),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name and distance
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            court.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (showDistance && court.distance != null)
                            Text(
                              court.distanceFormatted,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Address
                if (court.addressDistrict != null)
                  Text(
                    court.addressDistrict!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                // Opening hours
                if (court.openingHours?.todayHours != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppTheme.textHint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Today: ${court.openingHours!.todayHours}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],

                // Actions
                if (showActions) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (onDirectionsTap != null)
                        _ActionButton(
                          icon: Icons.directions,
                          label: 'Directions',
                          color: AppTheme.primaryColor,
                          onTap: onDirectionsTap,
                        ),
                      if (onCallTap != null &&
                          court.phoneNumbers.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _ActionButton(
                          icon: Icons.phone,
                          label: 'Call',
                          color: AppTheme.accentColor,
                          onTap: onCallTap,
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
