import 'package:cloud_firestore/cloud_firestore.dart';

enum ExamResultSubmissionType {
  manual,
  automatic,
}

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
    };
  }

  factory ExamResult.fromMap(Map<String, dynamic> map) {
    DateTime readDate(
        dynamic value, {
          DateTime? fallback,
        }) {
      if (value is Timestamp) {
        return value.toDate();
      }

      if (value is DateTime) {
        return value;
      }

      return fallback ?? DateTime.now();
    }

    ExamResultSubmissionType readSubmissionType(
        dynamic value,
        ) {
      if (value is String) {
        return ExamResultSubmissionType.values.firstWhere(
              (type) => type.name == value,
          orElse: () => ExamResultSubmissionType.manual,
        );
      }

      return ExamResultSubmissionType.manual;
    }

    return ExamResult(
      resultId: map['resultId'] as String? ?? '',
      examId: map['examId'] as String? ?? '',
      attemptId: map['attemptId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      totalQuestions:
      (map['totalQuestions'] as num?)?.toInt() ?? 0,
      answeredQuestions:
      (map['answeredQuestions'] as num?)?.toInt() ?? 0,
      unansweredQuestions:
      (map['unansweredQuestions'] as num?)?.toInt() ?? 0,
      correctAnswers:
      (map['correctAnswers'] as num?)?.toInt() ?? 0,
      wrongAnswers:
      (map['wrongAnswers'] as num?)?.toInt() ?? 0,
      totalMarks:
      (map['totalMarks'] as num?)?.toDouble() ?? 0.0,
      score:
      (map['score'] as num?)?.toDouble() ?? 0.0,
      percentage:
      (map['percentage'] as num?)?.toDouble() ?? 0.0,
      passed:
      map['passed'] as bool? ?? false,
      submissionType:
      readSubmissionType(map['submissionType']),
      startedAt: readDate(map['startedAt']),
      completedAt: readDate(map['completedAt']),
      createdAt: readDate(map['createdAt']),
    );
  }
}