import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:smatch_badminton/models/api_response.dart';
import 'package:smatch_badminton/models/court.dart';
import 'package:smatch_badminton/models/search_suggestion.dart';
import 'package:smatch_badminton/repositories/court_repository.dart';
import 'package:smatch_badminton/services/court_service.dart';
import 'package:smatch_badminton/view_models/search_view_model.dart';

import 'search_view_model_test.mocks.dart';

@GenerateMocks([CourtRepository, CourtService])
void main() {
  late MockCourtRepository mockCourtRepository;
  late MockCourtService mockCourtService;
  late SearchViewModel viewModel;

  setUp(() {
    mockCourtRepository = MockCourtRepository();
    mockCourtService = MockCourtService();
    viewModel = SearchViewModel(
      courtRepository: mockCourtRepository,
      courtService: mockCourtService,
    );
  });

  tearDown(() {
    viewModel.dispose();
  });

  group('SearchViewModel', () {
    group('initial state', () {
      test('should start with idle state', () {
        expect(viewModel.state, SearchState.idle);
        expect(viewModel.searchQuery, isEmpty);
        expect(viewModel.searchResults, isEmpty);
        expect(viewModel.autocompleteSuggestions, isEmpty);
        expect(viewModel.isLoadingAutocomplete, isFalse);
        expect(viewModel.errorMessage, isNull);
      });

      test('should have default categories', () {
        expect(viewModel.categories, isNotEmpty);
        expect(viewModel.selectedCategoryId, isNull);
      });
    });

    group('updateSearchQuery', () {
      test('should update search query', () {
        viewModel.updateSearchQuery('Ngọc Khánh');

        expect(viewModel.searchQuery, 'Ngọc Khánh');
      });

      test('should notify listeners on update', () {
        var notified = false;
        viewModel.addListener(() => notified = true);

        viewModel.updateSearchQuery('test');

        expect(notified, isTrue);
      });
    });

    group('clearSearch', () {
      test('should reset all search state', () {
        viewModel.updateSearchQuery('test');
        viewModel.clearSearch();

        expect(viewModel.searchQuery, isEmpty);
        expect(viewModel.searchResults, isEmpty);
        expect(viewModel.autocompleteSuggestions, isEmpty);
        expect(viewModel.isLoadingAutocomplete, isFalse);
        expect(viewModel.state, SearchState.idle);
      });
    });

    group('clearAutocompleteSuggestions', () {
      test('should clear only suggestions', () {
        viewModel.updateSearchQuery('test');
        viewModel.clearAutocompleteSuggestions();

        expect(viewModel.autocompleteSuggestions, isEmpty);
        expect(viewModel.searchQuery, 'test');
      });
    });

    group('searchAutocomplete', () {
      test('should clear suggestions for query less than 2 characters', () {
        viewModel.searchAutocomplete('a');

        expect(viewModel.autocompleteSuggestions, isEmpty);
        expect(viewModel.isLoadingAutocomplete, isFalse);
      });

      test('should set loading state for valid query', () {
        viewModel.searchAutocomplete('Ngọc');

        expect(viewModel.isLoadingAutocomplete, isTrue);
      });

      test('should debounce autocomplete requests', () {
        fakeAsync((async) {
          when(mockCourtService.getAutocomplete(
            query: anyNamed('query'),
            limit: anyNamed('limit'),
          )).thenAnswer((_) async => ApiResponse(
                success: true,
                data: [
                  const SearchSuggestion(
                    id: 'court-1',
                    text: 'Sân Cầu Lông Ngọc Khánh',
                    score: 100,
                  ),
                ],
              ));

          // Type rapidly
          viewModel.searchAutocomplete('N');
          viewModel.searchAutocomplete('Ng');
          viewModel.searchAutocomplete('Ngọ');
          viewModel.searchAutocomplete('Ngọc');

          // API shouldn't be called yet
          verifyNever(mockCourtService.getAutocomplete(
            query: anyNamed('query'),
            limit: anyNamed('limit'),
          ));

          // Wait for debounce
          async.elapse(const Duration(milliseconds: 250));

          // Only one call should be made
          verify(mockCourtService.getAutocomplete(
            query: 'Ngọc',
            limit: 10,
          )).called(1);
        });
      });

      test('should update suggestions after API response', () {
        fakeAsync((async) {
          when(mockCourtService.getAutocomplete(
            query: anyNamed('query'),
            limit: anyNamed('limit'),
          )).thenAnswer((_) async => ApiResponse(
                success: true,
                data: [
                  const SearchSuggestion(
                    id: 'court-1',
                    text: 'Result 1',
                    score: 100,
                  ),
                  const SearchSuggestion(
                    id: 'court-2',
                    text: 'Result 2',
                    score: 90,
                  ),
                ],
              ));

          viewModel.searchAutocomplete('test');

          // Wait for debounce
          async.elapse(const Duration(milliseconds: 250));

          expect(viewModel.autocompleteSuggestions.length, 2);
          expect(viewModel.autocompleteSuggestions[0].text, 'Result 1');
          expect(viewModel.isLoadingAutocomplete, isFalse);
        });
      });

      test('should handle API error gracefully', () {
        fakeAsync((async) {
          when(mockCourtService.getAutocomplete(
            query: anyNamed('query'),
            limit: anyNamed('limit'),
          )).thenThrow(Exception('Network error'));

          viewModel.searchAutocomplete('test');

          async.elapse(const Duration(milliseconds: 250));

          expect(viewModel.autocompleteSuggestions, isEmpty);
          expect(viewModel.isLoadingAutocomplete, isFalse);
        });
      });

      test('should handle unsuccessful API response', () {
        fakeAsync((async) {
          when(mockCourtService.getAutocomplete(
            query: anyNamed('query'),
            limit: anyNamed('limit'),
          )).thenAnswer((_) async => const ApiResponse(
                success: false,
                data: null,
              ));

          viewModel.searchAutocomplete('test');

          async.elapse(const Duration(milliseconds: 250));

          expect(viewModel.autocompleteSuggestions, isEmpty);
        });
      });
    });

    group('selectCategory', () {
      test('should select category', () {
        viewModel.selectCategory('badminton');

        expect(viewModel.selectedCategoryId, 'badminton');
        expect(viewModel.isCategorySelected('badminton'), isTrue);
      });

      test('should deselect category when selecting again', () {
        viewModel.selectCategory('badminton');
        viewModel.selectCategory('badminton');

        expect(viewModel.selectedCategoryId, isNull);
        expect(viewModel.isCategorySelected('badminton'), isFalse);
      });

      test('should update categories list with selection state', () {
        viewModel.selectCategory('badminton');

        final selected = viewModel.categories.where((c) => c.isSelected);
        expect(selected.length, 1);
        expect(selected.first.id, 'badminton');
      });

      test('should switch selection between categories', () {
        viewModel.selectCategory('badminton');
        viewModel.selectCategory('restaurants');

        expect(viewModel.selectedCategoryId, 'restaurants');
        expect(viewModel.isCategorySelected('badminton'), isFalse);
        expect(viewModel.isCategorySelected('restaurants'), isTrue);
      });
    });

    group('search', () {
      test('should return idle state for empty query', () async {
        viewModel.updateSearchQuery('');
        await viewModel.search();

        expect(viewModel.state, SearchState.idle);
        expect(viewModel.searchResults, isEmpty);
      });

      test('should set searching state during search', () async {
        when(mockCourtRepository.fetchCourts())
            .thenAnswer((_) async => []);

        viewModel.updateSearchQuery('test');

        final searchFuture = viewModel.search();

        expect(viewModel.state, SearchState.searching);

        await searchFuture;
      });

      test('should filter courts by name', () async {
        when(mockCourtRepository.fetchCourts()).thenAnswer((_) async => [
              const Court(id: 'court-1', name: 'Sân Cầu Lông Ngọc Khánh'),
              const Court(id: 'court-2', name: 'Sân Cầu Lông Ba Đình'),
              const Court(id: 'court-3', name: 'Other Name'),
            ]);

        viewModel.updateSearchQuery('Ngọc');
        await viewModel.search();

        expect(viewModel.state, SearchState.results);
        expect(viewModel.searchResults.length, 1);
        expect(viewModel.searchResults[0].name, contains('Ngọc'));
      });

      test('should filter courts by district', () async {
        when(mockCourtRepository.fetchCourts()).thenAnswer((_) async => [
              const Court(id: 'court-1', name: 'Court 1', addressDistrict: 'Cầu Giấy'),
              const Court(id: 'court-2', name: 'Court 2', addressDistrict: 'Ba Đình'),
            ]);

        viewModel.updateSearchQuery('Cầu Giấy');
        await viewModel.search();

        expect(viewModel.searchResults.length, 1);
        expect(viewModel.searchResults[0].addressDistrict, 'Cầu Giấy');
      });

      test('should handle search error', () async {
        when(mockCourtRepository.fetchCourts())
            .thenThrow(Exception('Failed to fetch'));

        viewModel.updateSearchQuery('test');
        await viewModel.search();

        expect(viewModel.state, SearchState.error);
        expect(viewModel.errorMessage, contains('Search failed'));
      });
    });

    group('searchByDistrict', () {
      test('should search by district with force refresh', () async {
        when(mockCourtRepository.fetchCourts(
          district: anyNamed('district'),
          forceRefresh: anyNamed('forceRefresh'),
        )).thenAnswer((_) async => [
              const Court(id: 'court-1', name: 'Court 1', addressDistrict: 'Cầu Giấy'),
            ]);

        await viewModel.searchByDistrict('Cầu Giấy');

        expect(viewModel.state, SearchState.results);
        expect(viewModel.searchResults.length, 1);

        verify(mockCourtRepository.fetchCourts(
          district: 'Cầu Giấy',
          forceRefresh: true,
        )).called(1);
      });

      test('should handle searchByDistrict error', () async {
        when(mockCourtRepository.fetchCourts(
          district: anyNamed('district'),
          forceRefresh: anyNamed('forceRefresh'),
        )).thenThrow(Exception('Network error'));

        await viewModel.searchByDistrict('Cầu Giấy');

        expect(viewModel.state, SearchState.error);
        expect(viewModel.errorMessage, contains('Search failed'));
      });
    });
  });
}

