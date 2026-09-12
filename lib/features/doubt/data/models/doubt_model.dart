import 'doubt_answer_model.dart';

class DoubtModel {
  final int doubtId;
  final int subjectId;
  final String subjectName;
  final int studentId;
  final String studentName;
  final String question;
  final String status;
  final bool helpful;
  final String createdAt;
  final int answerCount;
  final int verifiedAnswerCount;
  final int unverifiedAnswerCount;
  final List<DoubtAnswerModel> answers;

  const DoubtModel({
    required this.doubtId,
    required this.subjectId,
    required this.subjectName,
    required this.studentId,
    required this.studentName,
    required this.question,
    required this.status,
    required this.helpful,
    required this.createdAt,
    required this.answerCount,
    required this.verifiedAnswerCount,
    required this.unverifiedAnswerCount,
    this.answers = const [],
  });

  factory DoubtModel.fromJson(Map<String, dynamic> json) {
    final answersList = (json['answers'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map((e) => DoubtAnswerModel.fromJson(e))
            .toList() ??
        [];

    return DoubtModel(
      doubtId: (json['doubtId'] as num?)?.toInt() ?? 0,
      subjectId: (json['subjectId'] as num?)?.toInt() ?? 0,
      subjectName: json['subjectName'] as String? ?? 'Subject',
      studentId: (json['studentId'] as num?)?.toInt() ?? 0,
      studentName: json['studentName'] as String? ?? 'Student',
      question: json['question'] as String? ?? '',
      status: json['status'] as String? ?? 'OPEN',
      helpful: json['helpful'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? '',
      answerCount: (json['answerCount'] as num?)?.toInt() ?? 0,
      verifiedAnswerCount: (json['verifiedAnswerCount'] as num?)?.toInt() ?? 0,
      unverifiedAnswerCount: (json['unverifiedAnswerCount'] as num?)?.toInt() ?? 0,
      answers: answersList,
    );
  }
}
