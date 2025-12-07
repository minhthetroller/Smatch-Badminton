import 'package:flutter_test/flutter_test.dart';
import 'package:smatch_badminton/models/availability.dart';

void main() {
  group('TimeSlot', () {
    group('fromJson', () {
      test('should parse available slot correctly', () {
        final json = {
          'startTime': '10:00',
          'endTime': '10:30',
          'isAvailable': true,
          'price': 35000,
        };

        final slot = TimeSlot.fromJson(json);

        expect(slot.startTime, '10:00');
        expect(slot.endTime, '10:30');
        expect(slot.isBooked, isFalse);
        expect(slot.price, 35000.0);
      });

      test('should parse booked slot correctly (isAvailable: false)', () {
        final json = {
          'startTime': '11:00',
          'endTime': '11:30',
          'isAvailable': false,
          'bookedBy': 'user@example.com',
          'price': 35000,
        };

        final slot = TimeSlot.fromJson(json);

        expect(slot.startTime, '11:00');
        expect(slot.endTime, '11:30');
        expect(slot.isBooked, isTrue);
        expect(slot.bookedBy, 'user@example.com');
      });

      test('should handle null optional fields', () {
        final json = {
          'startTime': '12:00',
          'endTime': '12:30',
          'isAvailable': true,
        };

        final slot = TimeSlot.fromJson(json);

        expect(slot.bookedBy, isNull);
        expect(slot.price, isNull);
      });

      test('should default isAvailable to true when null', () {
        final json = {
          'startTime': '13:00',
          'endTime': '13:30',
          'isAvailable': null,
        };

        final slot = TimeSlot.fromJson(json);

        expect(slot.isBooked, isFalse);
      });
    });

    group('toJson', () {
      test('should serialize correctly', () {
        const slot = TimeSlot(
          startTime: '10:00',
          endTime: '10:30',
          isBooked: false,
          price: 35000.0,
        );

        final json = slot.toJson();

        expect(json['startTime'], '10:00');
        expect(json['endTime'], '10:30');
        expect(json['isBooked'], false);
        expect(json['price'], 35000.0);
      });
    });

    group('time parsing', () {
      test('should parse startDateTime correctly', () {
        const slot = TimeSlot(
          startTime: '14:30',
          endTime: '15:00',
          isBooked: false,
        );

        final dateTime = slot.startDateTime;

        expect(dateTime.hour, 14);
        expect(dateTime.minute, 30);
      });

      test('should parse endDateTime correctly', () {
        const slot = TimeSlot(
          startTime: '14:30',
          endTime: '15:00',
          isBooked: false,
        );

        final dateTime = slot.endDateTime;

        expect(dateTime.hour, 15);
        expect(dateTime.minute, 0);
      });

      test('should return startHour', () {
        const slot = TimeSlot(
          startTime: '08:30',
          endTime: '09:00',
          isBooked: false,
        );

        expect(slot.startHour, 8);
      });

      test('should return startMinute', () {
        const slot = TimeSlot(
          startTime: '08:30',
          endTime: '09:00',
          isBooked: false,
        );

        expect(slot.startMinute, 30);
      });
    });
  });

  group('SubCourt', () {
    group('fromJson', () {
      test('should parse complete JSON with slots array', () {
        final json = {
          'id': 'subcourt-1',
          'name': 'Court 1',
          'courtNumber': 1,
          'pricePerHour': 70000.0,
          'slots': [
            {'startTime': '07:00', 'endTime': '07:30', 'isAvailable': true, 'price': 35000},
            {'startTime': '07:30', 'endTime': '08:00', 'isAvailable': false, 'price': 35000},
          ],
        };

        final subCourt = SubCourt.fromJson(json);

        expect(subCourt.id, 'subcourt-1');
        expect(subCourt.name, 'Court 1');
        expect(subCourt.courtNumber, 1);
        expect(subCourt.pricePerHour, 70000.0);
        expect(subCourt.timeSlots.length, 2);
        expect(subCourt.timeSlots[0].startTime, '07:00');
        expect(subCourt.timeSlots[0].isBooked, false);
        expect(subCourt.timeSlots[1].startTime, '07:30');
        expect(subCourt.timeSlots[1].isBooked, true);
      });

      test('should parse timeSlots key as alternative', () {
        final json = {
          'id': 'subcourt-2',
          'name': 'Court 2',
          'courtNumber': 2,
          'timeSlots': [
            {'startTime': '08:00', 'endTime': '08:30', 'isAvailable': true},
          ],
        };

        final subCourt = SubCourt.fromJson(json);

        expect(subCourt.timeSlots.length, 1);
        expect(subCourt.timeSlots[0].startTime, '08:00');
      });

      test('should handle null/empty slots', () {
        final json = {
          'id': 'subcourt-3',
          'name': 'Court 3',
          'courtNumber': 3,
        };

        final subCourt = SubCourt.fromJson(json);

        expect(subCourt.timeSlots, isEmpty);
      });

      test('should default courtNumber to 1', () {
        final json = {
          'id': 'subcourt-4',
          'name': 'Court 4',
        };

        final subCourt = SubCourt.fromJson(json);

        expect(subCourt.courtNumber, 1);
      });
    });

    group('toJson', () {
      test('should serialize correctly', () {
        const subCourt = SubCourt(
          id: 'subcourt-1',
          name: 'Court 1',
          courtNumber: 1,
          pricePerHour: 70000.0,
          timeSlots: [
            TimeSlot(startTime: '07:00', endTime: '07:30', isBooked: false),
          ],
        );

        final json = subCourt.toJson();

        expect(json['id'], 'subcourt-1');
        expect(json['name'], 'Court 1');
        expect(json['courtNumber'], 1);
        expect(json['pricePerHour'], 70000.0);
        expect(json['timeSlots'], isA<List>());
        expect((json['timeSlots'] as List).length, 1);
      });
    });
  });

  group('CourtAvailability', () {
    group('fromJson', () {
      test('should parse complete JSON correctly', () {
        final json = {
          'courtId': 'court-123',
          'date': '2024-01-20',
          'openTime': '07:00',
          'closeTime': '22:00',
          'defaultPricePerHour': 70000.0,
          'subCourts': [
            {
              'id': 'subcourt-1',
              'name': 'Court 1',
              'courtNumber': 1,
              'slots': [],
            },
            {
              'id': 'subcourt-2',
              'name': 'Court 2',
              'courtNumber': 2,
              'slots': [],
            },
          ],
        };

        final availability = CourtAvailability.fromJson(json);

        expect(availability.courtId, 'court-123');
        expect(availability.date, '2024-01-20');
        expect(availability.openTime, '07:00');
        expect(availability.closeTime, '22:00');
        expect(availability.defaultPricePerHour, 70000.0);
        expect(availability.subCourts.length, 2);
      });

      test('should use default times when not provided', () {
        final json = {
          'courtId': 'court-456',
          'date': '2024-01-21',
        };

        final availability = CourtAvailability.fromJson(json);

        expect(availability.openTime, '07:00');
        expect(availability.closeTime, '22:00');
      });

      test('should handle null subCourts', () {
        final json = {
          'courtId': 'court-789',
          'date': '2024-01-22',
          'openTime': '08:00',
          'closeTime': '21:00',
          'subCourts': null,
        };

        final availability = CourtAvailability.fromJson(json);

        expect(availability.subCourts, isEmpty);
      });
    });

    group('openHour / closeHour', () {
      test('should parse open hour correctly', () {
        const availability = CourtAvailability(
          courtId: 'court-1',
          date: '2024-01-20',
          openTime: '07:00',
          closeTime: '22:00',
        );

        expect(availability.openHour, 7);
      });

      test('should parse close hour correctly', () {
        const availability = CourtAvailability(
          courtId: 'court-1',
          date: '2024-01-20',
          openTime: '07:00',
          closeTime: '22:00',
        );

        expect(availability.closeHour, 22);
      });

      test('should default to 7 for invalid openTime', () {
        const availability = CourtAvailability(
          courtId: 'court-1',
          date: '2024-01-20',
          openTime: 'invalid',
          closeTime: '22:00',
        );

        expect(availability.openHour, 7);
      });

      test('should default to 22 for invalid closeTime', () {
        const availability = CourtAvailability(
          courtId: 'court-1',
          date: '2024-01-20',
          openTime: '07:00',
          closeTime: 'invalid',
        );

        expect(availability.closeHour, 22);
      });
    });

    group('toJson', () {
      test('should serialize correctly', () {
        const availability = CourtAvailability(
          courtId: 'court-123',
          date: '2024-01-20',
          openTime: '07:00',
          closeTime: '22:00',
          defaultPricePerHour: 70000.0,
        );

        final json = availability.toJson();

        expect(json['courtId'], 'court-123');
        expect(json['date'], '2024-01-20');
        expect(json['openTime'], '07:00');
        expect(json['closeTime'], '22:00');
        expect(json['defaultPricePerHour'], 70000.0);
      });
    });
  });

  group('SelectedSlot', () {
    test('should create with correct values', () {
      const slot = SelectedSlot(
        subCourtIndex: 0,
        subCourtName: 'Court 1',
        hour: 10,
        minute: 30,
        price: 35000.0,
      );

      expect(slot.subCourtIndex, 0);
      expect(slot.subCourtName, 'Court 1');
      expect(slot.hour, 10);
      expect(slot.minute, 30);
      expect(slot.price, 35000.0);
    });

    group('key', () {
      test('should generate unique key', () {
        const slot = SelectedSlot(
          subCourtIndex: 1,
          subCourtName: 'Court 2',
          hour: 14,
          minute: 0,
          price: 35000.0,
        );

        expect(slot.key, '1-14-0');
      });
    });

    group('timeString', () {
      test('should format time with leading zeros', () {
        const slot = SelectedSlot(
          subCourtIndex: 0,
          subCourtName: 'Court 1',
          hour: 7,
          minute: 0,
          price: 35000.0,
        );

        expect(slot.timeString, '07:00');
      });

      test('should format time correctly for double digit hour', () {
        const slot = SelectedSlot(
          subCourtIndex: 0,
          subCourtName: 'Court 1',
          hour: 14,
          minute: 30,
          price: 35000.0,
        );

        expect(slot.timeString, '14:30');
      });
    });

    group('endTimeString', () {
      test('should add 30 minutes', () {
        const slot = SelectedSlot(
          subCourtIndex: 0,
          subCourtName: 'Court 1',
          hour: 10,
          minute: 0,
          price: 35000.0,
        );

        expect(slot.endTimeString, '10:30');
      });

      test('should handle hour rollover', () {
        const slot = SelectedSlot(
          subCourtIndex: 0,
          subCourtName: 'Court 1',
          hour: 10,
          minute: 30,
          price: 35000.0,
        );

        expect(slot.endTimeString, '11:00');
      });
    });

    group('equality', () {
      test('should be equal when same subCourtIndex, hour, minute', () {
        const slot1 = SelectedSlot(
          subCourtIndex: 0,
          subCourtName: 'Court 1',
          hour: 10,
          minute: 0,
          price: 35000.0,
        );

        const slot2 = SelectedSlot(
          subCourtIndex: 0,
          subCourtName: 'Court 1',
          hour: 10,
          minute: 0,
          price: 40000.0, // Different price, same slot
        );

        expect(slot1, equals(slot2));
      });

      test('should not be equal when different subCourtIndex', () {
        const slot1 = SelectedSlot(
          subCourtIndex: 0,
          subCourtName: 'Court 1',
          hour: 10,
          minute: 0,
          price: 35000.0,
        );

        const slot2 = SelectedSlot(
          subCourtIndex: 1,
          subCourtName: 'Court 2',
          hour: 10,
          minute: 0,
          price: 35000.0,
        );

        expect(slot1, isNot(equals(slot2)));
      });
    });

    group('copyWith', () {
      test('should create copy with updated values', () {
        const original = SelectedSlot(
          subCourtIndex: 0,
          subCourtName: 'Court 1',
          hour: 10,
          minute: 0,
          price: 35000.0,
        );

        final copy = original.copyWith(price: 40000.0);

        expect(copy.subCourtIndex, 0);
        expect(copy.hour, 10);
        expect(copy.minute, 0);
        expect(copy.price, 40000.0);
      });
    });
  });

  group('BookingSelection', () {
    group('isSlotSelected', () {
      test('should return true for selected slot', () {
        const selection = BookingSelection(
          slots: [
            SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 10, minute: 0, price: 35000),
          ],
        );

        expect(selection.isSlotSelected(0, 10, 0), isTrue);
      });

      test('should return false for unselected slot', () {
        const selection = BookingSelection(
          slots: [
            SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 10, minute: 0, price: 35000),
          ],
        );

        expect(selection.isSlotSelected(0, 11, 0), isFalse);
        expect(selection.isSlotSelected(1, 10, 0), isFalse);
      });
    });

    group('addSlot', () {
      test('should add new slot', () {
        const selection = BookingSelection();
        const slot = SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 10, minute: 0, price: 35000);

        final newSelection = selection.addSlot(slot);

        expect(newSelection.slots.length, 1);
        expect(newSelection.isSlotSelected(0, 10, 0), isTrue);
      });

      test('should not duplicate existing slot', () {
        const slot = SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 10, minute: 0, price: 35000);
        const selection = BookingSelection(slots: [slot]);

        final newSelection = selection.addSlot(slot);

        expect(newSelection.slots.length, 1);
      });
    });

    group('removeSlot', () {
      test('should remove existing slot', () {
        const slot = SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 10, minute: 0, price: 35000);
        const selection = BookingSelection(slots: [slot]);

        final newSelection = selection.removeSlot(0, 10, 0);

        expect(newSelection.slots, isEmpty);
      });

      test('should not change selection if slot not found', () {
        const slot = SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 10, minute: 0, price: 35000);
        const selection = BookingSelection(slots: [slot]);

        final newSelection = selection.removeSlot(1, 10, 0);

        expect(newSelection.slots.length, 1);
      });
    });

    group('toggleSlot', () {
      test('should add slot if not selected', () {
        const selection = BookingSelection();
        const slot = SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 10, minute: 0, price: 35000);

        final newSelection = selection.toggleSlot(slot);

        expect(newSelection.isSlotSelected(0, 10, 0), isTrue);
      });

      test('should remove slot if already selected', () {
        const slot = SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 10, minute: 0, price: 35000);
        const selection = BookingSelection(slots: [slot]);

        final newSelection = selection.toggleSlot(slot);

        expect(newSelection.isSlotSelected(0, 10, 0), isFalse);
      });
    });

    group('clear', () {
      test('should remove all slots', () {
        const selection = BookingSelection(slots: [
          SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 10, minute: 0, price: 35000),
          SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 10, minute: 30, price: 35000),
        ]);

        final cleared = selection.clear();

        expect(cleared.isEmpty, isTrue);
      });
    });

    group('totalDurationMinutes', () {
      test('should calculate total duration', () {
        const selection = BookingSelection(slots: [
          SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 10, minute: 0, price: 35000),
          SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 10, minute: 30, price: 35000),
          SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 11, minute: 0, price: 35000),
        ]);

        expect(selection.totalDurationMinutes, 90); // 3 slots * 30 min
      });
    });

    group('totalPrice', () {
      test('should sum all slot prices', () {
        const selection = BookingSelection(slots: [
          SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 10, minute: 0, price: 35000),
          SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 10, minute: 30, price: 35000),
          SelectedSlot(subCourtIndex: 1, subCourtName: 'Court 2', hour: 10, minute: 0, price: 40000),
        ]);

        expect(selection.totalPrice, 110000);
      });
    });

    group('durationFormatted', () {
      test('should format minutes only', () {
        const selection = BookingSelection(slots: [
          SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 10, minute: 0, price: 35000),
        ]);

        expect(selection.durationFormatted, '30m');
      });

      test('should format hours only', () {
        const selection = BookingSelection(slots: [
          SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 10, minute: 0, price: 35000),
          SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 10, minute: 30, price: 35000),
        ]);

        expect(selection.durationFormatted, '1h');
      });

      test('should format hours and minutes', () {
        const selection = BookingSelection(slots: [
          SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 10, minute: 0, price: 35000),
          SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 10, minute: 30, price: 35000),
          SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 11, minute: 0, price: 35000),
        ]);

        expect(selection.durationFormatted, '1h 30m');
      });
    });

    group('slotsByCourtIndex', () {
      test('should group slots by court index', () {
        const selection = BookingSelection(slots: [
          SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 10, minute: 0, price: 35000),
          SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 10, minute: 30, price: 35000),
          SelectedSlot(subCourtIndex: 1, subCourtName: 'Court 2', hour: 11, minute: 0, price: 35000),
        ]);

        final grouped = selection.slotsByCourtIndex;

        expect(grouped.keys.length, 2);
        expect(grouped[0]!.length, 2);
        expect(grouped[1]!.length, 1);
      });

      test('should sort slots within each court by time', () {
        const selection = BookingSelection(slots: [
          SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 11, minute: 0, price: 35000),
          SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 10, minute: 0, price: 35000),
          SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 10, minute: 30, price: 35000),
        ]);

        final grouped = selection.slotsByCourtIndex;
        final court0Slots = grouped[0]!;

        expect(court0Slots[0].hour, 10);
        expect(court0Slots[0].minute, 0);
        expect(court0Slots[1].hour, 10);
        expect(court0Slots[1].minute, 30);
        expect(court0Slots[2].hour, 11);
        expect(court0Slots[2].minute, 0);
      });
    });

    group('summaries', () {
      test('should create summary with consecutive time range', () {
        const selection = BookingSelection(slots: [
          SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 10, minute: 0, price: 35000),
          SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 10, minute: 30, price: 35000),
          SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 11, minute: 0, price: 35000),
        ]);

        final summaries = selection.summaries;

        expect(summaries.length, 1);
        expect(summaries[0].subCourtName, 'Court 1');
        expect(summaries[0].timeRanges.length, 1);
        expect(summaries[0].timeRanges[0].startTimeString, '10:00');
        expect(summaries[0].timeRanges[0].endTimeString, '11:30');
        expect(summaries[0].totalSlots, 3);
        expect(summaries[0].totalPrice, 105000);
      });

      test('should create multiple time ranges for non-consecutive slots', () {
        const selection = BookingSelection(slots: [
          SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 10, minute: 0, price: 35000),
          SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 10, minute: 30, price: 35000),
          // Gap here
          SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 14, minute: 0, price: 35000),
          SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 14, minute: 30, price: 35000),
        ]);

        final summaries = selection.summaries;

        expect(summaries.length, 1);
        expect(summaries[0].timeRanges.length, 2);
        expect(summaries[0].timeRanges[0].formatted, '10:00 - 11:00');
        expect(summaries[0].timeRanges[1].formatted, '14:00 - 15:00');
      });

      test('should create separate summaries for different courts', () {
        const selection = BookingSelection(slots: [
          SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 10, minute: 0, price: 35000),
          SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 10, minute: 30, price: 35000),
          SelectedSlot(subCourtIndex: 1, subCourtName: 'Court 2', hour: 11, minute: 0, price: 40000),
          SelectedSlot(subCourtIndex: 1, subCourtName: 'Court 2', hour: 11, minute: 30, price: 40000),
        ]);

        final summaries = selection.summaries;

        expect(summaries.length, 2);
        
        final court1Summary = summaries.firstWhere((s) => s.subCourtName == 'Court 1');
        final court2Summary = summaries.firstWhere((s) => s.subCourtName == 'Court 2');

        expect(court1Summary.totalPrice, 70000);
        expect(court2Summary.totalPrice, 80000);
      });
    });

    group('isEmpty / isNotEmpty', () {
      test('should return true for empty selection', () {
        const selection = BookingSelection();
        expect(selection.isEmpty, isTrue);
        expect(selection.isNotEmpty, isFalse);
      });

      test('should return false for non-empty selection', () {
        const selection = BookingSelection(slots: [
          SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 10, minute: 0, price: 35000),
        ]);
        expect(selection.isEmpty, isFalse);
        expect(selection.isNotEmpty, isTrue);
      });
    });

    group('slotCount / courtCount', () {
      test('should count slots correctly', () {
        const selection = BookingSelection(slots: [
          SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 10, minute: 0, price: 35000),
          SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 10, minute: 30, price: 35000),
          SelectedSlot(subCourtIndex: 1, subCourtName: 'Court 2', hour: 11, minute: 0, price: 35000),
        ]);

        expect(selection.slotCount, 3);
      });

      test('should count courts correctly', () {
        const selection = BookingSelection(slots: [
          SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 10, minute: 0, price: 35000),
          SelectedSlot(subCourtIndex: 0, subCourtName: 'Court 1', hour: 10, minute: 30, price: 35000),
          SelectedSlot(subCourtIndex: 1, subCourtName: 'Court 2', hour: 11, minute: 0, price: 35000),
        ]);

        expect(selection.courtCount, 2);
      });
    });
  });

  group('TimeRange', () {
    test('should format start time string', () {
      const range = TimeRange(startHour: 10, startMinute: 0, endHour: 11, endMinute: 30);
      expect(range.startTimeString, '10:00');
    });

    test('should format end time string', () {
      const range = TimeRange(startHour: 10, startMinute: 0, endHour: 11, endMinute: 30);
      expect(range.endTimeString, '11:30');
    });

    test('should format full range', () {
      const range = TimeRange(startHour: 10, startMinute: 0, endHour: 11, endMinute: 30);
      expect(range.formatted, '10:00 - 11:30');
    });

    test('should calculate duration in minutes', () {
      const range = TimeRange(startHour: 10, startMinute: 0, endHour: 11, endMinute: 30);
      expect(range.durationMinutes, 90);
    });
  });

  group('CourtBookingSummary', () {
    test('should calculate total duration minutes', () {
      const summary = CourtBookingSummary(
        subCourtIndex: 0,
        subCourtName: 'Court 1',
        timeRanges: [],
        totalSlots: 4, // 2 hours
        totalPrice: 140000,
      );

      expect(summary.totalDurationMinutes, 120);
    });

    test('should format duration', () {
      const summary = CourtBookingSummary(
        subCourtIndex: 0,
        subCourtName: 'Court 1',
        timeRanges: [],
        totalSlots: 3, // 1.5 hours
        totalPrice: 105000,
      );

      expect(summary.durationFormatted, '1h 30m');
    });
  });
}

