import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:smatch_badminton/models/booking.dart';
import 'package:smatch_badminton/models/payment.dart';
import 'package:smatch_badminton/services/payment_service.dart';
import 'package:smatch_badminton/view_models/payment_view_model.dart';

import 'payment_view_model_test.mocks.dart';

@GenerateMocks([PaymentService])
void main() {
  late MockPaymentService mockPaymentService;
  late PaymentViewModel viewModel;
  late StreamController<PaymentNotification> notificationController;

  setUp(() {
    mockPaymentService = MockPaymentService();
    notificationController = StreamController<PaymentNotification>.broadcast();

    when(mockPaymentService.notificationStream)
        .thenAnswer((_) => notificationController.stream);
    when(mockPaymentService.isConnected).thenReturn(false);
    when(mockPaymentService.disconnect()).thenAnswer((_) async {});

    viewModel = PaymentViewModel(paymentService: mockPaymentService);
  });

  tearDown(() {
    viewModel.dispose();
    notificationController.close();
  });

  group('PaymentViewModel', () {
    group('initial state', () {
      test('should have initial state', () {
        expect(viewModel.state, PaymentViewState.initial);
        expect(viewModel.errorMessage, isNull);
        expect(viewModel.booking, isNull);
        expect(viewModel.paymentResponse, isNull);
        expect(viewModel.qrCodeBytes, isNull);
      });

      test('should not be payment active initially', () {
        expect(viewModel.isPaymentActive, isFalse);
      });
    });

    group('initializePayment', () {
      test('should create booking and payment successfully', () async {
        final testBooking = Booking(
          id: 'booking-123',
          subCourtId: 'subcourt-1',
          guestName: 'Test User',
          guestPhone: '0912345678',
          date: '2024-01-20',
          startTime: '10:00',
          endTime: '12:00',
          totalPrice: 140000,
          status: BookingStatus.pending,
        );

        final testPaymentResponse = CreatePaymentResponse(
          payment: const Payment(
            id: 'payment-123',
            bookingId: 'booking-123',
            amount: 140000,
            status: PaymentStatus.pending,
          ),
          orderUrl: 'https://zalopay.vn/order/123',
          qrCode: const QrCodeData(
            base64: 'data:image/png;base64,iVBORw0KGgo=',
            rawBase64: 'iVBORw0KGgo=',
          ),
          expireAt: DateTime.now().add(const Duration(minutes: 10)),
          wsSubscribeUrl: 'wss://api.example.com/ws/payments',
        );

        when(mockPaymentService.createBooking(any))
            .thenAnswer((_) async => testBooking);
        when(mockPaymentService.createPayment(any))
            .thenAnswer((_) async => testPaymentResponse);
        when(mockPaymentService.connectAndSubscribe(any))
            .thenAnswer((_) async {});
        when(mockPaymentService.queryPaymentStatus(any))
            .thenAnswer((_) async => testPaymentResponse.payment);

        await viewModel.initializePayment(
          subCourtId: 'subcourt-1',
          guestName: 'Test User',
          guestPhone: '0912345678',
          date: '2024-01-20',
          startTime: '10:00',
          endTime: '12:00',
        );

        expect(viewModel.state, PaymentViewState.waitingForPayment);
        expect(viewModel.booking, isNotNull);
        expect(viewModel.booking!.id, 'booking-123');
        expect(viewModel.paymentResponse, isNotNull);
        expect(viewModel.paymentResponse!.payment.id, 'payment-123');

        verify(mockPaymentService.createBooking(any)).called(1);
        verify(mockPaymentService.createPayment('booking-123')).called(1);
      });

      test('should handle booking creation error', () async {
        when(mockPaymentService.createBooking(any))
            .thenThrow(Exception('Failed to create booking'));

        await viewModel.initializePayment(
          subCourtId: 'subcourt-1',
          guestName: 'Test User',
          guestPhone: '0912345678',
          date: '2024-01-20',
          startTime: '10:00',
          endTime: '12:00',
        );

        expect(viewModel.state, PaymentViewState.error);
        expect(viewModel.errorMessage, contains('Failed to create booking'));
      });

      test('should handle payment creation error', () async {
        final testBooking = Booking(
          id: 'booking-123',
          subCourtId: 'subcourt-1',
          guestName: 'Test User',
          guestPhone: '0912345678',
          date: '2024-01-20',
          startTime: '10:00',
          endTime: '12:00',
          totalPrice: 140000,
          status: BookingStatus.pending,
        );

        when(mockPaymentService.createBooking(any))
            .thenAnswer((_) async => testBooking);
        when(mockPaymentService.createPayment(any))
            .thenThrow(Exception('Failed to create payment'));

        await viewModel.initializePayment(
          subCourtId: 'subcourt-1',
          guestName: 'Test User',
          guestPhone: '0912345678',
          date: '2024-01-20',
          startTime: '10:00',
          endTime: '12:00',
        );

        expect(viewModel.state, PaymentViewState.error);
        expect(viewModel.errorMessage, contains('Failed to create payment'));
      });
    });

    group('formattedRemainingTime', () {
      test('should format remaining time correctly', () {
        // This tests the formatting logic
        expect(viewModel.formattedRemainingTime, '00:00');
      });
    });

    group('payment notifications', () {
      test('should handle success notification', () async {
        // Setup initial state
        final testBooking = Booking(
          id: 'booking-123',
          subCourtId: 'subcourt-1',
          guestName: 'Test User',
          guestPhone: '0912345678',
          date: '2024-01-20',
          startTime: '10:00',
          endTime: '12:00',
          totalPrice: 140000,
          status: BookingStatus.pending,
        );

        final testPaymentResponse = CreatePaymentResponse(
          payment: const Payment(
            id: 'payment-123',
            bookingId: 'booking-123',
            amount: 140000,
            status: PaymentStatus.pending,
          ),
          orderUrl: 'https://zalopay.vn/order/123',
          qrCode: const QrCodeData(
            base64: 'data:image/png;base64,iVBORw0KGgo=',
            rawBase64: 'iVBORw0KGgo=',
          ),
          expireAt: DateTime.now().add(const Duration(minutes: 10)),
          wsSubscribeUrl: 'wss://api.example.com/ws/payments',
        );

        when(mockPaymentService.createBooking(any))
            .thenAnswer((_) async => testBooking);
        when(mockPaymentService.createPayment(any))
            .thenAnswer((_) async => testPaymentResponse);
        when(mockPaymentService.connectAndSubscribe(any))
            .thenAnswer((_) async {});
        when(mockPaymentService.queryPaymentStatus(any))
            .thenAnswer((_) async => testPaymentResponse.payment);

        await viewModel.initializePayment(
          subCourtId: 'subcourt-1',
          guestName: 'Test User',
          guestPhone: '0912345678',
          date: '2024-01-20',
          startTime: '10:00',
          endTime: '12:00',
        );

        // Send success notification
        notificationController.add(const PaymentNotification(
          type: 'payment_status',
          paymentId: 'payment-123',
          status: PaymentStatus.success,
        ));

        // Wait for notification processing
        await Future.delayed(const Duration(milliseconds: 100));

        expect(viewModel.state, PaymentViewState.paymentSuccess);
      });

      test('should handle failed notification', () async {
        final testBooking = Booking(
          id: 'booking-123',
          subCourtId: 'subcourt-1',
          guestName: 'Test User',
          guestPhone: '0912345678',
          date: '2024-01-20',
          startTime: '10:00',
          endTime: '12:00',
          totalPrice: 140000,
          status: BookingStatus.pending,
        );

        final testPaymentResponse = CreatePaymentResponse(
          payment: const Payment(
            id: 'payment-123',
            bookingId: 'booking-123',
            amount: 140000,
            status: PaymentStatus.pending,
          ),
          orderUrl: 'https://zalopay.vn/order/123',
          qrCode: const QrCodeData(
            base64: 'data:image/png;base64,iVBORw0KGgo=',
            rawBase64: 'iVBORw0KGgo=',
          ),
          expireAt: DateTime.now().add(const Duration(minutes: 10)),
          wsSubscribeUrl: 'wss://api.example.com/ws/payments',
        );

        when(mockPaymentService.createBooking(any))
            .thenAnswer((_) async => testBooking);
        when(mockPaymentService.createPayment(any))
            .thenAnswer((_) async => testPaymentResponse);
        when(mockPaymentService.connectAndSubscribe(any))
            .thenAnswer((_) async {});
        when(mockPaymentService.queryPaymentStatus(any))
            .thenAnswer((_) async => testPaymentResponse.payment);

        await viewModel.initializePayment(
          subCourtId: 'subcourt-1',
          guestName: 'Test User',
          guestPhone: '0912345678',
          date: '2024-01-20',
          startTime: '10:00',
          endTime: '12:00',
        );

        // Send failed notification
        notificationController.add(const PaymentNotification(
          type: 'payment_status',
          paymentId: 'payment-123',
          status: PaymentStatus.failed,
          message: 'Payment was declined',
        ));

        await Future.delayed(const Duration(milliseconds: 100));

        expect(viewModel.state, PaymentViewState.paymentFailed);
        expect(viewModel.errorMessage, contains('Payment was declined'));
      });
    });

    group('qrCodeBytes', () {
      test('should decode QR code from base64', () async {
        final testBooking = Booking(
          id: 'booking-123',
          subCourtId: 'subcourt-1',
          guestName: 'Test User',
          guestPhone: '0912345678',
          date: '2024-01-20',
          startTime: '10:00',
          endTime: '12:00',
          totalPrice: 140000,
          status: BookingStatus.pending,
        );

        // Valid PNG base64
        final validBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
        
        final testPaymentResponse = CreatePaymentResponse(
          payment: const Payment(
            id: 'payment-123',
            bookingId: 'booking-123',
            amount: 140000,
            status: PaymentStatus.pending,
          ),
          orderUrl: 'https://zalopay.vn/order/123',
          qrCode: QrCodeData(
            base64: 'data:image/png;base64,$validBase64',
            rawBase64: validBase64,
          ),
          expireAt: DateTime.now().add(const Duration(minutes: 10)),
          wsSubscribeUrl: 'wss://api.example.com/ws/payments',
        );

        when(mockPaymentService.createBooking(any))
            .thenAnswer((_) async => testBooking);
        when(mockPaymentService.createPayment(any))
            .thenAnswer((_) async => testPaymentResponse);
        when(mockPaymentService.connectAndSubscribe(any))
            .thenAnswer((_) async {});
        when(mockPaymentService.queryPaymentStatus(any))
            .thenAnswer((_) async => testPaymentResponse.payment);

        await viewModel.initializePayment(
          subCourtId: 'subcourt-1',
          guestName: 'Test User',
          guestPhone: '0912345678',
          date: '2024-01-20',
          startTime: '10:00',
          endTime: '12:00',
        );

        expect(viewModel.qrCodeBytes, isNotNull);
        expect(viewModel.qrCodeBytes!.isNotEmpty, isTrue);
      });
    });

    group('retryPayment', () {
      test('should create new payment for existing booking', () async {
        final testBooking = Booking(
          id: 'booking-123',
          subCourtId: 'subcourt-1',
          guestName: 'Test User',
          guestPhone: '0912345678',
          date: '2024-01-20',
          startTime: '10:00',
          endTime: '12:00',
          totalPrice: 140000,
          status: BookingStatus.pending,
        );

        final testPaymentResponse = CreatePaymentResponse(
          payment: const Payment(
            id: 'payment-456',
            bookingId: 'booking-123',
            amount: 140000,
            status: PaymentStatus.pending,
          ),
          orderUrl: 'https://zalopay.vn/order/456',
          qrCode: const QrCodeData(
            base64: 'data:image/png;base64,newQR',
            rawBase64: 'newQR',
          ),
          expireAt: DateTime.now().add(const Duration(minutes: 10)),
          wsSubscribeUrl: 'wss://api.example.com/ws/payments',
        );

        when(mockPaymentService.createBooking(any))
            .thenAnswer((_) async => testBooking);
        when(mockPaymentService.createPayment(any))
            .thenAnswer((_) async => testPaymentResponse);
        when(mockPaymentService.connectAndSubscribe(any))
            .thenAnswer((_) async {});
        when(mockPaymentService.queryPaymentStatus(any))
            .thenAnswer((_) async => testPaymentResponse.payment);

        // First payment
        await viewModel.initializePayment(
          subCourtId: 'subcourt-1',
          guestName: 'Test User',
          guestPhone: '0912345678',
          date: '2024-01-20',
          startTime: '10:00',
          endTime: '12:00',
        );

        // Retry payment
        await viewModel.retryPayment();

        expect(viewModel.state, PaymentViewState.waitingForPayment);
        verify(mockPaymentService.createPayment('booking-123')).called(2);
      });
    });

    group('refreshPaymentStatus', () {
      test('should update payment status', () async {
        final testBooking = Booking(
          id: 'booking-123',
          subCourtId: 'subcourt-1',
          guestName: 'Test User',
          guestPhone: '0912345678',
          date: '2024-01-20',
          startTime: '10:00',
          endTime: '12:00',
          totalPrice: 140000,
          status: BookingStatus.pending,
        );

        final testPaymentResponse = CreatePaymentResponse(
          payment: const Payment(
            id: 'payment-123',
            bookingId: 'booking-123',
            amount: 140000,
            status: PaymentStatus.pending,
          ),
          orderUrl: 'https://zalopay.vn/order/123',
          qrCode: const QrCodeData(
            base64: 'data:image/png;base64,abc',
            rawBase64: 'abc',
          ),
          expireAt: DateTime.now().add(const Duration(minutes: 10)),
          wsSubscribeUrl: 'wss://api.example.com/ws/payments',
        );

        when(mockPaymentService.createBooking(any))
            .thenAnswer((_) async => testBooking);
        when(mockPaymentService.createPayment(any))
            .thenAnswer((_) async => testPaymentResponse);
        when(mockPaymentService.connectAndSubscribe(any))
            .thenAnswer((_) async {});
        when(mockPaymentService.queryPaymentStatus(any)).thenAnswer(
            (_) async => const Payment(
                  id: 'payment-123',
                  bookingId: 'booking-123',
                  amount: 140000,
                  status: PaymentStatus.success,
                ));

        await viewModel.initializePayment(
          subCourtId: 'subcourt-1',
          guestName: 'Test User',
          guestPhone: '0912345678',
          date: '2024-01-20',
          startTime: '10:00',
          endTime: '12:00',
        );

        await viewModel.refreshPaymentStatus();

        expect(viewModel.state, PaymentViewState.paymentSuccess);
      });
    });
  });
}

