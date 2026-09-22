import 'package:cloud_firestore/cloud_firestore.dart';

enum QuestionAssessmentStatus { automatic, pending, manuallyAssessed }

class ExamQuestionResult {
  final String questionId;
  final double maximumMarks;
  final double awardedMarks;

  final bool answered;
  final bool correct;

  final List<String> selectedOptionIds;
  final String writtenAnswer;

  final QuestionAssessmentStatus assessmentStatus;

  final String? assessedBy;
  final DateTime? assessedAt;
  final String? feedback;

  const ExamQuestionResult({
    required this.questionId,
    required this.maximumMarks,
    required this.awardedMarks,
    required this.answered,
    required this.correct,
    required this.selectedOptionIds,
    required this.writtenAnswer,
    required this.assessmentStatus,
    this.assessedBy,
    this.assessedAt,
    this.feedback,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'maximumMarks': maximumMarks,
      'awardedMarks': awardedMarks,
      'answered': answered,
      'correct': correct,
      'selectedOptionIds': selectedOptionIds,
      'writtenAnswer': writtenAnswer,
      'assessmentStatus': assessmentStatus.name,
      'assessedBy': assessedBy,
      'assessedAt': assessedAt == null ? null : Timestamp.fromDate(assessedAt!),
      'feedback': feedback,
    };
  }

  factory ExamQuestionResult.fromMap(Map<String, dynamic> map) {
    QuestionAssessmentStatus readStatus(dynamic value) {
      if (value is String) {
        return QuestionAssessmentStatus.values.firstWhere(
          (status) => status.name == value,
          orElse: () => QuestionAssessmentStatus.pending,
        );
      }

      return QuestionAssessmentStatus.pending;
    }

    DateTime? readNullableDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }

      if (value is DateTime) {
        return value;
      }

      return null;
    }

    final selectedData = map['selectedOptionIds'];

    return ExamQuestionResult(
      questionId: map['questionId'] as String? ?? '',
      maximumMarks: (map['maximumMarks'] as num?)?.toDouble() ?? 0.0,
      awardedMarks: (map['awardedMarks'] as num?)?.toDouble() ?? 0.0,
      answered: map['answered'] as bool? ?? false,
      correct: map['correct'] as bool? ?? false,
      selectedOptionIds: selectedData is List
          ? selectedData.whereType<String>().toList()
          : const [],
      writtenAnswer: map['writtenAnswer'] as String? ?? '',
      assessmentStatus: readStatus(map['assessmentStatus']),
      assessedBy: map['assessedBy'] as String?,
      assessedAt: readNullableDate(map['assessedAt']),
      feedback: map['feedback'] as String?,
    );
  }

  ExamQuestionResult copyWith({
    String? questionId,
    double? maximumMarks,
    double? awardedMarks,
    bool? answered,
    bool? correct,
    List<String>? selectedOptionIds,
    String? writtenAnswer,
    QuestionAssessmentStatus? assessmentStatus,
    String? assessedBy,
    DateTime? assessedAt,
    String? feedback,
  }) {
    return ExamQuestionResult(
      questionId: questionId ?? this.questionId,
      maximumMarks: maximumMarks ?? this.maximumMarks,
      awardedMarks: awardedMarks ?? this.awardedMarks,
      answered: answered ?? this.answered,
      correct: correct ?? this.correct,
      selectedOptionIds: selectedOptionIds ?? this.selectedOptionIds,
      writtenAnswer: writtenAnswer ?? this.writtenAnswer,
      assessmentStatus: assessmentStatus ?? this.assessmentStatus,
      assessedBy: assessedBy ?? this.assessedBy,
      assessedAt: assessedAt ?? this.assessedAt,
      feedback: feedback ?? this.feedback,
    );
  }
}
