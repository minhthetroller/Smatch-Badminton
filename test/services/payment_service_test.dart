import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:smatch_badminton/models/booking.dart';
import 'package:smatch_badminton/models/payment.dart';
import 'package:smatch_badminton/services/api_service.dart';
import 'package:smatch_badminton/services/payment_service.dart';

import 'payment_service_test.mocks.dart';

@GenerateMocks([ApiService])
void main() {
  late MockApiService mockApiService;
  late PaymentService paymentService;

  setUp(() {
    mockApiService = MockApiService();
    paymentService = PaymentService(apiService: mockApiService);
  });

  tearDown(() {
    paymentService.dispose();
  });

  group('PaymentService', () {
    group('createBooking', () {
      test('should create booking successfully', () async {
        const request = CreateBookingRequest(
          subCourtId: 'subcourt-1',
          guestName: 'Nguyễn Văn A',
          guestPhone: '0912345678',
          guestEmail: 'test@example.com',
          date: '2024-01-20',
          startTime: '10:00',
          endTime: '12:00',
          notes: 'Test booking',
        );

        when(mockApiService.post(
          any,
          body: anyNamed('body'),
        )).thenAnswer((_) async => {
              'success': true,
              'data': {
                'id': 'booking-123',
                'subCourtId': 'subcourt-1',
                'guestName': 'Nguyễn Văn A',
                'guestPhone': '0912345678',
                'guestEmail': 'test@example.com',
                'date': '2024-01-20',
                'startTime': '10:00',
                'endTime': '12:00',
                'totalPrice': 140000,
                'status': 'pending',
                'notes': 'Test booking',
              },
            });

        final booking = await paymentService.createBooking(request);

        expect(booking.id, 'booking-123');
        expect(booking.subCourtId, 'subcourt-1');
        expect(booking.guestName, 'Nguyễn Văn A');
        expect(booking.totalPrice, 140000);
        expect(booking.status, BookingStatus.pending);

        verify(mockApiService.post(
          '/api/bookings',
          body: request.toJson(),
        )).called(1);
      });

      test('should throw ApiException on failure', () async {
        const request = CreateBookingRequest(
          subCourtId: 'subcourt-1',
          guestName: 'Test',
          guestPhone: '0912345678',
          date: '2024-01-20',
          startTime: '10:00',
          endTime: '12:00',
        );

        when(mockApiService.post(
          any,
          body: anyNamed('body'),
        )).thenAnswer((_) async => {
              'success': false,
              'error': {'message': 'Time slot already booked'},
            });

        expect(
          () => paymentService.createBooking(request),
          throwsA(isA<ApiException>()
              .having((e) => e.message, 'message', 'Time slot already booked')),
        );
      });

      test('should throw error when data is null', () async {
        const request = CreateBookingRequest(
          subCourtId: 'subcourt-1',
          guestName: 'Test',
          guestPhone: '0912345678',
          date: '2024-01-20',
          startTime: '10:00',
          endTime: '12:00',
        );

        when(mockApiService.post(
          any,
          body: anyNamed('body'),
        )).thenAnswer((_) async => {
              'success': true,
              'data': null,
            });

        expect(
          () => paymentService.createBooking(request),
          throwsA(anything), // Throws when trying to access null data
        );
      });
    });

    group('createPayment', () {
      test('should create payment and return QR code data', () async {
        when(mockApiService.post(
          any,
          body: anyNamed('body'),
        )).thenAnswer((_) async => {
              'success': true,
              'data': {
                'payment': {
                  'id': 'payment-123',
                  'bookingId': 'booking-456',
                  'amount': 140000,
                  'status': 'pending',
                },
                'orderUrl': 'https://zalopay.vn/order/123',
                'qrCode': {
                  'base64': 'data:image/png;base64,abc123',
                  'rawBase64': 'abc123',
                },
                'zpTransToken': 'token_xyz',
                'expireAt': '2024-01-20T10:40:00.000Z',
                'wsSubscribeUrl': 'wss://api.example.com/ws/payments',
              },
            });

        final response = await paymentService.createPayment('booking-456');

        expect(response.payment.id, 'payment-123');
        expect(response.payment.bookingId, 'booking-456');
        expect(response.payment.amount, 140000);
        expect(response.payment.status, PaymentStatus.pending);
        expect(response.orderUrl, 'https://zalopay.vn/order/123');
        expect(response.qrCode.base64, 'data:image/png;base64,abc123');
        expect(response.qrCode.rawBase64, 'abc123');
        expect(response.zpTransToken, 'token_xyz');
        expect(response.wsSubscribeUrl, 'wss://api.example.com/ws/payments');

        verify(mockApiService.post(
          '/api/payments/create',
          body: {'bookingId': 'booking-456'},
        )).called(1);
      });

      test('should handle 409 conflict when slot is being reserved', () async {
        when(mockApiService.post(
          any,
          body: anyNamed('body'),
        )).thenAnswer((_) async => {
              'success': false,
              'error': {'message': 'Time slot is being reserved by another user'},
            });

        expect(
          () => paymentService.createPayment('booking-456'),
          throwsA(isA<ApiException>()
              .having((e) => e.message, 'message', 'Time slot is being reserved by another user')),
        );
      });

      test('should throw ApiException on booking not found', () async {
        when(mockApiService.post(
          any,
          body: anyNamed('body'),
        )).thenAnswer((_) async => {
              'success': false,
              'error': {'message': 'Booking not found'},
            });

        expect(
          () => paymentService.createPayment('invalid-booking'),
          throwsA(isA<ApiException>()
              .having((e) => e.message, 'message', 'Booking not found')),
        );
      });
    });

    group('getPayment', () {
      test('should get payment by ID', () async {
        when(mockApiService.get(any)).thenAnswer((_) async => {
              'success': true,
              'data': {
                'id': 'payment-123',
                'bookingId': 'booking-456',
                'appTransId': '241220_123456',
                'zpTransId': 'zp_trans_789',
                'amount': 140000,
                'status': 'success',
                'orderUrl': 'https://zalopay.vn/order/123',
              },
            });

        final payment = await paymentService.getPayment('payment-123');

        expect(payment.id, 'payment-123');
        expect(payment.bookingId, 'booking-456');
        expect(payment.appTransId, '241220_123456');
        expect(payment.zpTransId, 'zp_trans_789');
        expect(payment.amount, 140000);
        expect(payment.status, PaymentStatus.success);

        verify(mockApiService.get('/api/payments/payment-123')).called(1);
      });

      test('should throw ApiException when payment not found', () async {
        when(mockApiService.get(any)).thenAnswer((_) async => {
              'success': false,
              'error': {'message': 'Payment not found'},
            });

        expect(
          () => paymentService.getPayment('invalid'),
          throwsA(isA<ApiException>()
              .having((e) => e.message, 'message', 'Payment not found')),
        );
      });
    });

    group('queryPaymentStatus', () {
      test('should query and return updated payment status', () async {
        when(mockApiService.get(any)).thenAnswer((_) async => {
              'success': true,
              'data': {
                'id': 'payment-123',
                'bookingId': 'booking-456',
                'amount': 140000,
                'status': 'success',
              },
            });

        final payment = await paymentService.queryPaymentStatus('payment-123');

        expect(payment.id, 'payment-123');
        expect(payment.status, PaymentStatus.success);

        verify(mockApiService.get('/api/payments/payment-123/status')).called(1);
      });

      test('should return expired status', () async {
        when(mockApiService.get(any)).thenAnswer((_) async => {
              'success': true,
              'data': {
                'id': 'payment-123',
                'bookingId': 'booking-456',
                'amount': 140000,
                'status': 'expired',
              },
            });

        final payment = await paymentService.queryPaymentStatus('payment-123');

        expect(payment.status, PaymentStatus.expired);
      });

      test('should return failed status', () async {
        when(mockApiService.get(any)).thenAnswer((_) async => {
              'success': true,
              'data': {
                'id': 'payment-123',
                'bookingId': 'booking-456',
                'amount': 140000,
                'status': 'failed',
              },
            });

        final payment = await paymentService.queryPaymentStatus('payment-123');

        expect(payment.status, PaymentStatus.failed);
      });
    });

    group('getBooking', () {
      test('should get booking by ID', () async {
        when(mockApiService.get(any)).thenAnswer((_) async => {
              'success': true,
              'data': {
                'id': 'booking-123',
                'subCourtId': 'subcourt-1',
                'subCourtName': 'Court 1',
                'courtId': 'court-456',
                'courtName': 'Sân Cầu Lông Ngọc Khánh',
                'guestName': 'Nguyễn Văn A',
                'guestPhone': '0912345678',
                'date': '2024-01-20',
                'startTime': '10:00',
                'endTime': '12:00',
                'totalPrice': 140000,
                'status': 'confirmed',
              },
            });

        final booking = await paymentService.getBooking('booking-123');

        expect(booking.id, 'booking-123');
        expect(booking.courtName, 'Sân Cầu Lông Ngọc Khánh');
        expect(booking.guestName, 'Nguyễn Văn A');
        expect(booking.status, BookingStatus.confirmed);

        verify(mockApiService.get('/api/bookings/booking-123')).called(1);
      });

      test('should throw ApiException when booking not found', () async {
        when(mockApiService.get(any)).thenAnswer((_) async => {
              'success': false,
              'error': {'message': 'Booking not found'},
            });

        expect(
          () => paymentService.getBooking('invalid'),
          throwsA(isA<ApiException>()
              .having((e) => e.message, 'message', 'Booking not found')),
        );
      });
    });

    group('notificationStream', () {
      test('should provide broadcast stream for notifications', () {
        expect(paymentService.notificationStream, isA<Stream<PaymentNotification>>());
      });
    });

    group('isConnected', () {
      test('should return false initially', () {
        expect(paymentService.isConnected, isFalse);
      });
    });

    group('disconnect', () {
      test('should disconnect and reset state', () async {
        await paymentService.disconnect();

        expect(paymentService.isConnected, isFalse);
      });
    });
  });
}

