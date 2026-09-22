import 'package:cloud_firestore/cloud_firestore.dart';

enum ExamAttemptStatus {
  inProgress,
  completed,
  autoSubmitted,
}

class ExamAttemptAnswer {
  final String questionId;

  /// Selected option IDs for multiple-choice questions.
  final List<String> selectedOptionIds;

  /// Text entered by the examinee for written questions.
  final String writtenAnswer;

  /// Whether the examinee marked this question for review.
  final bool markedForReview;

  const ExamAttemptAnswer({
    required this.questionId,
    this.selectedOptionIds = const [],
    this.writtenAnswer = '',
    this.markedForReview = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'selectedOptionIds': selectedOptionIds,
      'writtenAnswer': writtenAnswer,
      'markedForReview': markedForReview,
    };
  }

  factory ExamAttemptAnswer.fromMap(Map<String, dynamic> map) {
    final selectedData = map['selectedOptionIds'];

    return ExamAttemptAnswer(
      questionId: map['questionId'] as String? ?? '',
      selectedOptionIds: selectedData is List
          ? selectedData.whereType<String>().toList()
          : const [],
      writtenAnswer: map['writtenAnswer'] as String? ?? '',
      markedForReview: map['markedForReview'] as bool? ?? false,
    );
  }

  ExamAttemptAnswer copyWith({
    String? questionId,
    List<String>? selectedOptionIds,
    String? writtenAnswer,
    bool? markedForReview,
  }) {
    return ExamAttemptAnswer(
      questionId: questionId ?? this.questionId,
      selectedOptionIds:
      selectedOptionIds ?? this.selectedOptionIds,
      writtenAnswer:
      writtenAnswer ?? this.writtenAnswer,
      markedForReview:
      markedForReview ?? this.markedForReview,
    );
  }
}

class ExamAttempt {
  final String attemptId;
  final String examId;
  final String userId;

  final DateTime startedAt;
  final DateTime? completedAt;

  final ExamAttemptStatus status;

  /// Actual question order used for this particular attempt.
  ///
  /// This is separate from Exam.questions because the exam
  /// may have randomizeQuestions enabled.
  final List<String> questionOrder;

  /// Actual option order used for this particular attempt.
  ///
  /// Key = questionId
  /// Value = ordered list of optionIds.
  ///
  /// This allows each examinee's option order to be preserved.
  final Map<String, List<String>> optionOrder;

  final List<ExamAttemptAnswer> answers;

  /// Number of questions answered so far.
  final int answeredCount;

  /// Current question index in the attempt.
  final int currentQuestionIndex;

  /// Result information will be populated after submission.
  final double score;
  final double percentage;

  const ExamAttempt({
    required this.attemptId,
    required this.examId,
    required this.userId,
    required this.startedAt,
    this.completedAt,
    required this.status,
    required this.questionOrder,
    required this.optionOrder,
    required this.answers,
    required this.answeredCount,
    required this.currentQuestionIndex,
    required this.score,
    required this.percentage,
  });

  Map<String, dynamic> toMap() {
    return {
      'attemptId': attemptId,
      'examId': examId,
      'userId': userId,
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': completedAt == null
          ? null
          : Timestamp.fromDate(completedAt!),
      'status': status.name,
      'questionOrder': questionOrder,
      'optionOrder': optionOrder.map(
            (questionId, optionIds) => MapEntry(
          questionId,
          optionIds,
        ),
      ),
      'answers': answers
          .map((answer) => answer.toMap())
          .toList(),
      'answeredCount': answeredCount,
      'currentQuestionIndex': currentQuestionIndex,
      'score': score,
      'percentage': percentage,
    };
  }

  factory ExamAttempt.fromMap(Map<String, dynamic> map) {
    DateTime readDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }

      if (value is DateTime) {
        return value;
      }

      return DateTime.now();
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

    ExamAttemptStatus readStatus(dynamic value) {
      if (value is String) {
        return ExamAttemptStatus.values.firstWhere(
              (status) => status.name == value,
          orElse: () => ExamAttemptStatus.inProgress,
        );
      }

      return ExamAttemptStatus.inProgress;
    }

    final questionData = map['questionOrder'];

    final List<String> questionOrder;
    if (questionData is List) {
      questionOrder =
          questionData.whereType<String>().toList();
    } else {
      questionOrder = [];
    }

    final optionData = map['optionOrder'];

    final Map<String, List<String>> optionOrder = {};

    if (optionData is Map) {
      optionData.forEach((questionId, value) {
        if (questionId is String && value is List) {
          optionOrder[questionId] =
              value.whereType<String>().toList();
        }
      });
    }

    final answerData = map['answers'];

    final List<ExamAttemptAnswer> answers;

    if (answerData is List) {
      answers = answerData
          .whereType<Map>()
          .map(
            (item) => ExamAttemptAnswer.fromMap(
          Map<String, dynamic>.from(item),
        ),
      )
          .toList();
    } else {
      answers = [];
    }

    return ExamAttempt(
      attemptId: map['attemptId'] as String? ?? '',
      examId: map['examId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      startedAt: readDate(map['startedAt']),
      completedAt:
      readNullableDate(map['completedAt']),
      status: readStatus(map['status']),
      questionOrder: questionOrder,
      optionOrder: optionOrder,
      answers: answers,
      answeredCount:
      (map['answeredCount'] as num?)?.toInt() ?? 0,
      currentQuestionIndex:
      (map['currentQuestionIndex'] as num?)?.toInt() ?? 0,
      score:
      (map['score'] as num?)?.toDouble() ?? 0.0,
      percentage:
      (map['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  ExamAttempt copyWith({
    String? attemptId,
    String? examId,
    String? userId,
    DateTime? startedAt,
    DateTime? completedAt,
    ExamAttemptStatus? status,
    List<String>? questionOrder,
    Map<String, List<String>>? optionOrder,
    List<ExamAttemptAnswer>? answers,
    int? answeredCount,
    int? currentQuestionIndex,
    double? score,
    double? percentage,
  }) {
    return ExamAttempt(
      attemptId: attemptId ?? this.attemptId,
      examId: examId ?? this.examId,
      userId: userId ?? this.userId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      questionOrder:
      questionOrder ?? this.questionOrder,
      optionOrder:
      optionOrder ?? this.optionOrder,
      answers: answers ?? this.answers,
      answeredCount:
      answeredCount ?? this.answeredCount,
      currentQuestionIndex:
      currentQuestionIndex ??
          this.currentQuestionIndex,
      score: score ?? this.score,
      percentage:
      percentage ?? this.percentage,
    );
  }
}