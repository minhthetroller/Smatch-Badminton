import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/image_url_helper.dart';
import '../../models/match.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/match_view_model.dart';
import 'match_payment_view.dart';
import 'manage_match_view.dart';

/// Full-screen match detail view with join button at bottom
class MatchDetailView extends StatefulWidget {
  final String matchId;

  const MatchDetailView({super.key, required this.matchId});

  @override
  State<MatchDetailView> createState() => _MatchDetailViewState();
}

class _MatchDetailViewState extends State<MatchDetailView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Always refresh to get currentUserStatus for authenticated users
      context.read<MatchViewModel>().fetchMatchById(widget.matchId, refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Consumer<MatchViewModel>(
        builder: (context, matchVM, _) {
          if (matchVM.selectedMatchState == MatchState.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          if (matchVM.selectedMatchState == MatchState.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
                  const SizedBox(height: 16),
                  Text(
                    matchVM.selectedMatchError ?? 'Failed to load match',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => matchVM.fetchMatchById(widget.matchId, refresh: true),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final match = matchVM.selectedMatch;
          if (match == null) {
            return const Center(child: Text('Match not found'));
          }

          return Stack(
            children: [
              SafeArea(
                child: RefreshIndicator(
                  onRefresh: () => matchVM.fetchMatchById(widget.matchId, refresh: true),
                  color: AppTheme.primaryColor,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Full-width image carousel at the top
                          _buildImageCarousel(match.images),
                        
                          // Match title below images
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              match.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMatchInfo(match),
                            const SizedBox(height: 24),
                            _buildPlayersSection(match),
                            const SizedBox(height: 80), // Space for bottom button
                          ],
                        ),
                      ),
                    ),
                  ],
                  ),
                ),
              ),
              // Back button overlay
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer2<MatchViewModel, AuthViewModel>(
        builder: (context, matchVM, authVM, _) {
          final match = matchVM.selectedMatch;
          if (match == null) return const SizedBox.shrink();

          return _buildBottomButton(context, match, matchVM, authVM);
        },
      ),
    );
  }

  Widget _buildDefaultBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColorDark,
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.sports_tennis, size: 80, color: Colors.white38),
      ),
    );
  }

  Widget _buildImageCarousel(List<String> images) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Show images if available, otherwise show default background
    if (images.isEmpty) {
      return SizedBox(
        width: screenWidth,
        height: screenWidth,
        child: _buildDefaultBackground(),
      );
    }

    return SizedBox(
      width: screenWidth,
      height: screenWidth,
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (context, index) {
          return CachedNetworkImage(
            imageUrl: ImageUrlHelper.transformImageUrl(images[index]),
            httpHeaders: ImageUrlHelper.imageHeaders,
            fit: BoxFit.cover,
            width: screenWidth,
            height: screenWidth,
            placeholder: (context, url) => Container(
              color: Colors.grey.shade200,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (context, url, error) => _buildDefaultBackground(),
          );
        },
      ),
    );
  }

  Widget _buildMatchInfo(MatchWithDetails match) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(
              icon: Icons.location_on,
              title: 'Court',
              value: match.court?.name ?? 'Unknown',
              subtitle: match.court?.addressFull,
            ),
            const Divider(height: 24),
            _InfoRow(
              icon: Icons.calendar_today,
              title: 'Date',
              value: _formatDate(match.date),
            ),
            const Divider(height: 24),
            _InfoRow(
              icon: Icons.access_time,
              title: 'Time',
              value: '${match.startTime} - ${match.endTime}',
            ),
            const Divider(height: 24),
            _InfoRow(
              icon: Icons.bar_chart,
              title: 'Skill Level',
              value: match.skillLevel.displayName,
            ),
            const Divider(height: 24),
            _InfoRow(
              icon: Icons.people,
              title: 'Format',
              value: match.playerFormat.displayName,
            ),
            const Divider(height: 24),
            _InfoRow(
              icon: Icons.sports,
              title: 'Shuttle',
              value: match.shuttleType.displayName,
            ),
            const Divider(height: 24),
            _InfoRow(
              icon: Icons.attach_money,
              title: 'Price per person',
              value: _formatPrice(match.price),
            ),
            if (match.description?.isNotEmpty == true) ...[
              const Divider(height: 24),
              const Text(
                'Description',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                match.description!,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlayersSection(MatchWithDetails match) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Players (${match.totalPlayersCount}/${match.slotsNeeded})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            if (match.remainingSlots > 0)
              Text(
                '${match.remainingSlots} slots left',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Host
        _buildPlayerTile(
          name: match.host?.displayName ?? 'Unknown',
          avatarUrl: match.host?.avatarUrl,
          badge: 'Host',
          badgeColor: AppTheme.primaryColor,
        ),

        // Accepted players
        ...match.acceptedPlayers.map((player) => _buildPlayerTile(
          name: player.user?.displayName ?? 'Unknown',
          avatarUrl: player.user?.avatarUrl,
        )),

        // Pending players (only visible to host)
        if (match.pendingPlayers.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Pending Requests',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ...match.pendingPlayers.map((player) => _buildPendingPlayerTile(
            context,
            match,
            player,
          )),
        ],
      ],
    );
  }

  Widget _buildPlayerTile({
    required String name,
    String? avatarUrl,
    String? badge,
    Color? badgeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: CircleAvatar(
          backgroundImage: avatarUrl != null ? NetworkImage(
            ImageUrlHelper.transformImageUrl(avatarUrl),
            headers: ImageUrlHelper.imageHeaders,
          ) : null,
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          child: avatarUrl == null
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: (badgeColor ?? AppTheme.primaryColor).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: badgeColor ?? AppTheme.primaryColor,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildPendingPlayerTile(
    BuildContext context,
    MatchWithDetails match,
    MatchPlayer player,
  ) {
    final authVM = context.read<AuthViewModel>();
    final matchVM = context.read<MatchViewModel>();
    final isHost = authVM.user?.id == match.hostUserId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        tileColor: Colors.orange.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: CircleAvatar(
          backgroundImage: player.user?.avatarUrl != null
              ? NetworkImage(
                  ImageUrlHelper.transformImageUrl(player.user!.avatarUrl!),
                  headers: ImageUrlHelper.imageHeaders,
                )
              : null,
          backgroundColor: Colors.orange.withValues(alpha: 0.1),
          child: player.user?.avatarUrl == null
              ? Text(
                  player.user?.displayName?.isNotEmpty == true
                      ? player.user!.displayName![0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          player.user?.displayName ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          'Pending',
          style: TextStyle(fontSize: 12, color: Colors.orange[700]),
        ),
        trailing: isHost
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: matchVM.isRespondingToRequest
                        ? null
                        : () => _respondToRequest(context, match.id, player.userId, true),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: matchVM.isRespondingToRequest
                        ? null
                        : () => _respondToRequest(context, match.id, player.userId, false),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildBottomButton(
    BuildContext context,
    MatchWithDetails match,
    MatchViewModel matchVM,
    AuthViewModel authVM,
  ) {
    final userId = authVM.user?.id;
    if (userId == null) return const SizedBox.shrink();

    final isHost = match.hostUserId == userId;
    
    // Use currentUserStatus from API response (available when authenticated)
    // This is more reliable than searching through players list
    final currentUserStatus = match.currentUserStatus;
    final hasJoined = currentUserStatus != null;
    final joinStatus = currentUserStatus?.status;
    
    // Debug: print current status for troubleshooting
    debugPrint('Match ${match.id} - currentUserStatus: ${currentUserStatus?.status.value}, hasJoined: $hasJoined, isHost: $isHost');
    
    // Check if user was rejected (blocked from retrying)
    final wasRejected = joinStatus == MatchPlayerStatus.rejected;

    Widget button;

    if (isHost) {
      // Show pending count badge if there are pending requests
      final pendingCount = match.pendingPlayers.length;
      button = _ActionButton(
        label: pendingCount > 0 ? 'Manage Match ($pendingCount pending)' : 'Manage Match',
        icon: pendingCount > 0 ? Icons.notification_important : Icons.settings,
        backgroundColor: pendingCount > 0 ? Colors.orange : AppTheme.primaryColor,
        onPressed: () => _navigateToManageMatch(context, match.id),
      );
    } else if (wasRejected) {
      // User was rejected - show disabled state, no retry allowed
      button = _ActionButton(
        label: 'Request Rejected',
        icon: Icons.block,
        backgroundColor: Colors.red.shade300,
        onPressed: null,
      );
    } else if (hasJoined) {
      // Switch statement ensures we handle all status cases explicitly
      switch (joinStatus) {
        case MatchPlayerStatus.pending:
          // Private match: waiting for host approval
          button = _ActionButton(
            label: 'Request Pending',
            icon: Icons.pending,
            backgroundColor: Colors.orange,
            onPressed: null,
          );
          break;
        case MatchPlayerStatus.pendingPayment:
          // Private match: host approved, now need to pay
          final priceText = match.price > 0 
              ? _formatPrice(match.price)
              : 'Free';
          button = _ActionButton(
            label: 'Pay Now • $priceText',
            icon: Icons.payment,
            backgroundColor: AppTheme.primaryColor,
            isLoading: matchVM.isJoining,
            onPressed: () => _navigateToPayment(context, match),
          );
          break;
        case MatchPlayerStatus.accepted:
          button = _ActionButton(
            label: 'Leave Match',
            icon: Icons.exit_to_app,
            backgroundColor: Colors.red,
            isLoading: matchVM.isLeaving,
            onPressed: () => _leaveMatch(context, match.id),
          );
          break;
        case MatchPlayerStatus.expired:
          // Payment expired - allow retry
          button = _ActionButton(
            label: 'Payment Expired • Retry',
            icon: Icons.refresh,
            backgroundColor: Colors.orange,
            isLoading: matchVM.isJoining,
            onPressed: () => _navigateToPayment(context, match),
          );
          break;
        case MatchPlayerStatus.rejected:
        case MatchPlayerStatus.left:
        case null:
          // Should not happen if hasJoined is true, but handle gracefully
          return const SizedBox.shrink();
      }
    } else if (match.isFull) {
      button = _ActionButton(
        label: 'Match Full',
        icon: Icons.block,
        backgroundColor: Colors.grey,
        onPressed: null,
      );
    } else if (match.status != MatchStatus.open) {
      button = _ActionButton(
        label: 'Match ${match.status.displayName}',
        icon: Icons.block,
        backgroundColor: Colors.grey,
        onPressed: null,
      );
    } else {
      // Determine join flow based on match type (public vs private)
      if (match.isPrivate) {
        // Private match: Request to join first, then host approves, then pay
        button = _ActionButton(
          label: 'Request to Join',
          icon: Icons.lock_outline,
          isLoading: matchVM.isJoining,
          onPressed: authVM.isAnonymous
              ? () => _showSignInRequired(context)
              : () => _requestToJoin(context, match),
        );
      } else {
        // Public match: Direct join (with payment if price > 0)
        final priceText = match.price > 0 
            ? _formatPrice(match.price)
            : 'Free';
        button = _ActionButton(
          label: 'Join Match • $priceText',
          icon: Icons.check_circle,
          isLoading: matchVM.isJoining,
          onPressed: authVM.isAnonymous
              ? () => _showSignInRequired(context)
              : () => _navigateToPayment(context, match),
        );
      }
    }

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: button,
    );
  }

  /// Navigate to manage match screen for hosts
  void _navigateToManageMatch(BuildContext context, String matchId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ManageMatchView(matchId: matchId),
      ),
    ).then((_) {
      // Refresh match details when returning
      if (context.mounted) {
        context.read<MatchViewModel>().fetchMatchById(widget.matchId, refresh: true);
      }
    });
  }

  /// Navigate to payment screen for joining the match
  void _navigateToPayment(BuildContext context, MatchWithDetails match) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MatchPaymentView(match: match),
      ),
    ).then((result) {
      // If payment was successful, refresh match details
      if (result == true && context.mounted) {
        context.read<MatchViewModel>().fetchMatchById(widget.matchId, refresh: true);
      }
    });
  }

  /// Request to join a private match (creates PENDING status, waits for host approval)
  Future<void> _requestToJoin(BuildContext context, MatchWithDetails match) async {
    final matchVM = context.read<MatchViewModel>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      await matchVM.joinMatch(match.id);
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Join request sent! Waiting for host approval.'),
            backgroundColor: Colors.orange,
          ),
        );
        // Refresh to show updated status
        matchVM.fetchMatchById(widget.matchId, refresh: true);
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to send request: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _leaveMatch(BuildContext context, String matchId) async {
    final matchVM = context.read<MatchViewModel>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await matchVM.leaveMatch(matchId);
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Left the match'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to leave: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _respondToRequest(
    BuildContext context,
    String matchId,
    String playerId,
    bool accept,
  ) async {
    final matchVM = context.read<MatchViewModel>();
    final player = matchVM.selectedMatch?.players
        .firstWhere(
          (p) => p.userId == playerId,
          orElse: () => MatchPlayer(
            id: '',
            userId: playerId,
            matchId: matchId,
            status: MatchPlayerStatus.pending,
            joinedAt: DateTime.now(),
          ),
        );
    final playerName = player?.user?.displayName ?? 'this player';
    final matchPlayerId = player?.id ?? '';
    
    if (matchPlayerId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Player not found'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(accept ? 'Accept Player' : 'Reject Player'),
        content: Text(
          accept 
              ? 'Accept $playerName to join the match?'
              : 'Reject $playerName\'s request to join?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: accept ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(accept ? 'Accept' : 'Reject'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      await matchVM.respondToJoinRequest(matchId, matchPlayerId, accept: accept);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept ? 'Player accepted' : 'Player rejected'),
            backgroundColor: accept ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showSignInRequired(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Please sign in to join matches'),
        action: SnackBarAction(
          label: 'Sign In',
          onPressed: () {
            // TODO: Navigate to sign in
          },
        ),
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final parsed = DateTime.parse(date);
      return DateFormat('EEEE, MMMM d, y').format(parsed);
    } catch (_) {
      return date;
    }
  }

  String _formatPrice(int price) {
    if (price == 0) return 'Free';
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(price)}đ';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textHint,
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

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final bool isLoading;

  const _ActionButton({
    required this.label,
    required this.icon,
    this.onPressed,
    this.backgroundColor = AppTheme.primaryColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
