import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:smatch_badminton/services/api_service.dart';
import 'package:smatch_badminton/services/match_service.dart';

import 'match_service_test.mocks.dart';

@GenerateMocks([ApiService])
void main() {
  late MockApiService mockApiService;
  late MatchService matchService;
  late Directory tempDir;

  setUp(() {
    mockApiService = MockApiService();
    matchService = MatchService(apiService: mockApiService);
    ApiService.setGlobalAuthToken('test-token');
    tempDir = Directory.systemTemp.createTempSync('match_service_test_');
  });

  tearDown(() {
    ApiService.setGlobalAuthToken(null);
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  File createTempFile(String name, {int sizeInBytes = 1024}) {
    final file = File('${tempDir.path}/$name');
    file.createSync(recursive: true);
    file.writeAsBytesSync(List.filled(sizeInBytes, 0));
    return file;
  }

  group('uploadMatchImage', () {
    test('should upload valid JPG and return S3 URL', () async {
      final image = createTempFile('photo.jpg');

      when(mockApiService.postMultipartWithAuth(
        any,
        authToken: anyNamed('authToken'),
        fields: anyNamed('fields'),
        files: anyNamed('files'),
        maxRetries: anyNamed('maxRetries'),
        retryDelay: anyNamed('retryDelay'),
      )).thenAnswer((_) async => {
            'success': true,
            'data': {
              'url':
                  'https://smatch-matches.s3.amazonaws.com/matches/uuid-ts.jpg',
            },
          });

      final url = await matchService.uploadMatchImage(image);

      expect(url,
          'https://smatch-matches.s3.amazonaws.com/matches/uuid-ts.jpg');
      verify(mockApiService.postMultipartWithAuth(
        any,
        authToken: 'test-token',
        fields: anyNamed('fields'),
        files: anyNamed('files'),
        maxRetries: anyNamed('maxRetries'),
        retryDelay: anyNamed('retryDelay'),
      )).called(1);
    });

    test('should accept JPEG extension', () async {
      final image = createTempFile('photo.jpeg');

      when(mockApiService.postMultipartWithAuth(
        any,
        authToken: anyNamed('authToken'),
        fields: anyNamed('fields'),
        files: anyNamed('files'),
        maxRetries: anyNamed('maxRetries'),
        retryDelay: anyNamed('retryDelay'),
      )).thenAnswer((_) async => {
            'success': true,
            'data': {'url': 'https://example.com/photo.jpg'},
          });

      final url = await matchService.uploadMatchImage(image);
      expect(url, 'https://example.com/photo.jpg');
    });

    test('should accept PNG extension', () async {
      final image = createTempFile('photo.png');

      when(mockApiService.postMultipartWithAuth(
        any,
        authToken: anyNamed('authToken'),
        fields: anyNamed('fields'),
        files: anyNamed('files'),
        maxRetries: anyNamed('maxRetries'),
        retryDelay: anyNamed('retryDelay'),
      )).thenAnswer((_) async => {
            'success': true,
            'data': {'url': 'https://example.com/photo.png'},
          });

      final url = await matchService.uploadMatchImage(image);
      expect(url, 'https://example.com/photo.png');
    });

    test('should reject WEBP with ApiException (400)', () async {
      final image = createTempFile('photo.webp');

      expect(
        () => matchService.uploadMatchImage(image),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message',
                'Unsupported image type. Use JPG or PNG.')
            .having((e) => e.statusCode, 'statusCode', 400)),
      );
      verifyNever(mockApiService.postMultipartWithAuth(
        any,
        authToken: anyNamed('authToken'),
        fields: anyNamed('fields'),
        files: anyNamed('files'),
        maxRetries: anyNamed('maxRetries'),
        retryDelay: anyNamed('retryDelay'),
      ));
    });

    test('should reject GIF with ApiException (400)', () async {
      final image = createTempFile('photo.gif');

      expect(
        () => matchService.uploadMatchImage(image),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 400)),
      );
      verifyNever(mockApiService.postMultipartWithAuth(
        any,
        authToken: anyNamed('authToken'),
        fields: anyNamed('fields'),
        files: anyNamed('files'),
        maxRetries: anyNamed('maxRetries'),
        retryDelay: anyNamed('retryDelay'),
      ));
    });

    test('should reject PDF with ApiException (400)', () async {
      final image = createTempFile('document.pdf');

      expect(
        () => matchService.uploadMatchImage(image),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 400)),
      );
      verifyNever(mockApiService.postMultipartWithAuth(
        any,
        authToken: anyNamed('authToken'),
        fields: anyNamed('fields'),
        files: anyNamed('files'),
        maxRetries: anyNamed('maxRetries'),
        retryDelay: anyNamed('retryDelay'),
      ));
    });

    test('should reject files larger than 5MB with ApiException (400)',
        () async {
      final image =
          createTempFile('large.jpg', sizeInBytes: 5 * 1024 * 1024 + 1);

      expect(
        () => matchService.uploadMatchImage(image),
        throwsA(isA<ApiException>()
            .having(
                (e) => e.message, 'message', 'Image size must be less than 5MB')
            .having((e) => e.statusCode, 'statusCode', 400)),
      );
      verifyNever(mockApiService.postMultipartWithAuth(
        any,
        authToken: anyNamed('authToken'),
        fields: anyNamed('fields'),
        files: anyNamed('files'),
        maxRetries: anyNamed('maxRetries'),
        retryDelay: anyNamed('retryDelay'),
      ));
    });

    test('should accept file exactly at 5MB limit', () async {
      final image = createTempFile('exact.jpg', sizeInBytes: 5 * 1024 * 1024);

      when(mockApiService.postMultipartWithAuth(
        any,
        authToken: anyNamed('authToken'),
        fields: anyNamed('fields'),
        files: anyNamed('files'),
        maxRetries: anyNamed('maxRetries'),
        retryDelay: anyNamed('retryDelay'),
      )).thenAnswer((_) async => {
            'success': true,
            'data': {'url': 'https://example.com/exact.jpg'},
          });

      final url = await matchService.uploadMatchImage(image);
      expect(url, 'https://example.com/exact.jpg');
    });

    test('should throw when response data.url is missing', () async {
      final image = createTempFile('photo.jpg');

      when(mockApiService.postMultipartWithAuth(
        any,
        authToken: anyNamed('authToken'),
        fields: anyNamed('fields'),
        files: anyNamed('files'),
        maxRetries: anyNamed('maxRetries'),
        retryDelay: anyNamed('retryDelay'),
      )).thenAnswer((_) async => {'success': true, 'data': {}});

      expect(
        () => matchService.uploadMatchImage(image),
        throwsA(isA<ApiException>().having((e) => e.message, 'message',
            'Image upload failed: unexpected response format')),
      );
    });

    test('should throw when not authenticated', () async {
      ApiService.setGlobalAuthToken(null);
      final image = createTempFile('photo.jpg');

      expect(
        () => matchService.uploadMatchImage(image),
        throwsA(isA<ApiException>()
            .having(
                (e) => e.message, 'message', 'Authorization header required')
            .having((e) => e.statusCode, 'statusCode', 401)),
      );
      verifyNever(mockApiService.postMultipartWithAuth(
        any,
        authToken: anyNamed('authToken'),
        fields: anyNamed('fields'),
        files: anyNamed('files'),
        maxRetries: anyNamed('maxRetries'),
        retryDelay: anyNamed('retryDelay'),
      ));
    });
  });
}
