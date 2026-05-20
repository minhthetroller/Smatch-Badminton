import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/availability.dart';
import '../models/booking.dart';
import '../models/court.dart';
import '../repositories/court_repository.dart';

/// View state for the booking screen
enum BookingViewState { initial, loading, loaded, error }

/// ViewModel for the booking/timeline selector view
class BookingViewModel extends ChangeNotifier {
  final CourtRepository _courtRepository;
  final Court court;

  BookingViewModel({required this.court, CourtRepository? courtRepository})
    : _courtRepository = courtRepository ?? CourtRepository();

  // State
  BookingViewState _state = BookingViewState.initial;
  String? _errorMessage;
  CourtAvailability? _availability;
  int _selectedSubCourtIndex = 0;
  DateTime _selectedDate = DateTime.now();
  BookingSelection _selection = const BookingSelection();

  // Time slot constants
  static const int slotDurationMinutes = 30;
  static const double defaultPricePerSlot =
      35000.0; // Default price per 30-min slot in VND

  // Getters
  BookingViewState get state => _state;
  String? get errorMessage => _errorMessage;
  CourtAvailability? get availability => _availability;
  int get selectedSubCourtIndex => _selectedSubCourtIndex;
  DateTime get selectedDate => _selectedDate;
  BookingSelection get selection => _selection;

  /// Get list of sub-courts
  List<SubCourt> get subCourts => _availability?.subCourts ?? [];

  /// Get currently selected sub-court (for viewing, not for selection)
  SubCourt? get selectedSubCourt {
    if (_availability == null || _availability!.subCourts.isEmpty) return null;
    if (_selectedSubCourtIndex >= _availability!.subCourts.length) return null;
    return _availability!.subCourts[_selectedSubCourtIndex];
  }

  /// Get operating hours
  int get openHour => _availability?.openHour ?? 7;
  int get closeHour => _availability?.closeHour ?? 22;

  /// Calculate total price for all selections
  double get totalPrice => _selection.totalPrice;

  /// Get total duration formatted
  String get totalDurationFormatted => _selection.durationFormatted;

  /// Get number of selected slots
  int get selectedSlotCount => _selection.slotCount;

  /// Get number of courts with selections
  int get selectedCourtCount => _selection.courtCount;

  /// Format date for display (Vietnamese standard: dd/MM/yyyy)
  String get formattedDate {
    return DateFormat('dd/MM/yyyy').format(_selectedDate);
  }

  /// Format price to VND currency
  static String formatPriceVND(double price) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(price.round())} ₫';
  }

  /// Format date for API
  String get apiFormattedDate {
    return DateFormat('yyyy-MM-dd').format(_selectedDate);
  }

  /// Initialize and load availability
  Future<void> initialize() async {
    await loadAvailability();
  }

  /// Load availability for selected date
  Future<void> loadAvailability() async {
    _state = BookingViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _availability = await _courtRepository.fetchCourtAvailability(
        courtId: court.id,
        date: apiFormattedDate,
      );
      _state = BookingViewState.loaded;

      // Don't reset selection when reloading - user may want to keep selections
    } catch (e) {
      debugPrint('Failed to load availability: $e');
      _state = BookingViewState.error;
      _errorMessage = e.toString();

      // Generate mock data for demo purposes
      _generateMockAvailability();
    }

    notifyListeners();
  }

  /// Generate mock availability data when API fails
  void _generateMockAvailability() {
    final mockSubCourts = List.generate(4, (index) {
      // Create 30-minute time slots from 7:00 to 22:00
      final slots = <TimeSlot>[];
      for (int hour = 7; hour < 22; hour++) {
        for (int minute = 0; minute < 60; minute += 30) {
          // Simulate some booked slots
          final isBooked =
              (index == 1 && hour >= 7 && hour < 9) ||
              (index == 1 && hour >= 17 && hour < 18) ||
              (index == 0 && hour >= 10 && hour < 12);

          final endMinute = minute + 30;
          final endHour = hour + (endMinute >= 60 ? 1 : 0);

          slots.add(
            TimeSlot(
              startTime:
                  '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
              endTime:
                  '${endHour.toString().padLeft(2, '0')}:${(endMinute % 60).toString().padLeft(2, '0')}',
              isBooked: isBooked,
              bookedBy: isBooked ? null : null,
              price: 35000.0, // 35,000 VND per 30-min slot
            ),
          );
        }
      }

      return SubCourt(
        id: 'subcourt-${index + 1}',
        name: 'Court ${index + 1}',
        courtNumber: index + 1,
        timeSlots: slots,
        pricePerHour: 70000.0, // 70,000 VND per hour
      );
    });

    _availability = CourtAvailability(
      courtId: court.id,
      date: apiFormattedDate,
      openTime: '07:00',
      closeTime: '22:00',
      subCourts: mockSubCourts,
      defaultPricePerHour: 70000.0, // 70,000 VND per hour
    );
    _state = BookingViewState.loaded;
    _errorMessage = null;
  }

  /// Select a sub-court (for viewing)
  void selectSubCourt(int index) {
    if (index < 0 || index >= subCourts.length) return;
    _selectedSubCourtIndex = index;
    notifyListeners();
  }

  /// Select a date
  Future<void> selectDate(DateTime date) async {
    _selectedDate = date;
    // Clear selections when changing date
    _selection = const BookingSelection();
    await loadAvailability();
  }

  /// Check if the selected date is today
  bool get isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  /// Check if a time slot has passed (only applicable for today)
  bool isSlotPassed(int hour, int minute) {
    if (!isToday) return false;

    final now = DateTime.now();
    final slotTime = DateTime(now.year, now.month, now.day, hour, minute);
    return slotTime.isBefore(now);
  }

  /// Check if a time slot is available for selection (not booked and not passed)
  bool isSlotAvailable(int subCourtIndex, int hour, int minute) {
    // Check if time has passed (for today)
    if (isSlotPassed(hour, minute)) return false;

    final slot = getBookingForSlot(subCourtIndex, hour, minute);
    // Slot is available only if it exists in API data and is not booked
    return slot != null && !slot.isBooked;
  }

  /// Check if a specific slot is booked
  bool isSlotBooked(int subCourtIndex, int hour, int minute) {
    final slot = getBookingForSlot(subCourtIndex, hour, minute);
    // Slot is booked if it exists and isBooked is true
    return slot != null && slot.isBooked;
  }

  /// Get booking info for a specific time slot
  TimeSlot? getBookingForSlot(int subCourtIndex, int hour, int minute) {
    if (_availability == null) return null;
    if (subCourtIndex < 0 || subCourtIndex >= subCourts.length) return null;

    final subCourt = subCourts[subCourtIndex];
    final timeStr =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    for (final slot in subCourt.timeSlots) {
      if (slot.startTime == timeStr) {
        return slot;
      }
    }

    return null;
  }

  /// Get price for a specific time slot from API data
  double getSlotPrice(int subCourtIndex, int hour, int minute) {
    final slot = getBookingForSlot(subCourtIndex, hour, minute);
    return slot?.price ?? defaultPricePerSlot;
  }

  /// Toggle selection for a specific slot
  void toggleSlotSelection(int subCourtIndex, int hour, int minute) {
    if (!isSlotAvailable(subCourtIndex, hour, minute)) return;

    final subCourt = subCourts[subCourtIndex];
    final price = getSlotPrice(subCourtIndex, hour, minute);

    final slot = SelectedSlot(
      subCourtIndex: subCourtIndex,
      subCourtId: subCourt.id,
      subCourtName: subCourt.name,
      hour: hour,
      minute: minute,
      price: price,
    );

    _selection = _selection.toggleSlot(slot);
    notifyListeners();
  }

  /// Check if a slot is selected
  bool isSlotSelected(int subCourtIndex, int hour, int minute) {
    return _selection.isSlotSelected(subCourtIndex, hour, minute);
  }

  /// Clear all selections
  void clearSelection() {
    _selection = const BookingSelection();
    notifyListeners();
  }

  // Minimum slots required per court (1 hour = 2 x 30-min slots)
  static const int minSlotsPerCourt = 2;

  /// Check if we can proceed with booking
  /// Requires at least 1 hour (2 slots) per court
  bool get canBook {
    if (_selection.isEmpty) return false;
    if (!_hasOnlyBookableSubCourtIds) return false;

    // Check each court has at least minSlotsPerCourt (1 hour)
    final slotsByCourt = _selection.slotsByCourtIndex;
    for (final courtSlots in slotsByCourt.values) {
      if (courtSlots.length < minSlotsPerCourt) {
        return false;
      }
    }
    return true;
  }

  bool get _hasOnlyBookableSubCourtIds {
    return _selection.slots.every(
      (slot) => CreateBookingRequest.isValidSubCourtId(slot.subCourtId),
    );
  }

  /// Get validation message if booking cannot proceed
  String? get bookingValidationMessage {
    if (_selection.isEmpty) return null;

    if (!_hasOnlyBookableSubCourtIds) {
      return 'Could not load real court availability. Please refresh and try again.';
    }

    final slotsByCourt = _selection.slotsByCourtIndex;
    for (final entry in slotsByCourt.entries) {
      if (entry.value.length < minSlotsPerCourt) {
        final courtName = entry.value.first.subCourtName;
        final currentMinutes = entry.value.length * 30;
        return '$courtName: Tối thiểu 1 giờ (hiện tại: $currentMinutes phút)';
      }
    }
    return null;
  }

  /// Get booking summaries for confirmation page
  List<CourtBookingSummary> get bookingSummaries => _selection.summaries;

  /// Proceed with booking
  Future<bool> confirmBooking() async {
    if (!canBook) return false;

    // TODO: Implement actual booking API call
    debugPrint('Booking confirmed:');
    for (final summary in bookingSummaries) {
      debugPrint(
        '  ${summary.subCourtName}: ${summary.timeRanges.map((r) => r.formatted).join(', ')}',
      );
    }
    debugPrint('Total price: ${formatPriceVND(totalPrice)}');

    return true;
  }
}
