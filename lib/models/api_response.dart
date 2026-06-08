/// Pagination metadata that mirrors the Mock API response shape.
class PageMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const PageMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PageMeta.fromJson(Map<String, dynamic> json) {
    return PageMeta(
      currentPage: json['current_page'] as int,
      lastPage: json['last_page'] as int,
      perPage: json['per_page'] as int,
      total: json['total'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'current_page': currentPage,
        'last_page': lastPage,
        'per_page': perPage,
        'total': total,
      };

  bool get hasNextPage => currentPage < lastPage;
}

/// Generic paginated response: `{ "data": [...], "meta": {...} }`.
class PaginatedResponse<T> {
  final List<T> data;
  final PageMeta meta;

  const PaginatedResponse({required this.data, required this.meta});

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponse<T>(
      data: (json['data'] as List<dynamic>)
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      meta: PageMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }
}
