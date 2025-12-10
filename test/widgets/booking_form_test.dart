import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smatch_badminton/models/availability.dart';
import 'package:smatch_badminton/models/court.dart';
import 'package:smatch_badminton/views/booking_confirmation_view.dart';

void main() {
  group('BookingConfirmationView', () {
    late Court testCourt;
    late List<CourtBookingSummary> testSummaries;

    setUp(() {
      testCourt = const Court(
        id: 'court-123',
        name: 'Test Court',
        addressDistrict: 'Test District',
      );
      
      testSummaries = [
        const CourtBookingSummary(
          subCourtIndex: 0,
          subCourtName: 'Court 1',
          timeRanges: [
            TimeRange(startHour: 10, startMinute: 0, endHour: 11, endMinute: 0),
          ],
          totalSlots: 2,
          totalPrice: 70000,
        ),
      ];
    });

    Widget createWidget() {
      return MaterialApp(
        home: BookingConfirmationView(
          court: testCourt,
          formattedDate: '20/01/2024',
          apiFormattedDate: '2024-01-20',
          summaries: testSummaries,
          totalPrice: 70000,
          totalDuration: '1h',
          subCourts: const [
            SubCourt(
              id: 'subcourt-1',
              name: 'Court 1',
              courtNumber: 1,
            ),
          ],
        ),
      );
    }

    group('Booking summary display', () {
      testWidgets('should display court name', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Test Court'), findsOneWidget);
      });

      testWidgets('should display formatted date', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('20/01/2024'), findsOneWidget);
      });

      testWidgets('should display total duration', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('1h'), findsAtLeastNWidgets(1));
      });

      testWidgets('should display sub court name in summary', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Court 1'), findsAtLeastNWidgets(1));
      });

      testWidgets('should display app bar title', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Confirm Booking'), findsOneWidget);
      });
    });

    group('Form fields display', () {
      testWidgets('should display name field with label', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Full Name *'), findsOneWidget);
      });

      testWidgets('should display phone field with label', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Phone Number *'), findsOneWidget);
      });

      testWidgets('should display email field with optional label', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Email (Optional)'), findsOneWidget);
      });

      testWidgets('should display required fields indicator', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('* Required fields'), findsOneWidget);
      });

      testWidgets('should display three text form fields', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.byType(TextFormField), findsNWidgets(3));
      });
    });

    group('Price Summary', () {
      testWidgets('should display Price Summary section', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Price Summary'), findsOneWidget);
      });

      testWidgets('should display slots count', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('2 slots × 30 min'), findsOneWidget);
      });
    });

    group('User input handling', () {
      testWidgets('should allow entering name', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final nameField = find.byType(TextFormField).first;
        await tester.enterText(nameField, 'Nguyễn Văn A');
        await tester.pump();

        expect(find.text('Nguyễn Văn A'), findsOneWidget);
      });

      testWidgets('should allow entering phone', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final phoneField = find.byType(TextFormField).at(1);
        await tester.enterText(phoneField, '0912345678');
        await tester.pump();

        expect(find.text('0912345678'), findsOneWidget);
      });

      testWidgets('should allow entering email', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final emailField = find.byType(TextFormField).at(2);
        await tester.enterText(emailField, 'test@example.com');
        await tester.pump();

        expect(find.text('test@example.com'), findsOneWidget);
      });
    });
  });
}
