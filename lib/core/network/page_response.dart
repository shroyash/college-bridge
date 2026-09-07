import 'package:equatable/equatable.dart';

/// Reusable pagination wrapper matching Spring Data [Page<T>] and custom [PageResponse<T>]:
/// {
///   "content": [...],
///   "pageNumber": 0,
///   "pageSize": 20,
///   "totalElements": 100,
///   "totalPages": 5,
///   "last": false,
///   "first": true
/// }
class PageResponse<T> extends Equatable {
  final List<T> content;
  final int pageNumber;
  final int pageSize;
  final int totalElements;
  final int totalPages;
  final bool last;
  final bool first;

  const PageResponse({
    required this.content,
    required this.pageNumber,
    required this.pageSize,
    required this.totalElements,
    required this.totalPages,
    required this.last,
    required this.first,
  });

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    final rawContent = json['content'] as List<dynamic>? ?? [];
    final contentList = rawContent.map((item) => fromJsonT(item)).toList();

    // Check pageable structure if present (Spring default Page structure)
    int pNumber = 0;
    int pSize = contentList.length;

    if (json.containsKey('pageable') && json['pageable'] is Map) {
      final pageable = json['pageable'] as Map<String, dynamic>;
      pNumber = pageable['pageNumber'] as int? ?? 0;
      pSize = pageable['pageSize'] as int? ?? (json['size'] as int? ?? pSize);
    } else {
      pNumber = json['pageNumber'] as int? ?? (json['number'] as int? ?? 0);
      pSize = json['pageSize'] as int? ?? (json['size'] as int? ?? pSize);
    }

    final totalElem = json['totalElements'] as int? ?? contentList.length;
    final totalPgs = json['totalPages'] as int? ?? (totalElem > 0 ? (totalElem / (pSize > 0 ? pSize : 1)).ceil() : 1);

    return PageResponse<T>(
      content: contentList,
      pageNumber: pNumber,
      pageSize: pSize,
      totalElements: totalElem,
      totalPages: totalPgs,
      last: json['last'] as bool? ?? (pNumber >= totalPgs - 1),
      first: json['first'] as bool? ?? (pNumber == 0),
    );
  }

  @override
  List<Object?> get props => [
        content,
        pageNumber,
        pageSize,
        totalElements,
        totalPages,
        last,
        first,
      ];
}
