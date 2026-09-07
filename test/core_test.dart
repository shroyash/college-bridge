import 'package:flutter_test/flutter_test.dart';
import 'package:bridge_mobile/core/network/api_response.dart';
import 'package:bridge_mobile/core/network/page_response.dart';

void main() {
  group('Core Network Deserialization Tests', () {
    test('ApiResponse parses success response correctly', () {
      final json = {
        'success': true,
        'message': 'Data retrieved successfully',
        'data': {'id': 101, 'title': 'Test Subject'},
      };

      final response = ApiResponse.fromJson(
        json,
        (item) => item['title'] as String,
      );

      expect(response.success, true);
      expect(response.message, 'Data retrieved successfully');
      expect(response.data, 'Test Subject');
    });

    test('PageResponse parses Spring Data page correctly', () {
      final json = {
        'content': [
          {'id': 1, 'name': 'Item 1'},
          {'id': 2, 'name': 'Item 2'},
        ],
        'pageable': {'pageNumber': 0, 'pageSize': 10},
        'totalElements': 2,
        'totalPages': 1,
        'last': true,
        'first': true,
      };

      final page = PageResponse.fromJson(
        json,
        (item) => item['name'] as String,
      );

      expect(page.content.length, 2);
      expect(page.content.first, 'Item 1');
      expect(page.pageNumber, 0);
      expect(page.totalElements, 2);
      expect(page.first, true);
      expect(page.last, true);
    });
  });
}
