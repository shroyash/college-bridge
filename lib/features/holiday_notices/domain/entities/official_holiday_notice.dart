import 'package:equatable/equatable.dart';
import 'holiday_notice_enums.dart';

class OfficialHolidayNotice extends Equatable {
  final int noticeId;
  final int institutionId;
  final String dateAd;
  final String dateBs;
  final String holidayName;
  final NoticeVariant variant;
  final String title;
  final String body;
  final String? publishedAt;

  const OfficialHolidayNotice({
    required this.noticeId,
    required this.institutionId,
    required this.dateAd,
    required this.dateBs,
    required this.holidayName,
    required this.variant,
    required this.title,
    required this.body,
    this.publishedAt,
  });

  @override
  List<Object?> get props => [
        noticeId,
        institutionId,
        dateAd,
        dateBs,
        holidayName,
        variant,
        title,
        body,
        publishedAt,
      ];
}
