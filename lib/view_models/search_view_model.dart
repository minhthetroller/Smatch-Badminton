import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/category_item.dart';
import '../models/court.dart';
import '../models/search_suggestion.dart';
import '../repositories/court_repository.dart';
import '../services/court_service.dart';

/// Search state
enum SearchState { idle, searching, results, error }

/// ViewModel for search functionality
class SearchViewModel extends ChangeNotifier {
  final CourtRepository _courtRepository;
  final CourtService _courtService;

  /// Debounce timer for autocomplete
  Timer? _debounceTimer;

  /// Debounce duration (200ms as specified)
  static const Duration _debounceDuration = Duration(milliseconds: 200);

  SearchViewModel({CourtRepository? courtRepository, CourtService? courtService})
    : _courtRepository = courtRepository ?? CourtRepository(),
      _courtService = courtService ?? CourtService();

  // State
  SearchState _state = SearchState.idle;
  String _searchQuery = '';
  List<Court> _searchResults = [];
  List<SearchSuggestion> _autocompleteSuggestions = [];
  bool _isLoadingAutocomplete = false;
  String? _errorMessage;
  List<CategoryItem> _categories = CategoryItem.defaultCategories;
  String? _selectedCategoryId;

  // Getters
  SearchState get state => _state;
  String get searchQuery => _searchQuery;
  List<Court> get searchResults => _searchResults;
  List<SearchSuggestion> get autocompleteSuggestions => _autocompleteSuggestions;
  bool get isLoadingAutocomplete => _isLoadingAutocomplete;
  String? get errorMessage => _errorMessage;
  List<CategoryItem> get categories => _categories;
  String? get selectedCategoryId => _selectedCategoryId;

  /// Check if a category is selected
  bool isCategorySelected(String categoryId) {
    return _selectedCategoryId == categoryId;
  }

  /// Update search query
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Clear search
  void clearSearch() {
    _debounceTimer?.cancel();
    _searchQuery = '';
    _searchResults = [];
    _autocompleteSuggestions = [];
    _isLoadingAutocomplete = false;
    _state = SearchState.idle;
    notifyListeners();
  }

  /// Clear autocomplete suggestions
  void clearAutocompleteSuggestions() {
    _autocompleteSuggestions = [];
    notifyListeners();
  }

  /// Search autocomplete with debouncing (200ms)
  /// Supports both English and Vietnamese characters
  void searchAutocomplete(String query) {
    _searchQuery = query;

    // Cancel previous timer
    _debounceTimer?.cancel();

    // Clear suggestions if query is too short
    if (query.length < 2) {
      _autocompleteSuggestions = [];
      _isLoadingAutocomplete = false;
      notifyListeners();
      return;
    }

    // Set loading state
    _isLoadingAutocomplete = true;
    notifyListeners();

    // Start debounce timer
    _debounceTimer = Timer(_debounceDuration, () async {
      await _performAutocomplete(query);
    });
  }

  /// Perform the actual autocomplete API call
  Future<void> _performAutocomplete(String query) async {
    try {
      final response = await _courtService.getAutocomplete(
        query: query,
        limit: 10,
      );

      if (response.success && response.data != null) {
        _autocompleteSuggestions = response.data!;
      } else {
        _autocompleteSuggestions = [];
      }
    } catch (e) {
      debugPrint('Autocomplete error: $e');
      _autocompleteSuggestions = [];
    }

    _isLoadingAutocomplete = false;
    notifyListeners();
  }

  /// Select a category
  void selectCategory(String categoryId) {
    if (_selectedCategoryId == categoryId) {
      // Deselect if already selected
      _selectedCategoryId = null;
    } else {
      _selectedCategoryId = categoryId;
    }

    // Update categories list
    _categories = _categories.map((cat) {
      return cat.copyWith(isSelected: cat.id == _selectedCategoryId);
    }).toList();

    notifyListeners();
  }

  /// Search courts
  Future<void> search() async {
    if (_searchQuery.isEmpty) {
      _state = SearchState.idle;
      _searchResults = [];
      notifyListeners();
      return;
    }

    _state = SearchState.searching;
    _errorMessage = null;
    notifyListeners();

    try {
      // For now, filter from cached courts
      // In production, this would call a search API
      final allCourts = await _courtRepository.fetchCourts();

      _searchResults = allCourts.where((court) {
        final queryLower = _searchQuery.toLowerCase();
        return court.name.toLowerCase().contains(queryLower) ||
            (court.addressDistrict?.toLowerCase().contains(queryLower) ??
                false) ||
            (court.addressWard?.toLowerCase().contains(queryLower) ?? false) ||
            (court.addressStreet?.toLowerCase().contains(queryLower) ?? false);
      }).toList();

      _state = SearchState.results;
    } catch (e) {
      _state = SearchState.error;
      _errorMessage = 'Search failed: ${e.toString()}';
    }
    notifyListeners();
  }

  /// Search by district (from category or filter)
  Future<void> searchByDistrict(String district) async {
    _state = SearchState.searching;
    _errorMessage = null;
    notifyListeners();

    try {
      final courts = await _courtRepository.fetchCourts(
        district: district,
        forceRefresh: true,
      );
      _searchResults = courts;
      _state = SearchState.results;
    } catch (e) {
      _state = SearchState.error;
      _errorMessage = 'Search failed: ${e.toString()}';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _courtRepository.dispose();
    _courtService.dispose();
    super.dispose();
  }
}
