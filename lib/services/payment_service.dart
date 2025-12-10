import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/constants/api_constants.dart';
import '../models/booking.dart';
import '../models/payment.dart';
import 'api_service.dart';

/// Service for handling payments and WebSocket connections
class PaymentService {
  final ApiService _apiService;
  final FirebaseAuth _firebaseAuth;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  
  // Stream controller for payment notifications
  final _notificationController = StreamController<PaymentNotification>.broadcast();
  
  // Connection state
  bool _isConnected = false;
  String? _currentPaymentId;
  
  PaymentService({ApiService? apiService, FirebaseAuth? firebaseAuth})
      : _apiService = apiService ?? ApiService(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// Stream of payment notifications
  Stream<PaymentNotification> get notificationStream => _notificationController.stream;
  
  /// Check if WebSocket is connected
  bool get isConnected => _isConnected;

  /// Create a new booking
  /// If user is authenticated, the booking will be linked to their account
  Future<Booking> createBooking(CreateBookingRequest request) async {
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
      debugPrint('PaymentService: Creating booking with auth token (authenticated user)');
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
      final booking = Booking.fromJson(response['data'] as Map<String, dynamic>);
      debugPrint('PaymentService: Booking created successfully - ID: ${booking.id}');
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
      return CreatePaymentResponse.fromJson(response['data'] as Map<String, dynamic>);
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

  /// Query payment status (syncs with ZaloPay)
  Future<Payment> queryPaymentStatus(String paymentId) async {
    final response = await _apiService.get(ApiConstants.paymentStatus(paymentId));

    if (response['success'] == true && response['data'] != null) {
      return Payment.fromJson(response['data'] as Map<String, dynamic>);
    }
    
    throw ApiException(
      response['error']?['message'] ?? 'Failed to query payment status',
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

  /// Connect to WebSocket and subscribe to payment updates
  Future<void> connectAndSubscribe(String paymentId) async {
    await disconnect(); // Disconnect existing connection if any
    
    _currentPaymentId = paymentId;
    
    try {
      final wsUrl = ApiConstants.wsPayments;
      debugPrint('PaymentService: Connecting to WebSocket: $wsUrl');
      
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
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
        },
        onDone: () {
          debugPrint('PaymentService: WebSocket connection closed');
          _isConnected = false;
        },
      );
      
      // Subscribe to payment updates
      _subscribe(paymentId);
    } catch (e) {
      debugPrint('PaymentService: Failed to connect WebSocket: $e');
      _isConnected = false;
      rethrow;
    }
  }

  /// Subscribe to payment updates
  void _subscribe(String paymentId) {
    if (_channel == null || !_isConnected) return;
    
    final message = jsonEncode({
      'action': 'subscribe',
      'paymentId': paymentId,
    });
    
    debugPrint('PaymentService: Subscribing to payment: $paymentId');
    _channel!.sink.add(message);
  }

  /// Handle incoming WebSocket message
  void _handleMessage(dynamic message) {
    try {
      debugPrint('PaymentService: Received message: $message');
      
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final notification = PaymentNotification.fromJson(data);
      
      _notificationController.add(notification);
      
      if (notification.isPaymentStatus) {
        debugPrint('PaymentService: Payment status update - ${notification.status?.value}');
      }
    } catch (e) {
      debugPrint('PaymentService: Failed to parse message: $e');
    }
  }

  /// Send ping to keep connection alive
  void sendPing() {
    if (_channel == null || !_isConnected) return;
    
    final message = jsonEncode({'action': 'ping'});
    _channel!.sink.add(message);
  }

  /// Unsubscribe from payment updates
  void unsubscribe() {
    if (_channel == null || !_isConnected || _currentPaymentId == null) return;
    
    final message = jsonEncode({
      'action': 'unsubscribe',
      'paymentId': _currentPaymentId,
    });
    
    _channel!.sink.add(message);
  }

  /// Disconnect WebSocket
  Future<void> disconnect() async {
    _isConnected = false;
    _currentPaymentId = null;
    
    await _subscription?.cancel();
    _subscription = null;
    
    await _channel?.sink.close();
    _channel = null;
    
    debugPrint('PaymentService: Disconnected');
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _notificationController.close();
    _apiService.dispose();
  }
}

