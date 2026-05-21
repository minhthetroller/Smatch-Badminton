import '../models/match.dart';
import '../services/match_service.dart';
import 'dart:io';

/// Repository for match data operations
/// Acts as a single source of truth, abstracting data sources
class MatchRepository {
  final MatchService _matchService;

  // In-memory cache
  List<MatchWithDetails> _cachedMatches = [];
  List<MatchWithDetails> _cachedHostedMatches = [];
  List<MatchWithDetails> _cachedJoinedMatches = [];

  MatchRepository({MatchService? matchService})
      : _matchService = matchService ?? MatchService();

  /// Get cached browse matches
  List<MatchWithDetails> get cachedMatches => List.unmodifiable(_cachedMatches);

  /// Get cached hosted matches
  List<MatchWithDetails> get cachedHostedMatches =>
      List.unmodifiable(_cachedHostedMatches);

  /// Get cached joined matches
  List<MatchWithDetails> get cachedJoinedMatches =>
      List.unmodifiable(_cachedJoinedMatches);

  /// Fetch matches from API with pagination and filters
  Future<List<MatchWithDetails>> fetchMatches({
    int page = 1,
    int limit = 10,
    String? courtId,
    SkillLevel? skillLevel,
    PlayerFormat? playerFormat,
    MatchStatus? status,
    String? date,
    String? dateFrom,
    String? dateTo,
    bool forceRefresh = false,
  }) async {
    // Return cached data if available and not forcing refresh
    if (!forceRefresh && _cachedMatches.isNotEmpty && page == 1) {
      return _cachedMatches;
    }

    final response = await _matchService.getMatches(
      page: page,
      limit: limit,
      courtId: courtId,
      skillLevel: skillLevel,
      playerFormat: playerFormat,
      status: status,
      date: date,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );

    if (response.success && response.data != null) {
      if (page == 1) {
        _cachedMatches = response.data!;
      } else {
        _cachedMatches.addAll(response.data!);
      }
      return response.data!;
    }

    throw Exception(response.error?.message ?? 'Failed to fetch matches');
  }

  /// Fetch hosted matches for current user
  Future<List<MatchWithDetails>> fetchHostedMatches({
    MatchStatus? status,
    bool forceRefresh = false,
    bool includeExpired = false,
  }) async {
    if (!forceRefresh && _cachedHostedMatches.isNotEmpty) {
      return _cachedHostedMatches;
    }

    final response = await _matchService.getHostedMatches(
      status: status,
      includeExpired: includeExpired,
    );

    if (response.success && response.data != null) {
      _cachedHostedMatches = response.data!;
      return response.data!;
    }

    throw Exception(response.error?.message ?? 'Failed to fetch hosted matches');
  }

  /// Fetch joined matches for current user
  Future<List<MatchWithDetails>> fetchJoinedMatches({
    bool forceRefresh = false,
    bool includeExpired = false,
  }) async {
    if (!forceRefresh && _cachedJoinedMatches.isNotEmpty) {
      return _cachedJoinedMatches;
    }

    final response = await _matchService.getJoinedMatches(
      includeExpired: includeExpired,
    );

    if (response.success && response.data != null) {
      _cachedJoinedMatches = response.data!;
      return response.data!;
    }

    throw Exception(response.error?.message ?? 'Failed to fetch joined matches');
  }

  /// Fetch match by ID
  /// Note: forceRefresh should be true when you need currentUserStatus
  /// because cached matches from list endpoints don't include it
  Future<MatchWithDetails> fetchMatchById(String id, {bool forceRefresh = false}) async {
    // Skip cache when forceRefresh is true to get fresh currentUserStatus
    if (!forceRefresh) {
      // Check caches first
      final cachedMatch = _cachedMatches.where((m) => m.id == id).firstOrNull ??
          _cachedHostedMatches.where((m) => m.id == id).firstOrNull ??
          _cachedJoinedMatches.where((m) => m.id == id).firstOrNull;

      // Only use cached match if it has currentUserStatus populated
      // or if the user is the host (doesn't need currentUserStatus)
      if (cachedMatch != null && cachedMatch.currentUserStatus != null) {
        return cachedMatch;
      }
    }

    final response = await _matchService.getMatchById(id);

    if (response.success && response.data != null) {
      return response.data!;
    }

    throw Exception(response.error?.message ?? 'Match not found');
  }

  /// Create a new match
  Future<MatchWithDetails> createMatch(CreateMatchRequest request) async {
    final response = await _matchService.createMatch(request);

    if (response.success && response.data != null) {
      // Add to hosted matches cache
      _cachedHostedMatches.insert(0, response.data!);
      return response.data!;
    }

    throw Exception(response.error?.message ?? 'Failed to create match');
  }

  /// Create a new match with images (multipart upload)
  Future<MatchWithDetails> createMatchWithImages(
    CreateMatchRequest request,
    List<File> images,
  ) async {
    final response = await _matchService.createMatchWithImages(request, images);

    if (response.success && response.data != null) {
      // Add to hosted matches cache
      _cachedHostedMatches.insert(0, response.data!);
      return response.data!;
    }

    throw Exception(response.error?.message ?? 'Failed to create match');
  }

  /// Update a match
  Future<MatchWithDetails> updateMatch(
    String id,
    UpdateMatchRequest request,
  ) async {
    final response = await _matchService.updateMatch(id, request);

    if (response.success && response.data != null) {
      // Update in caches
      _updateMatchInCaches(response.data!);
      return response.data!;
    }

    throw Exception(response.error?.message ?? 'Failed to update match');
  }

  /// Cancel a match
  Future<void> cancelMatch(String id) async {
    final response = await _matchService.cancelMatch(id);

    if (response.success) {
      // Remove from caches
      _cachedMatches.removeWhere((m) => m.id == id);
      _cachedHostedMatches.removeWhere((m) => m.id == id);
      return;
    }

    throw Exception(response.error?.message ?? 'Failed to cancel match');
  }

  /// Join a match
  Future<MatchPlayer> joinMatch(String matchId, {String? message}) async {
    final response = await _matchService.joinMatch(
      matchId,
      request: message != null ? JoinMatchRequest(message: message) : null,
    );

    if (response.success && response.data != null) {
      // Refresh match details
      try {
        final updatedMatch = await fetchMatchById(matchId);
        _updateMatchInCaches(updatedMatch);
        // Add to joined matches cache
        if (!_cachedJoinedMatches.any((m) => m.id == matchId)) {
          _cachedJoinedMatches.insert(0, updatedMatch);
        }
      } catch (_) {
        // Ignore cache update errors
      }
      return response.data!;
    }

    throw Exception(response.error?.message ?? 'Failed to join match');
  }

  /// Leave a match
  Future<void> leaveMatch(String matchId) async {
    final response = await _matchService.leaveMatch(matchId);

    if (response.success) {
      // Remove from joined matches cache
      _cachedJoinedMatches.removeWhere((m) => m.id == matchId);
      return;
    }

    throw Exception(response.error?.message ?? 'Failed to leave match');
  }

  /// Respond to a join request
  Future<MatchPlayer> respondToJoinRequest(
    String matchId,
    String playerId, {
    required bool accept,
  }) async {
    final response = await _matchService.respondToJoinRequest(
      matchId,
      playerId,
      RespondToJoinRequest(status: accept ? 'ACCEPTED' : 'REJECTED'),
    );

    if (response.success && response.data != null) {
      // Refresh match details
      try {
        final updatedMatch = await fetchMatchById(matchId);
        _updateMatchInCaches(updatedMatch);
      } catch (_) {
        // Ignore cache update errors
      }
      return response.data!;
    }

    throw Exception(
        response.error?.message ?? 'Failed to respond to join request');
  }

  /// Fetch join requests for a match (host only)
  Future<List<MatchPlayer>> fetchJoinRequests(
    String matchId, {
    MatchPlayerStatus? status,
  }) async {
    final response = await _matchService.getJoinRequests(
      matchId,
      status: status,
    );

    if (response.success && response.data != null) {
      return response.data!;
    }

    throw Exception(
        response.error?.message ?? 'Failed to fetch join requests');
  }

  /// Update match in all caches
  void _updateMatchInCaches(MatchWithDetails match) {
    final index = _cachedMatches.indexWhere((m) => m.id == match.id);
    if (index != -1) {
      _cachedMatches[index] = match;
    }

    final hostedIndex =
        _cachedHostedMatches.indexWhere((m) => m.id == match.id);
    if (hostedIndex != -1) {
      _cachedHostedMatches[hostedIndex] = match;
    }

    final joinedIndex =
        _cachedJoinedMatches.indexWhere((m) => m.id == match.id);
    if (joinedIndex != -1) {
      _cachedJoinedMatches[joinedIndex] = match;
    }
  }

  /// Clear all caches
  void clearCache() {
    _cachedMatches.clear();
    _cachedHostedMatches.clear();
    _cachedJoinedMatches.clear();
  }
}
