import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smatch_badminton/models/court.dart';
import 'package:smatch_badminton/views/widgets/court_card.dart';

void main() {
  group('CourtCard', () {
    late Court testCourt;

    setUp(() {
      testCourt = const Court(
        id: 'court-123',
        name: 'Sân Cầu Lông Ngọc Khánh',
        description: 'A great badminton court',
        phoneNumbers: ['0912345678'],
        addressStreet: '123 Ngọc Khánh',
        addressWard: 'Phường Ngọc Khánh',
        addressDistrict: 'Quận Ba Đình',
        addressCity: 'Hà Nội',
        distance: 1500.0,
        openingHours: OpeningHours(
          mon: '06:00-22:00',
          tue: '06:00-22:00',
          wed: '06:00-22:00',
          thu: '06:00-22:00',
          fri: '06:00-22:00',
          sat: '07:00-23:00',
          sun: '08:00-20:00',
        ),
      );
    });

    Widget createWidget({
      Court? court,
      VoidCallback? onTap,
      VoidCallback? onDirectionsTap,
      VoidCallback? onCallTap,
      bool showDistance = true,
      bool showActions = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: CourtCard(
            court: court ?? testCourt,
            onTap: onTap,
            onDirectionsTap: onDirectionsTap,
            onCallTap: onCallTap,
            showDistance: showDistance,
            showActions: showActions,
          ),
        ),
      );
    }

    testWidgets('should display court name', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('Sân Cầu Lông Ngọc Khánh'), findsOneWidget);
    });

    testWidgets('should display district', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('Quận Ba Đình'), findsOneWidget);
    });

    testWidgets('should display formatted distance when showDistance is true', (tester) async {
      await tester.pumpWidget(createWidget(showDistance: true));

      expect(find.text('1.5km'), findsOneWidget);
    });

    testWidgets('should not display distance when showDistance is false', (tester) async {
      await tester.pumpWidget(createWidget(showDistance: false));

      expect(find.text('1.5km'), findsNothing);
    });

    testWidgets('should not display distance when court has no distance', (tester) async {
      const courtWithoutDistance = Court(
        id: 'court-456',
        name: 'Test Court',
        addressDistrict: 'Test District',
      );

      await tester.pumpWidget(createWidget(court: courtWithoutDistance));

      // Should only find the court name, not any distance
      expect(find.text('Test Court'), findsOneWidget);
    });

    testWidgets('should display opening hours when available', (tester) async {
      await tester.pumpWidget(createWidget());

      // Should show "Today: <hours>" text
      expect(find.textContaining('Today:'), findsOneWidget);
    });

    testWidgets('should not display opening hours when not available', (tester) async {
      const courtWithoutHours = Court(
        id: 'court-789',
        name: 'Court Without Hours',
        addressDistrict: 'Test District',
      );

      await tester.pumpWidget(createWidget(court: courtWithoutHours));

      expect(find.textContaining('Today:'), findsNothing);
    });

    testWidgets('should trigger onTap callback when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(createWidget(
        onTap: () => tapped = true,
      ));

      await tester.tap(find.byType(InkWell).first);
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('should display Directions button when onDirectionsTap provided', (tester) async {
      await tester.pumpWidget(createWidget(
        onDirectionsTap: () {},
      ));

      expect(find.text('Directions'), findsOneWidget);
    });

    testWidgets('should trigger onDirectionsTap callback when Directions button tapped', (tester) async {
      var directionsTapped = false;

      await tester.pumpWidget(createWidget(
        onDirectionsTap: () => directionsTapped = true,
      ));

      await tester.tap(find.text('Directions'));
      await tester.pump();

      expect(directionsTapped, isTrue);
    });

    testWidgets('should display Call button when phone numbers available and onCallTap provided', (tester) async {
      await tester.pumpWidget(createWidget(
        onCallTap: () {},
      ));

      expect(find.text('Call'), findsOneWidget);
    });

    testWidgets('should trigger onCallTap callback when Call button tapped', (tester) async {
      var callTapped = false;

      await tester.pumpWidget(createWidget(
        onCallTap: () => callTapped = true,
      ));

      await tester.tap(find.text('Call'));
      await tester.pump();

      expect(callTapped, isTrue);
    });

    testWidgets('should not display Call button when no phone numbers', (tester) async {
      const courtWithoutPhone = Court(
        id: 'court-101',
        name: 'Court Without Phone',
        addressDistrict: 'Test District',
        phoneNumbers: [],
      );

      await tester.pumpWidget(createWidget(
        court: courtWithoutPhone,
        onCallTap: () {},
      ));

      expect(find.text('Call'), findsNothing);
    });

    testWidgets('should not display action buttons when showActions is false', (tester) async {
      await tester.pumpWidget(createWidget(
        showActions: false,
        onDirectionsTap: () {},
        onCallTap: () {},
      ));

      expect(find.text('Directions'), findsNothing);
      expect(find.text('Call'), findsNothing);
    });

    testWidgets('should display badminton icon', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.byIcon(Icons.sports_tennis), findsWidgets);
    });

    testWidgets('should handle long court name with ellipsis', (tester) async {
      const courtWithLongName = Court(
        id: 'court-102',
        name: 'This is a very long court name that should be truncated with ellipsis to fit in the card',
        addressDistrict: 'Test District',
      );

      await tester.pumpWidget(createWidget(court: courtWithLongName));

      // Widget should build without errors
      expect(find.byType(CourtCard), findsOneWidget);
    });
  });
}

