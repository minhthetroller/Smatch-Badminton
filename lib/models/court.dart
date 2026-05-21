/// Model representing a badminton court
class Court {
  final String id;
  final String name;
  final String? description;
  final List<String> phoneNumbers;
  final String? addressStreet;
  final String? addressWard;
  final String? addressDistrict;
  final String? addressCity;
  final CourtDetails? details;
  final OpeningHours? openingHours;
  final CourtLocation? location;
  final double? distance; // Distance from user in meters (for nearby search)
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Court({
    required this.id,
    required this.name,
    this.description,
    this.phoneNumbers = const [],
    this.addressStreet,
    this.addressWard,
    this.addressDistrict,
    this.addressCity,
    this.details,
    this.openingHours,
    this.location,
    this.distance,
    this.createdAt,
    this.updatedAt,
  });

  /// Full address string
  String get fullAddress {
    final parts = [
      addressStreet,
      addressWard,
      addressDistrict,
      addressCity,
    ].where((part) => part != null && part.isNotEmpty).toList();
    return parts.join(', ');
  }

  /// Distance formatted as string
  String get distanceFormatted {
    if (distance == null) return '';
    if (distance! < 1000) {
      return '${distance!.toInt()}m';
    }
    return '${(distance! / 1000).toStringAsFixed(1)}km';
  }

  factory Court.fromJson(Map<String, dynamic> json) {
    CourtLocation? parsedLocation;
    final openingHoursJson = json['openingHours'] ?? json['opening_hours'];

    final locationJson = json['location'];
    if (locationJson is Map<String, dynamic>) {
      parsedLocation = CourtLocation.fromJson(locationJson);
    } else {
      // Backend may return top-level lat/lng instead of nested location.
      final lat = (json['lat'] ?? json['latitude']) as num?;
      final lng = (json['lng'] ?? json['longitude']) as num?;
      if (lat != null && lng != null) {
        parsedLocation = CourtLocation(
          latitude: lat.toDouble(),
          longitude: lng.toDouble(),
        );
      }
    }

    return Court(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      phoneNumbers:
          (json['phoneNumbers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      addressStreet: json['addressStreet'] as String?,
      addressWard: json['addressWard'] as String?,
      addressDistrict: json['addressDistrict'] as String?,
      addressCity: json['addressCity'] as String?,
      details: json['details'] != null
          ? CourtDetails.fromJson(json['details'] as Map<String, dynamic>)
          : null,
      openingHours: openingHoursJson is Map<String, dynamic>
          ? OpeningHours.fromJson(openingHoursJson)
          : null,
      location: parsedLocation,
      distance: (json['distance'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'phoneNumbers': phoneNumbers,
      'addressStreet': addressStreet,
      'addressWard': addressWard,
      'addressDistrict': addressDistrict,
      'addressCity': addressCity,
      'details': details?.toJson(),
      'openingHours': openingHours?.toJson(),
      'location': location?.toJson(),
      'distance': distance,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Court copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? phoneNumbers,
    String? addressStreet,
    String? addressWard,
    String? addressDistrict,
    String? addressCity,
    CourtDetails? details,
    OpeningHours? openingHours,
    CourtLocation? location,
    double? distance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Court(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      phoneNumbers: phoneNumbers ?? this.phoneNumbers,
      addressStreet: addressStreet ?? this.addressStreet,
      addressWard: addressWard ?? this.addressWard,
      addressDistrict: addressDistrict ?? this.addressDistrict,
      addressCity: addressCity ?? this.addressCity,
      details: details ?? this.details,
      openingHours: openingHours ?? this.openingHours,
      location: location ?? this.location,
      distance: distance ?? this.distance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Court details including amenities, payments, etc.
class CourtDetails {
  final List<String> amenities;
  final List<String> payments;
  final List<String> serviceOptions;
  final List<String> highlights;

  const CourtDetails({
    this.amenities = const [],
    this.payments = const [],
    this.serviceOptions = const [],
    this.highlights = const [],
  });

  factory CourtDetails.fromJson(Map<String, dynamic> json) {
    return CourtDetails(
      amenities:
          (json['amenities'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      payments:
          (json['payments'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      serviceOptions:
          (json['serviceOptions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      highlights:
          (json['highlights'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amenities': amenities,
      'payments': payments,
      'serviceOptions': serviceOptions,
      'highlights': highlights,
    };
  }
}

/// Opening hours for each day of the week
class OpeningHours {
  final String? mon;
  final String? tue;
  final String? wed;
  final String? thu;
  final String? fri;
  final String? sat;
  final String? sun;

  const OpeningHours({
    this.mon,
    this.tue,
    this.wed,
    this.thu,
    this.fri,
    this.sat,
    this.sun,
  });

  factory OpeningHours.fromJson(Map<String, dynamic> json) {
    String? mon = json['mon'] as String?;
    String? tue = json['tue'] as String?;
    String? wed = json['wed'] as String?;
    String? thu = json['thu'] as String?;
    String? fri = json['fri'] as String?;
    String? sat = json['sat'] as String?;
    String? sun = json['sun'] as String?;

    // Fallback to backend weekdays/weekends format
    final weekdays = json['weekdays'] as Map<String, dynamic>?;
    final weekends = json['weekends'] as Map<String, dynamic>?;

    if (weekdays != null) {
      final open = weekdays['open'] as String?;
      final close = weekdays['close'] as String?;
      if (open != null && close != null) {
        final range = '$open-$close';
        mon ??= range;
        tue ??= range;
        wed ??= range;
        thu ??= range;
        fri ??= range;
      }
    }

    if (weekends != null) {
      final open = weekends['open'] as String?;
      final close = weekends['close'] as String?;
      if (open != null && close != null) {
        final range = '$open-$close';
        sat ??= range;
        sun ??= range;
      }
    }

    return OpeningHours(
      mon: mon,
      tue: tue,
      wed: wed,
      thu: thu,
      fri: fri,
      sat: sat,
      sun: sun,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mon': mon,
      'tue': tue,
      'wed': wed,
      'thu': thu,
      'fri': fri,
      'sat': sat,
      'sun': sun,
    };
  }

  /// Get hours for a specific day (0 = Monday, 6 = Sunday)
  String? getHoursForDay(int dayIndex) {
    switch (dayIndex) {
      case 0:
        return mon;
      case 1:
        return tue;
      case 2:
        return wed;
      case 3:
        return thu;
      case 4:
        return fri;
      case 5:
        return sat;
      case 6:
        return sun;
      default:
        return null;
    }
  }

  /// Get today's hours
  String? get todayHours {
    final today = DateTime.now().weekday - 1; // weekday is 1-7
    return getHoursForDay(today);
  }
}

/// Geographic location
class CourtLocation {
  final double latitude;
  final double longitude;

  const CourtLocation({required this.latitude, required this.longitude});

  factory CourtLocation.fromJson(Map<String, dynamic> json) {
    final lat = (json['latitude'] ?? json['lat']) as num?;
    final lng = (json['longitude'] ?? json['lng']) as num?;
    if (lat == null || lng == null) {
      throw const FormatException(
        'CourtLocation requires latitude/longitude or lat/lng',
      );
    }

    return CourtLocation(latitude: lat.toDouble(), longitude: lng.toDouble());
  }

  Map<String, dynamic> toJson() {
    return {'latitude': latitude, 'longitude': longitude};
  }
}
