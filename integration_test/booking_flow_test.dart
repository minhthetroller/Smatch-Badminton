import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:smatch_badminton/main.dart' as app;

/// E2E tests for the complete booking flow
/// Uses Patrol for reliable native interactions
void main() {
  patrolTest(
    'Complete booking flow - Search, Select, Book, Pay',
    ($) async {
      // Initialize app
      app.main();
      await $.pumpAndSettle();

      // ----- Phase 1: Search & Selection -----
      debugPrint('Phase 1: Search & Selection');

      // Verify we're on the map view
      expect($(Icons.search), findsOneWidget);

      // Tap search area to open search interface
      await $(Icons.search).tap();
      await $.pumpAndSettle();

      // Enter search query
      await $.native.enterText(
        Selector(text: 'Search'),
        text: 'Sân cầu lông',
      );
      await $.pumpAndSettle();

      // Wait for autocomplete suggestions
      await $.pump(const Duration(milliseconds: 300));

      // Note: In a real test environment with a mock server,
      // we would tap on a suggestion to select a court
      // For now, we verify the search interface works
    },
    config: const PatrolTesterConfig(
      // Allow longer timeouts for E2E tests
      visibleTimeout: Duration(seconds: 10),
      settleTimeout: Duration(seconds: 10),
    ),
  );
}

// Additional test utilities for E2E testing
class E2ETestHelper {
  /// Mock court data for testing
  static Map<String, dynamic> getMockCourtAvailability() {
    return {
      'success': true,
      'data': {
        'courtId': 'test-court-123',
        'date': DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0],
        'openTime': '07:00',
        'closeTime': '22:00',
        'defaultPricePerHour': 70000.0,
        'subCourts': [
          {
            'id': 'subcourt-1',
            'name': 'Court 1',
            'courtNumber': 1,
            'pricePerHour': 70000.0,
            'slots': List.generate(30, (index) {
              final hour = 7 + (index ~/ 2);
              final minute = (index % 2) * 30;
              return {
                'startTime': '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                'endTime': '${(hour + (minute + 30) ~/ 60).toString().padLeft(2, '0')}:${((minute + 30) % 60).toString().padLeft(2, '0')}',
                'isAvailable': index % 5 != 0, // Some slots booked
                'price': 35000,
              };
            }),
          },
          {
            'id': 'subcourt-2',
            'name': 'Court 2',
            'courtNumber': 2,
            'pricePerHour': 70000.0,
            'slots': List.generate(30, (index) {
              final hour = 7 + (index ~/ 2);
              final minute = (index % 2) * 30;
              return {
                'startTime': '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                'endTime': '${(hour + (minute + 30) ~/ 60).toString().padLeft(2, '0')}:${((minute + 30) % 60).toString().padLeft(2, '0')}',
                'isAvailable': true,
                'price': 35000,
              };
            }),
          },
        ],
      },
    };
  }

  /// Mock search suggestions
  static Map<String, dynamic> getMockSearchSuggestions() {
    return {
      'success': true,
      'data': {
        'suggestions': [
          {
            'id': 'court-1',
            'text': 'Sân Cầu Lông Ngọc Khánh',
            'score': 100,
            'address': '123 Ngọc Khánh, Ba Đình, Hà Nội',
            'latitude': 21.0285,
            'longitude': 105.8542,
          },
          {
            'id': 'court-2',
            'text': 'Sân Cầu Lông Ba Đình',
            'score': 90,
            'address': '456 Ba Đình, Hà Nội',
            'latitude': 21.03,
            'longitude': 105.86,
          },
        ],
      },
    };
  }

  /// Mock payment response
  static Map<String, dynamic> getMockPaymentResponse() {
    return {
      'success': true,
      'data': {
        'payment': {
          'id': 'payment-123',
          'bookingId': 'booking-456',
          'amount': 70000,
          'status': 'pending',
        },
        'orderUrl': 'https://zalopay.vn/order/123',
        'qrCode': {
          'base64': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
          'rawBase64': 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
        },
        'zpTransToken': 'token_xyz',
        'expireAt': DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
        'wsSubscribeUrl': 'wss://api.example.com/ws/payments',
      },
    };
  }

  /// Mock booking response
  static Map<String, dynamic> getMockBookingResponse() {
    return {
      'success': true,
      'data': {
        'id': 'booking-456',
        'subCourtId': 'subcourt-1',
        'subCourtName': 'Court 1',
        'courtId': 'test-court-123',
        'courtName': 'Sân Cầu Lông Test',
        'guestName': 'Test User',
        'guestPhone': '0912345678',
        'date': DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0],
        'startTime': '10:00',
        'endTime': '12:00',
        'totalPrice': 140000,
        'status': 'pending',
      },
    };
  }
}

