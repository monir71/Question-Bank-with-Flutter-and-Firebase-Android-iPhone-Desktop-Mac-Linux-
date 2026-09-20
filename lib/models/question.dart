import 'package:cloud_firestore/cloud_firestore.dart';

enum QuestionType {
  multiple,
  trueFalse,
  written,
}

enum DifficultyLevel {
  easy,
  medium,
  hard,
}

enum QuestionStatus {
  pending,
  approved,
  rejected,
}

class QuestionOption {
  final String optionId;
  final String optionText;

  const QuestionOption({
    required this.optionId,
    required this.optionText,
  });

  Map<String, dynamic> toMap() {
    return {
      'optionId': optionId,
      'optionText': optionText,
    };
  }

  factory QuestionOption.fromMap(Map<String, dynamic> map) {
    return QuestionOption(
      optionId: map['optionId'] as String? ?? '',
      optionText: map['optionText'] as String? ?? '',
    );
  }
}

enum AssessmentType {
  automatic,
  manual,
  hybrid,
}

class WrittenAssessment {
  final AssessmentType assessmentType;
  final String referenceAnswer;
  final List<AssessmentCriterion> criteria;

  const WrittenAssessment({
    required this.assessmentType,
    required this.referenceAnswer,
    required this.criteria,
  });

  Map<String, dynamic> toMap() {
    return {
      'assessmentType': assessmentType.name,
      'referenceAnswer': referenceAnswer,
      'criteria': criteria
          .map((criterion) => criterion.toMap())
          .toList(),
    };
  }

  factory WrittenAssessment.fromMap(Map<String, dynamic> map) {
    final criteriaData = map['criteria'] as List<dynamic>? ?? [];

    return WrittenAssessment(
      assessmentType: AssessmentType.values.firstWhere(
            (value) => value.name == map['assessmentType'],
        orElse: () => AssessmentType.manual,
      ),
      referenceAnswer: map['referenceAnswer'] as String? ?? '',
      criteria: criteriaData
          .map(
            (item) => AssessmentCriterion.fromMap(
          Map<String, dynamic>.from(item as Map),
        ),
      )
          .toList(),
    );
  }
}

class AssessmentCriterion {
  final String criterionId;
  final String criterion;
  final double marks;

  const AssessmentCriterion({
    required this.criterionId,
    required this.criterion,
    required this.marks,
  });

  Map<String, dynamic> toMap() {
    return {
      'criterionId': criterionId,
      'criterion': criterion,
      'marks': marks,
    };
  }

  factory AssessmentCriterion.fromMap(Map<String, dynamic> map) {
    return AssessmentCriterion(
      criterionId: map['criterionId'] as String? ?? '',
      criterion: map['criterion'] as String? ?? '',
      marks: (map['marks'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Question {
  final String questionId;
  final String questionDescription;

  final String programId;
  final String subjectId;
  final String topicId;

  final QuestionType questionType;
  final DifficultyLevel difficulty;

  final List<QuestionOption> options;
  final List<String> correctAnswers;

  final WrittenAssessment? writtenAssessment;

  final double marks;

  final String createdBy;
  final QuestionStatus status;

  final String? approvedBy;
  final DateTime? approvedAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Question({
    required this.questionId,
    required this.questionDescription,
    required this.programId,
    required this.subjectId,
    required this.topicId,
    required this.questionType,
    required this.difficulty,
    required this.options,
    required this.correctAnswers,
    this.writtenAssessment,
    required this.marks,
    required this.createdBy,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'questionDescription': questionDescription,
      'programId': programId,
      'subjectId': subjectId,
      'topicId': topicId,
      'questionType': questionType.name,
      'difficulty': difficulty.name,
      'options': options
          .map((option) => option.toMap())
          .toList(),
      'correctAnswers': correctAnswers,
      'writtenAssessment':
      writtenAssessment?.toMap(),
      'marks': marks,
      'createdBy': createdBy,
      'status': status.name,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt == null
          ? null
          : Timestamp.fromDate(approvedAt!),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    final optionsData = map['options'] as List<dynamic>? ?? [];

    final writtenAssessmentData =
    map['writtenAssessment'] as Map<String, dynamic>?;

    return Question(
      questionId: map['questionId'] as String? ?? '',
      questionDescription:
      map['questionDescription'] as String? ?? '',
      programId: map['programId'] as String? ?? '',
      subjectId: map['subjectId'] as String? ?? '',
      topicId: map['topicId'] as String? ?? '',
      questionType: QuestionType.values.firstWhere(
            (value) => value.name == map['questionType'],
        orElse: () => QuestionType.multiple,
      ),
      difficulty: DifficultyLevel.values.firstWhere(
            (value) => value.name == map['difficulty'],
        orElse: () => DifficultyLevel.medium,
      ),
      options: optionsData
          .map(
            (item) => QuestionOption.fromMap(
          Map<String, dynamic>.from(item as Map),
        ),
      )
          .toList(),
      correctAnswers:
      List<String>.from(map['correctAnswers'] ?? []),
      writtenAssessment: writtenAssessmentData == null
          ? null
          : WrittenAssessment.fromMap(
        Map<String, dynamic>.from(
          writtenAssessmentData,
        ),
      ),
      marks: (map['marks'] as num?)?.toDouble() ?? 0,
      createdBy: map['createdBy'] as String? ?? '',
      status: QuestionStatus.values.firstWhere(
            (value) => value.name == map['status'],
        orElse: () => QuestionStatus.pending,
      ),
      approvedBy: map['approvedBy'] as String?,
      approvedAt: _parseDateTime(map['approvedAt']),
      createdAt: _parseDateTime(map['createdAt']) ??
          DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']) ??
          DateTime.now(),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }
}