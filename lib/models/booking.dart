/// Model representing a booking response from the API
class Booking {
  final String id;
  final String subCourtId;
  final String? subCourtName;
  final String? courtId;
  final String? courtName;
  final String guestName;
  final String guestPhone;
  final String? guestEmail;
  final String date;
  final String startTime;
  final String endTime;
  final int totalPrice;
  final BookingStatus status;
  final String? notes;
  final DateTime? createdAt;

  const Booking({
    required this.id,
    required this.subCourtId,
    this.subCourtName,
    this.courtId,
    this.courtName,
    required this.guestName,
    required this.guestPhone,
    this.guestEmail,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    required this.status,
    this.notes,
    this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      subCourtId: json['subCourtId'] as String,
      subCourtName: json['subCourtName'] as String?,
      courtId: json['courtId'] as String?,
      courtName: json['courtName'] as String?,
      guestName: json['guestName'] as String,
      guestPhone: json['guestPhone'] as String,
      guestEmail: json['guestEmail'] as String?,
      date: json['date'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      totalPrice: json['totalPrice'] as int,
      status: BookingStatus.fromString(json['status'] as String),
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subCourtId': subCourtId,
      'subCourtName': subCourtName,
      'courtId': courtId,
      'courtName': courtName,
      'guestName': guestName,
      'guestPhone': guestPhone,
      'guestEmail': guestEmail,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'totalPrice': totalPrice,
      'status': status.value,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

/// Booking status enum
enum BookingStatus {
  pending('pending'),
  confirmed('confirmed'),
  cancelled('cancelled'),
  completed('completed');

  final String value;
  const BookingStatus(this.value);

  static BookingStatus fromString(String value) {
    return BookingStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BookingStatus.pending,
    );
  }
}

/// Request model for creating a booking
class CreateBookingRequest {
  final String subCourtId;
  final String guestName;
  final String guestPhone;
  final String? guestEmail;
  final String date;
  final String startTime;
  final String endTime;
  final String? notes;

  const CreateBookingRequest({
    required this.subCourtId,
    required this.guestName,
    required this.guestPhone,
    this.guestEmail,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'subCourtId': subCourtId,
      'guestName': guestName,
      'guestPhone': guestPhone,
      if (guestEmail != null) 'guestEmail': guestEmail,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      if (notes != null) 'notes': notes,
    };
  }
}

