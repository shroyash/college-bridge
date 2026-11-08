import 'package:equatable/equatable.dart';
import 'holiday_notice_enums.dart';

class HolidayNoticeDraft extends Equatable {
  final NoticeVariant variant;
  final String title;
  final String body;
  final NoticeOrigin origin;
  final String? model;

  const HolidayNoticeDraft({
    required this.variant,
    required this.title,
    required this.body,
    this.origin = NoticeOrigin.AI,
    this.model,
  });

  @override
  List<Object?> get props => [variant, title, body, origin, model];
}
