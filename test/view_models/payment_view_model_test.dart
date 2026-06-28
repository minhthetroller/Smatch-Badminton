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

  Booking testBooking() {
    return Booking(
      id: 'booking-123',
      subCourtId: '11111111-1111-1111-1111-111111111111',
      guestName: 'Test User',
      guestPhone: '0912345678',
      date: '2024-01-20',
      startTime: '10:00',
      endTime: '12:00',
      totalPrice: 140000,
      status: BookingStatus.pending,
    );
  }

  CreatePaymentResponse testPaymentResponse({
    String paymentId = 'payment-123',
    String wsSubscribeUrl =
        'wss://api.example.com/ws/payments?paymentId=payment-123&ticket=ticket',
  }) {
    return CreatePaymentResponse(
      payment: Payment(
        id: paymentId,
        bookingId: 'booking-123',
        amount: 140000,
        status: PaymentStatus.pending,
      ),
      orderUrl: 'https://zalopay.vn/order/$paymentId',
      qrCode: const QrCodeData(
        base64: 'data:image/png;base64,iVBORw0KGgo=',
        rawBase64: 'iVBORw0KGgo=',
      ),
      expireAt: DateTime.now().add(const Duration(minutes: 10)),
      wsSubscribeUrl: wsSubscribeUrl,
    );
  }

  setUp(() {
    mockPaymentService = MockPaymentService();
    notificationController = StreamController<PaymentNotification>.broadcast();

    when(
      mockPaymentService.notificationStream,
    ).thenAnswer((_) => notificationController.stream);
    when(mockPaymentService.isConnected).thenReturn(false);
    when(mockPaymentService.disconnect()).thenAnswer((_) async {});
    when(
      mockPaymentService.connectToPaymentUpdates(
        paymentId: anyNamed('paymentId'),
        wsSubscribeUrl: anyNamed('wsSubscribeUrl'),
        onConnectionInterrupted: anyNamed('onConnectionInterrupted'),
      ),
    ).thenAnswer((_) async {});

    viewModel = PaymentViewModel(paymentService: mockPaymentService);
  });

  tearDown(() {
    viewModel.dispose();
    notificationController.close();
  });

  group('PaymentViewModel', () {
    test('starts payment and connects to the returned websocket URL', () async {
      final paymentResponse = testPaymentResponse();
      when(
        mockPaymentService.createBooking(any),
      ).thenAnswer((_) async => testBooking());
      when(
        mockPaymentService.createPayment(any),
      ).thenAnswer((_) async => paymentResponse);

      await viewModel.initializePayment(
        subCourtId: '11111111-1111-1111-1111-111111111111',
        guestName: 'Test User',
        guestPhone: '0912345678',
        date: '2024-01-20',
        startTime: '10:00',
        endTime: '12:00',
      );

      expect(viewModel.state, PaymentViewState.waitingForPayment);
      expect(viewModel.booking?.id, 'booking-123');
      expect(viewModel.paymentResponse?.payment.id, 'payment-123');
      verify(mockPaymentService.createPayment('booking-123')).called(1);
      verify(
        mockPaymentService.connectToPaymentUpdates(
          paymentId: 'payment-123',
          wsSubscribeUrl: paymentResponse.wsSubscribeUrl,
          onConnectionInterrupted: anyNamed('onConnectionInterrupted'),
        ),
      ).called(1);
    });

    test('handles payment_status success notification', () async {
      when(
        mockPaymentService.createBooking(any),
      ).thenAnswer((_) async => testBooking());
      when(
        mockPaymentService.createPayment(any),
      ).thenAnswer((_) async => testPaymentResponse());

      await viewModel.initializePayment(
        subCourtId: '11111111-1111-1111-1111-111111111111',
        guestName: 'Test User',
        guestPhone: '0912345678',
        date: '2024-01-20',
        startTime: '10:00',
        endTime: '12:00',
      );

      notificationController.add(
        const PaymentNotification(
          type: 'payment_status',
          paymentId: 'payment-123',
          status: PaymentStatus.success,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.state, PaymentViewState.paymentSuccess);
      verify(mockPaymentService.disconnect()).called(1);
    });

    test('handles payment_status failed notification', () async {
      when(
        mockPaymentService.createBooking(any),
      ).thenAnswer((_) async => testBooking());
      when(
        mockPaymentService.createPayment(any),
      ).thenAnswer((_) async => testPaymentResponse());

      await viewModel.initializePayment(
        subCourtId: '11111111-1111-1111-1111-111111111111',
        guestName: 'Test User',
        guestPhone: '0912345678',
        date: '2024-01-20',
        startTime: '10:00',
        endTime: '12:00',
      );

      notificationController.add(
        const PaymentNotification(
          type: 'payment_status',
          paymentId: 'payment-123',
          status: PaymentStatus.failed,
          message: 'Payment was declined',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.state, PaymentViewState.paymentFailed);
      expect(viewModel.errorMessage, 'Payment was declined');
    });

    test('handles payment_status expired notification', () async {
      when(
        mockPaymentService.createBooking(any),
      ).thenAnswer((_) async => testBooking());
      when(
        mockPaymentService.createPayment(any),
      ).thenAnswer((_) async => testPaymentResponse());

      await viewModel.initializePayment(
        subCourtId: '11111111-1111-1111-1111-111111111111',
        guestName: 'Test User',
        guestPhone: '0912345678',
        date: '2024-01-20',
        startTime: '10:00',
        endTime: '12:00',
      );

      notificationController.add(
        const PaymentNotification(
          type: 'payment_status',
          paymentId: 'payment-123',
          status: PaymentStatus.expired,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.state, PaymentViewState.paymentExpired);
    });

    test('refreshes payment websocket URL on ticket error', () async {
      final responses = [
        testPaymentResponse(),
        testPaymentResponse(
          paymentId: 'payment-456',
          wsSubscribeUrl:
              'wss://api.example.com/ws/payments?paymentId=payment-456&ticket=fresh',
        ),
      ];
      when(
        mockPaymentService.createBooking(any),
      ).thenAnswer((_) async => testBooking());
      when(
        mockPaymentService.createPayment(any),
      ).thenAnswer((_) async => responses.removeAt(0));

      await viewModel.initializePayment(
        subCourtId: '11111111-1111-1111-1111-111111111111',
        guestName: 'Test User',
        guestPhone: '0912345678',
        date: '2024-01-20',
        startTime: '10:00',
        endTime: '12:00',
      );

      notificationController.add(
        const PaymentNotification(
          type: 'error',
          paymentId: 'payment-123',
          code: 'INVALID_PAYMENT_WS_TICKET',
          message: 'Invalid or expired payment websocket ticket',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(viewModel.state, PaymentViewState.waitingForPayment);
      expect(viewModel.paymentResponse?.payment.id, 'payment-456');
      verify(mockPaymentService.createPayment('booking-123')).called(2);
      verify(
        mockPaymentService.connectToPaymentUpdates(
          paymentId: 'payment-456',
          wsSubscribeUrl:
              'wss://api.example.com/ws/payments?paymentId=payment-456&ticket=fresh',
          onConnectionInterrupted: anyNamed('onConnectionInterrupted'),
        ),
      ).called(1);
    });
  });
}
