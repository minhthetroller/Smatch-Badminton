import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/match.dart';

/// Card widget for displaying match information
class MatchCard extends StatelessWidget {
  final MatchWithDetails match;
  final VoidCallback? onTap;
  final bool isHosted;

  const MatchCard({
    super.key,
    required this.match,
    this.onTap,
    this.isHosted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Title + Status badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isHosted) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Host',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StatusBadge(status: match.status),
                ],
              ),

              const SizedBox(height: 12),

              // Court info
              if (match.court != null) ...[
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  text: match.court!.name,
                  secondaryText: match.court!.addressDistrict,
                ),
                const SizedBox(height: 8),
              ],

              // Date and time
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                text: _formatDate(match.date),
                secondaryText: '${match.startTime} - ${match.endTime}',
              ),

              const SizedBox(height: 12),

              // Tags row: Skill level, format, slots
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Tag(
                    icon: Icons.bar_chart,
                    label: match.skillLevel.displayName,
                    color: AppTheme.primaryColor,
                  ),
                  _Tag(
                    icon: Icons.people_outline,
                    label: match.playerFormat.displayName,
                    color: Colors.blue,
                  ),
                  _Tag(
                    icon: Icons.person_add_outlined,
                    label: '${match.acceptedPlayersCount}/${match.slotsNeeded}',
                    color: match.isFull ? Colors.orange : Colors.green,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Bottom row: Price + Host info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Price
                  Text(
                    _formatPrice(match.price),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),

                  // Host info
                  if (match.host != null && !isHosted)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                          backgroundImage: match.host!.avatarUrl != null
                              ? NetworkImage(match.host!.avatarUrl!)
                              : null,
                          child: match.host!.avatarUrl == null
                              ? Text(
                                  match.host!.displayName?.isNotEmpty == true
                                      ? match.host!.displayName![0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          match.host!.displayName ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),

                  // Pending requests indicator for hosted matches
                  if (isHosted && match.pendingPlayers.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.pending_actions,
                            size: 14,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${match.pendingPlayers.length} pending',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final parsed = DateTime.parse(date);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final parsedDate = DateTime(parsed.year, parsed.month, parsed.day);

      if (parsedDate == today) {
        return 'Today';
      } else if (parsedDate == tomorrow) {
        return 'Tomorrow';
      } else {
        return DateFormat('EEE, dd MMM').format(parsed);
      }
    } catch (_) {
      return date;
    }
  }

  String _formatPrice(int price) {
    if (price == 0) return 'Free';
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(price)}đ/person';
  }
}

/// Status badge widget
class _StatusBadge extends StatelessWidget {
  final MatchStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case MatchStatus.open:
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
        break;
      case MatchStatus.full:
        backgroundColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange;
        break;
      case MatchStatus.inProgress:
        backgroundColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
        break;
      case MatchStatus.completed:
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey;
        break;
      case MatchStatus.cancelled:
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

/// Info row widget
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? secondaryText;

  const _InfoRow({
    required this.icon,
    required this.text,
    this.secondaryText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (secondaryText != null) ...[
                const Text(
                  ' • ',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textHint,
                  ),
                ),
                Flexible(
                  child: Text(
                    secondaryText!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Tag widget
class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Tag({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
