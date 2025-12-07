import 'package:flutter_test/flutter_test.dart';
import 'package:smatch_badminton/models/search_suggestion.dart';

void main() {
  group('SearchSuggestion', () {
    group('fromJson', () {
      test('should parse complete JSON with location details', () {
        final json = {
          'id': 'court-123',
          'text': 'Sân Cầu Lông Ngọc Khánh',
          'score': 100.0,
          'address': '123 Ngọc Khánh, Phường Ngọc Khánh, Quận Ba Đình, Hà Nội',
          'latitude': 21.0285,
          'longitude': 105.8542,
        };

        final suggestion = SearchSuggestion.fromJson(json);

        expect(suggestion.id, 'court-123');
        expect(suggestion.text, 'Sân Cầu Lông Ngọc Khánh');
        expect(suggestion.score, 100.0);
        expect(suggestion.address, '123 Ngọc Khánh, Phường Ngọc Khánh, Quận Ba Đình, Hà Nội');
        expect(suggestion.latitude, 21.0285);
        expect(suggestion.longitude, 105.8542);
      });

      test('should parse basic JSON without location details', () {
        final json = {
          'id': 'court-456',
          'text': 'Another Court',
          'score': 85,
        };

        final suggestion = SearchSuggestion.fromJson(json);

        expect(suggestion.id, 'court-456');
        expect(suggestion.text, 'Another Court');
        expect(suggestion.score, 85.0);
        expect(suggestion.address, isNull);
        expect(suggestion.latitude, isNull);
        expect(suggestion.longitude, isNull);
      });

      test('should handle integer score', () {
        final json = {
          'id': 'court-789',
          'text': 'Test Court',
          'score': 75,
        };

        final suggestion = SearchSuggestion.fromJson(json);

        expect(suggestion.score, 75.0);
      });

      test('should handle null optional fields explicitly', () {
        final json = {
          'id': 'court-101',
          'text': 'Explicit Null Court',
          'score': 90.0,
          'address': null,
          'latitude': null,
          'longitude': null,
        };

        final suggestion = SearchSuggestion.fromJson(json);

        expect(suggestion.address, isNull);
        expect(suggestion.latitude, isNull);
        expect(suggestion.longitude, isNull);
      });
    });

    group('toJson', () {
      test('should serialize complete suggestion with location', () {
        const suggestion = SearchSuggestion(
          id: 'court-123',
          text: 'Test Court',
          score: 95.5,
          address: '123 Street, Ward, District, City',
          latitude: 21.0285,
          longitude: 105.8542,
        );

        final json = suggestion.toJson();

        expect(json['id'], 'court-123');
        expect(json['text'], 'Test Court');
        expect(json['score'], 95.5);
        expect(json['address'], '123 Street, Ward, District, City');
        expect(json['latitude'], 21.0285);
        expect(json['longitude'], 105.8542);
      });

      test('should not include null optional fields', () {
        const suggestion = SearchSuggestion(
          id: 'court-456',
          text: 'Basic Court',
          score: 80.0,
        );

        final json = suggestion.toJson();

        expect(json['id'], 'court-456');
        expect(json['text'], 'Basic Court');
        expect(json['score'], 80.0);
        expect(json.containsKey('address'), isFalse);
        expect(json.containsKey('latitude'), isFalse);
        expect(json.containsKey('longitude'), isFalse);
      });

      test('should include address but not location when only address provided', () {
        const suggestion = SearchSuggestion(
          id: 'court-789',
          text: 'Address Only Court',
          score: 70.0,
          address: '456 Another Street',
        );

        final json = suggestion.toJson();

        expect(json.containsKey('address'), isTrue);
        expect(json['address'], '456 Another Street');
        expect(json.containsKey('latitude'), isFalse);
        expect(json.containsKey('longitude'), isFalse);
      });
    });

    group('hasLocation', () {
      test('should return true when both latitude and longitude are present', () {
        const suggestion = SearchSuggestion(
          id: 'court-1',
          text: 'Court with Location',
          score: 90.0,
          latitude: 21.0285,
          longitude: 105.8542,
        );

        expect(suggestion.hasLocation, isTrue);
      });

      test('should return false when latitude is null', () {
        const suggestion = SearchSuggestion(
          id: 'court-2',
          text: 'Court without Latitude',
          score: 90.0,
          longitude: 105.8542,
        );

        expect(suggestion.hasLocation, isFalse);
      });

      test('should return false when longitude is null', () {
        const suggestion = SearchSuggestion(
          id: 'court-3',
          text: 'Court without Longitude',
          score: 90.0,
          latitude: 21.0285,
        );

        expect(suggestion.hasLocation, isFalse);
      });

      test('should return false when both are null', () {
        const suggestion = SearchSuggestion(
          id: 'court-4',
          text: 'Court without Location',
          score: 90.0,
        );

        expect(suggestion.hasLocation, isFalse);
      });
    });

    group('toString', () {
      test('should return formatted string representation', () {
        const suggestion = SearchSuggestion(
          id: 'court-1',
          text: 'Test Court',
          score: 95.0,
          address: 'Test Address',
          latitude: 21.0,
          longitude: 105.0,
        );

        final string = suggestion.toString();

        expect(string, contains('SearchSuggestion'));
        expect(string, contains('court-1'));
        expect(string, contains('Test Court'));
        expect(string, contains('95.0'));
        expect(string, contains('Test Address'));
        expect(string, contains('21.0'));
        expect(string, contains('105.0'));
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        const suggestion1 = SearchSuggestion(
          id: 'court-1',
          text: 'Test Court',
          score: 90.0,
          address: 'Address',
          latitude: 21.0,
          longitude: 105.0,
        );

        const suggestion2 = SearchSuggestion(
          id: 'court-1',
          text: 'Test Court',
          score: 90.0,
          address: 'Address',
          latitude: 21.0,
          longitude: 105.0,
        );

        expect(suggestion1, equals(suggestion2));
      });

      test('should not be equal when id differs', () {
        const suggestion1 = SearchSuggestion(
          id: 'court-1',
          text: 'Test Court',
          score: 90.0,
        );

        const suggestion2 = SearchSuggestion(
          id: 'court-2',
          text: 'Test Court',
          score: 90.0,
        );

        expect(suggestion1, isNot(equals(suggestion2)));
      });

      test('should not be equal when text differs', () {
        const suggestion1 = SearchSuggestion(
          id: 'court-1',
          text: 'Test Court 1',
          score: 90.0,
        );

        const suggestion2 = SearchSuggestion(
          id: 'court-1',
          text: 'Test Court 2',
          score: 90.0,
        );

        expect(suggestion1, isNot(equals(suggestion2)));
      });

      test('should not be equal when score differs', () {
        const suggestion1 = SearchSuggestion(
          id: 'court-1',
          text: 'Test Court',
          score: 90.0,
        );

        const suggestion2 = SearchSuggestion(
          id: 'court-1',
          text: 'Test Court',
          score: 85.0,
        );

        expect(suggestion1, isNot(equals(suggestion2)));
      });
    });

    group('hashCode', () {
      test('should produce same hashCode for equal objects', () {
        const suggestion1 = SearchSuggestion(
          id: 'court-1',
          text: 'Test Court',
          score: 90.0,
        );

        const suggestion2 = SearchSuggestion(
          id: 'court-1',
          text: 'Test Court',
          score: 90.0,
        );

        expect(suggestion1.hashCode, equals(suggestion2.hashCode));
      });
    });
  });
}

