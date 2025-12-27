import 'package:flutter/foundation.dart';

import '../models/match.dart';
import '../repositories/match_repository.dart';

/// State for match operations
enum MatchState {
  initial,
  loading,
  loaded,
  error,
}

/// ViewModel for managing match state
class MatchViewModel extends ChangeNotifier {
  final MatchRepository _matchRepository;

  MatchViewModel({MatchRepository? matchRepository})
      : _matchRepository = matchRepository ?? MatchRepository();

  // Browse matches state
  MatchState _browseState = MatchState.initial;
  List<MatchWithDetails> _browseMatches = [];
  int _browsePage = 1;
  bool _hasMoreBrowseMatches = true;
  String? _browseError;

  // Filters for browsing
  SkillLevel? _skillLevelFilter;
  PlayerFormat? _playerFormatFilter;
  String? _dateFromFilter;
  String? _dateToFilter;

  // My matches state (hosted)
  MatchState _hostedState = MatchState.initial;
  List<MatchWithDetails> _hostedMatches = [];
  String? _hostedError;

  // Joined matches state
  MatchState _joinedState = MatchState.initial;
  List<MatchWithDetails> _joinedMatches = [];
  String? _joinedError;

  // Selected match state
  MatchWithDetails? _selectedMatch;
  MatchState _selectedMatchState = MatchState.initial;
  String? _selectedMatchError;

  // Operation states
  bool _isJoining = false;
  bool _isLeaving = false;
  bool _isCreating = false;
  bool _isRespondingToRequest = false;

  // Getters - Browse
  MatchState get browseState => _browseState;
  List<MatchWithDetails> get browseMatches => List.unmodifiable(_browseMatches);
  bool get hasMoreBrowseMatches => _hasMoreBrowseMatches;
  String? get browseError => _browseError;
  bool get isBrowseLoading => _browseState == MatchState.loading;

  // Getters - Filters
  SkillLevel? get skillLevelFilter => _skillLevelFilter;
  PlayerFormat? get playerFormatFilter => _playerFormatFilter;
  String? get dateFromFilter => _dateFromFilter;
  String? get dateToFilter => _dateToFilter;
  bool get hasActiveFilters =>
      _skillLevelFilter != null ||
      _playerFormatFilter != null ||
      _dateFromFilter != null ||
      _dateToFilter != null;

  // Getters - Hosted
  MatchState get hostedState => _hostedState;
  List<MatchWithDetails> get hostedMatches => List.unmodifiable(_hostedMatches);
  String? get hostedError => _hostedError;
  bool get isHostedLoading => _hostedState == MatchState.loading;

  // Getters - Joined
  MatchState get joinedState => _joinedState;
  List<MatchWithDetails> get joinedMatches => List.unmodifiable(_joinedMatches);
  String? get joinedError => _joinedError;
  bool get isJoinedLoading => _joinedState == MatchState.loading;

  // Getters - Selected Match
  MatchWithDetails? get selectedMatch => _selectedMatch;
  MatchState get selectedMatchState => _selectedMatchState;
  String? get selectedMatchError => _selectedMatchError;

  // Getters - Operations
  bool get isJoining => _isJoining;
  bool get isLeaving => _isLeaving;
  bool get isCreating => _isCreating;
  bool get isRespondingToRequest => _isRespondingToRequest;

  // ==================== Browse Matches ====================

  /// Fetch matches for browsing
  Future<void> fetchBrowseMatches({bool refresh = false}) async {
    if (_browseState == MatchState.loading) return;

    if (refresh) {
      _browsePage = 1;
      _hasMoreBrowseMatches = true;
    }

    if (!_hasMoreBrowseMatches && !refresh) return;

    _browseState = MatchState.loading;
    _browseError = null;
    notifyListeners();

    try {
      final matches = await _matchRepository.fetchMatches(
        page: _browsePage,
        limit: 10,
        skillLevel: _skillLevelFilter,
        playerFormat: _playerFormatFilter,
        dateFrom: _dateFromFilter,
        dateTo: _dateToFilter,
        status: MatchStatus.open, // Only show open matches in browse
        forceRefresh: refresh,
      );

      if (refresh) {
        _browseMatches = matches;
      } else {
        _browseMatches.addAll(matches);
      }

      _hasMoreBrowseMatches = matches.length >= 10;
      _browsePage++;
      _browseState = MatchState.loaded;
    } catch (e) {
      debugPrint('Failed to fetch browse matches: $e');
      _browseError = e.toString();
      _browseState = MatchState.error;
    }

    notifyListeners();
  }

  /// Load more browse matches
  Future<void> loadMoreBrowseMatches() async {
    if (_browseState == MatchState.loading || !_hasMoreBrowseMatches) return;
    await fetchBrowseMatches();
  }

  /// Refresh browse matches
  Future<void> refreshBrowseMatches() async {
    await fetchBrowseMatches(refresh: true);
  }

  /// Set skill level filter
  void setSkillLevelFilter(SkillLevel? skillLevel) {
    if (_skillLevelFilter == skillLevel) return;
    _skillLevelFilter = skillLevel;
    notifyListeners();
  }

  /// Set player format filter
  void setPlayerFormatFilter(PlayerFormat? format) {
    if (_playerFormatFilter == format) return;
    _playerFormatFilter = format;
    notifyListeners();
  }

  /// Set date range filter
  void setDateRangeFilter(String? dateFrom, String? dateTo) {
    _dateFromFilter = dateFrom;
    _dateToFilter = dateTo;
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _skillLevelFilter = null;
    _playerFormatFilter = null;
    _dateFromFilter = null;
    _dateToFilter = null;
    notifyListeners();
  }

  /// Apply filters and refresh matches
  Future<void> applyFiltersAndRefresh() async {
    await fetchBrowseMatches(refresh: true);
  }

  // ==================== My Matches (Hosted) ====================

  /// Fetch hosted matches
  Future<void> fetchHostedMatches({bool refresh = false}) async {
    if (_hostedState == MatchState.loading && !refresh) return;

    _hostedState = MatchState.loading;
    _hostedError = null;
    notifyListeners();

    try {
      _hostedMatches = await _matchRepository.fetchHostedMatches(
        forceRefresh: refresh,
      );
      _hostedState = MatchState.loaded;
    } catch (e) {
      debugPrint('Failed to fetch hosted matches: $e');
      _hostedError = e.toString();
      _hostedState = MatchState.error;
    }

    notifyListeners();
  }

  /// Refresh hosted matches
  Future<void> refreshHostedMatches() async {
    await fetchHostedMatches(refresh: true);
  }

  // ==================== Joined Matches ====================

  /// Fetch joined matches
  Future<void> fetchJoinedMatches({bool refresh = false}) async {
    if (_joinedState == MatchState.loading && !refresh) return;

    _joinedState = MatchState.loading;
    _joinedError = null;
    notifyListeners();

    try {
      _joinedMatches = await _matchRepository.fetchJoinedMatches(
        forceRefresh: refresh,
      );
      _joinedState = MatchState.loaded;
    } catch (e) {
      debugPrint('Failed to fetch joined matches: $e');
      _joinedError = e.toString();
      _joinedState = MatchState.error;
    }

    notifyListeners();
  }

  /// Refresh joined matches
  Future<void> refreshJoinedMatches() async {
    await fetchJoinedMatches(refresh: true);
  }

  // ==================== Selected Match ====================

  /// Fetch match by ID
  Future<void> fetchMatchById(String id, {bool refresh = false}) async {
    _selectedMatchState = MatchState.loading;
    _selectedMatchError = null;
    notifyListeners();

    try {
      _selectedMatch = await _matchRepository.fetchMatchById(id);
      _selectedMatchState = MatchState.loaded;
    } catch (e) {
      debugPrint('Failed to fetch match: $e');
      _selectedMatchError = e.toString();
      _selectedMatchState = MatchState.error;
    }

    notifyListeners();
  }

  /// Clear selected match
  void clearSelectedMatch() {
    _selectedMatch = null;
    _selectedMatchState = MatchState.initial;
    _selectedMatchError = null;
    notifyListeners();
  }

  // ==================== Match Operations ====================

  /// Create a new match
  Future<MatchWithDetails?> createMatch(CreateMatchRequest request) async {
    _isCreating = true;
    notifyListeners();

    try {
      final match = await _matchRepository.createMatch(request);
      // Don't insert here - fetchHostedMatches will get it and prevents duplicates
      _isCreating = false;
      notifyListeners();
      return match;
    } catch (e) {
      debugPrint('Failed to create match: $e');
      _isCreating = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Join a match
  Future<bool> joinMatch(String matchId, {String? message}) async {
    _isJoining = true;
    notifyListeners();

    try {
      await _matchRepository.joinMatch(matchId, message: message);
      
      // Refresh the selected match if it's the one being joined
      if (_selectedMatch?.id == matchId) {
        await fetchMatchById(matchId, refresh: true);
      }
      
      // Add to joined matches list
      await fetchJoinedMatches(refresh: true);
      
      _isJoining = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to join match: $e');
      _isJoining = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Leave a match
  Future<bool> leaveMatch(String matchId) async {
    _isLeaving = true;
    notifyListeners();

    try {
      await _matchRepository.leaveMatch(matchId);
      
      // Remove from joined matches list
      _joinedMatches.removeWhere((m) => m.id == matchId);
      
      // Refresh the selected match if it's the one being left
      if (_selectedMatch?.id == matchId) {
        await fetchMatchById(matchId, refresh: true);
      }
      
      _isLeaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to leave match: $e');
      _isLeaving = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Cancel a match (host only)
  Future<bool> cancelMatch(String matchId) async {
    try {
      await _matchRepository.cancelMatch(matchId);
      
      // Remove from hosted matches list
      _hostedMatches.removeWhere((m) => m.id == matchId);
      
      // Clear selected match if it's the one being cancelled
      if (_selectedMatch?.id == matchId) {
        clearSelectedMatch();
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to cancel match: $e');
      rethrow;
    }
  }

  /// Respond to a join request (accept/reject)
  Future<bool> respondToJoinRequest(
    String matchId,
    String playerId, {
    required bool accept,
  }) async {
    _isRespondingToRequest = true;
    notifyListeners();

    try {
      await _matchRepository.respondToJoinRequest(
        matchId,
        playerId,
        accept: accept,
      );
      
      // Refresh the match to get updated player list
      if (_selectedMatch?.id == matchId) {
        await fetchMatchById(matchId, refresh: true);
      }
      
      // Refresh hosted matches
      await fetchHostedMatches(refresh: true);
      
      _isRespondingToRequest = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to respond to join request: $e');
      _isRespondingToRequest = false;
      notifyListeners();
      rethrow;
    }
  }

  // ==================== Utility Methods ====================

  /// Check if user is the host of a match
  bool isHostOfMatch(String matchId, String userId) {
    final match = _hostedMatches.firstWhere(
      (m) => m.id == matchId,
      orElse: () => _browseMatches.firstWhere(
        (m) => m.id == matchId,
        orElse: () => _selectedMatch ?? _browseMatches.first,
      ),
    );
    return match.hostUserId == userId;
  }

  /// Check if user has joined a match
  bool hasJoinedMatch(String matchId, String userId) {
    // Check if user is in joined matches list
    if (_joinedMatches.any((m) => m.id == matchId)) {
      return true;
    }
    
    // Check in selected match players
    if (_selectedMatch?.id == matchId) {
      return _selectedMatch!.players.any(
        (p) => p.userId == userId && p.status != MatchPlayerStatus.rejected,
      );
    }
    
    return false;
  }

  /// Get user's join status for a match
  MatchPlayerStatus? getUserJoinStatus(String matchId, String userId) {
    // Check selected match first
    if (_selectedMatch?.id == matchId) {
      final player = _selectedMatch!.players.where((p) => p.userId == userId).firstOrNull;
      return player?.status;
    }
    
    // Check joined matches
    final joinedMatch = _joinedMatches.where((m) => m.id == matchId).firstOrNull;
    if (joinedMatch != null) {
      final player = joinedMatch.players.where((p) => p.userId == userId).firstOrNull;
      return player?.status;
    }
    
    return null;
  }

  /// Clear all match caches
  void clearCache() {
    _matchRepository.clearCache();
    _browseMatches.clear();
    _hostedMatches.clear();
    _joinedMatches.clear();
    _browsePage = 1;
    _hasMoreBrowseMatches = true;
    _browseState = MatchState.initial;
    _hostedState = MatchState.initial;
    _joinedState = MatchState.initial;
    clearSelectedMatch();
    notifyListeners();
  }
}
