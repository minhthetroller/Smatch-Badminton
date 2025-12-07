import 'package:flutter_test/flutter_test.dart';
import 'package:smatch_badminton/models/court.dart';

void main() {
  group('Court', () {
    group('fromJson', () {
      test('should parse complete JSON correctly', () {
        final json = {
          'id': 'court-123',
          'name': 'Sân Cầu Lông Ngọc Khánh',
          'description': 'A great badminton court',
          'phoneNumbers': ['0912345678', '0987654321'],
          'addressStreet': '123 Ngọc Khánh',
          'addressWard': 'Phường Ngọc Khánh',
          'addressDistrict': 'Quận Ba Đình',
          'addressCity': 'Hà Nội',
          'details': {
            'amenities': ['Parking', 'Wifi'],
            'payments': ['Cash', 'Card'],
            'serviceOptions': ['Racket rental'],
            'highlights': ['Air conditioned'],
          },
          'openingHours': {
            'mon': '06:00-22:00',
            'tue': '06:00-22:00',
            'wed': '06:00-22:00',
            'thu': '06:00-22:00',
            'fri': '06:00-22:00',
            'sat': '07:00-23:00',
            'sun': '07:00-23:00',
          },
          'location': {
            'latitude': 21.0285,
            'longitude': 105.8542,
          },
          'distance': 1500.5,
          'createdAt': '2024-01-15T10:30:00.000Z',
          'updatedAt': '2024-01-20T15:45:00.000Z',
        };

        final court = Court.fromJson(json);

        expect(court.id, 'court-123');
        expect(court.name, 'Sân Cầu Lông Ngọc Khánh');
        expect(court.description, 'A great badminton court');
        expect(court.phoneNumbers, ['0912345678', '0987654321']);
        expect(court.addressStreet, '123 Ngọc Khánh');
        expect(court.addressWard, 'Phường Ngọc Khánh');
        expect(court.addressDistrict, 'Quận Ba Đình');
        expect(court.addressCity, 'Hà Nội');
        expect(court.details, isNotNull);
        expect(court.details!.amenities, ['Parking', 'Wifi']);
        expect(court.openingHours, isNotNull);
        expect(court.openingHours!.mon, '06:00-22:00');
        expect(court.location, isNotNull);
        expect(court.location!.latitude, 21.0285);
        expect(court.distance, 1500.5);
        expect(court.createdAt, isNotNull);
        expect(court.updatedAt, isNotNull);
      });

      test('should handle minimal JSON with only required fields', () {
        final json = {
          'id': 'court-456',
          'name': 'Simple Court',
        };

        final court = Court.fromJson(json);

        expect(court.id, 'court-456');
        expect(court.name, 'Simple Court');
        expect(court.description, isNull);
        expect(court.phoneNumbers, isEmpty);
        expect(court.addressStreet, isNull);
        expect(court.details, isNull);
        expect(court.openingHours, isNull);
        expect(court.location, isNull);
        expect(court.distance, isNull);
      });

      test('should handle null phone numbers list', () {
        final json = {
          'id': 'court-789',
          'name': 'No Phone Court',
          'phoneNumbers': null,
        };

        final court = Court.fromJson(json);
        expect(court.phoneNumbers, isEmpty);
      });
    });

    group('toJson', () {
      test('should serialize to JSON correctly', () {
        const court = Court(
          id: 'court-123',
          name: 'Test Court',
          description: 'Description',
          phoneNumbers: ['0912345678'],
          addressStreet: '123 Street',
          addressWard: 'Ward 1',
          addressDistrict: 'District 1',
          addressCity: 'Hà Nội',
        );

        final json = court.toJson();

        expect(json['id'], 'court-123');
        expect(json['name'], 'Test Court');
        expect(json['description'], 'Description');
        expect(json['phoneNumbers'], ['0912345678']);
        expect(json['addressStreet'], '123 Street');
      });
    });

    group('fullAddress', () {
      test('should combine all address parts', () {
        const court = Court(
          id: 'court-1',
          name: 'Test',
          addressStreet: '123 Street',
          addressWard: 'Ward 1',
          addressDistrict: 'District 1',
          addressCity: 'Hà Nội',
        );

        expect(court.fullAddress, '123 Street, Ward 1, District 1, Hà Nội');
      });

      test('should skip null address parts', () {
        const court = Court(
          id: 'court-2',
          name: 'Test',
          addressDistrict: 'District 1',
          addressCity: 'Hà Nội',
        );

        expect(court.fullAddress, 'District 1, Hà Nội');
      });

      test('should skip empty address parts', () {
        const court = Court(
          id: 'court-3',
          name: 'Test',
          addressStreet: '',
          addressWard: 'Ward 1',
          addressCity: 'Hà Nội',
        );

        expect(court.fullAddress, 'Ward 1, Hà Nội');
      });

      test('should return empty string when no address parts', () {
        const court = Court(id: 'court-4', name: 'Test');
        expect(court.fullAddress, '');
      });
    });

    group('distanceFormatted', () {
      test('should return empty string when distance is null', () {
        const court = Court(id: 'court-1', name: 'Test');
        expect(court.distanceFormatted, '');
      });

      test('should format distance in meters when less than 1000', () {
        const court = Court(id: 'court-2', name: 'Test', distance: 500.0);
        expect(court.distanceFormatted, '500m');
      });

      test('should format distance in meters at exactly 999', () {
        const court = Court(id: 'court-3', name: 'Test', distance: 999.0);
        expect(court.distanceFormatted, '999m');
      });

      test('should format distance in km when 1000 or more', () {
        const court = Court(id: 'court-4', name: 'Test', distance: 1000.0);
        expect(court.distanceFormatted, '1.0km');
      });

      test('should format distance in km with one decimal', () {
        const court = Court(id: 'court-5', name: 'Test', distance: 2500.0);
        expect(court.distanceFormatted, '2.5km');
      });

      test('should round meters to int', () {
        const court = Court(id: 'court-6', name: 'Test', distance: 750.7);
        expect(court.distanceFormatted, '750m');
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        const original = Court(
          id: 'court-1',
          name: 'Original',
          description: 'Original Description',
        );

        final copy = original.copyWith(
          name: 'Updated',
          description: 'Updated Description',
        );

        expect(copy.id, 'court-1');
        expect(copy.name, 'Updated');
        expect(copy.description, 'Updated Description');
      });

      test('should preserve original values when not specified', () {
        const original = Court(
          id: 'court-1',
          name: 'Original',
          phoneNumbers: ['0912345678'],
          addressCity: 'Hà Nội',
        );

        final copy = original.copyWith(name: 'New Name');

        expect(copy.id, 'court-1');
        expect(copy.name, 'New Name');
        expect(copy.phoneNumbers, ['0912345678']);
        expect(copy.addressCity, 'Hà Nội');
      });
    });
  });

  group('CourtDetails', () {
    group('fromJson', () {
      test('should parse complete JSON', () {
        final json = {
          'amenities': ['Parking', 'Wifi', 'Shower'],
          'payments': ['Cash', 'Card', 'Transfer'],
          'serviceOptions': ['Racket rental', 'Coaching'],
          'highlights': ['Air conditioned', 'Professional courts'],
        };

        final details = CourtDetails.fromJson(json);

        expect(details.amenities, ['Parking', 'Wifi', 'Shower']);
        expect(details.payments, ['Cash', 'Card', 'Transfer']);
        expect(details.serviceOptions, ['Racket rental', 'Coaching']);
        expect(details.highlights, ['Air conditioned', 'Professional courts']);
      });

      test('should handle empty or null arrays', () {
        final json = <String, dynamic>{
          'amenities': null,
          'payments': [],
        };

        final details = CourtDetails.fromJson(json);

        expect(details.amenities, isEmpty);
        expect(details.payments, isEmpty);
        expect(details.serviceOptions, isEmpty);
        expect(details.highlights, isEmpty);
      });
    });

    group('toJson', () {
      test('should serialize correctly', () {
        const details = CourtDetails(
          amenities: ['Parking'],
          payments: ['Cash'],
          serviceOptions: ['Rental'],
          highlights: ['AC'],
        );

        final json = details.toJson();

        expect(json['amenities'], ['Parking']);
        expect(json['payments'], ['Cash']);
        expect(json['serviceOptions'], ['Rental']);
        expect(json['highlights'], ['AC']);
      });
    });
  });

  group('OpeningHours', () {
    group('fromJson', () {
      test('should parse all days', () {
        final json = {
          'mon': '06:00-22:00',
          'tue': '06:00-22:00',
          'wed': '06:00-22:00',
          'thu': '06:00-22:00',
          'fri': '06:00-22:00',
          'sat': '07:00-23:00',
          'sun': '08:00-20:00',
        };

        final hours = OpeningHours.fromJson(json);

        expect(hours.mon, '06:00-22:00');
        expect(hours.tue, '06:00-22:00');
        expect(hours.wed, '06:00-22:00');
        expect(hours.thu, '06:00-22:00');
        expect(hours.fri, '06:00-22:00');
        expect(hours.sat, '07:00-23:00');
        expect(hours.sun, '08:00-20:00');
      });

      test('should handle null days', () {
        final json = <String, dynamic>{
          'mon': '06:00-22:00',
          'wed': null,
        };

        final hours = OpeningHours.fromJson(json);

        expect(hours.mon, '06:00-22:00');
        expect(hours.tue, isNull);
        expect(hours.wed, isNull);
      });
    });

    group('getHoursForDay', () {
      test('should return correct hours for each day index', () {
        const hours = OpeningHours(
          mon: 'Monday',
          tue: 'Tuesday',
          wed: 'Wednesday',
          thu: 'Thursday',
          fri: 'Friday',
          sat: 'Saturday',
          sun: 'Sunday',
        );

        expect(hours.getHoursForDay(0), 'Monday');
        expect(hours.getHoursForDay(1), 'Tuesday');
        expect(hours.getHoursForDay(2), 'Wednesday');
        expect(hours.getHoursForDay(3), 'Thursday');
        expect(hours.getHoursForDay(4), 'Friday');
        expect(hours.getHoursForDay(5), 'Saturday');
        expect(hours.getHoursForDay(6), 'Sunday');
      });

      test('should return null for invalid day index', () {
        const hours = OpeningHours(mon: 'Monday');

        expect(hours.getHoursForDay(-1), isNull);
        expect(hours.getHoursForDay(7), isNull);
        expect(hours.getHoursForDay(100), isNull);
      });
    });

    group('todayHours', () {
      test('should return hours for current weekday', () {
        // Note: This test's result depends on when it's run
        const hours = OpeningHours(
          mon: '06:00-22:00',
          tue: '06:00-22:00',
          wed: '06:00-22:00',
          thu: '06:00-22:00',
          fri: '06:00-22:00',
          sat: '07:00-23:00',
          sun: '08:00-20:00',
        );

        final todayIndex = DateTime.now().weekday - 1;
        final expectedHours = hours.getHoursForDay(todayIndex);

        expect(hours.todayHours, expectedHours);
      });
    });

    group('toJson', () {
      test('should serialize correctly', () {
        const hours = OpeningHours(
          mon: '06:00-22:00',
          sat: '07:00-23:00',
        );

        final json = hours.toJson();

        expect(json['mon'], '06:00-22:00');
        expect(json['sat'], '07:00-23:00');
        expect(json['tue'], isNull);
      });
    });
  });

  group('CourtLocation', () {
    group('fromJson', () {
      test('should parse coordinates correctly', () {
        final json = {
          'latitude': 21.0285,
          'longitude': 105.8542,
        };

        final location = CourtLocation.fromJson(json);

        expect(location.latitude, 21.0285);
        expect(location.longitude, 105.8542);
      });

      test('should handle integer coordinates', () {
        final json = {
          'latitude': 21,
          'longitude': 106,
        };

        final location = CourtLocation.fromJson(json);

        expect(location.latitude, 21.0);
        expect(location.longitude, 106.0);
      });
    });

    group('toJson', () {
      test('should serialize correctly', () {
        const location = CourtLocation(latitude: 21.0285, longitude: 105.8542);

        final json = location.toJson();

        expect(json['latitude'], 21.0285);
        expect(json['longitude'], 105.8542);
      });
    });
  });
}

