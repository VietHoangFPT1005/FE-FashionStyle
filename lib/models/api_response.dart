/// Generic API response wrapper matching BE's ApiResponse<T>
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResponse({required this.success, required this.message, this.data});

  factory ApiResponse.fromJson(
    dynamic rawJson,
    T Function(dynamic)? fromJsonT,
  ) {
    if (rawJson is! Map<String, dynamic>) {
      return ApiResponse(success: false, message: rawJson?.toString() ?? 'Unknown error');
    }

    final json = rawJson;

    // Handle ASP.NET validation error format: {type, title, status, errors}
    if (json.containsKey('errors') && json.containsKey('status')) {
      final errors = json['errors'] as Map<String, dynamic>?;
      final messages = <String>[];
      errors?.forEach((key, value) {
        if (value is List) {
          messages.addAll(value.map((e) => e.toString()));
        } else {
          messages.add(value.toString());
        }
      });
      return ApiResponse(
        success: false,
        message: messages.isNotEmpty ? messages.join('. ') : (json['title'] ?? 'Validation error'),
      );
    }

    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
    );
  }
}

/// Paginated response matching BE's PaginatedResponse<T>
class PaginatedResponse<T> {
  final List<T> items;
  final PaginationInfo pagination;

  PaginatedResponse({required this.items, required this.pagination});

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponse(
      items: (json['items'] as List? ?? [])
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
    );
  }
}

class PaginationInfo {
  final int currentPage;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  PaginationInfo({
    this.currentPage = 1,
    this.pageSize = 10,
    this.totalItems = 0,
    this.totalPages = 0,
    this.hasNext = false,
    this.hasPrevious = false,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['currentPage'] ?? 1,
      pageSize: json['pageSize'] ?? 10,
      totalItems: json['totalItems'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      hasNext: json['hasNext'] ?? false,
      hasPrevious: json['hasPrevious'] ?? false,
    );
  }
}
