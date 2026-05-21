/// Model representing a time slot booking
class TimeSlot {
  final String startTime;
  final String endTime;
  final bool isBooked;
  final String? bookedBy;
  final double? price;

  const TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.isBooked,
    this.bookedBy,
    this.price,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    // API returns 'isAvailable' - slot is booked when isAvailable is false
    final isAvailable = json['isAvailable'] as bool? ?? true;
    return TimeSlot(
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      isBooked: !isAvailable,
      bookedBy: json['bookedBy'] as String?,
      price: (json['price'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'isBooked': isBooked,
      'bookedBy': bookedBy,
      'price': price,
    };
  }

  /// Parse time string to DateTime (assumes format "HH:mm")
  DateTime get startDateTime {
    final parts = startTime.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  DateTime get endDateTime {
    final parts = endTime.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  /// Get hour from start time
  int get startHour => int.parse(startTime.split(':')[0]);

  /// Get minute from start time
  int get startMinute => int.parse(startTime.split(':')[1]);
}

/// Model representing a sub-court within a venue
class SubCourt {
  final String id;
  final String name;
  final int courtNumber;
  final List<TimeSlot> timeSlots;
  final double? pricePerHour;

  const SubCourt({
    required this.id,
    required this.name,
    required this.courtNumber,
    this.timeSlots = const [],
    this.pricePerHour,
  });

  factory SubCourt.fromJson(Map<String, dynamic> json) {
    // API returns 'slots' for time slot data
    final slotsData =
        json['slots'] as List<dynamic>? ??
        json['timeSlots'] as List<dynamic>? ??
        [];
    return SubCourt(
      id: json['id'] as String,
      name: json['name'] as String,
      courtNumber: json['courtNumber'] as int? ?? 1,
      timeSlots: slotsData
          .map((e) => TimeSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
      pricePerHour: (json['pricePerHour'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'courtNumber': courtNumber,
      'timeSlots': timeSlots.map((e) => e.toJson()).toList(),
      'pricePerHour': pricePerHour,
    };
  }
}

/// Model representing court availability response
class CourtAvailability {
  final String courtId;
  final String date;
  final String openTime;
  final String closeTime;
  final List<SubCourt> subCourts;
  final double? defaultPricePerHour;

  const CourtAvailability({
    required this.courtId,
    required this.date,
    required this.openTime,
    required this.closeTime,
    this.subCourts = const [],
    this.defaultPricePerHour,
  });

  factory CourtAvailability.fromJson(Map<String, dynamic> json) {
    return CourtAvailability(
      courtId: json['courtId'] as String,
      date: json['date'] as String,
      openTime: json['openTime'] as String? ??
          json['openingTime'] as String? ??
          '07:00',
      closeTime: json['closeTime'] as String? ??
          json['closingTime'] as String? ??
          '22:00',
      subCourts:
          (json['subCourts'] as List<dynamic>?)
              ?.map((e) => SubCourt.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      defaultPricePerHour: (json['defaultPricePerHour'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courtId': courtId,
      'date': date,
      'openTime': openTime,
      'closeTime': closeTime,
      'subCourts': subCourts.map((e) => e.toJson()).toList(),
      'defaultPricePerHour': defaultPricePerHour,
    };
  }

  /// Parse open time to hour
  int get openHour {
    final parts = openTime.split(':');
    return int.tryParse(parts[0]) ?? 7;
  }

  /// Parse open time to minute
  int get openMinute {
    final parts = openTime.split(':');
    return parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
  }

  /// Parse close time to hour
  int get closeHour {
    final parts = closeTime.split(':');
    return int.tryParse(parts[0]) ?? 22;
  }
}

/// Model representing a single selected time slot for a specific court
class SelectedSlot {
  final int subCourtIndex;
  final String subCourtId;
  final String subCourtName;
  final int hour;
  final int minute;
  final double price;

  const SelectedSlot({
    required this.subCourtIndex,
    this.subCourtId = '',
    required this.subCourtName,
    required this.hour,
    required this.minute,
    required this.price,
  });

  /// Unique key for this slot
  String get key => '$subCourtIndex-$hour-$minute';

  /// Time string (e.g., "07:00")
  String get timeString =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// End time string (30 min later)
  String get endTimeString {
    final endMinute = minute + 30;
    final endHour = hour + (endMinute >= 60 ? 1 : 0);
    return '${endHour.toString().padLeft(2, '0')}:${(endMinute % 60).toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectedSlot &&
          runtimeType == other.runtimeType &&
          subCourtIndex == other.subCourtIndex &&
          hour == other.hour &&
          minute == other.minute;

  @override
  int get hashCode => subCourtIndex.hashCode ^ hour.hashCode ^ minute.hashCode;

  SelectedSlot copyWith({
    int? subCourtIndex,
    String? subCourtId,
    String? subCourtName,
    int? hour,
    int? minute,
    double? price,
  }) {
    return SelectedSlot(
      subCourtIndex: subCourtIndex ?? this.subCourtIndex,
      subCourtId: subCourtId ?? this.subCourtId,
      subCourtName: subCourtName ?? this.subCourtName,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      price: price ?? this.price,
    );
  }
}

/// Model representing all user selections grouped by court
class BookingSelection {
  final List<SelectedSlot> slots;

  const BookingSelection({this.slots = const []});

  /// Check if a specific slot is selected
  bool isSlotSelected(int subCourtIndex, int hour, int minute) {
    return slots.any(
      (s) =>
          s.subCourtIndex == subCourtIndex &&
          s.hour == hour &&
          s.minute == minute,
    );
  }

  /// Add a slot to selection
  BookingSelection addSlot(SelectedSlot slot) {
    if (isSlotSelected(slot.subCourtIndex, slot.hour, slot.minute)) {
      return this;
    }
    return BookingSelection(slots: [...slots, slot]);
  }

  /// Remove a slot from selection
  BookingSelection removeSlot(int subCourtIndex, int hour, int minute) {
    return BookingSelection(
      slots: slots
          .where(
            (s) =>
                !(s.subCourtIndex == subCourtIndex &&
                    s.hour == hour &&
                    s.minute == minute),
          )
          .toList(),
    );
  }

  /// Toggle a slot selection
  BookingSelection toggleSlot(SelectedSlot slot) {
    if (isSlotSelected(slot.subCourtIndex, slot.hour, slot.minute)) {
      return removeSlot(slot.subCourtIndex, slot.hour, slot.minute);
    }
    return addSlot(slot);
  }

  /// Clear all selections
  BookingSelection clear() => const BookingSelection();

  /// Get total duration in minutes
  int get totalDurationMinutes => slots.length * 30;

  /// Get total price
  double get totalPrice => slots.fold(0.0, (sum, slot) => sum + slot.price);

  /// Get formatted total duration
  String get durationFormatted {
    final minutes = totalDurationMinutes;
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours == 0) return '${mins}m';
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  /// Get slots grouped by court
  Map<int, List<SelectedSlot>> get slotsByCourtIndex {
    final grouped = <int, List<SelectedSlot>>{};
    for (final slot in slots) {
      grouped.putIfAbsent(slot.subCourtIndex, () => []).add(slot);
    }
    // Sort slots within each court by time
    for (final entry in grouped.entries) {
      entry.value.sort((a, b) {
        final aMinutes = a.hour * 60 + a.minute;
        final bMinutes = b.hour * 60 + b.minute;
        return aMinutes.compareTo(bMinutes);
      });
    }
    return grouped;
  }

  /// Get summary of selections grouped by court with time ranges
  List<CourtBookingSummary> get summaries {
    final grouped = slotsByCourtIndex;
    final result = <CourtBookingSummary>[];

    for (final entry in grouped.entries) {
      final courtSlots = entry.value;
      if (courtSlots.isEmpty) continue;

      // Group consecutive slots into time ranges
      final ranges = <TimeRange>[];
      TimeRange? currentRange;

      for (final slot in courtSlots) {
        if (currentRange == null) {
          currentRange = TimeRange(
            startHour: slot.hour,
            startMinute: slot.minute,
            endHour: slot.hour,
            endMinute: slot.minute + 30,
          );
        } else {
          // Check if this slot is consecutive
          final expectedMinutes =
              currentRange.endHour * 60 + currentRange.endMinute;
          final slotMinutes = slot.hour * 60 + slot.minute;

          if (slotMinutes == expectedMinutes) {
            // Consecutive - extend the range
            final endMinute = slot.minute + 30;
            currentRange = TimeRange(
              startHour: currentRange.startHour,
              startMinute: currentRange.startMinute,
              endHour: slot.hour + (endMinute >= 60 ? 1 : 0),
              endMinute: endMinute % 60,
            );
          } else {
            // Not consecutive - save current range and start new one
            ranges.add(currentRange);
            currentRange = TimeRange(
              startHour: slot.hour,
              startMinute: slot.minute,
              endHour: slot.hour,
              endMinute: slot.minute + 30,
            );
          }
        }
      }

      // Add the last range
      if (currentRange != null) {
        ranges.add(currentRange);
      }

      result.add(
        CourtBookingSummary(
          subCourtIndex: entry.key,
          subCourtId: courtSlots.first.subCourtId,
          subCourtName: courtSlots.first.subCourtName,
          timeRanges: ranges,
          totalSlots: courtSlots.length,
          totalPrice: courtSlots.fold(0.0, (sum, s) => sum + s.price),
        ),
      );
    }

    return result;
  }

  /// Check if selection is empty
  bool get isEmpty => slots.isEmpty;

  /// Check if selection is not empty
  bool get isNotEmpty => slots.isNotEmpty;

  /// Get number of selected slots
  int get slotCount => slots.length;

  /// Get number of courts with selections
  int get courtCount => slotsByCourtIndex.keys.length;
}

/// A time range (start to end)
class TimeRange {
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  const TimeRange({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  String get startTimeString =>
      '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';

  String get endTimeString =>
      '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

  String get formatted => '$startTimeString - $endTimeString';

  int get durationMinutes =>
      (endHour * 60 + endMinute) - (startHour * 60 + startMinute);
}

/// Summary of bookings for a single court
class CourtBookingSummary {
  final int subCourtIndex;
  final String subCourtId;
  final String subCourtName;
  final List<TimeRange> timeRanges;
  final int totalSlots;
  final double totalPrice;

  const CourtBookingSummary({
    required this.subCourtIndex,
    this.subCourtId = '',
    required this.subCourtName,
    required this.timeRanges,
    required this.totalSlots,
    required this.totalPrice,
  });

  int get totalDurationMinutes => totalSlots * 30;

  String get durationFormatted {
    final minutes = totalDurationMinutes;
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours == 0) return '${mins}m';
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }
}
