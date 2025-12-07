import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:smatch_badminton/models/court.dart';
import 'package:smatch_badminton/services/api_service.dart';
import 'package:smatch_badminton/services/court_service.dart';

import 'court_service_test.mocks.dart';

@GenerateMocks([ApiService])
void main() {
  late MockApiService mockApiService;
  late CourtService courtService;

  setUp(() {
    mockApiService = MockApiService();
    courtService = CourtService(apiService: mockApiService);
  });

  tearDown(() {
    courtService.dispose();
  });

  group('CourtService', () {
    group('getCourts', () {
      test('should fetch courts with default pagination', () async {
        when(mockApiService.get(
          any,
          queryParams: anyNamed('queryParams'),
        )).thenAnswer((_) async => {
              'success': true,
              'data': [
                {'id': 'court-1', 'name': 'Court 1'},
                {'id': 'court-2', 'name': 'Court 2'},
              ],
              'meta': {
                'pagination': {
                  'page': 1,
                  'limit': 10,
                  'total': 2,
                  'totalPages': 1,
                  'hasNext': false,
                  'hasPrev': false,
                }
              },
            });

        final response = await courtService.getCourts();

        expect(response.success, isTrue);
        expect(response.data, isNotNull);
        expect(response.data!.length, 2);
        expect(response.data![0].name, 'Court 1');
        expect(response.data![1].name, 'Court 2');

        verify(mockApiService.get(
          '/api/courts',
          queryParams: {'page': '1', 'limit': '10'},
        )).called(1);
      });

      test('should fetch courts with custom pagination', () async {
        when(mockApiService.get(
          any,
          queryParams: anyNamed('queryParams'),
        )).thenAnswer((_) async => {
              'success': true,
              'data': [],
            });

        await courtService.getCourts(page: 3, limit: 20);

        verify(mockApiService.get(
          '/api/courts',
          queryParams: {'page': '3', 'limit': '20'},
        )).called(1);
      });

      test('should filter by district when provided', () async {
        when(mockApiService.get(
          any,
          queryParams: anyNamed('queryParams'),
        )).thenAnswer((_) async => {
              'success': true,
              'data': [
                {'id': 'court-1', 'name': 'Cầu Giấy Court', 'addressDistrict': 'Cầu Giấy'},
              ],
            });

        await courtService.getCourts(district: 'Cầu Giấy');

        verify(mockApiService.get(
          '/api/courts',
          queryParams: {'page': '1', 'limit': '10', 'district': 'Cầu Giấy'},
        )).called(1);
      });

      test('should not include empty district in query params', () async {
        when(mockApiService.get(
          any,
          queryParams: anyNamed('queryParams'),
        )).thenAnswer((_) async => {'success': true, 'data': []});

        await courtService.getCourts(district: '');

        verify(mockApiService.get(
          '/api/courts',
          queryParams: {'page': '1', 'limit': '10'},
        )).called(1);
      });

      test('should return empty list when no data', () async {
        when(mockApiService.get(
          any,
          queryParams: anyNamed('queryParams'),
        )).thenAnswer((_) async => {'success': true, 'data': []});

        final response = await courtService.getCourts();

        expect(response.success, isTrue);
        expect(response.data, isEmpty);
      });
    });

    group('getCourtById', () {
      test('should fetch court by ID', () async {
        when(mockApiService.get(any)).thenAnswer((_) async => {
              'success': true,
              'data': {
                'id': 'court-123',
                'name': 'Sân Cầu Lông Ngọc Khánh',
                'description': 'Premium badminton court',
                'phoneNumbers': ['0912345678'],
                'addressStreet': '123 Ngọc Khánh',
                'addressDistrict': 'Ba Đình',
                'addressCity': 'Hà Nội',
              },
            });

        final response = await courtService.getCourtById('court-123');

        expect(response.success, isTrue);
        expect(response.data, isNotNull);
        expect(response.data!.id, 'court-123');
        expect(response.data!.name, 'Sân Cầu Lông Ngọc Khánh');
        expect(response.data!.addressDistrict, 'Ba Đình');

        verify(mockApiService.get('/api/courts/court-123')).called(1);
      });

      test('should handle court not found', () async {
        when(mockApiService.get(any))
            .thenThrow(ApiException('Court not found', statusCode: 404));

        expect(
          () => courtService.getCourtById('invalid-id'),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('getNearbyCourts', () {
      test('should fetch nearby courts with location parameters', () async {
        when(mockApiService.get(
          any,
          queryParams: anyNamed('queryParams'),
        )).thenAnswer((_) async => {
              'success': true,
              'data': [
                {
                  'id': 'court-1',
                  'name': 'Nearby Court',
                  'distance': 500.0,
                },
              ],
            });

        final response = await courtService.getNearbyCourts(
          latitude: 21.0285,
          longitude: 105.8542,
        );

        expect(response.success, isTrue);
        expect(response.data!.length, 1);
        expect(response.data![0].distance, 500.0);

        verify(mockApiService.get(
          '/api/courts/nearby',
          queryParams: {
            'latitude': '21.0285',
            'longitude': '105.8542',
            'radius': '5.0',
          },
        )).called(1);
      });

      test('should use custom radius when provided', () async {
        when(mockApiService.get(
          any,
          queryParams: anyNamed('queryParams'),
        )).thenAnswer((_) async => {'success': true, 'data': []});

        await courtService.getNearbyCourts(
          latitude: 21.0285,
          longitude: 105.8542,
          radius: 10,
        );

        verify(mockApiService.get(
          '/api/courts/nearby',
          queryParams: {
            'latitude': '21.0285',
            'longitude': '105.8542',
            'radius': '10.0',
          },
        )).called(1);
      });

      test('should return courts sorted by distance', () async {
        when(mockApiService.get(
          any,
          queryParams: anyNamed('queryParams'),
        )).thenAnswer((_) async => {
              'success': true,
              'data': [
                {'id': 'court-1', 'name': 'Court 1', 'distance': 200.0},
                {'id': 'court-2', 'name': 'Court 2', 'distance': 1500.0},
                {'id': 'court-3', 'name': 'Court 3', 'distance': 800.0},
              ],
            });

        final response = await courtService.getNearbyCourts(
          latitude: 21.0,
          longitude: 105.0,
        );

        expect(response.data!.length, 3);
        expect(response.data![0].distance, 200.0);
      });
    });

    group('getCourtAvailability', () {
      test('should fetch availability for court on specific date', () async {
        when(mockApiService.get(
          any,
          queryParams: anyNamed('queryParams'),
        )).thenAnswer((_) async => {
              'success': true,
              'data': {
                'courtId': 'court-123',
                'date': '2024-01-20',
                'openTime': '07:00',
                'closeTime': '22:00',
                'subCourts': [
                  {
                    'id': 'subcourt-1',
                    'name': 'Court 1',
                    'courtNumber': 1,
                    'slots': [
                      {'startTime': '07:00', 'endTime': '07:30', 'isAvailable': true, 'price': 35000},
                      {'startTime': '07:30', 'endTime': '08:00', 'isAvailable': false, 'price': 35000},
                    ],
                  },
                ],
              },
            });

        final response = await courtService.getCourtAvailability(
          courtId: 'court-123',
          date: '2024-01-20',
        );

        expect(response.success, isTrue);
        expect(response.data, isNotNull);
        expect(response.data!.courtId, 'court-123');
        expect(response.data!.date, '2024-01-20');
        expect(response.data!.subCourts.length, 1);
        expect(response.data!.subCourts[0].timeSlots.length, 2);
        expect(response.data!.subCourts[0].timeSlots[0].isBooked, false);
        expect(response.data!.subCourts[0].timeSlots[1].isBooked, true);

        verify(mockApiService.get(
          '/api/courts/court-123/availability',
          queryParams: {'date': '2024-01-20'},
        )).called(1);
      });

      test('should handle court not found for availability', () async {
        when(mockApiService.get(
          any,
          queryParams: anyNamed('queryParams'),
        )).thenThrow(ApiException('Court not found', statusCode: 404));

        expect(
          () => courtService.getCourtAvailability(
            courtId: 'invalid',
            date: '2024-01-20',
          ),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('getAutocomplete', () {
      test('should fetch autocomplete suggestions with includeDetails', () async {
        when(mockApiService.get(
          any,
          queryParams: anyNamed('queryParams'),
        )).thenAnswer((_) async => {
              'success': true,
              'data': {
                'suggestions': [
                  {
                    'id': 'court-1',
                    'text': 'Sân Cầu Lông Ngọc Khánh',
                    'score': 100,
                    'address': '123 Ngọc Khánh, Ba Đình, Hà Nội',
                    'latitude': 21.0285,
                    'longitude': 105.8542,
                  },
                  {
                    'id': 'court-2',
                    'text': 'Sân Cầu Lông Ba Đình',
                    'score': 85,
                    'address': '456 Ba Đình, Hà Nội',
                    'latitude': 21.03,
                    'longitude': 105.86,
                  },
                ],
              },
            });

        final response = await courtService.getAutocomplete(query: 'Ngọc');

        expect(response.success, isTrue);
        expect(response.data!.length, 2);
        expect(response.data![0].text, 'Sân Cầu Lông Ngọc Khánh');
        expect(response.data![0].address, '123 Ngọc Khánh, Ba Đình, Hà Nội');
        expect(response.data![0].latitude, 21.0285);
        expect(response.data![0].hasLocation, isTrue);

        verify(mockApiService.get(
          '/api/search/autocomplete',
          queryParams: {
            'q': 'Ngọc',
            'limit': '10',
            'includeDetails': 'true',
          },
        )).called(1);
      });

      test('should return empty list for query less than 2 characters', () async {
        final response = await courtService.getAutocomplete(query: 'a');

        expect(response.success, isTrue);
        expect(response.data, isEmpty);

        verifyNever(mockApiService.get(any, queryParams: anyNamed('queryParams')));
      });

      test('should return empty list for empty query', () async {
        final response = await courtService.getAutocomplete(query: '');

        expect(response.success, isTrue);
        expect(response.data, isEmpty);
      });

      test('should use custom limit when provided', () async {
        when(mockApiService.get(
          any,
          queryParams: anyNamed('queryParams'),
        )).thenAnswer((_) async => {
              'success': true,
              'data': {'suggestions': []},
            });

        await courtService.getAutocomplete(query: 'test', limit: 5);

        verify(mockApiService.get(
          '/api/search/autocomplete',
          queryParams: {
            'q': 'test',
            'limit': '5',
            'includeDetails': 'true',
          },
        )).called(1);
      });

      test('should handle includeDetails false', () async {
        when(mockApiService.get(
          any,
          queryParams: anyNamed('queryParams'),
        )).thenAnswer((_) async => {
              'success': true,
              'data': {
                'suggestions': [
                  {'id': 'court-1', 'text': 'Test Court', 'score': 90},
                ],
              },
            });

        final response = await courtService.getAutocomplete(
          query: 'Test',
          includeDetails: false,
        );

        expect(response.data![0].address, isNull);
        expect(response.data![0].hasLocation, isFalse);

        verify(mockApiService.get(
          '/api/search/autocomplete',
          queryParams: {
            'q': 'Test',
            'limit': '10',
            'includeDetails': 'false',
          },
        )).called(1);
      });

      test('should handle null suggestions in response', () async {
        when(mockApiService.get(
          any,
          queryParams: anyNamed('queryParams'),
        )).thenAnswer((_) async => {
              'success': true,
              'data': {'suggestions': null},
            });

        final response = await courtService.getAutocomplete(query: 'xyz');

        expect(response.data, isEmpty);
      });

      test('should support Vietnamese characters', () async {
        when(mockApiService.get(
          any,
          queryParams: anyNamed('queryParams'),
        )).thenAnswer((_) async => {
              'success': true,
              'data': {
                'suggestions': [
                  {'id': 'court-1', 'text': 'Sân Cầu Lông Cầu Giấy', 'score': 95},
                ],
              },
            });

        await courtService.getAutocomplete(query: 'Cầu Giấy');

        verify(mockApiService.get(
          '/api/search/autocomplete',
          queryParams: {
            'q': 'Cầu Giấy',
            'limit': '10',
            'includeDetails': 'true',
          },
        )).called(1);
      });
    });

    group('createCourt', () {
      test('should create court with correct body', () async {
        const newCourt = Court(
          id: '',
          name: 'New Court',
          description: 'A new badminton court',
          phoneNumbers: ['0912345678'],
          addressStreet: '123 New Street',
          addressDistrict: 'Cầu Giấy',
          addressCity: 'Hà Nội',
        );

        when(mockApiService.post(
          any,
          body: anyNamed('body'),
        )).thenAnswer((_) async => {
              'success': true,
              'data': {
                'id': 'new-court-123',
                'name': 'New Court',
                'description': 'A new badminton court',
              },
            });

        final response = await courtService.createCourt(newCourt);

        expect(response.success, isTrue);
        expect(response.data!.id, 'new-court-123');

        verify(mockApiService.post(
          '/api/courts',
          body: newCourt.toJson(),
        )).called(1);
      });
    });

    group('updateCourt', () {
      test('should update court with correct body', () async {
        final updates = {'name': 'Updated Name', 'description': 'Updated description'};

        when(mockApiService.put(
          any,
          body: anyNamed('body'),
        )).thenAnswer((_) async => {
              'success': true,
              'data': {
                'id': 'court-123',
                'name': 'Updated Name',
                'description': 'Updated description',
              },
            });

        final response = await courtService.updateCourt('court-123', updates);

        expect(response.success, isTrue);
        expect(response.data!.name, 'Updated Name');

        verify(mockApiService.put(
          '/api/courts/court-123',
          body: updates,
        )).called(1);
      });
    });

    group('deleteCourt', () {
      test('should delete court by ID', () async {
        when(mockApiService.delete(any)).thenAnswer((_) async => {
              'success': true,
              'data': {'message': 'Court deleted successfully'},
            });

        final response = await courtService.deleteCourt('court-123');

        expect(response.success, isTrue);

        verify(mockApiService.delete('/api/courts/court-123')).called(1);
      });

      test('should handle delete not found', () async {
        when(mockApiService.delete(any))
            .thenThrow(ApiException('Court not found', statusCode: 404));

        expect(
          () => courtService.deleteCourt('invalid'),
          throwsA(isA<ApiException>()),
        );
      });
    });
  });
}

