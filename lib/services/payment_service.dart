import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/constants/api_constants.dart';
import '../models/booking.dart';
import '../models/payment.dart';
import 'api_service.dart';

typedef PaymentWebSocketFactory = WebSocketChannel Function(Uri uri);

/// Service for handling payments and WebSocket connections
class PaymentService {
  final ApiService _apiService;
  final FirebaseAuth _firebaseAuth;
  final PaymentWebSocketFactory _webSocketFactory;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  // Stream controller for payment notifications
  final _notificationController =
      StreamController<PaymentNotification>.broadcast();

  // Connection state
  bool _isConnected = false;
  bool _isClosingConnection = false;
  bool _terminalMessageReceived = false;
  bool _socketErrorMessageReceived = false;
  bool _connectionIssueReported = false;
  VoidCallback? _onConnectionInterrupted;

  PaymentService({
    ApiService? apiService,
    FirebaseAuth? firebaseAuth,
    PaymentWebSocketFactory? webSocketFactory,
  }) : _apiService = apiService ?? ApiService(),
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _webSocketFactory = webSocketFactory ?? WebSocketChannel.connect;

  /// Stream of payment notifications
  Stream<PaymentNotification> get notificationStream =>
      _notificationController.stream;

  /// Check if WebSocket is connected
  bool get isConnected => _isConnected;

  /// Create a new booking
  /// If user is authenticated, the booking will be linked to their account
  Future<Booking> createBooking(CreateBookingRequest request) async {
    final validationError = CreateBookingRequest.validateSubCourtId(
      request.subCourtId,
    );
    if (validationError != null) {
      throw ApiException(validationError);
    }

    var authToken = ApiService.globalAuthToken;

    // Ensure we have a token if a user is logged in (including anonymous)
    if (authToken == null) {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        authToken = await user.getIdToken();
        ApiService.setGlobalAuthToken(authToken);
      }
    }

    // Debug logging to verify authentication
    if (authToken != null) {
      debugPrint(
        'PaymentService: Creating booking with auth token (authenticated user)',
      );
    } else {
      debugPrint('PaymentService: Creating booking WITHOUT auth token (guest)');
    }

    final Map<String, dynamic> response;
    if (authToken != null) {
      // Authenticated request - booking will be linked to user
      response = await _apiService.postWithAuth(
        ApiConstants.bookings,
        authToken: authToken,
        body: request.toJson(),
      );
    } else {
      // Unauthenticated request (fallback)
      response = await _apiService.post(
        ApiConstants.bookings,
        body: request.toJson(),
      );
    }

    if (response['success'] == true && response['data'] != null) {
      final booking = Booking.fromJson(
        response['data'] as Map<String, dynamic>,
      );
      debugPrint(
        'PaymentService: Booking created successfully - ID: ${booking.id}',
      );
      return booking;
    }

    throw ApiException(
      response['error']?['message'] ?? 'Failed to create booking',
    );
  }

  /// Create a payment for a booking
  Future<CreatePaymentResponse> createPayment(String bookingId) async {
    final response = await _apiService.post(
      ApiConstants.paymentsCreate,
      body: {'bookingId': bookingId},
    );

    if (response['success'] == true && response['data'] != null) {
      return CreatePaymentResponse.fromJson(
        response['data'] as Map<String, dynamic>,
      );
    }

    throw ApiException(
      response['error']?['message'] ?? 'Failed to create payment',
    );
  }

  /// Get payment by ID
  Future<Payment> getPayment(String paymentId) async {
    final response = await _apiService.get(ApiConstants.paymentById(paymentId));

    if (response['success'] == true && response['data'] != null) {
      return Payment.fromJson(response['data'] as Map<String, dynamic>);
    }

    throw ApiException(
      response['error']?['message'] ?? 'Failed to get payment',
    );
  }

  /// Get booking by ID
  Future<Booking> getBooking(String bookingId) async {
    final response = await _apiService.get(ApiConstants.bookingById(bookingId));

    if (response['success'] == true && response['data'] != null) {
      return Booking.fromJson(response['data'] as Map<String, dynamic>);
    }

    throw ApiException(
      response['error']?['message'] ?? 'Failed to get booking',
    );
  }

  /// Connect directly to the backend-provided payment WebSocket URL.
  Future<void> connectToPaymentUpdates({
    required String paymentId,
    required String wsSubscribeUrl,
    VoidCallback? onConnectionInterrupted,
  }) async {
    await disconnect(); // Disconnect existing connection if any

    if (wsSubscribeUrl.isEmpty) {
      throw ApiException('Missing payment websocket URL');
    }

    _terminalMessageReceived = false;
    _socketErrorMessageReceived = false;
    _connectionIssueReported = false;
    _onConnectionInterrupted = onConnectionInterrupted;

    try {
      debugPrint('PaymentService: Connecting to WebSocket: $wsSubscribeUrl');

      _channel = _webSocketFactory(Uri.parse(wsSubscribeUrl));

      // Wait for connection to be ready
      await _channel!.ready;
      _isConnected = true;
      debugPrint('PaymentService: WebSocket connected');

      // Listen for messages
      _subscription = _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          debugPrint('PaymentService: WebSocket error: $error');
          _isConnected = false;
          _reportConnectionInterrupted();
        },
        onDone: () {
          debugPrint('PaymentService: WebSocket connection closed');
          _isConnected = false;
          if (!_isClosingConnection &&
              !_terminalMessageReceived &&
              !_socketErrorMessageReceived) {
            _reportConnectionInterrupted();
          }
        },
      );
    } catch (e) {
      debugPrint('PaymentService: Failed to connect WebSocket: $e');
      _isConnected = false;
      rethrow;
    }
  }

  /// Handle incoming WebSocket message
  void _handleMessage(dynamic message) {
    try {
      debugPrint('PaymentService: Received message: $message');

      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final notification = PaymentNotification.fromJson(data);
      if (notification.isTerminal) {
        _terminalMessageReceived = true;
      }
      if (notification.isError) {
        _socketErrorMessageReceived = true;
      }

      _notificationController.add(notification);

      if (notification.isPaymentStatus) {
        debugPrint(
          'PaymentService: Payment status update - ${notification.status?.value}',
        );
      }
    } catch (e) {
      debugPrint('PaymentService: Failed to parse message: $e');
    }
  }

  void _reportConnectionInterrupted() {
    if (_connectionIssueReported) return;
    _connectionIssueReported = true;
    _onConnectionInterrupted?.call();
  }

  /// Disconnect WebSocket
  Future<void> disconnect() async {
    _isClosingConnection = true;
    _isConnected = false;
    _onConnectionInterrupted = null;

    await _subscription?.cancel();
    _subscription = null;

    await _channel?.sink.close();
    _channel = null;
    _isClosingConnection = false;
    _terminalMessageReceived = false;
    _socketErrorMessageReceived = false;
    _connectionIssueReported = false;

    debugPrint('PaymentService: Disconnected');
  }

  /// Dispose resources
  void dispose() {
    unawaited(disconnect());
    _notificationController.close();
    _apiService.dispose();
  }
}
