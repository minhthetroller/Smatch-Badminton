import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Customizable search bar widget similar to Google Maps
class MapSearchBar extends StatelessWidget {
  final String hintText;
  final String? value;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final VoidCallback? onVoiceSearch;
  final Widget? leading;
  final Widget? trailing;
  final bool readOnly;
  final bool showShadow;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final double borderRadius;
  final Color? backgroundColor;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  const MapSearchBar({
    super.key,
    this.hintText = 'Search here',
    this.value,
    this.onChanged,
    this.onTap,
    this.onClear,
    this.onVoiceSearch,
    this.leading,
    this.trailing,
    this.readOnly = false,
    this.showShadow = true,
    this.margin,
    this.padding,
    this.height,
    this.borderRadius = AppTheme.borderRadiusXLarge,
    this.backgroundColor,
    this.controller,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16),
      height: height ?? 52,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow ? AppTheme.cardShadow : null,
      ),
      child: Row(
        children: [
          // Leading widget (logo or back button)
          if (leading != null)
            Padding(padding: const EdgeInsets.only(left: 12), child: leading!)
          else
            const Padding(
              padding: EdgeInsets.only(left: 16),
              child: _GoogleMapsLogo(),
            ),

          // Search input
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              readOnly: readOnly,
              onTap: onTap,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: AppTheme.textHint,
                  fontSize: 16,
                ),
                border: InputBorder.none,
                contentPadding:
                    padding ??
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
          ),

          // Voice search button
          if (onVoiceSearch != null)
            IconButton(
              icon: const Icon(Icons.mic),
              color: AppTheme.textSecondary,
              onPressed: onVoiceSearch,
              tooltip: 'Voice search',
            ),

          // Trailing widget (profile or action)
          if (trailing != null)
            Padding(padding: const EdgeInsets.only(right: 8), child: trailing!)
          else
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: _ProfileAvatar(),
            ),
        ],
      ),
    );
  }
}

/// Google Maps style logo
class _GoogleMapsLogo extends StatelessWidget {
  const _GoogleMapsLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
      child: const Icon(Icons.location_on, color: Color(0xFF34A853), size: 24),
    );
  }
}

/// Profile avatar placeholder
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primaryColor, width: 2),
      ),
      child: ClipOval(
        child: Container(
          color: Colors.grey[200],
          child: const Icon(Icons.person, size: 20, color: Colors.grey),
        ),
      ),
    );
  }
}
