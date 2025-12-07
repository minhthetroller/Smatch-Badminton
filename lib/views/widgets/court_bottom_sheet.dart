import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../models/court.dart';

/// Google Maps-style draggable bottom sheet for court details
/// This widget is designed to be used as an overlay on top of other content
class CourtBottomSheet extends StatefulWidget {
  final Court court;
  final VoidCallback? onClose;
  final VoidCallback? onDirections;
  final VoidCallback? onBook;

  const CourtBottomSheet({
    super.key,
    required this.court,
    this.onClose,
    this.onDirections,
    this.onBook,
  });

  @override
  State<CourtBottomSheet> createState() => _CourtBottomSheetState();
}

class _CourtBottomSheetState extends State<CourtBottomSheet> {
  final DraggableScrollableController _controller =
      DraggableScrollableController();

  bool _isBookmarked = false;
  bool _isHoursExpanded = false;

  // Dummy data for missing fields
  static const _dummyRating = 4.8;
  static const _dummyReviewCount = 128;
  static const _dummyPriceRange = '₫50,000 - ₫150,000';
  static const _dummyPhotos = [
    'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=400',
    'https://images.unsplash.com/photo-1613918431703-aa50889e3be6?w=400',
    'https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=400',
    'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=400',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleClose() {
    widget.onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.25,
      maxChildSize: 0.92,
      snap: true,
      snapSizes: const [0.45, 0.65, 0.92],
      controller: _controller,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              // Drag handle
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // Header with name and circular buttons
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildHeader(),
                ),
              ),

              // Action buttons (horizontal scroll)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _buildActionButtons(),
                ),
              ),

              // Photo gallery (larger)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _buildPhotoGallery(),
                ),
              ),

              // Overview section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildOverviewSection(),
                ),
              ),

              // About section with amenities
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildAboutSection(),
                ),
              ),

              // Bottom padding
              SliverToBoxAdapter(
                child: SizedBox(height: bottomPadding + 100),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final court = widget.court;
    final rating = _dummyRating;
    final reviewCount = _dummyReviewCount;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name and info (flexible, won't overlap buttons)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              Text(
                court.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Rating and info row
              Row(
                children: [
                  // Rating
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green[700],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          rating.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.star, color: Colors.white, size: 12),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '($reviewCount)',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '• Badminton',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Price and status
              Row(
                children: [
                  Text(
                    _dummyPriceRange,
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '•',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isCurrentlyOpen() ? 'Open' : 'Closed',
                    style: TextStyle(
                      color:
                          _isCurrentlyOpen() ? Colors.green[700] : Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Circular buttons (bookmark and close)
        Row(
          children: [
            // Bookmark button
            _CircularIconButton(
              icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              onTap: () {
                setState(() {
                  _isBookmarked = !_isBookmarked;
                });
              },
              isActive: _isBookmarked,
            ),
            const SizedBox(width: 8),
            // Close button
            _CircularIconButton(
              icon: Icons.close,
              onTap: _handleClose,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Book button (first)
          _HorizontalActionButton(
            icon: Icons.calendar_today,
            label: 'Book',
            isPrimary: true,
            backgroundColor: const Color(0xFFFF5722),
            onTap: widget.onBook,
          ),
          const SizedBox(width: 10),

          // Directions button
          _HorizontalActionButton(
            icon: Icons.directions,
            label: 'Directions',
            isPrimary: true,
            onTap: widget.onDirections,
          ),
          const SizedBox(width: 10),

          // Call button
          _HorizontalActionButton(
            icon: Icons.phone,
            label: 'Call',
            onTap: () => _makePhoneCall(),
          ),
          const SizedBox(width: 10),

          // Share button
          _HorizontalActionButton(
            icon: Icons.share,
            label: 'Share',
            onTap: () {},
          ),
          const SizedBox(width: 10),

          // Website button
          _HorizontalActionButton(
            icon: Icons.language,
            label: 'Website',
            onTap: () {},
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery() {
    return SizedBox(
      height: 180, // Larger height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _dummyPhotos.length + 1,
        itemBuilder: (context, index) {
          if (index == _dummyPhotos.length) {
            // "See all" button
            return Container(
              width: 120,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library, color: Colors.grey[600], size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'See all',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return Container(
            width: 220,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[300],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _dummyPhotos[index],
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) => Container(
                  color: Colors.grey[300],
                  child: Icon(
                    Icons.sports_tennis,
                    size: 48,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewSection() {
    final court = widget.court;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Address
        _OverviewRow(
          icon: Icons.location_on_outlined,
          text: court.fullAddress.isNotEmpty
              ? court.fullAddress
              : '${court.addressDistrict ?? 'Hanoi'}, Vietnam',
          isLink: true,
        ),
        const SizedBox(height: 12),

        // Phone
        _OverviewRow(
          icon: Icons.phone_outlined,
          text: court.phoneNumbers.isNotEmpty
              ? court.phoneNumbers.first
              : '0123 456 789',
          isLink: true,
          onTap: () => _makePhoneCall(),
        ),
        const SizedBox(height: 12),

        // Website
        const _OverviewRow(
          icon: Icons.language,
          text: 'www.arcbadminton.vn',
          isLink: true,
        ),
        const SizedBox(height: 12),

        // Opening hours dropdown
        _buildOpeningHoursDropdown(),
      ],
    );
  }

  Widget _buildOpeningHoursDropdown() {
    final court = widget.court;
    final hours = court.openingHours;

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isHoursExpanded = !_isHoursExpanded;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        _isCurrentlyOpen() ? 'Open' : 'Closed',
                        style: TextStyle(
                          color: _isCurrentlyOpen()
                              ? Colors.green[700]
                              : Colors.red,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _isCurrentlyOpen()
                            ? ' · Closes ${_getClosingTime()}'
                            : ' · Opens ${_getOpeningTime()}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isHoursExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),

        // Expanded hours list
        if (_isHoursExpanded) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                if (hours != null) ...[
                  _buildDayHoursRow('Monday', hours.mon ?? '06:00 - 22:00'),
                  _buildDayHoursRow('Tuesday', hours.tue ?? '06:00 - 22:00'),
                  _buildDayHoursRow('Wednesday', hours.wed ?? '06:00 - 22:00'),
                  _buildDayHoursRow('Thursday', hours.thu ?? '06:00 - 22:00'),
                  _buildDayHoursRow('Friday', hours.fri ?? '06:00 - 22:00'),
                  _buildDayHoursRow('Saturday', hours.sat ?? '07:00 - 21:00'),
                  _buildDayHoursRow('Sunday', hours.sun ?? '07:00 - 21:00'),
                ] else ...[
                  _buildDayHoursRow('Monday', '06:00 - 22:00'),
                  _buildDayHoursRow('Tuesday', '06:00 - 22:00'),
                  _buildDayHoursRow('Wednesday', '06:00 - 22:00'),
                  _buildDayHoursRow('Thursday', '06:00 - 22:00'),
                  _buildDayHoursRow('Friday', '06:00 - 22:00'),
                  _buildDayHoursRow('Saturday', '07:00 - 21:00'),
                  _buildDayHoursRow('Sunday', '07:00 - 21:00'),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDayHoursRow(String day, String hours) {
    final isToday = _isToday(day);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              day,
              style: TextStyle(
                color: isToday ? AppTheme.primaryColor : Colors.grey[700],
                fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              hours,
              style: TextStyle(
                color: isToday ? AppTheme.primaryColor : Colors.grey[600],
                fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    final court = widget.court;
    final amenities = court.details?.amenities ??
        ['Parking', 'Shower', 'Locker', 'WiFi', 'Cafe', 'Pro Shop'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        const Text(
          'About',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        // Description
        Text(
          court.description ??
              'Professional badminton court with high-quality facilities and equipment. Perfect for players of all skill levels.',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),

        // Amenities title
        const Text(
          'Amenities',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Amenities chips (selectable)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: amenities.map((amenity) {
            return _AmenityChip(
              icon: _getAmenityIcon(amenity),
              label: amenity,
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _getAmenityIcon(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'parking':
        return Icons.local_parking;
      case 'shower':
        return Icons.shower;
      case 'locker':
        return Icons.lock;
      case 'wifi':
        return Icons.wifi;
      case 'cafe':
        return Icons.coffee;
      case 'pro shop':
        return Icons.shopping_bag;
      case 'swimming pool':
        return Icons.pool;
      case 'gym':
        return Icons.fitness_center;
      default:
        return Icons.check_circle_outline;
    }
  }

  bool _isToday(String day) {
    final weekday = DateTime.now().weekday;
    final dayLower = day.toLowerCase();
    switch (weekday) {
      case 1:
        return dayLower.contains('monday');
      case 2:
        return dayLower.contains('tuesday');
      case 3:
        return dayLower.contains('wednesday');
      case 4:
        return dayLower.contains('thursday');
      case 5:
        return dayLower.contains('friday');
      case 6:
        return dayLower.contains('saturday');
      case 7:
        return dayLower.contains('sunday');
      default:
        return false;
    }
  }

  String _getClosingTime() {
    final court = widget.court;
    final hours = court.openingHours;
    if (hours?.todayHours != null) {
      final parts = hours!.todayHours!.split('-');
      if (parts.length == 2) {
        return parts[1].trim();
      }
    }
    return '22:00';
  }

  String _getOpeningTime() {
    final court = widget.court;
    final hours = court.openingHours;
    if (hours?.todayHours != null) {
      final parts = hours!.todayHours!.split('-');
      if (parts.isNotEmpty) {
        return parts[0].trim();
      }
    }
    return '06:00';
  }

  bool _isCurrentlyOpen() {
    final now = DateTime.now();
    final hour = now.hour;
    return hour >= 6 && hour < 22;
  }

  Future<void> _makePhoneCall() async {
    final phone = widget.court.phoneNumbers.isNotEmpty
        ? widget.court.phoneNumbers.first
        : '0123456789';
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

/// Circular icon button for header
class _CircularIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isActive;

  const _CircularIconButton({
    required this.icon,
    this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[100],
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: Icon(
            icon,
            size: 20,
            color: isActive ? AppTheme.primaryColor : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

/// Horizontal action button with icon and text on same line
class _HorizontalActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const _HorizontalActionButton({
    required this.icon,
    required this.label,
    this.isPrimary = false,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        backgroundColor ?? (isPrimary ? AppTheme.primaryColor : Colors.white);
    final fgColor = isPrimary || backgroundColor != null
        ? Colors.white
        : AppTheme.primaryColor;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(24),
      elevation: isPrimary || backgroundColor != null ? 0 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: isPrimary || backgroundColor != null
                ? null
                : Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: fgColor, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: fgColor,
                  fontSize: 14,
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

/// Overview row widget
class _OverviewRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isLink;
  final VoidCallback? onTap;

  const _OverviewRow({
    required this.icon,
    required this.text,
    this.isLink = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLink ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: isLink ? AppTheme.primaryColor : Colors.grey[700],
                  fontSize: 14,
                ),
              ),
            ),
            if (isLink)
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}

/// Amenity chip widget (selectable style)
class _AmenityChip extends StatefulWidget {
  final IconData icon;
  final String label;

  const _AmenityChip({
    required this.icon,
    required this.label,
  });

  @override
  State<_AmenityChip> createState() => _AmenityChipState();
}

class _AmenityChipState extends State<_AmenityChip> {
  bool _isSelected = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isSelected = !_isSelected;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
            width: _isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              size: 16,
              color: _isSelected ? AppTheme.primaryColor : Colors.grey[700],
            ),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: TextStyle(
                color: _isSelected ? AppTheme.primaryColor : Colors.grey[700],
                fontSize: 13,
                fontWeight: _isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
