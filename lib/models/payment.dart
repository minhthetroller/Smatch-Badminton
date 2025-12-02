/// Model representing a payment response from the API
class Payment {
  final String id;
  final String bookingId;
  final String? appTransId;
  final String? zpTransId;
  final int amount;
  final PaymentStatus status;
  final String? orderUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Payment({
    required this.id,
    required this.bookingId,
    this.appTransId,
    this.zpTransId,
    required this.amount,
    required this.status,
    this.orderUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      bookingId: json['bookingId'] as String,
      appTransId: json['appTransId'] as String?,
      zpTransId: json['zpTransId'] as String?,
      amount: json['amount'] as int,
      status: PaymentStatus.fromString(json['status'] as String),
      orderUrl: json['orderUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'appTransId': appTransId,
      'zpTransId': zpTransId,
      'amount': amount,
      'status': status.value,
      'orderUrl': orderUrl,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

/// Payment status enum
enum PaymentStatus {
  pending('pending'),
  success('success'),
  failed('failed'),
  expired('expired');

  final String value;
  const PaymentStatus(this.value);

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PaymentStatus.pending,
    );
  }
}

/// QR Code data from payment creation
class QrCodeData {
  final String base64;
  final String rawBase64;

  const QrCodeData({
    required this.base64,
    required this.rawBase64,
  });

  factory QrCodeData.fromJson(Map<String, dynamic> json) {
    return QrCodeData(
      base64: json['base64'] as String,
      rawBase64: json['rawBase64'] as String,
    );
  }
}

/// Response model for payment creation
class CreatePaymentResponse {
  final Payment payment;
  final String orderUrl;
  final QrCodeData qrCode;
  final String? zpTransToken;
  final DateTime expireAt;
  final String wsSubscribeUrl;

  const CreatePaymentResponse({
    required this.payment,
    required this.orderUrl,
    required this.qrCode,
    this.zpTransToken,
    required this.expireAt,
    required this.wsSubscribeUrl,
  });

  factory CreatePaymentResponse.fromJson(Map<String, dynamic> json) {
    return CreatePaymentResponse(
      payment: Payment.fromJson(json['payment'] as Map<String, dynamic>),
      orderUrl: json['orderUrl'] as String,
      qrCode: QrCodeData.fromJson(json['qrCode'] as Map<String, dynamic>),
      zpTransToken: json['zpTransToken'] as String?,
      expireAt: DateTime.parse(json['expireAt'] as String),
      wsSubscribeUrl: json['wsSubscribeUrl'] as String,
    );
  }
}

/// WebSocket payment notification message
class PaymentNotification {
  final String type;
  final String paymentId;
  final PaymentStatus? status;
  final String? bookingId;
  final String? zpTransId;
  final String? message;

  const PaymentNotification({
    required this.type,
    required this.paymentId,
    this.status,
    this.bookingId,
    this.zpTransId,
    this.message,
  });

  factory PaymentNotification.fromJson(Map<String, dynamic> json) {
    return PaymentNotification(
      type: json['type'] as String,
      paymentId: json['paymentId'] as String,
      status: json['status'] != null
          ? PaymentStatus.fromString(json['status'] as String)
          : null,
      bookingId: json['bookingId'] as String?,
      zpTransId: json['zpTransId'] as String?,
      message: json['message'] as String?,
    );
  }

  bool get isPaymentStatus => type == 'payment_status';
  bool get isSubscribed => type == 'subscribed';
  bool get isSuccess => status == PaymentStatus.success;
  bool get isFailed => status == PaymentStatus.failed;
}

