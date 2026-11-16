import 'package:equatable/equatable.dart';
import '../../domain/entities/official_holiday_notice.dart';

sealed class OfficialNoticesState extends Equatable {
  const OfficialNoticesState();

  @override
  List<Object?> get props => [];
}

class OfficialNoticesInitial extends OfficialNoticesState {
  const OfficialNoticesInitial();
}

class OfficialNoticesLoading extends OfficialNoticesState {
  const OfficialNoticesLoading();
}

class OfficialNoticesLoaded extends OfficialNoticesState {
  final List<OfficialHolidayNotice> notices;
  final bool hasMore;

  const OfficialNoticesLoaded({
    required this.notices,
    this.hasMore = false,
  });

  @override
  List<Object?> get props => [notices, hasMore];
}

class OfficialNoticesError extends OfficialNoticesState {
  final String message;

  const OfficialNoticesError(this.message);

  @override
  List<Object?> get props => [message];
}
