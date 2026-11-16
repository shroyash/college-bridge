import 'package:equatable/equatable.dart';
import '../../domain/entities/pending_holiday_notice.dart';

sealed class PendingNoticeState extends Equatable {
  const PendingNoticeState();

  @override
  List<Object?> get props => [];
}

class PendingNoticeInitial extends PendingNoticeState {
  const PendingNoticeInitial();
}

class PendingNoticeLoading extends PendingNoticeState {
  const PendingNoticeLoading();
}

class PendingNoticeLoaded extends PendingNoticeState {
  final PendingHolidayNotice? notice;

  const PendingNoticeLoaded(this.notice);

  bool get hasPending => notice != null;

  @override
  List<Object?> get props => [notice];
}

class PendingNoticeError extends PendingNoticeState {
  final String message;

  const PendingNoticeError(this.message);

  @override
  List<Object?> get props => [message];
}
