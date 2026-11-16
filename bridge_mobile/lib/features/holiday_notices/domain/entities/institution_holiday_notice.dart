import 'package:equatable/equatable.dart';
import 'holiday_notice_enums.dart';

class InstitutionHolidayNotice extends Equatable {
  final int id;
  final int holidayId;
  final String holidayDateAd;
  final String holidayDateBs;
  final String holidayName;
  final int institutionId;
  final NoticeStatus status;
  final NoticeVariant? variant;
  final String? finalTitle;
  final String? finalBody;
  final String? customTitle;
  final String? customBody;
  final bool notifyStudents;
  final bool notifyTeachers;
  final int? approvedBy;
  final String? approvedAt;
  final String? publishedAt;
  final String? expiredAt;
  final int attempts;
  final int? version;

  const InstitutionHolidayNotice({
    required this.id,
    required this.holidayId,
    required this.holidayDateAd,
    required this.holidayDateBs,
    required this.holidayName,
    required this.institutionId,
    required this.status,
    this.variant,
    this.finalTitle,
    this.finalBody,
    this.customTitle,
    this.customBody,
    this.notifyStudents = true,
    this.notifyTeachers = true,
    this.approvedBy,
    this.approvedAt,
    this.publishedAt,
    this.expiredAt,
    this.attempts = 0,
    this.version,
  });

  @override
  List<Object?> get props => [
        id,
        holidayId,
        holidayDateAd,
        holidayDateBs,
        holidayName,
        institutionId,
        status,
        variant,
        finalTitle,
        finalBody,
        customTitle,
        customBody,
        notifyStudents,
        notifyTeachers,
        approvedBy,
        approvedAt,
        publishedAt,
        expiredAt,
        attempts,
        version,
      ];
}
