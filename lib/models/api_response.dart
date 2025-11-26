/// Generic API response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final ApiError? error;
  final PaginationMeta? meta;

  const ApiResponse({required this.success, this.data, this.error, this.meta});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] as bool,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : null,
      error: json['error'] != null
          ? ApiError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
      meta: json['meta'] != null
          ? PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// API error details
class ApiError {
  final String message;

  const ApiError({required this.message});

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(message: json['message'] as String);
  }
}

/// Pagination metadata
class PaginationMeta {
  final PaginationInfo pagination;

  const PaginationMeta({required this.pagination});

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      pagination: PaginationInfo.fromJson(
        json['pagination'] as Map<String, dynamic>,
      ),
    );
  }
}

/// Pagination details
class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      totalPages: json['totalPages'] as int,
      hasNext: json['hasNext'] as bool,
      hasPrev: json['hasPrev'] as bool,
    );
  }
}
