import 'package:equatable/equatable.dart';

/// Sealed state class for the Dashboard feature.
sealed class DashboardState<T> extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

/// Initial state — no action taken yet.
final class DashboardInitial<T> extends DashboardState<T> {
  const DashboardInitial();
}

/// Loading state — an API call is in flight.
final class DashboardLoading<T> extends DashboardState<T> {
  const DashboardLoading();
}

/// Success state — data fetched successfully.
final class DashboardSuccess<T> extends DashboardState<T> {
  final T data;
  const DashboardSuccess(this.data);

  @override
  List<Object?> get props => [data];
}

/// Failure state — an error occurred.
final class DashboardFailure<T> extends DashboardState<T> {
  final String message;
  const DashboardFailure(this.message);

  @override
  List<Object?> get props => [message];
}
