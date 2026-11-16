class DoubtSummaryModel {
  final int total;
  final int solved;
  final int unsolved;

  const DoubtSummaryModel({
    required this.total,
    required this.solved,
    required this.unsolved,
  });

  factory DoubtSummaryModel.fromJson(Map<String, dynamic> json) {
    return DoubtSummaryModel(
      total: (json['total'] as num?)?.toInt() ?? 0,
      solved: (json['solved'] as num?)?.toInt() ?? 0,
      unsolved: (json['unsolved'] as num?)?.toInt() ?? 0,
    );
  }
}
