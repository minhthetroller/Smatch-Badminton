import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/availability.dart';
import '../models/court.dart';
import '../repositories/court_repository.dart';

/// View state for the booking screen
enum BookingViewState { initial, loading, loaded, error }

/// ViewModel for the booking/timeline selector view
class BookingViewModel extends ChangeNotifier {
  final CourtRepository _courtRepository;
  final Court court;

  BookingViewModel({
    required this.court,
    CourtRepository? courtRepository,
  }) : _courtRepository = courtRepository ?? CourtRepository();

  // State
  BookingViewState _state = BookingViewState.initial;
  String? _errorMessage;
  CourtAvailability? _availability;
  int _selectedSubCourtIndex = 0;
  DateTime _selectedDate = DateTime.now();
  BookingSelection _selection = const BookingSelection();

  // Time slot constants
  static const int slotDurationMinutes = 30;
  static const double defaultPricePerSlot = 5.0; // Default price per 30-min slot

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

  /// Format date for display
  String get formattedDate {
    return DateFormat('EEE, MMM d, yyyy').format(_selectedDate);
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
          final isBooked = (index == 1 && hour >= 7 && hour < 9) ||
              (index == 1 && hour >= 17 && hour < 18) ||
              (index == 0 && hour >= 10 && hour < 12);

          final endMinute = minute + 30;
          final endHour = hour + (endMinute >= 60 ? 1 : 0);

          slots.add(TimeSlot(
            startTime: '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
            endTime: '${endHour.toString().padLeft(2, '0')}:${(endMinute % 60).toString().padLeft(2, '0')}',
            isBooked: isBooked,
            bookedBy: isBooked ? 'John D.' : null,
            price: 5.0, // $5 per 30-min slot
          ));
        }
      }

      return SubCourt(
        id: 'subcourt-${index + 1}',
        name: 'Court ${index + 1}',
        courtNumber: index + 1,
        timeSlots: slots,
        pricePerHour: 10.0,
      );
    });

    _availability = CourtAvailability(
      courtId: court.id,
      date: apiFormattedDate,
      openTime: '07:00',
      closeTime: '22:00',
      subCourts: mockSubCourts,
      defaultPricePerHour: 10.0,
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

  /// Check if a time slot is available for selection (not booked)
  bool isSlotAvailable(int subCourtIndex, int hour, int minute) {
    if (_availability == null) return false;
    if (subCourtIndex < 0 || subCourtIndex >= subCourts.length) return false;

    final subCourt = subCourts[subCourtIndex];
    final timeStr = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    // Check if this slot is booked
    for (final slot in subCourt.timeSlots) {
      if (slot.startTime == timeStr && slot.isBooked) {
        return false;
      }
    }

    return true;
  }

  /// Check if a specific slot is booked
  bool isSlotBooked(int subCourtIndex, int hour, int minute) {
    if (_availability == null) return false;
    if (subCourtIndex < 0 || subCourtIndex >= subCourts.length) return false;

    final subCourt = subCourts[subCourtIndex];
    final timeStr = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    for (final slot in subCourt.timeSlots) {
      if (slot.startTime == timeStr && slot.isBooked) {
        return true;
      }
    }

    return false;
  }

  /// Get booking info for a specific time slot
  TimeSlot? getBookingForSlot(int subCourtIndex, int hour, int minute) {
    if (_availability == null) return null;
    if (subCourtIndex < 0 || subCourtIndex >= subCourts.length) return null;

    final subCourt = subCourts[subCourtIndex];
    final timeStr = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    for (final slot in subCourt.timeSlots) {
      if (slot.startTime == timeStr) {
        return slot;
      }
    }

    return null;
  }

  /// Toggle selection for a specific slot
  void toggleSlotSelection(int subCourtIndex, int hour, int minute) {
    if (!isSlotAvailable(subCourtIndex, hour, minute)) return;

    final subCourt = subCourts[subCourtIndex];
    final slotInfo = getBookingForSlot(subCourtIndex, hour, minute);
    final price = slotInfo?.price ?? defaultPricePerSlot;

    final slot = SelectedSlot(
      subCourtIndex: subCourtIndex,
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

  /// Check if we can proceed with booking
  bool get canBook => _selection.isNotEmpty;

  /// Get booking summaries for confirmation page
  List<CourtBookingSummary> get bookingSummaries => _selection.summaries;

  /// Proceed with booking
  Future<bool> confirmBooking() async {
    if (!canBook) return false;

    // TODO: Implement actual booking API call
    debugPrint('Booking confirmed:');
    for (final summary in bookingSummaries) {
      debugPrint('  ${summary.subCourtName}: ${summary.timeRanges.map((r) => r.formatted).join(', ')}');
    }
    debugPrint('Total price: \$$totalPrice');

    return true;
  }
}
