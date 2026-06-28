/// Skill level enum for match participants
enum SkillLevel {
  tby('TBY', 'Tập bộ Y'),
  y('Y', 'Yếu'),
  yPlus('Y_PLUS', 'Yếu+'),
  yPlusPlus('Y_PLUS_PLUS', 'Yếu++'),
  tbk('TBK', 'Trung bình khá'),
  tb('TB', 'Trung bình'),
  tbPlus('TB_PLUS', 'Trung bình+'),
  tbPlusPlus('TB_PLUS_PLUS', 'Trung bình++'),
  k('K', 'Khá'),
  kPlus('K_PLUS', 'Khá+'),
  gioi('GIOI', 'Giỏi');

  final String value;
  final String displayName;
  const SkillLevel(this.value, this.displayName);

  static SkillLevel fromString(String value) {
    return SkillLevel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SkillLevel.tb,
    );
  }
}

/// Shuttle type enum
enum ShuttleType {
  tc77('TC77', 'TC77'),
  tc75('TC75', 'TC75'),
  basao('BASAO', 'Ba Sao'),
  lieningA60('LIENING_A60', 'Li-Ning A60'),
  lieningA62('LIENING_A62', 'Li-Ning A62'),
  yonexAs05('YONEX_AS05', 'Yonex AS05'),
  yonexAs30('YONEX_AS30', 'Yonex AS30'),
  victorMasterAce('VICTOR_MASTER_ACE', 'Victor Master Ace'),
  other('OTHER', 'Khác');

  final String value;
  final String displayName;
  const ShuttleType(this.value, this.displayName);

  static ShuttleType fromString(String value) {
    return ShuttleType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ShuttleType.other,
    );
  }
}

/// Player format enum
enum PlayerFormat {
  singleMale('SINGLE_MALE', 'Đơn nam'),
  singleFemale('SINGLE_FEMALE', 'Đơn nữ'),
  doubleMale('DOUBLE_MALE', 'Đôi nam'),
  doubleFemale('DOUBLE_FEMALE', 'Đôi nữ'),
  mixedDouble('MIXED_DOUBLE', 'Đôi nam nữ'),
  any('ANY', 'Linh hoạt');

  final String value;
  final String displayName;
  const PlayerFormat(this.value, this.displayName);

  static PlayerFormat fromString(String value) {
    return PlayerFormat.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PlayerFormat.any,
    );
  }
}

/// Match status enum
enum MatchStatus {
  open('OPEN', 'Đang mở'),
  full('FULL', 'Đã đủ người'),
  inProgress('IN_PROGRESS', 'Đang diễn ra'),
  completed('COMPLETED', 'Đã hoàn thành'),
  cancelled('CANCELLED', 'Đã hủy');

  final String value;
  final String displayName;
  const MatchStatus(this.value, this.displayName);

  static MatchStatus fromString(String value) {
    return MatchStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MatchStatus.open,
    );
  }
}

/// Match player status enum
enum MatchPlayerStatus {
  pending('PENDING', 'Đang chờ'),
  pendingPayment('PENDING_PAYMENT', 'Chờ thanh toán'),
  accepted('ACCEPTED', 'Đã chấp nhận'),
  rejected('REJECTED', 'Đã từ chối'),
  left('LEFT', 'Đã rời'),
  expired('EXPIRED', 'Đã hết hạn');

  final String value;
  final String displayName;
  const MatchPlayerStatus(this.value, this.displayName);

  static MatchPlayerStatus fromString(String value) {
    return MatchPlayerStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MatchPlayerStatus.pending,
    );
  }
}

/// Compact court info for match display
class MatchCourt {
  final String id;
  final String name;
  final String? addressFull;
  final String? addressCity;
  final String? addressDistrict;

  const MatchCourt({
    required this.id,
    required this.name,
    this.addressFull,
    this.addressCity,
    this.addressDistrict,
  });

  factory MatchCourt.fromJson(Map<String, dynamic> json) {
    return MatchCourt(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      addressFull: json['addressFull'] as String?,
      addressCity: json['addressCity'] as String?,
      addressDistrict: json['addressDistrict'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'addressFull': addressFull,
      'addressCity': addressCity,
      'addressDistrict': addressDistrict,
    };
  }
}

/// Compact host user info for match display
class MatchHost {
  final String id;
  final String? displayName;
  final String? avatarUrl;

  const MatchHost({required this.id, this.displayName, this.avatarUrl});

  factory MatchHost.fromJson(Map<String, dynamic> json) {
    return MatchHost(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'displayName': displayName, 'avatarUrl': avatarUrl};
  }
}

/// Player user info for match player display
class MatchPlayerUser {
  final String id;
  final String? displayName;
  final String? avatarUrl;

  const MatchPlayerUser({required this.id, this.displayName, this.avatarUrl});

  factory MatchPlayerUser.fromJson(Map<String, dynamic> json) {
    return MatchPlayerUser(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'displayName': displayName, 'avatarUrl': avatarUrl};
  }
}

/// Match player model
class MatchPlayer {
  final String id;
  final String matchId;
  final String userId;
  final MatchPlayerStatus status;
  final DateTime joinedAt;
  final MatchPlayerUser? user;

  const MatchPlayer({
    required this.id,
    required this.matchId,
    required this.userId,
    required this.status,
    required this.joinedAt,
    this.user,
  });

  factory MatchPlayer.fromJson(Map<String, dynamic> json) {
    // Handle user data - support both nested 'user' object and flat fields
    MatchPlayerUser? user;
    if (json['user'] != null) {
      user = MatchPlayerUser.fromJson(json['user'] as Map<String, dynamic>);
    } else if (json['userName'] != null || json['userPhotoUrl'] != null) {
      // Fallback to flat fields from API response
      user = MatchPlayerUser(
        id: json['userId'] as String? ?? '',
        displayName: json['userName'] as String?,
        avatarUrl: json['userPhotoUrl'] as String?,
      );
    }

    // Handle joinedAt - support both 'joinedAt' and 'requestedAt' field names
    DateTime joinedAt;
    if (json['joinedAt'] != null) {
      joinedAt = DateTime.parse(json['joinedAt'] as String);
    } else if (json['requestedAt'] != null) {
      joinedAt = DateTime.parse(json['requestedAt'] as String);
    } else {
      joinedAt = DateTime.now();
    }

    return MatchPlayer(
      id: json['id'] as String? ?? '',
      matchId: json['matchId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      status: MatchPlayerStatus.fromString(
        json['status'] as String? ?? 'PENDING',
      ),
      joinedAt: joinedAt,
      user: user,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matchId': matchId,
      'userId': userId,
      'status': status.value,
      'joinedAt': joinedAt.toIso8601String(),
      'user': user?.toJson(),
    };
  }
}

/// Current user's status in a match (returned when authenticated)
class CurrentUserStatus {
  final String id; // MatchPlayer record ID - use this for API calls
  final MatchPlayerStatus status;
  final int? position;
  final DateTime requestedAt;
  final DateTime? respondedAt;

  const CurrentUserStatus({
    required this.id,
    required this.status,
    this.position,
    required this.requestedAt,
    this.respondedAt,
  });

  factory CurrentUserStatus.fromJson(Map<String, dynamic> json) {
    return CurrentUserStatus(
      id: json['id'] as String? ?? '',
      status: MatchPlayerStatus.fromString(
        json['status'] as String? ?? 'PENDING',
      ),
      position: json['position'] as int?,
      requestedAt: json['requestedAt'] != null
          ? DateTime.parse(json['requestedAt'] as String)
          : DateTime.now(),
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status.value,
      'position': position,
      'requestedAt': requestedAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
    };
  }
}

/// Base match model
class Match {
  final String id;
  final String courtId;
  final String hostUserId;
  final String title;
  final String? description;
  final List<String> images;
  final SkillLevel skillLevel;
  final ShuttleType shuttleType;
  final PlayerFormat playerFormat;
  final String date;
  final String startTime;
  final String endTime;
  final bool isPrivate;
  final int price;
  final int slotsNeeded;
  final MatchStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Match({
    required this.id,
    required this.courtId,
    required this.hostUserId,
    required this.title,
    this.description,
    this.images = const [],
    required this.skillLevel,
    required this.shuttleType,
    required this.playerFormat,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isPrivate,
    required this.price,
    required this.slotsNeeded,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] as String? ?? '',
      courtId: json['courtId'] as String? ?? '',
      hostUserId: json['hostUserId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      skillLevel: SkillLevel.fromString(json['skillLevel'] as String? ?? 'TB'),
      shuttleType: ShuttleType.fromString(
        json['shuttleType'] as String? ?? 'OTHER',
      ),
      playerFormat: PlayerFormat.fromString(
        json['playerFormat'] as String? ?? 'ANY',
      ),
      date: json['date'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      isPrivate: json['isPrivate'] as bool? ?? false,
      price: json['price'] as int? ?? 0,
      slotsNeeded: json['slotsNeeded'] as int? ?? 0,
      status: MatchStatus.fromString(json['status'] as String? ?? 'OPEN'),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courtId': courtId,
      'hostUserId': hostUserId,
      'title': title,
      'description': description,
      'images': images,
      'skillLevel': skillLevel.value,
      'shuttleType': shuttleType.value,
      'playerFormat': playerFormat.value,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'isPrivate': isPrivate,
      'price': price,
      'slotsNeeded': slotsNeeded,
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// Match with full details including court, host, and players
class MatchWithDetails extends Match {
  final MatchCourt? court;
  final MatchHost? host;
  final List<MatchPlayer> players;
  final int acceptedPlayersCount;
  final CurrentUserStatus? currentUserStatus;

  const MatchWithDetails({
    required super.id,
    required super.courtId,
    required super.hostUserId,
    required super.title,
    super.description,
    super.images,
    required super.skillLevel,
    required super.shuttleType,
    required super.playerFormat,
    required super.date,
    required super.startTime,
    required super.endTime,
    required super.isPrivate,
    required super.price,
    required super.slotsNeeded,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    this.court,
    this.host,
    this.players = const [],
    this.acceptedPlayersCount = 0,
    this.currentUserStatus,
  });

  factory MatchWithDetails.fromJson(Map<String, dynamic> json) {
    // Handle court data - support both nested 'court' object and flat fields
    MatchCourt? court;
    if (json['court'] != null) {
      court = MatchCourt.fromJson(json['court'] as Map<String, dynamic>);
    } else if (json['courtName'] != null || json['courtAddress'] != null) {
      // Fallback to flat fields from API response
      court = MatchCourt(
        id: json['courtId'] as String? ?? '',
        name: json['courtName'] as String? ?? '',
        addressFull: json['courtAddress'] as String?,
      );
    }

    // Handle host data - support both nested 'host' object and flat fields
    MatchHost? host;
    if (json['host'] != null) {
      host = MatchHost.fromJson(json['host'] as Map<String, dynamic>);
    } else if (json['hostName'] != null || json['hostUserId'] != null) {
      // Fallback to flat fields from API response
      host = MatchHost(
        id: json['hostUserId'] as String? ?? '',
        displayName: json['hostName'] as String?,
      );
    }

    // Handle players - also parse flat player format from API
    final playersList = <MatchPlayer>[];
    final playersJson = json['players'] as List<dynamic>?;
    if (playersJson != null) {
      for (final p in playersJson) {
        if (p is Map<String, dynamic>) {
          playersList.add(MatchPlayer.fromJson(p));
        }
      }
    }

    // Handle acceptedPlayersCount - support both nested and flat 'slotsAccepted'
    final acceptedCount =
        json['acceptedPlayersCount'] as int? ??
        json['slotsAccepted'] as int? ??
        0;

    // Parse currentUserStatus if present (only returned for authenticated users)
    CurrentUserStatus? currentUserStatus;
    if (json['currentUserStatus'] != null) {
      currentUserStatus = CurrentUserStatus.fromJson(
        json['currentUserStatus'] as Map<String, dynamic>,
      );
    }

    return MatchWithDetails(
      id: json['id'] as String? ?? '',
      courtId: json['courtId'] as String? ?? '',
      hostUserId: json['hostUserId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      skillLevel: SkillLevel.fromString(json['skillLevel'] as String? ?? 'TB'),
      shuttleType: ShuttleType.fromString(
        json['shuttleType'] as String? ?? 'OTHER',
      ),
      playerFormat: PlayerFormat.fromString(
        json['playerFormat'] as String? ?? 'ANY',
      ),
      date: json['date'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      isPrivate: json['isPrivate'] as bool? ?? false,
      price: json['price'] as int? ?? 0,
      slotsNeeded: json['slotsNeeded'] as int? ?? 0,
      status: MatchStatus.fromString(json['status'] as String? ?? 'OPEN'),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      court: court,
      host: host,
      players: playersList,
      acceptedPlayersCount: acceptedCount,
      currentUserStatus: currentUserStatus,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'court': court?.toJson(),
      'host': host?.toJson(),
      'players': players.map((e) => e.toJson()).toList(),
      'acceptedPlayersCount': acceptedPlayersCount,
      'currentUserStatus': currentUserStatus?.toJson(),
    };
  }

  /// Get total current players count (NOT including host)
  /// acceptedPlayersCount is the number of accepted players (not including host)
  /// slotsNeeded does NOT include the host, so totalPlayersCount = acceptedPlayersCount
  int get totalPlayersCount => acceptedPlayersCount;

  /// Get remaining slots
  int get remainingSlots => slotsNeeded - acceptedPlayersCount;

  /// Check if match is full
  bool get isFull => remainingSlots <= 0;

  /// Get pending players
  List<MatchPlayer> get pendingPlayers =>
      players.where((p) => p.status == MatchPlayerStatus.pending).toList();

  /// Get accepted players
  List<MatchPlayer> get acceptedPlayers =>
      players.where((p) => p.status == MatchPlayerStatus.accepted).toList();
}

/// Request model for creating a match
class CreateMatchRequest {
  final String courtId;
  final String title;
  final String? description;
  final List<String>? images;
  final SkillLevel skillLevel;
  final ShuttleType shuttleType;
  final PlayerFormat playerFormat;
  final String date;
  final String startTime;
  final String endTime;
  final bool isPrivate;
  final int price;
  final int slotsNeeded;

  const CreateMatchRequest({
    required this.courtId,
    required this.title,
    this.description,
    this.images,
    required this.skillLevel,
    required this.shuttleType,
    required this.playerFormat,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.isPrivate = false,
    required this.price,
    required this.slotsNeeded,
  });

  Map<String, dynamic> toJson() {
    return {
      'courtId': courtId,
      'title': title,
      if (description != null) 'description': description,
      if (images != null && images!.isNotEmpty) 'images': images,
      'skillLevel': skillLevel.value,
      'shuttleType': shuttleType.value,
      'playerFormat': playerFormat.value,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'isPrivate': isPrivate,
      'price': price,
      'slotsNeeded': slotsNeeded,
    };
  }
}

/// Request model for updating a match
class UpdateMatchRequest {
  final String? title;
  final String? description;
  final List<String>? images;
  final SkillLevel? skillLevel;
  final ShuttleType? shuttleType;
  final PlayerFormat? playerFormat;
  final String? date;
  final String? startTime;
  final String? endTime;
  final bool? isPrivate;
  final int? price;
  final int? slotsNeeded;

  const UpdateMatchRequest({
    this.title,
    this.description,
    this.images,
    this.skillLevel,
    this.shuttleType,
    this.playerFormat,
    this.date,
    this.startTime,
    this.endTime,
    this.isPrivate,
    this.price,
    this.slotsNeeded,
  });

  Map<String, dynamic> toJson() {
    return {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (images != null) 'images': images,
      if (skillLevel != null) 'skillLevel': skillLevel!.value,
      if (shuttleType != null) 'shuttleType': shuttleType!.value,
      if (playerFormat != null) 'playerFormat': playerFormat!.value,
      if (date != null) 'date': date,
      if (startTime != null) 'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
      if (isPrivate != null) 'isPrivate': isPrivate,
      if (price != null) 'price': price,
      if (slotsNeeded != null) 'slotsNeeded': slotsNeeded,
    };
  }
}

/// Request model for joining a match
class JoinMatchRequest {
  final String? message;

  const JoinMatchRequest({this.message});

  Map<String, dynamic> toJson() {
    return {if (message != null) 'message': message};
  }
}

/// Request model for responding to a join request
class RespondToJoinRequest {
  final String status; // 'ACCEPTED' or 'REJECTED'

  const RespondToJoinRequest({required this.status});

  Map<String, dynamic> toJson() {
    return {'status': status};
  }
}

/// Match payment status enum
enum MatchPaymentStatus {
  pending('pending'),
  success('success'),
  failed('failed'),
  expired('expired');

  final String value;
  const MatchPaymentStatus(this.value);

  static MatchPaymentStatus fromString(String value) {
    return MatchPaymentStatus.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => MatchPaymentStatus.pending,
    );
  }
}

/// Match payment model
class MatchPayment {
  final String id;
  final String bookingId; // Match ID for compatibility
  final String appTransId;
  final String? zpTransId;
  final int amount;
  final MatchPaymentStatus status;
  final String? orderUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MatchPayment({
    required this.id,
    required this.bookingId,
    required this.appTransId,
    this.zpTransId,
    required this.amount,
    required this.status,
    this.orderUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MatchPayment.fromJson(Map<String, dynamic> json) {
    return MatchPayment(
      id: json['id'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? '',
      appTransId: json['appTransId'] as String? ?? '',
      zpTransId: json['zpTransId'] as String?,
      amount: json['amount'] as int? ?? 0,
      status: MatchPaymentStatus.fromString(
        json['status'] as String? ?? 'pending',
      ),
      orderUrl: json['orderUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}

/// QR Code model for payment
class PaymentQRCode {
  final String base64;
  final String rawBase64;

  const PaymentQRCode({required this.base64, required this.rawBase64});

  factory PaymentQRCode.fromJson(Map<String, dynamic> json) {
    return PaymentQRCode(
      base64: json['base64'] as String? ?? '',
      rawBase64: json['rawBase64'] as String? ?? '',
    );
  }
}

/// Match payment response containing payment info and QR code
class MatchPaymentResponse {
  final MatchPayment payment;
  final String orderUrl;
  final PaymentQRCode qrCode;
  final String? zpTransToken;
  final DateTime expireAt;
  final String wsSubscribeUrl;

  const MatchPaymentResponse({
    required this.payment,
    required this.orderUrl,
    required this.qrCode,
    this.zpTransToken,
    required this.expireAt,
    required this.wsSubscribeUrl,
  });

  factory MatchPaymentResponse.fromJson(Map<String, dynamic> json) {
    return MatchPaymentResponse(
      payment: MatchPayment.fromJson(json['payment'] as Map<String, dynamic>),
      orderUrl: json['orderUrl'] as String? ?? '',
      qrCode: PaymentQRCode.fromJson(json['qrCode'] as Map<String, dynamic>),
      zpTransToken: json['zpTransToken'] as String?,
      expireAt: json['expireAt'] != null
          ? DateTime.parse(json['expireAt'] as String)
          : DateTime.now().add(const Duration(minutes: 15)),
      wsSubscribeUrl: json['wsSubscribeUrl'] as String? ?? '',
    );
  }
}
