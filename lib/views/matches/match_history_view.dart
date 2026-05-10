import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../view_models/match_view_model.dart';
import 'widgets/match_card.dart';
import 'match_detail_view.dart';

/// Match history view showing all joined matches
class MatchHistoryView extends StatefulWidget {
  const MatchHistoryView({super.key});

  @override
  State<MatchHistoryView> createState() => _MatchHistoryViewState();
}

class _MatchHistoryViewState extends State<MatchHistoryView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final matchVM = context.read<MatchViewModel>();
      // Fetch all matches including expired ones for full history
      matchVM.fetchJoinedMatches(refresh: true, includeExpired: true);
      matchVM.fetchHostedMatches(refresh: true, includeExpired: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Match History',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<MatchViewModel>(
        builder: (context, matchVM, _) {
          final isLoading = matchVM.isHostedLoading && matchVM.isJoinedLoading;
          final hasError = matchVM.hostedState == MatchState.error ||
              matchVM.joinedState == MatchState.error;
          final isEmpty =
              matchVM.hostedMatches.isEmpty && matchVM.joinedMatches.isEmpty;

          if (isLoading && isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          if (hasError && isEmpty) {
            return _buildErrorState(
              matchVM.hostedError ??
                  matchVM.joinedError ??
                  'Failed to load match history',
              () {
                matchVM.fetchJoinedMatches(refresh: true, includeExpired: true);
                matchVM.fetchHostedMatches(refresh: true, includeExpired: true);
              },
            );
          }

          if (isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                matchVM.fetchJoinedMatches(refresh: true, includeExpired: true),
                matchVM.fetchHostedMatches(refresh: true, includeExpired: true),
              ]);
            },
            color: AppTheme.primaryColor,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hosted Matches Section
                  if (matchVM.hostedMatches.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Hosted by me',
                      count: matchVM.hostedMatches.length,
                    ),
                    const SizedBox(height: 12),
                    ...matchVM.hostedMatches.map(
                      (match) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MatchCard(
                          match: match,
                          isHosted: true,
                          onTap: () => _navigateToMatchDetail(match.id),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Joined Matches Section
                  if (matchVM.joinedMatches.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Joined',
                      count: matchVM.joinedMatches.length,
                    ),
                    const SizedBox(height: 12),
                    ...matchVM.joinedMatches.map(
                      (match) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MatchCard(
                          match: match,
                          onTap: () => _navigateToMatchDetail(match.id),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigateToMatchDetail(String matchId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MatchDetailView(matchId: matchId),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sports_tennis,
              size: 80,
              color: AppTheme.textHint.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'No matches yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Join or create a match to see it here',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textHint,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section header widget
class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
