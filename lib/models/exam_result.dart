import 'package:cloud_firestore/cloud_firestore.dart';

import 'exam_question_result.dart';

enum ExamResultSubmissionType { manual, automatic }

class ExamResult {
  final String resultId;
  final String examId;
  final String attemptId;
  final String userId;

  final int totalQuestions;
  final int answeredQuestions;
  final int unansweredQuestions;
  final int correctAnswers;
  final int wrongAnswers;

  final double totalMarks;
  final double score;
  final double percentage;

  final bool passed;

  final ExamResultSubmissionType submissionType;

  final DateTime startedAt;
  final DateTime completedAt;
  final DateTime createdAt;

  final double passPercentage;

  final List<ExamQuestionResult> questionResults;

  const ExamResult({
    required this.resultId,
    required this.examId,
    required this.attemptId,
    required this.userId,
    required this.totalQuestions,
    required this.answeredQuestions,
    required this.unansweredQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.totalMarks,
    required this.score,
    required this.percentage,
    required this.passed,
    required this.submissionType,
    required this.startedAt,
    required this.completedAt,
    required this.createdAt,
    required this.questionResults,
    required this.passPercentage,
  });

  Map<String, dynamic> toMap() {
    return {
      'resultId': resultId,
      'examId': examId,
      'attemptId': attemptId,
      'userId': userId,
      'totalQuestions': totalQuestions,
      'answeredQuestions': answeredQuestions,
      'unansweredQuestions': unansweredQuestions,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'totalMarks': totalMarks,
      'score': score,
      'percentage': percentage,
      'passed': passed,
      'submissionType': submissionType.name,
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': Timestamp.fromDate(completedAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'questionResults': questionResults
          .map((result) => result.toMap())
          .toList(),
      'passPercentage': passPercentage,
    };
  }

  factory ExamResult.fromMap(Map<String, dynamic> map) {
    DateTime readDate(dynamic value, {DateTime? fallback}) {
      if (value is Timestamp) {
        return value.toDate();
      }

      if (value is DateTime) {
        return value;
      }

      return fallback ?? DateTime.now();
    }

    ExamResultSubmissionType readSubmissionType(dynamic value) {
      if (value is String) {
        return ExamResultSubmissionType.values.firstWhere(
          (type) => type.name == value,
          orElse: () => ExamResultSubmissionType.manual,
        );
      }

      return ExamResultSubmissionType.manual;
    }

    final questionResultsData = map['questionResults'];

    final List<ExamQuestionResult> questionResults;

    if (questionResultsData is List) {
      questionResults = questionResultsData
          .whereType<Map>()
          .map(
            (item) =>
                ExamQuestionResult.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList();
    } else {
      questionResults = [];
    }

    return ExamResult(
      resultId: map['resultId'] as String? ?? '',
      examId: map['examId'] as String? ?? '',
      attemptId: map['attemptId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      totalQuestions: (map['totalQuestions'] as num?)?.toInt() ?? 0,
      answeredQuestions: (map['answeredQuestions'] as num?)?.toInt() ?? 0,
      unansweredQuestions: (map['unansweredQuestions'] as num?)?.toInt() ?? 0,
      correctAnswers: (map['correctAnswers'] as num?)?.toInt() ?? 0,
      wrongAnswers: (map['wrongAnswers'] as num?)?.toInt() ?? 0,
      totalMarks: (map['totalMarks'] as num?)?.toDouble() ?? 0.0,
      score: (map['score'] as num?)?.toDouble() ?? 0.0,
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
      passed: map['passed'] as bool? ?? false,
      submissionType: readSubmissionType(map['submissionType']),
      startedAt: readDate(map['startedAt']),
      completedAt: readDate(map['completedAt']),
      createdAt: readDate(map['createdAt']),
      questionResults: questionResults,
      passPercentage:
      (map['passPercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  ExamResult copyWith({
    String? resultId,
    String? examId,
    String? attemptId,
    String? userId,
    int? totalQuestions,
    int? answeredQuestions,
    int? unansweredQuestions,
    int? correctAnswers,
    int? wrongAnswers,
    double? totalMarks,
    double? score,
    double? percentage,
    bool? passed,
    ExamResultSubmissionType? submissionType,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? createdAt,
    List<ExamQuestionResult>? questionResults,
    double? passPercentage,
  }) {
    return ExamResult(
      resultId: resultId ?? this.resultId,
      examId: examId ?? this.examId,
      attemptId: attemptId ?? this.attemptId,
      userId: userId ?? this.userId,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      answeredQuestions: answeredQuestions ?? this.answeredQuestions,
      unansweredQuestions: unansweredQuestions ?? this.unansweredQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      wrongAnswers: wrongAnswers ?? this.wrongAnswers,
      totalMarks: totalMarks ?? this.totalMarks,
      score: score ?? this.score,
      percentage: percentage ?? this.percentage,
      passed: passed ?? this.passed,
      submissionType: submissionType ?? this.submissionType,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      questionResults: questionResults ?? this.questionResults,
      passPercentage:
      passPercentage ?? this.passPercentage,
    );
  }
}
