import '../../domain/entities/dashboard_metric.dart';

/// Data model mapping the backend DashboardMetric JSON to the domain entity.
/// Backend payload: { key: String, title: String, value: Long }
class DashboardMetricModel extends DashboardMetric {
  const DashboardMetricModel({
    required super.key,
    required super.title,
    required super.value,
  });

  factory DashboardMetricModel.fromJson(Map<String, dynamic> json) {
    return DashboardMetricModel(
      key: json['key'] as String,
      title: json['title'] as String,
      value: (json['value'] as num).toInt(),
    );
  }
}
