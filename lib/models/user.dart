/// User profile model matching the backend API UserProfile schema
class UserProfile {
  final String id;
  final String firebaseUid;
  final String? email;
  final String? username;
  final UserAuthProvider provider;
  final bool isAnonymous;
  final String? firstName;
  final String? lastName;
  final Gender? gender;
  final String? phoneNumber;
  final String? photoUrl;
  final UserAddress? address;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.firebaseUid,
    this.email,
    this.username,
    required this.provider,
    required this.isAnonymous,
    this.firstName,
    this.lastName,
    this.gender,
    this.phoneNumber,
    this.photoUrl,
    this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Display name - returns username, full name, or "Anonymous User"
  String get displayName {
    if (username != null && username!.isNotEmpty) {
      return username!;
    }
    final fullName = [firstName, lastName]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ');
    if (fullName.isNotEmpty) {
      return fullName;
    }
    return isAnonymous ? 'Anonymous User' : 'User';
  }

  /// Returns initials for avatar
  String get initials {
    if (firstName != null && firstName!.isNotEmpty) {
      if (lastName != null && lastName!.isNotEmpty) {
        return '${firstName![0]}${lastName![0]}'.toUpperCase();
      }
      return firstName![0].toUpperCase();
    }
    if (username != null && username!.isNotEmpty) {
      return username![0].toUpperCase();
    }
    return isAnonymous ? 'A' : 'U';
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      firebaseUid: json['firebaseUid'] as String,
      email: json['email'] as String?,
      username: json['username'] as String?,
      provider: UserAuthProvider.fromString(json['provider'] as String? ?? 'anonymous'),
      isAnonymous: json['isAnonymous'] as bool? ?? true,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      gender: json['gender'] != null
          ? Gender.fromString(json['gender'] as String)
          : null,
      phoneNumber: json['phoneNumber'] as String?,
      photoUrl: json['photoUrl'] as String?,
      address: json['address'] != null
          ? UserAddress.fromJson(json['address'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebaseUid': firebaseUid,
      'email': email,
      'username': username,
      'provider': provider.value,
      'isAnonymous': isAnonymous,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender?.value,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'address': address?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? firebaseUid,
    String? email,
    String? username,
    UserAuthProvider? provider,
    bool? isAnonymous,
    String? firstName,
    String? lastName,
    Gender? gender,
    String? phoneNumber,
    String? photoUrl,
    UserAddress? address,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      email: email ?? this.email,
      username: username ?? this.username,
      provider: provider ?? this.provider,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// User address model
class UserAddress {
  final String? street;
  final String? ward;
  final String? district;
  final String? city;

  const UserAddress({
    this.street,
    this.ward,
    this.district,
    this.city,
  });

  /// Returns formatted full address
  String get fullAddress {
    return [street, ward, district, city]
        .where((s) => s != null && s.isNotEmpty)
        .join(', ');
  }

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      street: json['street'] as String?,
      ward: json['ward'] as String?,
      district: json['district'] as String?,
      city: json['city'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'ward': ward,
      'district': district,
      'city': city,
    };
  }
}

/// Authentication provider enum
enum UserAuthProvider {
  google('google'),
  facebook('facebook'),
  password('password'),
  anonymous('anonymous');

  final String value;
  const UserAuthProvider(this.value);

  static UserAuthProvider fromString(String value) {
    return UserAuthProvider.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserAuthProvider.anonymous,
    );
  }
}

/// Gender enum
enum Gender {
  male('male'),
  female('female'),
  other('other'),
  preferNotToSay('prefer_not_to_say');

  final String value;
  const Gender(this.value);

  static Gender fromString(String value) {
    return Gender.values.firstWhere(
      (e) => e.value == value,
      orElse: () => Gender.preferNotToSay,
    );
  }

  String get displayName {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
      case Gender.preferNotToSay:
        return 'Prefer not to say';
    }
  }
}

/// Auth response from /api/auth/verify and /api/auth/anonymous
class AuthResponse {
  final UserProfile user;
  final bool isNewUser;

  const AuthResponse({
    required this.user,
    required this.isNewUser,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return AuthResponse(
      user: UserProfile.fromJson(data['user'] as Map<String, dynamic>),
      isNewUser: data['isNewUser'] as bool? ?? false,
    );
  }
}

/// Convert response from /api/auth/convert
class ConvertResponse {
  final UserProfile user;
  final bool converted;

  const ConvertResponse({
    required this.user,
    required this.converted,
  });

  factory ConvertResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return ConvertResponse(
      user: UserProfile.fromJson(data['user'] as Map<String, dynamic>),
      converted: data['converted'] as bool? ?? false,
    );
  }
}

/// Username availability check response
class UsernameAvailabilityResponse {
  final String username;
  final bool available;

  const UsernameAvailabilityResponse({
    required this.username,
    required this.available,
  });

  factory UsernameAvailabilityResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return UsernameAvailabilityResponse(
      username: data['username'] as String,
      available: data['available'] as bool,
    );
  }
}

/// Username lookup response (for username/password login)
class UsernameLookupResponse {
  final String username;
  final String email;

  const UsernameLookupResponse({
    required this.username,
    required this.email,
  });

  factory UsernameLookupResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return UsernameLookupResponse(
      username: data['username'] as String,
      email: data['email'] as String,
    );
  }
}

/// Link bookings response
class LinkBookingsResponse {
  final int linkedCount;
  final String message;

  const LinkBookingsResponse({
    required this.linkedCount,
    required this.message,
  });

  factory LinkBookingsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return LinkBookingsResponse(
      linkedCount: data['linkedCount'] as int,
      message: data['message'] as String,
    );
  }
}

/// Booking history item from /api/auth/me/bookings
class BookingHistoryItem {
  final String id;
  final DateTime date;
  final String startTime;
  final String endTime;
  final int totalPrice;
  final BookingStatus status;
  final String? notes;
  final DateTime createdAt;
  final BookingCourt court;
  final BookingSubCourt subCourt;

  const BookingHistoryItem({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.court,
    required this.subCourt,
  });

  factory BookingHistoryItem.fromJson(Map<String, dynamic> json) {
    return BookingHistoryItem(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      totalPrice: json['totalPrice'] as int,
      status: BookingStatus.fromString(json['status'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      court: BookingCourt.fromJson(json['court'] as Map<String, dynamic>),
      subCourt: BookingSubCourt.fromJson(json['subCourt'] as Map<String, dynamic>),
    );
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

  String get displayName {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.completed:
        return 'Completed';
    }
  }
}

/// Court info in booking history
class BookingCourt {
  final String id;
  final String name;
  final String? addressDistrict;
  final String? addressCity;

  const BookingCourt({
    required this.id,
    required this.name,
    this.addressDistrict,
    this.addressCity,
  });

  factory BookingCourt.fromJson(Map<String, dynamic> json) {
    return BookingCourt(
      id: json['id'] as String,
      name: json['name'] as String,
      addressDistrict: json['addressDistrict'] as String?,
      addressCity: json['addressCity'] as String?,
    );
  }
}

/// Sub-court info in booking history
class BookingSubCourt {
  final String id;
  final String name;

  const BookingSubCourt({
    required this.id,
    required this.name,
  });

  factory BookingSubCourt.fromJson(Map<String, dynamic> json) {
    return BookingSubCourt(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

/// Booking history response with pagination
class BookingHistoryResponse {
  final List<BookingHistoryItem> bookings;
  final BookingPagination pagination;

  const BookingHistoryResponse({
    required this.bookings,
    required this.pagination,
  });

  factory BookingHistoryResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return BookingHistoryResponse(
      bookings: (data['bookings'] as List<dynamic>)
          .map((e) => BookingHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: BookingPagination.fromJson(
          data['pagination'] as Map<String, dynamic>),
    );
  }
}

/// Pagination info for booking history
class BookingPagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const BookingPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  bool get hasNext => page < totalPages;
  bool get hasPrev => page > 1;

  factory BookingPagination.fromJson(Map<String, dynamic> json) {
    return BookingPagination(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      totalPages: json['totalPages'] as int,
    );
  }
}

/// Request model for updating user profile
class UpdateProfileRequest {
  final String? username;
  final String? firstName;
  final String? lastName;
  final Gender? gender;
  final String? phoneNumber;
  final String? photoUrl;
  final String? addressStreet;
  final String? addressWard;
  final String? addressDistrict;
  final String? addressCity;

  const UpdateProfileRequest({
    this.username,
    this.firstName,
    this.lastName,
    this.gender,
    this.phoneNumber,
    this.photoUrl,
    this.addressStreet,
    this.addressWard,
    this.addressDistrict,
    this.addressCity,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (username != null) json['username'] = username;
    if (firstName != null) json['firstName'] = firstName;
    if (lastName != null) json['lastName'] = lastName;
    if (gender != null) json['gender'] = gender!.value;
    if (phoneNumber != null) json['phoneNumber'] = phoneNumber;
    if (photoUrl != null) json['photoUrl'] = photoUrl;
    if (addressStreet != null) json['addressStreet'] = addressStreet;
    if (addressWard != null) json['addressWard'] = addressWard;
    if (addressDistrict != null) json['addressDistrict'] = addressDistrict;
    if (addressCity != null) json['addressCity'] = addressCity;
    return json;
  }
}

