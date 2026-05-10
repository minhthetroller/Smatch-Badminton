import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/image_url_helper.dart';
import '../../models/match.dart';
import '../../view_models/match_view_model.dart';

/// Full-screen view for managing match join requests (host only)
class ManageMatchView extends StatefulWidget {
  final String matchId;

  const ManageMatchView({super.key, required this.matchId});

  @override
  State<ManageMatchView> createState() => _ManageMatchViewState();
}

class _ManageMatchViewState extends State<ManageMatchView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatchViewModel>().fetchJoinRequests(widget.matchId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Manage Match',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          isScrollable: false,
          tabAlignment: TabAlignment.fill,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Accepted'),
            Tab(text: 'Rejected'),
          ],
          onTap: (index) {
            _loadRequestsByTab(index);
          },
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestsList(null),
          _buildRequestsList(MatchPlayerStatus.pending),
          _buildRequestsList(MatchPlayerStatus.accepted),
          _buildRequestsList(MatchPlayerStatus.rejected),
        ],
      ),
    );
  }

  void _loadRequestsByTab(int tabIndex) {
    final matchVM = context.read<MatchViewModel>();
    MatchPlayerStatus? status;
    
    switch (tabIndex) {
      case 1:
        status = MatchPlayerStatus.pending;
        break;
      case 2:
        status = MatchPlayerStatus.accepted;
        break;
      case 3:
        status = MatchPlayerStatus.rejected;
        break;
      default:
        status = null;
    }
    
    matchVM.fetchJoinRequests(widget.matchId, refresh: true, status: status);
  }

  Widget _buildRequestsList(MatchPlayerStatus? filterStatus) {
    return Consumer<MatchViewModel>(
      builder: (context, matchVM, _) {
        if (matchVM.joinRequestsState == MatchState.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }

        if (matchVM.joinRequestsState == MatchState.error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
                const SizedBox(height: 16),
                Text(
                  matchVM.joinRequestsError ?? 'Failed to load requests',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => matchVM.fetchJoinRequests(widget.matchId, refresh: true, status: filterStatus),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final allRequests = matchVM.joinRequests;
        final filteredRequests = filterStatus == null
            ? allRequests
            : allRequests.where((r) => r.status == filterStatus).toList();

        if (filteredRequests.isEmpty) {
          return _buildEmptyState(filterStatus);
        }

        return RefreshIndicator(
          onRefresh: () => matchVM.fetchJoinRequests(widget.matchId, refresh: true, status: filterStatus),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredRequests.length,
            itemBuilder: (context, index) {
              return _buildRequestCard(filteredRequests[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(MatchPlayerStatus? filterStatus) {
    String message;
    IconData icon;
    Color color;

    switch (filterStatus) {
      case MatchPlayerStatus.pending:
        message = 'No pending requests';
        icon = Icons.check_circle_outline;
        color = Colors.green;
        break;
      case MatchPlayerStatus.accepted:
        message = 'No accepted players yet';
        icon = Icons.person_add_disabled;
        color = Colors.blue;
        break;
      case MatchPlayerStatus.rejected:
        message = 'No rejected requests';
        icon = Icons.block;
        color = Colors.red;
        break;
      default:
        message = 'No join requests yet';
        icon = Icons.people_outline;
        color = AppTheme.textSecondary;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Join requests will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(MatchPlayer player) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player info
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: player.user?.avatarUrl != null
                    ? NetworkImage(
                        ImageUrlHelper.transformImageUrl(player.user!.avatarUrl!),
                        headers: ImageUrlHelper.imageHeaders,
                      )
                    : null,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                child: player.user?.avatarUrl == null
                    ? Text(
                        player.user?.displayName?.isNotEmpty == true
                            ? player.user!.displayName![0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.user?.displayName ?? 'Unknown Player',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Requested ${_formatTimestamp(player.joinedAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(player.status),
            ],
          ),
          
          // Action buttons for pending requests
          if (player.status == MatchPlayerStatus.pending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleRequest(player, false),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleRequest(player, true),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(MatchPlayerStatus status) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case MatchPlayerStatus.pending:
        backgroundColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange;
        label = 'Pending';
        break;
      case MatchPlayerStatus.pendingPayment:
        backgroundColor = Colors.purple.withValues(alpha: 0.1);
        textColor = Colors.purple;
        label = 'Payment Pending';
        break;
      case MatchPlayerStatus.accepted:
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
        label = 'Accepted';
        break;
      case MatchPlayerStatus.rejected:
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red;
        label = 'Rejected';
        break;
      case MatchPlayerStatus.left:
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey;
        label = 'Left';
        break;
      case MatchPlayerStatus.expired:
        backgroundColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange;
        label = 'Expired';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Future<void> _handleRequest(MatchPlayer player, bool accept) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(accept ? 'Accept Player' : 'Reject Player'),
        content: Text(
          accept
              ? 'Accept ${player.user?.displayName ?? 'this player'} to join the match?'
              : 'Reject ${player.user?.displayName ?? 'this player'}\'s request to join?',
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

    if (confirmed != true || !mounted) return;

    final matchVM = context.read<MatchViewModel>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await matchVM.respondToJoinRequest(
        widget.matchId,
        player.id,
        accept: accept,
      );

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(accept ? 'Player accepted' : 'Player rejected'),
            backgroundColor: accept ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
