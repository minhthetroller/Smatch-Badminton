import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:smatch_badminton/models/availability.dart';
import 'package:smatch_badminton/models/court.dart';
import 'package:smatch_badminton/repositories/court_repository.dart';
import 'package:smatch_badminton/view_models/booking_view_model.dart';

import 'booking_view_model_test.mocks.dart';

@GenerateMocks([CourtRepository])
void main() {
  late MockCourtRepository mockCourtRepository;
  late BookingViewModel viewModel;
  late Court testCourt;

  setUp(() {
    mockCourtRepository = MockCourtRepository();
    testCourt = const Court(
      id: 'court-123',
      name: 'Sân Cầu Lông Ngọc Khánh',
      addressDistrict: 'Ba Đình',
      addressCity: 'Hà Nội',
    );
    viewModel = BookingViewModel(
      court: testCourt,
      courtRepository: mockCourtRepository,
    );
  });

  group('BookingViewModel', () {
    group('initial state', () {
      test('should have correct initial state', () {
        expect(viewModel.state, BookingViewState.initial);
        expect(viewModel.court, testCourt);
        expect(viewModel.selectedSubCourtIndex, 0);
        expect(viewModel.selection.isEmpty, isTrue);
        expect(viewModel.totalPrice, 0);
      });

      test('should format date correctly', () {
        expect(viewModel.formattedDate, isNotEmpty);
        expect(viewModel.apiFormattedDate, matches(RegExp(r'\d{4}-\d{2}-\d{2}')));
      });
    });

    group('loadAvailability', () {
      test('should set loading state then loaded state', () async {
        when(mockCourtRepository.fetchCourtAvailability(
          courtId: anyNamed('courtId'),
          date: anyNamed('date'),
        )).thenAnswer((_) async => CourtAvailability(
              courtId: 'court-123',
              date: viewModel.apiFormattedDate,
              openTime: '07:00',
              closeTime: '22:00',
              subCourts: [
                const SubCourt(
                  id: 'sc-1',
                  name: 'Court 1',
                  courtNumber: 1,
                  timeSlots: [
                    TimeSlot(startTime: '07:00', endTime: '07:30', isBooked: false, price: 35000),
                    TimeSlot(startTime: '07:30', endTime: '08:00', isBooked: true, price: 35000),
                  ],
                ),
              ],
            ));

        await viewModel.loadAvailability();

        expect(viewModel.state, BookingViewState.loaded);
        expect(viewModel.availability, isNotNull);
        expect(viewModel.subCourts.length, 1);
      });

      test('should generate mock data on API error', () async {
        when(mockCourtRepository.fetchCourtAvailability(
          courtId: anyNamed('courtId'),
          date: anyNamed('date'),
        )).thenThrow(Exception('Network error'));

        await viewModel.loadAvailability();

        // Should still be loaded with mock data
        expect(viewModel.state, BookingViewState.loaded);
        expect(viewModel.availability, isNotNull);
        expect(viewModel.subCourts, isNotEmpty);
      });

      test('should set operating hours from availability', () async {
        when(mockCourtRepository.fetchCourtAvailability(
          courtId: anyNamed('courtId'),
          date: anyNamed('date'),
        )).thenAnswer((_) async => const CourtAvailability(
              courtId: 'court-123',
              date: '2024-01-20',
              openTime: '06:00',
              closeTime: '23:00',
            ));

        await viewModel.loadAvailability();

        expect(viewModel.openHour, 6);
        expect(viewModel.closeHour, 23);
      });
    });

    group('selectSubCourt', () {
      test('should update selected sub court index', () async {
        when(mockCourtRepository.fetchCourtAvailability(
          courtId: anyNamed('courtId'),
          date: anyNamed('date'),
        )).thenAnswer((_) async => const CourtAvailability(
              courtId: 'court-123',
              date: '2024-01-20',
              openTime: '07:00',
              closeTime: '22:00',
              subCourts: [
                SubCourt(id: 'sc-1', name: 'Court 1', courtNumber: 1),
                SubCourt(id: 'sc-2', name: 'Court 2', courtNumber: 2),
              ],
            ));

        await viewModel.loadAvailability();
        viewModel.selectSubCourt(1);

        expect(viewModel.selectedSubCourtIndex, 1);
        expect(viewModel.selectedSubCourt?.name, 'Court 2');
      });

      test('should not update for invalid index', () async {
        when(mockCourtRepository.fetchCourtAvailability(
          courtId: anyNamed('courtId'),
          date: anyNamed('date'),
        )).thenAnswer((_) async => const CourtAvailability(
              courtId: 'court-123',
              date: '2024-01-20',
              openTime: '07:00',
              closeTime: '22:00',
              subCourts: [
                SubCourt(id: 'sc-1', name: 'Court 1', courtNumber: 1),
              ],
            ));

        await viewModel.loadAvailability();
        viewModel.selectSubCourt(5);

        expect(viewModel.selectedSubCourtIndex, 0);
      });
    });

    group('selectDate', () {
      test('should update date and reload availability', () async {
        when(mockCourtRepository.fetchCourtAvailability(
          courtId: anyNamed('courtId'),
          date: anyNamed('date'),
        )).thenAnswer((_) async => const CourtAvailability(
              courtId: 'court-123',
              date: '2024-01-21',
              openTime: '07:00',
              closeTime: '22:00',
            ));

        final newDate = DateTime.now().add(const Duration(days: 3));
        await viewModel.selectDate(newDate);

        expect(viewModel.selectedDate, newDate);
        verify(mockCourtRepository.fetchCourtAvailability(
          courtId: 'court-123',
          date: anyNamed('date'),
        )).called(1);
      });

      test('should clear selections when changing date', () async {
        // First select a future date to avoid isSlotPassed issues
        final futureDate = DateTime.now().add(const Duration(days: 7));
        
        when(mockCourtRepository.fetchCourtAvailability(
          courtId: anyNamed('courtId'),
          date: anyNamed('date'),
        )).thenAnswer((_) async => const CourtAvailability(
              courtId: 'court-123',
              date: '2024-01-27',
              openTime: '07:00',
              closeTime: '22:00',
              subCourts: [
                SubCourt(
                  id: 'sc-1',
                  name: 'Court 1',
                  courtNumber: 1,
                  timeSlots: [
                    TimeSlot(startTime: '10:00', endTime: '10:30', isBooked: false, price: 35000),
                  ],
                ),
              ],
            ));

        await viewModel.selectDate(futureDate);
        viewModel.toggleSlotSelection(0, 10, 0);

        expect(viewModel.selection.isNotEmpty, isTrue);

        await viewModel.selectDate(DateTime.now().add(const Duration(days: 8)));

        expect(viewModel.selection.isEmpty, isTrue);
      });
    });

    group('slot selection', () {
      setUp(() async {
        // Configure mock FIRST before calling selectDate
        when(mockCourtRepository.fetchCourtAvailability(
          courtId: anyNamed('courtId'),
          date: anyNamed('date'),
        )).thenAnswer((_) async => const CourtAvailability(
              courtId: 'court-123',
              date: '2024-01-27',
              openTime: '07:00',
              closeTime: '22:00',
              subCourts: [
                SubCourt(
                  id: 'sc-1',
                  name: 'Court 1',
                  courtNumber: 1,
                  timeSlots: [
                    TimeSlot(startTime: '10:00', endTime: '10:30', isBooked: false, price: 35000),
                    TimeSlot(startTime: '10:30', endTime: '11:00', isBooked: false, price: 35000),
                    TimeSlot(startTime: '11:00', endTime: '11:30', isBooked: true, price: 35000),
                    TimeSlot(startTime: '11:30', endTime: '12:00', isBooked: false, price: 35000),
                  ],
                ),
                SubCourt(
                  id: 'sc-2',
                  name: 'Court 2',
                  courtNumber: 2,
                  timeSlots: [
                    TimeSlot(startTime: '10:00', endTime: '10:30', isBooked: false, price: 40000),
                    TimeSlot(startTime: '10:30', endTime: '11:00', isBooked: false, price: 40000),
                  ],
                ),
              ],
            ));

        // Use a future date to avoid isSlotPassed issues
        final futureDate = DateTime.now().add(const Duration(days: 7));
        await viewModel.selectDate(futureDate);
      });

      test('should toggle slot selection', () {
        viewModel.toggleSlotSelection(0, 10, 0);

        expect(viewModel.isSlotSelected(0, 10, 0), isTrue);
        expect(viewModel.selection.slotCount, 1);
      });

      test('should deselect slot when toggled again', () {
        viewModel.toggleSlotSelection(0, 10, 0);
        viewModel.toggleSlotSelection(0, 10, 0);

        expect(viewModel.isSlotSelected(0, 10, 0), isFalse);
        expect(viewModel.selection.isEmpty, isTrue);
      });

      test('should not select booked slots', () {
        viewModel.toggleSlotSelection(0, 11, 0);

        expect(viewModel.isSlotSelected(0, 11, 0), isFalse);
      });

      test('should calculate total price correctly', () {
        // Select 2 slots from Court 1 (35000 each)
        viewModel.toggleSlotSelection(0, 10, 0);
        viewModel.toggleSlotSelection(0, 10, 30);

        expect(viewModel.totalPrice, 70000);
      });

      test('should calculate price for multiple courts', () {
        // Select 2 slots from Court 1 (35000 each)
        viewModel.toggleSlotSelection(0, 10, 0);
        viewModel.toggleSlotSelection(0, 10, 30);
        // Select 2 slots from Court 2 (40000 each)
        viewModel.toggleSlotSelection(1, 10, 0);
        viewModel.toggleSlotSelection(1, 10, 30);

        expect(viewModel.totalPrice, 150000); // 70000 + 80000
        expect(viewModel.selectedCourtCount, 2);
        expect(viewModel.selectedSlotCount, 4);
      });

      test('should format duration correctly', () {
        viewModel.toggleSlotSelection(0, 10, 0);
        viewModel.toggleSlotSelection(0, 10, 30);

        expect(viewModel.totalDurationFormatted, '1h');
      });
    });

    group('slot availability checks', () {
      setUp(() async {
        // Configure mock FIRST before calling selectDate
        when(mockCourtRepository.fetchCourtAvailability(
          courtId: anyNamed('courtId'),
          date: anyNamed('date'),
        )).thenAnswer((_) async => const CourtAvailability(
              courtId: 'court-123',
              date: '2024-01-27',
              openTime: '07:00',
              closeTime: '22:00',
              subCourts: [
                SubCourt(
                  id: 'sc-1',
                  name: 'Court 1',
                  courtNumber: 1,
                  timeSlots: [
                    TimeSlot(startTime: '10:00', endTime: '10:30', isBooked: false, price: 35000),
                    TimeSlot(startTime: '11:00', endTime: '11:30', isBooked: true, price: 35000),
                  ],
                ),
              ],
            ));

        // Use a future date to avoid isSlotPassed issues
        final futureDate = DateTime.now().add(const Duration(days: 7));
        await viewModel.selectDate(futureDate);
      });

      test('should check if slot is booked', () {
        expect(viewModel.isSlotBooked(0, 10, 0), isFalse);
        expect(viewModel.isSlotBooked(0, 11, 0), isTrue);
      });

      test('should get booking info for slot', () {
        final slot = viewModel.getBookingForSlot(0, 10, 0);
        expect(slot, isNotNull);
        expect(slot!.startTime, '10:00');
        expect(slot.isBooked, isFalse);
      });

      test('should return null for invalid slot', () {
        final slot = viewModel.getBookingForSlot(0, 15, 0);
        expect(slot, isNull);
      });

      test('should get slot price', () {
        expect(viewModel.getSlotPrice(0, 10, 0), 35000);
      });
    });

    group('booking validation', () {
      setUp(() async {
        // Configure mock FIRST before calling selectDate
        when(mockCourtRepository.fetchCourtAvailability(
          courtId: anyNamed('courtId'),
          date: anyNamed('date'),
        )).thenAnswer((_) async => const CourtAvailability(
              courtId: 'court-123',
              date: '2024-01-27',
              openTime: '07:00',
              closeTime: '22:00',
              subCourts: [
                SubCourt(
                  id: 'sc-1',
                  name: 'Court 1',
                  courtNumber: 1,
                  timeSlots: [
                    TimeSlot(startTime: '10:00', endTime: '10:30', isBooked: false, price: 35000),
                    TimeSlot(startTime: '10:30', endTime: '11:00', isBooked: false, price: 35000),
                    TimeSlot(startTime: '11:00', endTime: '11:30', isBooked: false, price: 35000),
                  ],
                ),
              ],
            ));

        // Use a future date to avoid isSlotPassed issues
        final futureDate = DateTime.now().add(const Duration(days: 7));
        await viewModel.selectDate(futureDate);
      });

      test('should not allow booking with no selections', () {
        expect(viewModel.canBook, isFalse);
      });

      test('should not allow booking with less than 1 hour per court', () {
        viewModel.toggleSlotSelection(0, 10, 0); // Only 30 min

        expect(viewModel.canBook, isFalse);
        expect(viewModel.bookingValidationMessage, isNotNull);
        expect(viewModel.bookingValidationMessage, contains('Tối thiểu 1 giờ'));
      });

      test('should allow booking with 1 hour (2 slots)', () {
        viewModel.toggleSlotSelection(0, 10, 0);
        viewModel.toggleSlotSelection(0, 10, 30);

        expect(viewModel.canBook, isTrue);
        expect(viewModel.bookingValidationMessage, isNull);
      });
    });

    group('clearSelection', () {
      test('should clear all selections', () async {
        // Configure mock FIRST before calling selectDate
        when(mockCourtRepository.fetchCourtAvailability(
          courtId: anyNamed('courtId'),
          date: anyNamed('date'),
        )).thenAnswer((_) async => const CourtAvailability(
              courtId: 'court-123',
              date: '2024-01-27',
              openTime: '07:00',
              closeTime: '22:00',
              subCourts: [
                SubCourt(
                  id: 'sc-1',
                  name: 'Court 1',
                  courtNumber: 1,
                  timeSlots: [
                    TimeSlot(startTime: '10:00', endTime: '10:30', isBooked: false, price: 35000),
                  ],
                ),
              ],
            ));

        // Use a future date to avoid isSlotPassed issues
        final futureDate = DateTime.now().add(const Duration(days: 7));
        await viewModel.selectDate(futureDate);

        viewModel.toggleSlotSelection(0, 10, 0);
        expect(viewModel.selection.isNotEmpty, isTrue);

        viewModel.clearSelection();
        expect(viewModel.selection.isEmpty, isTrue);
      });
    });

    group('bookingSummaries', () {
      test('should generate correct booking summaries', () async {
        // Configure mock FIRST before calling selectDate
        when(mockCourtRepository.fetchCourtAvailability(
          courtId: anyNamed('courtId'),
          date: anyNamed('date'),
        )).thenAnswer((_) async => const CourtAvailability(
              courtId: 'court-123',
              date: '2024-01-27',
              openTime: '07:00',
              closeTime: '22:00',
              subCourts: [
                SubCourt(
                  id: 'sc-1',
                  name: 'Court 1',
                  courtNumber: 1,
                  timeSlots: [
                    TimeSlot(startTime: '10:00', endTime: '10:30', isBooked: false, price: 35000),
                    TimeSlot(startTime: '10:30', endTime: '11:00', isBooked: false, price: 35000),
                    TimeSlot(startTime: '11:00', endTime: '11:30', isBooked: false, price: 35000),
                  ],
                ),
              ],
            ));

        // Use a future date to avoid isSlotPassed issues
        final futureDate = DateTime.now().add(const Duration(days: 7));
        await viewModel.selectDate(futureDate);

        viewModel.toggleSlotSelection(0, 10, 0);
        viewModel.toggleSlotSelection(0, 10, 30);
        viewModel.toggleSlotSelection(0, 11, 0);

        final summaries = viewModel.bookingSummaries;

        expect(summaries.length, 1);
        expect(summaries[0].subCourtName, 'Court 1');
        expect(summaries[0].totalSlots, 3);
        expect(summaries[0].totalPrice, 105000);
        expect(summaries[0].timeRanges.length, 1); // Consecutive slots
        expect(summaries[0].timeRanges[0].formatted, '10:00 - 11:30');
      });
    });

    group('formatPriceVND', () {
      test('should format price in VND correctly', () {
        // Vietnamese locale uses . as thousands separator
        expect(BookingViewModel.formatPriceVND(70000), '70.000 ₫');
        expect(BookingViewModel.formatPriceVND(1500000), '1.500.000 ₫');
        expect(BookingViewModel.formatPriceVND(35000.5), '35.001 ₫');
      });
    });
  });
}

