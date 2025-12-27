import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/match_view_model.dart';
import 'widgets/match_card.dart';
import 'create_match_view.dart';
import 'match_detail_view.dart';

/// Main screen for matches - Browse and My Matches tabs
class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initial data fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final matchVM = context.read<MatchViewModel>();
      matchVM.fetchBrowseMatches();
      matchVM.fetchHostedMatches();
      matchVM.fetchJoinedMatches();
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
          'Matches',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Browse'),
            Tab(text: 'My Matches'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _BrowseMatchesTab(),
          _MyMatchesTab(),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 10, // Account for bottom nav bar
        ),
        child: FloatingActionButton(
          onPressed: () => _navigateToCreateMatch(context),
          backgroundColor: AppTheme.primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _navigateToCreateMatch(BuildContext context) {
    final authVM = context.read<AuthViewModel>();
    
    // Check if user is authenticated and not anonymous
    if (authVM.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please sign in to create a match'),
          action: SnackBarAction(
            label: 'Sign In',
            onPressed: () {
              // TODO: Navigate to sign in
            },
          ),
        ),
      );
      return;
    }
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateMatchView(),
      ),
    ).then((result) {
      // If match was created successfully, switch to My Matches tab and refresh
      if (result != null) {
        _tabController.animateTo(1); // Switch to My Matches tab
        context.read<MatchViewModel>().fetchHostedMatches(refresh: true);
      }
    });
  }
}

/// Browse tab - shows all open matches
class _BrowseMatchesTab extends StatelessWidget {
  const _BrowseMatchesTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<MatchViewModel>(
      builder: (context, matchVM, _) {
        if (matchVM.isBrowseLoading && matchVM.browseMatches.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }

        if (matchVM.browseState == MatchState.error &&
            matchVM.browseMatches.isEmpty) {
          return _ErrorState(
            message: matchVM.browseError ?? 'Failed to load matches',
            onRetry: () => matchVM.fetchBrowseMatches(refresh: true),
          );
        }

        if (matchVM.browseMatches.isEmpty) {
          return const _EmptyState(
            icon: Icons.sports_tennis,
            title: 'No matches available',
            subtitle: 'Be the first to create a match!',
          );
        }

        return RefreshIndicator(
          onRefresh: () => matchVM.refreshBrowseMatches(),
          color: AppTheme.primaryColor,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollEndNotification &&
                  notification.metrics.extentAfter < 200) {
                matchVM.loadMoreBrowseMatches();
              }
              return false;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: matchVM.browseMatches.length +
                  (matchVM.hasMoreBrowseMatches ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= matchVM.browseMatches.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  );
                }

                final match = matchVM.browseMatches[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MatchCard(
                    match: match,
                    onTap: () => _navigateToMatchDetail(context, match.id),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _navigateToMatchDetail(BuildContext context, String matchId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MatchDetailView(matchId: matchId),
      ),
    );
  }
}

/// My Matches tab - shows hosted and joined matches
class _MyMatchesTab extends StatelessWidget {
  const _MyMatchesTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<MatchViewModel>(
      builder: (context, matchVM, _) {
        final isLoading =
            matchVM.isHostedLoading && matchVM.isJoinedLoading;
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
          return _ErrorState(
            message: matchVM.hostedError ??
                matchVM.joinedError ??
                'Failed to load matches',
            onRetry: () {
              matchVM.refreshHostedMatches();
              matchVM.refreshJoinedMatches();
            },
          );
        }

        if (isEmpty) {
          return const _EmptyState(
            icon: Icons.sports_tennis,
            title: 'No matches yet',
            subtitle: 'Create or join a match to see it here',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              matchVM.refreshHostedMatches(),
              matchVM.refreshJoinedMatches(),
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
                        onTap: () => _navigateToMatchDetail(context, match.id),
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
                        onTap: () => _navigateToMatchDetail(context, match.id),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToMatchDetail(BuildContext context, String matchId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MatchDetailView(matchId: matchId),
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

/// Empty state widget
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppTheme.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
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
}

/// Error state widget
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorState({
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
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
            if (onRetry != null) ...[
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
          ],
        ),
      ),
    );
  }
}
