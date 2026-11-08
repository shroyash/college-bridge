import '../../domain/entities/holiday_notice_draft.dart';
import '../../domain/entities/holiday_notice_enums.dart';
import '../../domain/entities/institution_holiday_notice.dart';
import '../../domain/entities/official_holiday_notice.dart';
import '../../domain/entities/pending_holiday_notice.dart';

class HolidayDraftModel {
  final String title;
  final String body;
  final String? origin;
  final String? model;

  const HolidayDraftModel({
    required this.title,
    required this.body,
    this.origin,
    this.model,
  });

  factory HolidayDraftModel.fromJson(Map<String, dynamic> json) {
    return HolidayDraftModel(
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      origin: json['origin'] as String?,
      model: json['model'] as String?,
    );
  }

  HolidayNoticeDraft toEntity(NoticeVariant variant) {
    return HolidayNoticeDraft(
      variant: variant,
      title: title,
      body: body,
      origin: (origin?.toUpperCase() == 'TEMPLATE')
          ? NoticeOrigin.TEMPLATE
          : NoticeOrigin.AI,
      model: model,
    );
  }
}

class PendingNoticeModel {
  final int id;
  final int institutionId;
  final String status;
  final int holidayId;
  final String holidayDateAd;
  final String holidayDateBs;
  final String holidayName;
  final String? holidayScope;
  final HolidayDraftModel? closedDraft;
  final HolidayDraftModel? openDraft;
  final String? createdAt;

  const PendingNoticeModel({
    required this.id,
    required this.institutionId,
    required this.status,
    required this.holidayId,
    required this.holidayDateAd,
    required this.holidayDateBs,
    required this.holidayName,
    this.holidayScope,
    this.closedDraft,
    this.openDraft,
    this.createdAt,
  });

  factory PendingNoticeModel.fromJson(Map<String, dynamic> json) {
    return PendingNoticeModel(
      id: (json['id'] as num?)?.toInt() ?? (json['noticeId'] as num?)?.toInt() ?? 0,
      institutionId: (json['institutionId'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'AWAITING_DECISION',
      holidayId: (json['holidayId'] as num?)?.toInt() ?? 0,
      holidayDateAd: json['holidayDateAd'] as String? ?? json['date'] as String? ?? '',
      holidayDateBs: json['holidayDateBs'] as String? ?? json['dateBs'] as String? ?? '',
      holidayName: json['holidayName'] as String? ?? '',
      holidayScope: json['holidayScope'] as String?,
      closedDraft: json['closedDraft'] != null
          ? HolidayDraftModel.fromJson(Map<String, dynamic>.from(json['closedDraft'] as Map))
          : _findDraft(json['drafts'], 'CLOSED'),
      openDraft: json['openDraft'] != null
          ? HolidayDraftModel.fromJson(Map<String, dynamic>.from(json['openDraft'] as Map))
          : _findDraft(json['drafts'], 'OPEN'),
      createdAt: json['createdAt'] as String?,
    );
  }

  static HolidayDraftModel? _findDraft(dynamic draftsRaw, String variant) {
    if (draftsRaw is List) {
      for (final item in draftsRaw) {
        if (item is Map && (item['variant']?.toString().toUpperCase() == variant)) {
          return HolidayDraftModel.fromJson(Map<String, dynamic>.from(item));
        }
      }
    }
    return null;
  }

  PendingHolidayNotice toEntity() {
    return PendingHolidayNotice(
      id: id,
      institutionId: institutionId,
      status: NoticeStatus.values.firstWhere(
        (s) => s.name == status,
        orElse: () => NoticeStatus.AWAITING_DECISION,
      ),
      holidayId: holidayId,
      holidayDateAd: holidayDateAd,
      holidayDateBs: holidayDateBs,
      holidayName: holidayName,
      holidayScope: holidayScope,
      closedDraft: closedDraft != null
          ? closedDraft!.toEntity(NoticeVariant.CLOSED)
          : const HolidayNoticeDraft(
              variant: NoticeVariant.CLOSED,
              title: 'Holiday Notice: College Closed',
              body: 'College will remain closed for the holiday.',
            ),
      openDraft: openDraft != null
          ? openDraft!.toEntity(NoticeVariant.OPEN)
          : const HolidayNoticeDraft(
              variant: NoticeVariant.OPEN,
              title: 'Holiday Notice: College Open',
              body: 'College operations will continue as usual.',
            ),
      createdAt: createdAt,
    );
  }
}

class InstitutionNoticeModel {
  final int id;
  final int holidayId;
  final String holidayDateAd;
  final String holidayDateBs;
  final String holidayName;
  final int institutionId;
  final String status;
  final String? variant;
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

  const InstitutionNoticeModel({
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

  factory InstitutionNoticeModel.fromJson(Map<String, dynamic> json) {
    return InstitutionNoticeModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      holidayId: (json['holidayId'] as num?)?.toInt() ?? 0,
      holidayDateAd: json['holidayDateAd'] as String? ?? json['date'] as String? ?? '',
      holidayDateBs: json['holidayDateBs'] as String? ?? json['dateBs'] as String? ?? '',
      holidayName: json['holidayName'] as String? ?? '',
      institutionId: (json['institutionId'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'AWAITING_DECISION',
      variant: json['variant'] as String? ?? json['approvedVariant'] as String?,
      finalTitle: json['finalTitle'] as String? ?? json['title'] as String?,
      finalBody: json['finalBody'] as String? ?? json['body'] as String?,
      customTitle: json['customTitle'] as String?,
      customBody: json['customBody'] as String?,
      notifyStudents: json['notifyStudents'] as bool? ?? true,
      notifyTeachers: json['notifyTeachers'] as bool? ?? true,
      approvedBy: (json['approvedBy'] as num?)?.toInt(),
      approvedAt: json['approvedAt'] as String?,
      publishedAt: json['publishedAt'] as String?,
      expiredAt: json['expiredAt'] as String?,
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      version: (json['version'] as num?)?.toInt(),
    );
  }

  InstitutionHolidayNotice toEntity() {
    return InstitutionHolidayNotice(
      id: id,
      holidayId: holidayId,
      holidayDateAd: holidayDateAd,
      holidayDateBs: holidayDateBs,
      holidayName: holidayName,
      institutionId: institutionId,
      status: NoticeStatus.values.firstWhere(
        (s) => s.name == status,
        orElse: () => NoticeStatus.AWAITING_DECISION,
      ),
      variant: variant != null
          ? NoticeVariant.values.firstWhere(
              (v) => v.name == variant,
              orElse: () => NoticeVariant.CLOSED,
            )
          : null,
      finalTitle: finalTitle,
      finalBody: finalBody,
      customTitle: customTitle,
      customBody: customBody,
      notifyStudents: notifyStudents,
      notifyTeachers: notifyTeachers,
      approvedBy: approvedBy,
      approvedAt: approvedAt,
      publishedAt: publishedAt,
      expiredAt: expiredAt,
      attempts: attempts,
      version: version,
    );
  }
}

class OfficialNoticeModel {
  final int noticeId;
  final int institutionId;
  final String dateAd;
  final String dateBs;
  final String holidayName;
  final String variant;
  final String title;
  final String body;
  final String? publishedAt;

  const OfficialNoticeModel({
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

  factory OfficialNoticeModel.fromJson(Map<String, dynamic> json) {
    return OfficialNoticeModel(
      noticeId: (json['noticeId'] as num?)?.toInt() ?? (json['holidayId'] as num?)?.toInt() ?? 0,
      institutionId: (json['institutionId'] as num?)?.toInt() ?? 0,
      dateAd: json['dateAd'] as String? ?? json['date'] as String? ?? '',
      dateBs: json['dateBs'] as String? ?? '',
      holidayName: json['holidayName'] as String? ?? '',
      variant: json['variant'] as String? ?? 'CLOSED',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      publishedAt: json['publishedAt'] as String? ?? json['approvedAt'] as String?,
    );
  }

  OfficialHolidayNotice toEntity() {
    return OfficialHolidayNotice(
      noticeId: noticeId,
      institutionId: institutionId,
      dateAd: dateAd,
      dateBs: dateBs,
      holidayName: holidayName,
      variant: NoticeVariant.values.firstWhere(
        (v) => v.name == variant,
        orElse: () => NoticeVariant.CLOSED,
      ),
      title: title,
      body: body,
      publishedAt: publishedAt,
    );
  }
}
