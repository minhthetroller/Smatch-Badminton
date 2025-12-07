import 'package:flutter_test/flutter_test.dart';
import 'package:smatch_badminton/models/api_response.dart';

void main() {
  group('ApiResponse', () {
    group('fromJson', () {
      test('should parse successful response with data', () {
        final json = {
          'success': true,
          'data': {'name': 'Test', 'value': 123},
        };

        final response = ApiResponse<Map<String, dynamic>>.fromJson(
          json,
          (data) => data as Map<String, dynamic>,
        );

        expect(response.success, isTrue);
        expect(response.data, isNotNull);
        expect(response.data!['name'], 'Test');
        expect(response.data!['value'], 123);
        expect(response.error, isNull);
        expect(response.meta, isNull);
      });

      test('should parse error response', () {
        final json = {
          'success': false,
          'error': {'message': 'Something went wrong'},
        };

        final response = ApiResponse<String?>.fromJson(json, null);

        expect(response.success, isFalse);
        expect(response.data, isNull);
        expect(response.error, isNotNull);
        expect(response.error!.message, 'Something went wrong');
      });

      test('should parse response with pagination meta', () {
        final json = {
          'success': true,
          'data': [
            {'id': '1', 'name': 'Item 1'},
            {'id': '2', 'name': 'Item 2'},
          ],
          'meta': {
            'pagination': {
              'page': 1,
              'limit': 10,
              'total': 50,
              'totalPages': 5,
              'hasNext': true,
              'hasPrev': false,
            },
          },
        };

        final response = ApiResponse<List<Map<String, dynamic>>>.fromJson(
          json,
          (data) => (data as List).cast<Map<String, dynamic>>(),
        );

        expect(response.success, isTrue);
        expect(response.data, isNotNull);
        expect(response.data!.length, 2);
        expect(response.meta, isNotNull);
        expect(response.meta!.pagination.page, 1);
        expect(response.meta!.pagination.limit, 10);
        expect(response.meta!.pagination.total, 50);
        expect(response.meta!.pagination.totalPages, 5);
        expect(response.meta!.pagination.hasNext, isTrue);
        expect(response.meta!.pagination.hasPrev, isFalse);
      });

      test('should handle null data with null transformer', () {
        final json = {
          'success': true,
          'data': null,
        };

        final response = ApiResponse<String?>.fromJson(json, null);

        expect(response.success, isTrue);
        expect(response.data, isNull);
      });

      test('should handle missing optional fields', () {
        final json = {
          'success': true,
        };

        final response = ApiResponse<String?>.fromJson(json, null);

        expect(response.success, isTrue);
        expect(response.data, isNull);
        expect(response.error, isNull);
        expect(response.meta, isNull);
      });

      test('should parse list data correctly', () {
        final json = {
          'success': true,
          'data': ['item1', 'item2', 'item3'],
        };

        final response = ApiResponse<List<String>>.fromJson(
          json,
          (data) => (data as List).cast<String>(),
        );

        expect(response.success, isTrue);
        expect(response.data, ['item1', 'item2', 'item3']);
      });
    });
  });

  group('ApiError', () {
    group('fromJson', () {
      test('should parse error message', () {
        final json = {'message': 'Not found'};

        final error = ApiError.fromJson(json);

        expect(error.message, 'Not found');
      });
    });
  });

  group('PaginationMeta', () {
    group('fromJson', () {
      test('should parse pagination info', () {
        final json = {
          'pagination': {
            'page': 2,
            'limit': 20,
            'total': 100,
            'totalPages': 5,
            'hasNext': true,
            'hasPrev': true,
          },
        };

        final meta = PaginationMeta.fromJson(json);

        expect(meta.pagination.page, 2);
        expect(meta.pagination.limit, 20);
        expect(meta.pagination.total, 100);
        expect(meta.pagination.totalPages, 5);
        expect(meta.pagination.hasNext, isTrue);
        expect(meta.pagination.hasPrev, isTrue);
      });
    });
  });

  group('PaginationInfo', () {
    group('fromJson', () {
      test('should parse all pagination fields', () {
        final json = {
          'page': 1,
          'limit': 10,
          'total': 25,
          'totalPages': 3,
          'hasNext': true,
          'hasPrev': false,
        };

        final info = PaginationInfo.fromJson(json);

        expect(info.page, 1);
        expect(info.limit, 10);
        expect(info.total, 25);
        expect(info.totalPages, 3);
        expect(info.hasNext, isTrue);
        expect(info.hasPrev, isFalse);
      });

      test('should handle first page scenario', () {
        final json = {
          'page': 1,
          'limit': 10,
          'total': 50,
          'totalPages': 5,
          'hasNext': true,
          'hasPrev': false,
        };

        final info = PaginationInfo.fromJson(json);

        expect(info.page, 1);
        expect(info.hasPrev, isFalse);
        expect(info.hasNext, isTrue);
      });

      test('should handle last page scenario', () {
        final json = {
          'page': 5,
          'limit': 10,
          'total': 50,
          'totalPages': 5,
          'hasNext': false,
          'hasPrev': true,
        };

        final info = PaginationInfo.fromJson(json);

        expect(info.page, 5);
        expect(info.hasPrev, isTrue);
        expect(info.hasNext, isFalse);
      });

      test('should handle single page scenario', () {
        final json = {
          'page': 1,
          'limit': 10,
          'total': 5,
          'totalPages': 1,
          'hasNext': false,
          'hasPrev': false,
        };

        final info = PaginationInfo.fromJson(json);

        expect(info.totalPages, 1);
        expect(info.hasPrev, isFalse);
        expect(info.hasNext, isFalse);
      });
    });
  });
}

