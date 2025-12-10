import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:smatch_badminton/services/api_service.dart';

import 'api_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  late MockClient mockClient;
  late ApiService apiService;

  setUp(() {
    mockClient = MockClient();
    apiService = ApiService(client: mockClient, baseUrl: 'https://api.test.com');
  });

  tearDown(() {
    apiService.dispose();
  });

  group('ApiService', () {
    group('GET request', () {
      test('should make GET request with correct URL and headers', () async {
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
              jsonEncode({'success': true, 'data': {'test': 'value'}}),
              200,
            ));

        await apiService.get('/test-endpoint');

        verify(mockClient.get(
          Uri.parse('https://api.test.com/test-endpoint'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )).called(1);
      });

      test('should include query parameters when provided', () async {
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
              jsonEncode({'success': true, 'data': []}),
              200,
            ));

        await apiService.get(
          '/courts',
          queryParams: {'page': '1', 'limit': '10', 'district': 'Cầu Giấy'},
        );

        verify(mockClient.get(
          argThat(predicate<Uri>((uri) =>
              uri.queryParameters['page'] == '1' &&
              uri.queryParameters['limit'] == '10' &&
              uri.queryParameters['district'] == 'Cầu Giấy')),
          headers: anyNamed('headers'),
        )).called(1);
      });

      test('should parse successful response correctly', () async {
        final responseBody = {'success': true, 'data': {'id': '123', 'name': 'Test'}};
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(jsonEncode(responseBody), 200));

        final result = await apiService.get('/test');

        expect(result['success'], true);
        expect(result['data']['id'], '123');
        expect(result['data']['name'], 'Test');
      });

      test('should throw ApiException on 404 error', () async {
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
              jsonEncode({
                'success': false,
                'error': {'message': 'Court not found'}
              }),
              404,
            ));

        expect(
          () => apiService.get('/courts/invalid-id'),
          throwsA(isA<ApiException>()
              .having((e) => e.message, 'message', 'Court not found')
              .having((e) => e.statusCode, 'statusCode', 404)),
        );
      });

      test('should throw ApiException on 500 error', () async {
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
              jsonEncode({
                'success': false,
                'error': {'message': 'Internal server error'}
              }),
              500,
            ));

        expect(
          () => apiService.get('/test'),
          throwsA(isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 500)),
        );
      });

      test('should throw ApiException on network error (SocketException)', () async {
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenThrow(const SocketException('No internet connection'));

        expect(
          () => apiService.get('/test'),
          throwsA(isA<ApiException>()
              .having((e) => e.message, 'message', 'No internet connection')),
        );
      });

      test('should handle unknown error gracefully', () async {
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenThrow(Exception('Unknown error'));

        expect(
          () => apiService.get('/test'),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('POST request', () {
      test('should make POST request with correct body', () async {
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
              jsonEncode({'success': true, 'data': {'id': 'new-123'}}),
              201,
            ));

        final requestBody = {'name': 'Test Court', 'description': 'A test court'};
        await apiService.post('/courts', body: requestBody);

        verify(mockClient.post(
          Uri.parse('https://api.test.com/courts'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(requestBody),
        )).called(1);
      });

      test('should handle POST without body', () async {
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
              jsonEncode({'success': true}),
              200,
            ));

        await apiService.post('/endpoint');

        verify(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: null,
        )).called(1);
      });

      test('should parse successful POST response', () async {
        final responseBody = {
          'success': true,
          'data': {'id': 'booking-123', 'status': 'pending'}
        };
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(jsonEncode(responseBody), 201));

        final result = await apiService.post('/bookings', body: {'subCourtId': 'sc-1'});

        expect(result['success'], true);
        expect(result['data']['id'], 'booking-123');
      });

      test('should throw ApiException on 409 conflict', () async {
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
              jsonEncode({
                'success': false,
                'error': {'message': 'Time slot already booked'}
              }),
              409,
            ));

        expect(
          () => apiService.post('/bookings', body: {}),
          throwsA(isA<ApiException>()
              .having((e) => e.message, 'message', 'Time slot already booked')
              .having((e) => e.statusCode, 'statusCode', 409)),
        );
      });

      test('should throw ApiException on network error', () async {
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenThrow(const SocketException('Connection refused'));

        expect(
          () => apiService.post('/test', body: {}),
          throwsA(isA<ApiException>()
              .having((e) => e.message, 'message', 'No internet connection')),
        );
      });
    });

    group('PUT request', () {
      test('should make PUT request with correct body', () async {
        when(mockClient.put(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
              jsonEncode({'success': true, 'data': {'id': '123', 'name': 'Updated'}}),
              200,
            ));

        final updateBody = {'name': 'Updated Court'};
        await apiService.put('/courts/123', body: updateBody);

        verify(mockClient.put(
          Uri.parse('https://api.test.com/courts/123'),
          headers: anyNamed('headers'),
          body: jsonEncode(updateBody),
        )).called(1);
      });

      test('should parse successful PUT response', () async {
        final responseBody = {'success': true, 'data': {'name': 'Updated Name'}};
        when(mockClient.put(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(jsonEncode(responseBody), 200));

        final result = await apiService.put('/courts/123', body: {});

        expect(result['data']['name'], 'Updated Name');
      });

      test('should throw ApiException on 404 not found', () async {
        when(mockClient.put(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
              jsonEncode({
                'success': false,
                'error': {'message': 'Resource not found'}
              }),
              404,
            ));

        expect(
          () => apiService.put('/courts/invalid', body: {}),
          throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404)),
        );
      });
    });

    group('DELETE request', () {
      test('should make DELETE request to correct URL', () async {
        when(mockClient.delete(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
              jsonEncode({'success': true, 'data': {'message': 'Deleted'}}),
              200,
            ));

        await apiService.delete('/courts/123');

        verify(mockClient.delete(
          Uri.parse('https://api.test.com/courts/123'),
          headers: anyNamed('headers'),
        )).called(1);
      });

      test('should parse successful DELETE response', () async {
        final responseBody = {'success': true, 'data': {'message': 'Court deleted successfully'}};
        when(mockClient.delete(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(jsonEncode(responseBody), 200));

        final result = await apiService.delete('/courts/123');

        expect(result['success'], true);
        expect(result['data']['message'], 'Court deleted successfully');
      });

      test('should throw ApiException on 400 bad request', () async {
        when(mockClient.delete(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
              jsonEncode({
                'success': false,
                'error': {'message': 'Booking already cancelled'}
              }),
              400,
            ));

        expect(
          () => apiService.delete('/bookings/123'),
          throwsA(isA<ApiException>()
              .having((e) => e.message, 'message', 'Booking already cancelled')),
        );
      });
    });

    group('Response handling', () {
      test('should handle 201 Created as success', () async {
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
              jsonEncode({'success': true, 'data': {}}),
              201,
            ));

        final result = await apiService.post('/test', body: {});
        expect(result['success'], true);
      });

      test('should handle 204 No Content as success', () async {
        when(mockClient.delete(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
              jsonEncode({'success': true}),
              204,
            ));

        final result = await apiService.delete('/test');
        expect(result['success'], true);
      });

      test('should extract error message from response', () async {
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
              jsonEncode({
                'success': false,
                'error': {'message': 'Custom error message'}
              }),
              400,
            ));

        expect(
          () => apiService.get('/test'),
          throwsA(isA<ApiException>()
              .having((e) => e.message, 'message', 'Custom error message')),
        );
      });

      test('should use default error message when not provided', () async {
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
              jsonEncode({'success': false}),
              500,
            ));

        expect(
          () => apiService.get('/test'),
          throwsA(isA<ApiException>()
              .having((e) => e.message, 'message', 'Unknown error occurred')),
        );
      });
    });
  });

  group('ApiException', () {
    test('should store message and statusCode', () {
      final exception = ApiException('Test error', statusCode: 404);

      expect(exception.message, 'Test error');
      expect(exception.statusCode, 404);
    });

    test('should format toString correctly', () {
      final exception = ApiException('Not found', statusCode: 404);

      expect(exception.toString(), 'ApiException: Not found (status: 404)');
    });

    test('should handle null statusCode', () {
      final exception = ApiException('Network error');

      expect(exception.statusCode, isNull);
      expect(exception.toString(), 'ApiException: Network error (status: null)');
    });
  });
}

