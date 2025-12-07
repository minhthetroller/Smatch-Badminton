import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import '../models/booking.dart';
import '../models/payment.dart';
import '../services/payment_service.dart';

/// View state for the payment screen
enum PaymentViewState {
  initial,
  creatingBooking,
  creatingPayment,
  waitingForPayment,
  paymentSuccess,
  paymentFailed,
  paymentExpired,
  error,
}

/// Simple booking request for a single sub-court
class BookingRequest {
  final String subCourtId;
  final String startTime;
  final String endTime;

  const BookingRequest({
    required this.subCourtId,
    required this.startTime,
    required this.endTime,
  });
}

/// ViewModel for the payment view
class PaymentViewModel extends ChangeNotifier {
  final PaymentService _paymentService;
  
  // State
  PaymentViewState _state = PaymentViewState.initial;
  String? _errorMessage;
  Booking? _booking;
  List<Booking> _bookings = []; // All bookings for multiple courts
  CreatePaymentResponse? _paymentResponse;
  PaymentNotification? _lastNotification;
  
  // Countdown timer
  Timer? _countdownTimer;
  Duration _remainingTime = Duration.zero;
  
  // WebSocket subscription
  StreamSubscription<PaymentNotification>? _notificationSubscription;
  
  // Polling timer (fallback for WebSocket issues)
  Timer? _pollingTimer;
  
  // Store booking requests for retry
  List<BookingRequest>? _pendingBookingRequests;
  String? _pendingGuestName;
  String? _pendingGuestPhone;
  String? _pendingGuestEmail;
  String? _pendingDate;
  
  PaymentViewModel({PaymentService? paymentService})
      : _paymentService = paymentService ?? PaymentService();

  // Getters
  PaymentViewState get state => _state;
  String? get errorMessage => _errorMessage;
  Booking? get booking => _booking;
  List<Booking> get bookings => _bookings;
  CreatePaymentResponse? get paymentResponse => _paymentResponse;
  PaymentNotification? get lastNotification => _lastNotification;
  Duration get remainingTime => _remainingTime;
  Payment? get payment => _paymentResponse?.payment;
  
  /// Get QR code as bytes for Image.memory()
  Uint8List? get qrCodeBytes {
    final rawBase64 = _paymentResponse?.qrCode.rawBase64;
    if (rawBase64 == null) return null;
    
    try {
      return base64Decode(rawBase64);
    } catch (e) {
      debugPrint('PaymentViewModel: Failed to decode QR code: $e');
      return null;
    }
  }
  
  /// Get formatted remaining time (mm:ss)
  String get formattedRemainingTime {
    final minutes = _remainingTime.inMinutes;
    final seconds = _remainingTime.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  /// Check if payment is still active (not expired/failed/success)
  bool get isPaymentActive {
    return _state == PaymentViewState.waitingForPayment;
  }

  /// Initialize payment flow - create booking and payment
  Future<void> initializePayment({
    required String subCourtId,
    required String guestName,
    required String guestPhone,
    String? guestEmail,
    required String date,
    required String startTime,
    required String endTime,
    String? notes,
  }) async {
    _state = PaymentViewState.creatingBooking;
    _errorMessage = null;
    notifyListeners();

    try {
      // Step 1: Create booking
      final request = CreateBookingRequest(
        subCourtId: subCourtId,
        guestName: guestName,
        guestPhone: guestPhone,
        guestEmail: guestEmail,
        date: date,
        startTime: startTime,
        endTime: endTime,
        notes: notes,
      );

      debugPrint('PaymentViewModel: Creating booking...');
      _booking = await _paymentService.createBooking(request);
      debugPrint('PaymentViewModel: Booking created: ${_booking!.id}');

      // Step 2: Create payment
      _state = PaymentViewState.creatingPayment;
      notifyListeners();

      debugPrint('PaymentViewModel: Creating payment...');
      _paymentResponse = await _paymentService.createPayment(_booking!.id);
      debugPrint('PaymentViewModel: Payment created: ${_paymentResponse!.payment.id}');

      // Step 3: Connect to WebSocket for real-time updates
      _state = PaymentViewState.waitingForPayment;
      notifyListeners();

      await _connectWebSocket();
      _startCountdown();
      _startPolling(); // Fallback polling

    } catch (e) {
      debugPrint('PaymentViewModel: Error: $e');
      _state = PaymentViewState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Initialize payment flow for multiple courts
  /// Creates bookings for ALL selected courts, then creates a single payment
  Future<void> initializePaymentForMultipleCourts({
    required List<BookingRequest> bookingRequests,
    required String guestName,
    required String guestPhone,
    String? guestEmail,
    required String date,
    String? notes,
  }) async {
    if (bookingRequests.isEmpty) {
      _state = PaymentViewState.error;
      _errorMessage = 'No courts selected for booking.';
      notifyListeners();
      return;
    }

    // Store for retry
    _pendingBookingRequests = bookingRequests;
    _pendingGuestName = guestName;
    _pendingGuestPhone = guestPhone;
    _pendingGuestEmail = guestEmail;
    _pendingDate = date;

    _state = PaymentViewState.creatingBooking;
    _errorMessage = null;
    _bookings = [];
    notifyListeners();

    try {
      // Step 1: Create bookings for ALL selected courts
      for (final request in bookingRequests) {
        final bookingRequest = CreateBookingRequest(
          subCourtId: request.subCourtId,
          guestName: guestName,
          guestPhone: guestPhone,
          guestEmail: guestEmail,
          date: date,
          startTime: request.startTime,
          endTime: request.endTime,
          notes: notes,
        );

        debugPrint('PaymentViewModel: Creating booking for court ${request.subCourtId}...');
        final booking = await _paymentService.createBooking(bookingRequest);
        _bookings.add(booking);
        debugPrint('PaymentViewModel: Booking created: ${booking.id}');
      }

      // Use the first booking as the primary (for backward compatibility)
      _booking = _bookings.first;

      // Step 2: Create payment for the first booking
      // Note: If the backend supports multi-booking payments, this should be updated
      _state = PaymentViewState.creatingPayment;
      notifyListeners();

      debugPrint('PaymentViewModel: Creating payment for booking ${_booking!.id}...');
      _paymentResponse = await _paymentService.createPayment(_booking!.id);
      debugPrint('PaymentViewModel: Payment created: ${_paymentResponse!.payment.id}');

      // Step 3: Connect to WebSocket for real-time updates
      _state = PaymentViewState.waitingForPayment;
      notifyListeners();

      await _connectWebSocket();
      _startCountdown();
      _startPolling(); // Fallback polling

    } catch (e) {
      debugPrint('PaymentViewModel: Error: $e');
      _state = PaymentViewState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Connect to WebSocket and listen for payment updates
  Future<void> _connectWebSocket() async {
    if (_paymentResponse == null) return;

    try {
      // Subscribe to notifications
      _notificationSubscription = _paymentService.notificationStream.listen(
        _handleNotification,
        onError: (error) {
          debugPrint('PaymentViewModel: Notification stream error: $error');
        },
      );

      // Connect to WebSocket
      await _paymentService.connectAndSubscribe(_paymentResponse!.payment.id);
    } catch (e) {
      debugPrint('PaymentViewModel: WebSocket connection failed: $e');
      // Continue with polling fallback
    }
  }

  /// Handle payment notification from WebSocket
  void _handleNotification(PaymentNotification notification) {
    debugPrint('PaymentViewModel: Received notification: ${notification.type}');
    _lastNotification = notification;

    if (notification.isPaymentStatus) {
      if (notification.isSuccess) {
        _handlePaymentSuccess();
      } else if (notification.isFailed) {
        _handlePaymentFailed(notification.message);
      }
    }

    notifyListeners();
  }

  /// Handle successful payment
  void _handlePaymentSuccess() {
    debugPrint('PaymentViewModel: Payment successful!');
    _stopTimers();
    _state = PaymentViewState.paymentSuccess;
    notifyListeners();
  }

  /// Handle failed payment
  void _handlePaymentFailed(String? message) {
    debugPrint('PaymentViewModel: Payment failed: $message');
    _stopTimers();
    _state = PaymentViewState.paymentFailed;
    _errorMessage = message ?? 'Payment failed. Please try again.';
    notifyListeners();
  }

  /// Start countdown timer
  void _startCountdown() {
    if (_paymentResponse == null) return;

    final expireAt = _paymentResponse!.expireAt;
    _updateRemainingTime(expireAt);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemainingTime(expireAt);
      
      if (_remainingTime.isNegative || _remainingTime == Duration.zero) {
        _handlePaymentExpired();
      }
    });
  }

  /// Update remaining time
  void _updateRemainingTime(DateTime expireAt) {
    final now = DateTime.now();
    _remainingTime = expireAt.difference(now);
    
    if (_remainingTime.isNegative) {
      _remainingTime = Duration.zero;
    }
    
    notifyListeners();
  }

  /// Handle payment expiration
  void _handlePaymentExpired() {
    debugPrint('PaymentViewModel: Payment expired');
    _stopTimers();
    _state = PaymentViewState.paymentExpired;
    _errorMessage = 'Payment time expired. Please try again.';
    notifyListeners();
  }

  /// Start polling as fallback for WebSocket issues
  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!isPaymentActive) {
        timer.cancel();
        return;
      }

      try {
        final payment = await _paymentService.queryPaymentStatus(
          _paymentResponse!.payment.id,
        );

        if (payment.status == PaymentStatus.success) {
          _handlePaymentSuccess();
        } else if (payment.status == PaymentStatus.failed) {
          _handlePaymentFailed('Payment failed');
        } else if (payment.status == PaymentStatus.expired) {
          _handlePaymentExpired();
        }
      } catch (e) {
        debugPrint('PaymentViewModel: Polling error: $e');
      }
    });
  }

  /// Stop all timers
  void _stopTimers() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Retry payment (create new bookings and payment)
  Future<void> retryPayment() async {
    // If we have pending requests, recreate all bookings
    if (_pendingBookingRequests != null && 
        _pendingGuestName != null && 
        _pendingGuestPhone != null && 
        _pendingDate != null) {
      await initializePaymentForMultipleCourts(
        bookingRequests: _pendingBookingRequests!,
        guestName: _pendingGuestName!,
        guestPhone: _pendingGuestPhone!,
        guestEmail: _pendingGuestEmail,
        date: _pendingDate!,
      );
      return;
    }

    // Fallback: if we have an existing booking, just create a new payment
    if (_booking == null) {
      _errorMessage = 'No booking found. Please start over.';
      notifyListeners();
      return;
    }

    _state = PaymentViewState.creatingPayment;
    _errorMessage = null;
    notifyListeners();

    try {
      _paymentResponse = await _paymentService.createPayment(_booking!.id);
      _state = PaymentViewState.waitingForPayment;
      
      await _connectWebSocket();
      _startCountdown();
      _startPolling();
      
    } catch (e) {
      debugPrint('PaymentViewModel: Retry error: $e');
      _state = PaymentViewState.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  /// Refresh payment status manually
  Future<void> refreshPaymentStatus() async {
    if (_paymentResponse == null) return;

    try {
      final payment = await _paymentService.queryPaymentStatus(
        _paymentResponse!.payment.id,
      );

      if (payment.status == PaymentStatus.success) {
        _handlePaymentSuccess();
      } else if (payment.status == PaymentStatus.failed) {
        _handlePaymentFailed('Payment failed');
      } else if (payment.status == PaymentStatus.expired) {
        _handlePaymentExpired();
      }
    } catch (e) {
      debugPrint('PaymentViewModel: Refresh error: $e');
    }
  }

  @override
  void dispose() {
    _stopTimers();
    _notificationSubscription?.cancel();
    _paymentService.disconnect();
    super.dispose();
  }
}

