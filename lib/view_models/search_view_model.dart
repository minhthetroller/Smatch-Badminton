import 'package:flutter/foundation.dart';

import '../models/category_item.dart';
import '../models/court.dart';
import '../repositories/court_repository.dart';

/// Search state
enum SearchState { idle, searching, results, error }

/// ViewModel for search functionality
class SearchViewModel extends ChangeNotifier {
  final CourtRepository _courtRepository;

  SearchViewModel({CourtRepository? courtRepository})
    : _courtRepository = courtRepository ?? CourtRepository();

  // State
  SearchState _state = SearchState.idle;
  String _searchQuery = '';
  List<Court> _searchResults = [];
  String? _errorMessage;
  List<CategoryItem> _categories = CategoryItem.defaultCategories;
  String? _selectedCategoryId;

  // Getters
  SearchState get state => _state;
  String get searchQuery => _searchQuery;
  List<Court> get searchResults => _searchResults;
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
    _searchQuery = '';
    _searchResults = [];
    _state = SearchState.idle;
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
    _courtRepository.dispose();
    super.dispose();
  }
}
