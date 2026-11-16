class DoubtAnswerModel {
  final int answerId;
  final int answeredById;
  final String answeredByName;
  final String answer;
  final bool verified;
  final bool answeredByTeacher;
  final String createdAt;

  const DoubtAnswerModel({
    required this.answerId,
    required this.answeredById,
    required this.answeredByName,
    required this.answer,
    required this.verified,
    required this.answeredByTeacher,
    required this.createdAt,
  });

  factory DoubtAnswerModel.fromJson(Map<String, dynamic> json) {
    return DoubtAnswerModel(
      answerId: (json['answerId'] as num?)?.toInt() ?? 0,
      answeredById: (json['answeredById'] as num?)?.toInt() ?? 0,
      answeredByName: json['answeredByName'] as String? ?? 'Anonymous',
      answer: json['answer'] as String? ?? '',
      verified: json['verified'] as bool? ?? false,
      answeredByTeacher: json['answeredByTeacher'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}
