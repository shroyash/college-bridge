import 'package:equatable/equatable.dart';
import 'holiday_notice_draft.dart';
import 'holiday_notice_enums.dart';

class PendingHolidayNotice extends Equatable {
  final int id;
  final int institutionId;
  final NoticeStatus status;
  final int holidayId;
  final String holidayDateAd;
  final String holidayDateBs;
  final String holidayName;
  final String? holidayScope;
  final HolidayNoticeDraft closedDraft;
  final HolidayNoticeDraft openDraft;
  final String? createdAt;

  const PendingHolidayNotice({
    required this.id,
    required this.institutionId,
    required this.status,
    required this.holidayId,
    required this.holidayDateAd,
    required this.holidayDateBs,
    required this.holidayName,
    this.holidayScope,
    required this.closedDraft,
    required this.openDraft,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        institutionId,
        status,
        holidayId,
        holidayDateAd,
        holidayDateBs,
        holidayName,
        holidayScope,
        closedDraft,
        openDraft,
        createdAt,
      ];
}
