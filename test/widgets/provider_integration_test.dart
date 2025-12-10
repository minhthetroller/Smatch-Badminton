import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:smatch_badminton/models/api_response.dart';
import 'package:smatch_badminton/models/court.dart';
import 'package:smatch_badminton/models/search_suggestion.dart';
import 'package:smatch_badminton/repositories/court_repository.dart';
import 'package:smatch_badminton/services/court_service.dart';
import 'package:smatch_badminton/view_models/search_view_model.dart';

import 'provider_integration_test.mocks.dart';

@GenerateMocks([CourtRepository, CourtService])
void main() {
  late MockCourtRepository mockCourtRepository;
  late MockCourtService mockCourtService;

  setUp(() {
    mockCourtRepository = MockCourtRepository();
    mockCourtService = MockCourtService();
  });

  Widget createSearchTestWidget(Widget child) {
    return MaterialApp(
      home: ChangeNotifierProvider<SearchViewModel>(
        create: (_) => SearchViewModel(
          courtRepository: mockCourtRepository,
          courtService: mockCourtService,
        ),
        child: Scaffold(body: child),
      ),
    );
  }

  group('SearchViewModel Provider Integration', () {
    testWidgets('should update UI when search query changes', (tester) async {
      final widget = createSearchTestWidget(
        Consumer<SearchViewModel>(
          builder: (context, viewModel, _) {
            return Column(
              children: [
                TextField(
                  onChanged: viewModel.updateSearchQuery,
                  key: const Key('search_field'),
                ),
                Text('Query: ${viewModel.searchQuery}'),
              ],
            );
          },
        ),
      );

      await tester.pumpWidget(widget);

      // Initially empty
      expect(find.text('Query: '), findsOneWidget);

      // Enter text
      await tester.enterText(find.byKey(const Key('search_field')), 'Ngọc');
      await tester.pump();

      // Should update
      expect(find.text('Query: Ngọc'), findsOneWidget);
    });

    testWidgets('should show loading indicator during autocomplete', (tester) async {
      final widget = createSearchTestWidget(
        Consumer<SearchViewModel>(
          builder: (context, viewModel, _) {
            return Column(
              children: [
                TextField(
                  onChanged: (value) {
                    viewModel.searchAutocomplete(value);
                  },
                  key: const Key('search_field'),
                ),
                if (viewModel.isLoadingAutocomplete)
                  const CircularProgressIndicator(key: Key('loading')),
              ],
            );
          },
        ),
      );

      await tester.pumpWidget(widget);

      // Enter valid query (2+ chars)
      await tester.enterText(find.byKey(const Key('search_field')), 'Te');
      await tester.pump();

      // Should show loading
      expect(find.byKey(const Key('loading')), findsOneWidget);
    });

    testWidgets('should display autocomplete suggestions', (tester) async {
      when(mockCourtService.getAutocomplete(
        query: anyNamed('query'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => const ApiResponse(
            success: true,
            data: [
              SearchSuggestion(id: 'c1', text: 'Court 1', score: 100),
              SearchSuggestion(id: 'c2', text: 'Court 2', score: 90),
            ],
          ));

      final widget = createSearchTestWidget(
        Consumer<SearchViewModel>(
          builder: (context, viewModel, _) {
            return Column(
              children: [
                TextField(
                  onChanged: (value) {
                    viewModel.searchAutocomplete(value);
                  },
                  key: const Key('search_field'),
                ),
                ...viewModel.autocompleteSuggestions.map(
                  (s) => ListTile(key: Key(s.id), title: Text(s.text)),
                ),
              ],
            );
          },
        ),
      );

      await tester.pumpWidget(widget);

      // Enter query
      await tester.enterText(find.byKey(const Key('search_field')), 'Court');
      
      // Wait for debounce + API call
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Should display suggestions
      expect(find.byKey(const Key('c1')), findsOneWidget);
      expect(find.byKey(const Key('c2')), findsOneWidget);
    });

    testWidgets('should clear suggestions when clearAutocompleteSuggestions called', (tester) async {
      when(mockCourtService.getAutocomplete(
        query: anyNamed('query'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => const ApiResponse(
            success: true,
            data: [
              SearchSuggestion(id: 'c1', text: 'Court 1', score: 100),
            ],
          ));

      final widget = createSearchTestWidget(
        Consumer<SearchViewModel>(
          builder: (context, viewModel, _) {
            return Column(
              children: [
                TextField(
                  onChanged: (value) => viewModel.searchAutocomplete(value),
                  key: const Key('search_field'),
                ),
                ElevatedButton(
                  onPressed: viewModel.clearAutocompleteSuggestions,
                  child: const Text('Clear'),
                ),
                ...viewModel.autocompleteSuggestions.map(
                  (s) => ListTile(key: Key(s.id), title: Text(s.text)),
                ),
              ],
            );
          },
        ),
      );

      await tester.pumpWidget(widget);

      // Enter query and wait
      await tester.enterText(find.byKey(const Key('search_field')), 'Court');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Should have suggestions
      expect(find.byKey(const Key('c1')), findsOneWidget);

      // Clear suggestions
      await tester.tap(find.text('Clear'));
      await tester.pump();

      // Should be cleared
      expect(find.byKey(const Key('c1')), findsNothing);
    });

    testWidgets('should show search results after search', (tester) async {
      when(mockCourtRepository.fetchCourts()).thenAnswer((_) async => [
            const Court(id: 'court-1', name: 'Test Court 1'),
            const Court(id: 'court-2', name: 'Test Court 2'),
          ]);

      final widget = createSearchTestWidget(
        Consumer<SearchViewModel>(
          builder: (context, viewModel, _) {
            return Column(
              children: [
                TextField(
                  onChanged: viewModel.updateSearchQuery,
                  key: const Key('search_field'),
                ),
                ElevatedButton(
                  onPressed: viewModel.search,
                  child: const Text('Search'),
                ),
                if (viewModel.state == SearchState.searching)
                  const CircularProgressIndicator(key: Key('searching')),
                ...viewModel.searchResults.map(
                  (c) => ListTile(key: Key(c.id), title: Text(c.name)),
                ),
              ],
            );
          },
        ),
      );

      await tester.pumpWidget(widget);

      // Enter query
      await tester.enterText(find.byKey(const Key('search_field')), 'Test');
      await tester.pump();

      // Trigger search
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      // Should show results
      expect(find.byKey(const Key('court-1')), findsOneWidget);
      expect(find.byKey(const Key('court-2')), findsOneWidget);
    });

    testWidgets('should show error state on search failure', (tester) async {
      when(mockCourtRepository.fetchCourts())
          .thenThrow(Exception('Network error'));

      final widget = createSearchTestWidget(
        Consumer<SearchViewModel>(
          builder: (context, viewModel, _) {
            return Column(
              children: [
                TextField(
                  onChanged: viewModel.updateSearchQuery,
                  key: const Key('search_field'),
                ),
                ElevatedButton(
                  onPressed: viewModel.search,
                  child: const Text('Search'),
                ),
                if (viewModel.state == SearchState.error)
                  Text('Error: ${viewModel.errorMessage}', key: const Key('error')),
              ],
            );
          },
        ),
      );

      await tester.pumpWidget(widget);

      await tester.enterText(find.byKey(const Key('search_field')), 'Test');
      await tester.pump();

      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('error')), findsOneWidget);
      expect(find.textContaining('Search failed'), findsOneWidget);
    });

    testWidgets('should update category selection', (tester) async {
      final widget = createSearchTestWidget(
        Consumer<SearchViewModel>(
          builder: (context, viewModel, _) {
            return Column(
              children: [
                ...viewModel.categories.map((cat) => ElevatedButton(
                      key: Key(cat.id),
                      onPressed: () => viewModel.selectCategory(cat.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cat.isSelected ? Colors.blue : Colors.grey,
                      ),
                      child: Text(cat.label),
                    )),
                Text('Selected: ${viewModel.selectedCategoryId ?? 'none'}'),
              ],
            );
          },
        ),
      );

      await tester.pumpWidget(widget);

      // Initially no selection
      expect(find.text('Selected: none'), findsOneWidget);

      // Select badminton
      await tester.tap(find.byKey(const Key('badminton')));
      await tester.pump();

      expect(find.text('Selected: badminton'), findsOneWidget);

      // Tap again to deselect
      await tester.tap(find.byKey(const Key('badminton')));
      await tester.pump();

      expect(find.text('Selected: none'), findsOneWidget);
    });

    testWidgets('should clear all search state', (tester) async {
      when(mockCourtRepository.fetchCourts()).thenAnswer((_) async => [
            const Court(id: 'court-1', name: 'Test Court'),
          ]);

      final widget = createSearchTestWidget(
        Consumer<SearchViewModel>(
          builder: (context, viewModel, _) {
            return Column(
              children: [
                TextField(
                  onChanged: viewModel.updateSearchQuery,
                  key: const Key('search_field'),
                ),
                ElevatedButton(
                  onPressed: viewModel.search,
                  child: const Text('Search'),
                ),
                ElevatedButton(
                  onPressed: viewModel.clearSearch,
                  child: const Text('Clear'),
                ),
                Text('Query: ${viewModel.searchQuery}'),
                Text('Results: ${viewModel.searchResults.length}'),
              ],
            );
          },
        ),
      );

      await tester.pumpWidget(widget);

      // Enter query and search
      await tester.enterText(find.byKey(const Key('search_field')), 'Test');
      await tester.pump();
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      expect(find.text('Query: Test'), findsOneWidget);
      expect(find.text('Results: 1'), findsOneWidget);

      // Clear
      await tester.tap(find.text('Clear'));
      await tester.pump();

      expect(find.text('Query: '), findsOneWidget);
      expect(find.text('Results: 0'), findsOneWidget);
    });
  });
}

