import 'package:flutter_test/flutter_test.dart';
import 'package:smatch_badminton/models/payment.dart';

void main() {
  group('Payment', () {
    group('fromJson', () {
      test('should parse complete JSON correctly', () {
        final json = {
          'id': 'payment-123',
          'bookingId': 'booking-456',
          'appTransId': '241220_123456',
          'zpTransId': 'zp_trans_789',
          'amount': 140000,
          'status': 'success',
          'orderUrl': 'https://zalopay.vn/order/123',
          'createdAt': '2024-01-15T10:30:00.000Z',
          'updatedAt': '2024-01-15T10:35:00.000Z',
        };

        final payment = Payment.fromJson(json);

        expect(payment.id, 'payment-123');
        expect(payment.bookingId, 'booking-456');
        expect(payment.appTransId, '241220_123456');
        expect(payment.zpTransId, 'zp_trans_789');
        expect(payment.amount, 140000);
        expect(payment.status, PaymentStatus.success);
        expect(payment.orderUrl, 'https://zalopay.vn/order/123');
        expect(payment.createdAt, isNotNull);
        expect(payment.updatedAt, isNotNull);
      });

      test('should handle minimal JSON with required fields', () {
        final json = {
          'id': 'payment-456',
          'bookingId': 'booking-789',
          'amount': 70000,
          'status': 'pending',
        };

        final payment = Payment.fromJson(json);

        expect(payment.id, 'payment-456');
        expect(payment.bookingId, 'booking-789');
        expect(payment.appTransId, isNull);
        expect(payment.zpTransId, isNull);
        expect(payment.amount, 70000);
        expect(payment.status, PaymentStatus.pending);
        expect(payment.orderUrl, isNull);
        expect(payment.createdAt, isNull);
        expect(payment.updatedAt, isNull);
      });

      test('should handle create-payment snapshot with only id and status', () {
        final json = {'id': 'payment-456', 'status': 'pending'};

        final payment = Payment.fromJson(json);

        expect(payment.id, 'payment-456');
        expect(payment.bookingId, '');
        expect(payment.amount, 0);
        expect(payment.status, PaymentStatus.pending);
      });

      test('should handle null optional fields explicitly', () {
        final json = {
          'id': 'payment-789',
          'bookingId': 'booking-101',
          'appTransId': null,
          'zpTransId': null,
          'amount': 100000,
          'status': 'pending',
          'orderUrl': null,
          'createdAt': null,
          'updatedAt': null,
        };

        final payment = Payment.fromJson(json);

        expect(payment.appTransId, isNull);
        expect(payment.zpTransId, isNull);
        expect(payment.orderUrl, isNull);
        expect(payment.createdAt, isNull);
        expect(payment.updatedAt, isNull);
      });
    });

    group('toJson', () {
      test('should serialize complete payment correctly', () {
        final payment = Payment(
          id: 'payment-123',
          bookingId: 'booking-456',
          appTransId: '241220_123456',
          zpTransId: 'zp_trans_789',
          amount: 140000,
          status: PaymentStatus.success,
          orderUrl: 'https://zalopay.vn/order/123',
          createdAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
          updatedAt: DateTime.parse('2024-01-15T10:35:00.000Z'),
        );

        final json = payment.toJson();

        expect(json['id'], 'payment-123');
        expect(json['bookingId'], 'booking-456');
        expect(json['appTransId'], '241220_123456');
        expect(json['zpTransId'], 'zp_trans_789');
        expect(json['amount'], 140000);
        expect(json['status'], 'success');
        expect(json['orderUrl'], 'https://zalopay.vn/order/123');
        expect(json['createdAt'], isNotNull);
        expect(json['updatedAt'], isNotNull);
      });

      test('should serialize payment with null optional fields', () {
        const payment = Payment(
          id: 'payment-456',
          bookingId: 'booking-789',
          amount: 70000,
          status: PaymentStatus.pending,
        );

        final json = payment.toJson();

        expect(json['appTransId'], isNull);
        expect(json['zpTransId'], isNull);
        expect(json['orderUrl'], isNull);
        expect(json['createdAt'], isNull);
        expect(json['updatedAt'], isNull);
      });
    });
  });

  group('PaymentStatus', () {
    group('fromString', () {
      test('should parse pending status', () {
        expect(PaymentStatus.fromString('pending'), PaymentStatus.pending);
      });

      test('should parse success status', () {
        expect(PaymentStatus.fromString('success'), PaymentStatus.success);
      });

      test('should parse failed status', () {
        expect(PaymentStatus.fromString('failed'), PaymentStatus.failed);
      });

      test('should parse expired status', () {
        expect(PaymentStatus.fromString('expired'), PaymentStatus.expired);
      });

      test('should return pending for unknown status', () {
        expect(PaymentStatus.fromString('unknown'), PaymentStatus.pending);
        expect(PaymentStatus.fromString('invalid'), PaymentStatus.pending);
        expect(PaymentStatus.fromString(''), PaymentStatus.pending);
      });
    });

    group('value', () {
      test('should return correct string values', () {
        expect(PaymentStatus.pending.value, 'pending');
        expect(PaymentStatus.success.value, 'success');
        expect(PaymentStatus.failed.value, 'failed');
        expect(PaymentStatus.expired.value, 'expired');
      });
    });
  });

  group('QrCodeData', () {
    group('fromJson', () {
      test('should parse QR code data correctly', () {
        final json = {
          'base64': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUg...',
          'rawBase64': 'iVBORw0KGgoAAAANSUhEUg...',
        };

        final qrCode = QrCodeData.fromJson(json);

        expect(
          qrCode.base64,
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUg...',
        );
        expect(qrCode.rawBase64, 'iVBORw0KGgoAAAANSUhEUg...');
      });
    });
  });

  group('CreatePaymentResponse', () {
    group('fromJson', () {
      test('should parse complete response correctly', () {
        final json = {
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
          'expireAt': '2024-01-15T10:40:00.000Z',
          'wsSubscribeUrl': 'wss://api.example.com/ws/payments',
        };

        final response = CreatePaymentResponse.fromJson(json);

        expect(response.payment.id, 'payment-123');
        expect(response.payment.bookingId, 'booking-456');
        expect(response.payment.amount, 140000);
        expect(response.payment.status, PaymentStatus.pending);
        expect(response.orderUrl, 'https://zalopay.vn/order/123');
        expect(response.qrCode.base64, 'data:image/png;base64,abc123');
        expect(response.qrCode.rawBase64, 'abc123');
        expect(response.zpTransToken, 'token_xyz');
        expect(response.expireAt, isA<DateTime>());
        expect(response.wsSubscribeUrl, 'wss://api.example.com/ws/payments');
      });

      test('should handle null zpTransToken', () {
        final json = {
          'payment': {
            'id': 'payment-456',
            'bookingId': 'booking-789',
            'amount': 70000,
            'status': 'pending',
          },
          'orderUrl': 'https://zalopay.vn/order/456',
          'qrCode': {
            'base64': 'data:image/png;base64,def456',
            'rawBase64': 'def456',
          },
          'zpTransToken': null,
          'expireAt': '2024-01-16T11:00:00.000Z',
          'wsSubscribeUrl': 'wss://api.example.com/ws/payments',
        };

        final response = CreatePaymentResponse.fromJson(json);

        expect(response.zpTransToken, isNull);
      });
    });
  });

  group('PaymentNotification', () {
    group('fromJson', () {
      test('should parse payment status notification', () {
        final json = {
          'type': 'payment_status',
          'paymentId': 'payment-123',
          'status': 'success',
          'bookingId': 'booking-456',
          'matchPlayerId': null,
          'zpTransId': 'zp_trans_789',
          'message': 'Payment completed successfully',
        };

        final notification = PaymentNotification.fromJson(json);

        expect(notification.type, 'payment_status');
        expect(notification.paymentId, 'payment-123');
        expect(notification.status, PaymentStatus.success);
        expect(notification.bookingId, 'booking-456');
        expect(notification.matchPlayerId, isNull);
        expect(notification.zpTransId, 'zp_trans_789');
        expect(notification.message, 'Payment completed successfully');
      });

      test('should parse subscribed notification', () {
        final json = {
          'type': 'subscribed',
          'paymentId': 'payment-123',
          'message': 'Successfully subscribed to payment updates',
        };

        final notification = PaymentNotification.fromJson(json);

        expect(notification.type, 'subscribed');
        expect(notification.paymentId, 'payment-123');
        expect(notification.status, isNull);
        expect(notification.bookingId, isNull);
        expect(notification.zpTransId, isNull);
        expect(
          notification.message,
          'Successfully subscribed to payment updates',
        );
      });

      test('should parse connected notification without payment id', () {
        final notification = PaymentNotification.fromJson({
          'type': 'connected',
          'message': 'Connected to payment notification service',
        });

        expect(notification.type, 'connected');
        expect(notification.paymentId, isNull);
        expect(notification.isPaymentStatus, isFalse);
      });

      test('should parse websocket ticket error notification', () {
        final notification = PaymentNotification.fromJson({
          'type': 'error',
          'code': 'INVALID_PAYMENT_WS_TICKET',
          'paymentId': 'payment-123',
          'message': 'Invalid or expired payment websocket ticket',
        });

        expect(notification.isError, isTrue);
        expect(notification.isTicketError, isTrue);
        expect(notification.code, 'INVALID_PAYMENT_WS_TICKET');
      });

      test('should handle null optional fields', () {
        final json = {
          'type': 'payment_status',
          'paymentId': 'payment-456',
          'status': null,
          'bookingId': null,
          'zpTransId': null,
          'message': null,
        };

        final notification = PaymentNotification.fromJson(json);

        expect(notification.status, isNull);
        expect(notification.bookingId, isNull);
        expect(notification.zpTransId, isNull);
        expect(notification.message, isNull);
      });
    });

    group('isPaymentStatus', () {
      test('should return true for payment_status type', () {
        const notification = PaymentNotification(
          type: 'payment_status',
          paymentId: 'payment-123',
        );

        expect(notification.isPaymentStatus, isTrue);
      });

      test('should return false for other types', () {
        const notification = PaymentNotification(
          type: 'subscribed',
          paymentId: 'payment-123',
        );

        expect(notification.isPaymentStatus, isFalse);
      });
    });

    group('isSubscribed', () {
      test('should return true for subscribed type', () {
        const notification = PaymentNotification(
          type: 'subscribed',
          paymentId: 'payment-123',
        );

        expect(notification.isSubscribed, isTrue);
      });

      test('should return false for other types', () {
        const notification = PaymentNotification(
          type: 'payment_status',
          paymentId: 'payment-123',
        );

        expect(notification.isSubscribed, isFalse);
      });
    });

    group('isSuccess', () {
      test('should return true when status is success', () {
        const notification = PaymentNotification(
          type: 'payment_status',
          paymentId: 'payment-123',
          status: PaymentStatus.success,
        );

        expect(notification.isSuccess, isTrue);
      });

      test('should return false for other statuses', () {
        const pendingNotification = PaymentNotification(
          type: 'payment_status',
          paymentId: 'payment-123',
          status: PaymentStatus.pending,
        );
        expect(pendingNotification.isSuccess, isFalse);

        const failedNotification = PaymentNotification(
          type: 'payment_status',
          paymentId: 'payment-123',
          status: PaymentStatus.failed,
        );
        expect(failedNotification.isSuccess, isFalse);

        const expiredNotification = PaymentNotification(
          type: 'payment_status',
          paymentId: 'payment-123',
          status: PaymentStatus.expired,
        );
        expect(expiredNotification.isSuccess, isFalse);
      });

      test('should return false when status is null', () {
        const notification = PaymentNotification(
          type: 'subscribed',
          paymentId: 'payment-123',
        );

        expect(notification.isSuccess, isFalse);
      });
    });

    group('isFailed', () {
      test('should return true when status is failed', () {
        const notification = PaymentNotification(
          type: 'payment_status',
          paymentId: 'payment-123',
          status: PaymentStatus.failed,
        );

        expect(notification.isFailed, isTrue);
      });

      test('should return false for other statuses', () {
        const successNotification = PaymentNotification(
          type: 'payment_status',
          paymentId: 'payment-123',
          status: PaymentStatus.success,
        );
        expect(successNotification.isFailed, isFalse);

        const pendingNotification = PaymentNotification(
          type: 'payment_status',
          paymentId: 'payment-123',
          status: PaymentStatus.pending,
        );
        expect(pendingNotification.isFailed, isFalse);
      });

      test('should return false when status is null', () {
        const notification = PaymentNotification(
          type: 'subscribed',
          paymentId: 'payment-123',
        );

        expect(notification.isFailed, isFalse);
      });
    });
  });
}
