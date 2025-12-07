import 'package:flutter_test/flutter_test.dart';
import 'package:smatch_badminton/models/booking.dart';

void main() {
  group('Booking', () {
    group('fromJson', () {
      test('should parse complete JSON correctly', () {
        final json = {
          'id': 'booking-123',
          'subCourtId': 'subcourt-1',
          'subCourtName': 'Court 1',
          'courtId': 'court-456',
          'courtName': 'Sân Cầu Lông Ngọc Khánh',
          'guestName': 'Nguyễn Văn A',
          'guestPhone': '0912345678',
          'guestEmail': 'test@example.com',
          'date': '2024-01-20',
          'startTime': '10:00',
          'endTime': '12:00',
          'totalPrice': 140000,
          'status': 'confirmed',
          'notes': 'Please prepare rackets',
          'createdAt': '2024-01-15T10:30:00.000Z',
        };

        final booking = Booking.fromJson(json);

        expect(booking.id, 'booking-123');
        expect(booking.subCourtId, 'subcourt-1');
        expect(booking.subCourtName, 'Court 1');
        expect(booking.courtId, 'court-456');
        expect(booking.courtName, 'Sân Cầu Lông Ngọc Khánh');
        expect(booking.guestName, 'Nguyễn Văn A');
        expect(booking.guestPhone, '0912345678');
        expect(booking.guestEmail, 'test@example.com');
        expect(booking.date, '2024-01-20');
        expect(booking.startTime, '10:00');
        expect(booking.endTime, '12:00');
        expect(booking.totalPrice, 140000);
        expect(booking.status, BookingStatus.confirmed);
        expect(booking.notes, 'Please prepare rackets');
        expect(booking.createdAt, isNotNull);
      });

      test('should handle minimal JSON with required fields only', () {
        final json = {
          'id': 'booking-456',
          'subCourtId': 'subcourt-2',
          'guestName': 'Nguyễn Văn B',
          'guestPhone': '0987654321',
          'date': '2024-01-21',
          'startTime': '14:00',
          'endTime': '15:00',
          'totalPrice': 70000,
          'status': 'pending',
        };

        final booking = Booking.fromJson(json);

        expect(booking.id, 'booking-456');
        expect(booking.subCourtId, 'subcourt-2');
        expect(booking.subCourtName, isNull);
        expect(booking.courtId, isNull);
        expect(booking.courtName, isNull);
        expect(booking.guestEmail, isNull);
        expect(booking.status, BookingStatus.pending);
        expect(booking.notes, isNull);
        expect(booking.createdAt, isNull);
      });

      test('should handle null optional fields', () {
        final json = {
          'id': 'booking-789',
          'subCourtId': 'subcourt-3',
          'guestName': 'Test User',
          'guestPhone': '0123456789',
          'date': '2024-01-22',
          'startTime': '08:00',
          'endTime': '09:00',
          'totalPrice': 70000,
          'status': 'pending',
          'subCourtName': null,
          'courtId': null,
          'courtName': null,
          'guestEmail': null,
          'notes': null,
          'createdAt': null,
        };

        final booking = Booking.fromJson(json);

        expect(booking.subCourtName, isNull);
        expect(booking.courtId, isNull);
        expect(booking.courtName, isNull);
        expect(booking.guestEmail, isNull);
        expect(booking.notes, isNull);
        expect(booking.createdAt, isNull);
      });
    });

    group('toJson', () {
      test('should serialize complete booking correctly', () {
        final booking = Booking(
          id: 'booking-123',
          subCourtId: 'subcourt-1',
          subCourtName: 'Court 1',
          courtId: 'court-456',
          courtName: 'Test Court',
          guestName: 'Test User',
          guestPhone: '0912345678',
          guestEmail: 'test@example.com',
          date: '2024-01-20',
          startTime: '10:00',
          endTime: '12:00',
          totalPrice: 140000,
          status: BookingStatus.confirmed,
          notes: 'Notes here',
          createdAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
        );

        final json = booking.toJson();

        expect(json['id'], 'booking-123');
        expect(json['subCourtId'], 'subcourt-1');
        expect(json['subCourtName'], 'Court 1');
        expect(json['courtId'], 'court-456');
        expect(json['courtName'], 'Test Court');
        expect(json['guestName'], 'Test User');
        expect(json['guestPhone'], '0912345678');
        expect(json['guestEmail'], 'test@example.com');
        expect(json['date'], '2024-01-20');
        expect(json['startTime'], '10:00');
        expect(json['endTime'], '12:00');
        expect(json['totalPrice'], 140000);
        expect(json['status'], 'confirmed');
        expect(json['notes'], 'Notes here');
        expect(json['createdAt'], isNotNull);
      });

      test('should serialize booking with null optional fields', () {
        const booking = Booking(
          id: 'booking-456',
          subCourtId: 'subcourt-2',
          guestName: 'Test User',
          guestPhone: '0987654321',
          date: '2024-01-21',
          startTime: '14:00',
          endTime: '15:00',
          totalPrice: 70000,
          status: BookingStatus.pending,
        );

        final json = booking.toJson();

        expect(json['subCourtName'], isNull);
        expect(json['courtId'], isNull);
        expect(json['courtName'], isNull);
        expect(json['guestEmail'], isNull);
        expect(json['notes'], isNull);
        expect(json['createdAt'], isNull);
      });
    });
  });

  group('BookingStatus', () {
    group('fromString', () {
      test('should parse pending status', () {
        expect(BookingStatus.fromString('pending'), BookingStatus.pending);
      });

      test('should parse confirmed status', () {
        expect(BookingStatus.fromString('confirmed'), BookingStatus.confirmed);
      });

      test('should parse cancelled status', () {
        expect(BookingStatus.fromString('cancelled'), BookingStatus.cancelled);
      });

      test('should parse completed status', () {
        expect(BookingStatus.fromString('completed'), BookingStatus.completed);
      });

      test('should return pending for unknown status', () {
        expect(BookingStatus.fromString('unknown'), BookingStatus.pending);
        expect(BookingStatus.fromString('invalid'), BookingStatus.pending);
        expect(BookingStatus.fromString(''), BookingStatus.pending);
      });
    });

    group('value', () {
      test('should return correct string values', () {
        expect(BookingStatus.pending.value, 'pending');
        expect(BookingStatus.confirmed.value, 'confirmed');
        expect(BookingStatus.cancelled.value, 'cancelled');
        expect(BookingStatus.completed.value, 'completed');
      });
    });
  });

  group('CreateBookingRequest', () {
    group('toJson', () {
      test('should serialize complete request with all fields', () {
        const request = CreateBookingRequest(
          subCourtId: 'subcourt-1',
          guestName: 'Nguyễn Văn A',
          guestPhone: '0912345678',
          guestEmail: 'test@example.com',
          date: '2024-01-20',
          startTime: '10:00',
          endTime: '12:00',
          notes: 'Please prepare rackets',
        );

        final json = request.toJson();

        expect(json['subCourtId'], 'subcourt-1');
        expect(json['guestName'], 'Nguyễn Văn A');
        expect(json['guestPhone'], '0912345678');
        expect(json['guestEmail'], 'test@example.com');
        expect(json['date'], '2024-01-20');
        expect(json['startTime'], '10:00');
        expect(json['endTime'], '12:00');
        expect(json['notes'], 'Please prepare rackets');
      });

      test('should not include null optional fields', () {
        const request = CreateBookingRequest(
          subCourtId: 'subcourt-2',
          guestName: 'Test User',
          guestPhone: '0987654321',
          date: '2024-01-21',
          startTime: '14:00',
          endTime: '15:00',
        );

        final json = request.toJson();

        expect(json.containsKey('guestEmail'), isFalse);
        expect(json.containsKey('notes'), isFalse);
        expect(json['subCourtId'], 'subcourt-2');
        expect(json['guestName'], 'Test User');
        expect(json['guestPhone'], '0987654321');
        expect(json['date'], '2024-01-21');
        expect(json['startTime'], '14:00');
        expect(json['endTime'], '15:00');
      });

      test('should include guestEmail when provided, exclude notes when null', () {
        const request = CreateBookingRequest(
          subCourtId: 'subcourt-3',
          guestName: 'Another User',
          guestPhone: '0123456789',
          guestEmail: 'another@example.com',
          date: '2024-01-22',
          startTime: '08:00',
          endTime: '09:00',
        );

        final json = request.toJson();

        expect(json.containsKey('guestEmail'), isTrue);
        expect(json['guestEmail'], 'another@example.com');
        expect(json.containsKey('notes'), isFalse);
      });

      test('should include notes when provided, exclude guestEmail when null', () {
        const request = CreateBookingRequest(
          subCourtId: 'subcourt-4',
          guestName: 'Yet Another User',
          guestPhone: '0111222333',
          date: '2024-01-23',
          startTime: '16:00',
          endTime: '17:00',
          notes: 'Some notes here',
        );

        final json = request.toJson();

        expect(json.containsKey('guestEmail'), isFalse);
        expect(json.containsKey('notes'), isTrue);
        expect(json['notes'], 'Some notes here');
      });
    });
  });
}

