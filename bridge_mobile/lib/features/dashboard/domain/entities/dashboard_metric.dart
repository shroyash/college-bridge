import 'package:equatable/equatable.dart';

/// Domain entity for a single admin dashboard metric.
/// Maps to the backend DashboardMetric DTO: { key, title, value }
class DashboardMetric extends Equatable {
  final String key;
  final String title;
  final int value;

  const DashboardMetric({
    required this.key,
    required this.title,
    required this.value,
  });

  @override
  List<Object?> get props => [key, title, value];
}
