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
      context.read<MatchViewModel>().fetchJoinedMatches(refresh: true);
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
          if (matchVM.isJoinedLoading && matchVM.joinedMatches.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          if (matchVM.joinedState == MatchState.error &&
              matchVM.joinedMatches.isEmpty) {
            return _buildErrorState(
              matchVM.joinedError ?? 'Failed to load match history',
              () => matchVM.fetchJoinedMatches(refresh: true),
            );
          }

          if (matchVM.joinedMatches.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => matchVM.refreshJoinedMatches(),
            color: AppTheme.primaryColor,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: matchVM.joinedMatches.length,
              itemBuilder: (context, index) {
                final match = matchVM.joinedMatches[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MatchCard(
                    match: match,
                    onTap: () => _navigateToMatchDetail(match.id),
                  ),
                );
              },
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
              'Join a match to see it here',
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
