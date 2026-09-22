import 'package:cloud_firestore/cloud_firestore.dart';

import 'automatic_question_selection.dart';

enum ExamQuestionSelectionMode {
  manual,
  automatic,
}

class ExamQuestion {
  final String questionId;
  final double marks;
  final int order;

  const ExamQuestion({
    required this.questionId,
    required this.marks,
    required this.order,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'marks': marks,
      'order': order,
    };
  }

  factory ExamQuestion.fromMap(Map<String, dynamic> map) {
    return ExamQuestion(
      questionId: map['questionId'] as String? ?? '',
      marks: (map['marks'] as num?)?.toDouble() ?? 1.0,
      order: (map['order'] as num?)?.toInt() ?? 0,
    );
  }

  ExamQuestion copyWith({
    String? questionId,
    double? marks,
    int? order,
  }) {
    return ExamQuestion(
      questionId: questionId ?? this.questionId,
      marks: marks ?? this.marks,
      order: order ?? this.order,
    );
  }
}

class Exam {
  final String examId;
  final String examName;
  final String description;

  /// The program to which this exam belongs.
  final String? programId;

  /// Subjects covered by this exam.
  ///
  /// One or more subjects can be selected.
  /// If all subjects are selected during exam creation,
  /// all currently available subject IDs are stored here.
  final List<String> subjectIds;

  /// Determines how questions are selected for this exam.
  ///
  /// manual:
  /// Admin selects the actual questions.
  ///
  /// automatic:
  /// The system selects questions according to configured rules.
  final ExamQuestionSelectionMode questionSelectionMode;

  /// Configuration used when questionSelectionMode is automatic.
  ///
  /// This is null for manually selected exams.
  final AutomaticQuestionSelection? automaticQuestionSelection;

  final int durationMinutes;
  final double totalMarks;
  final double passPercentage;
  final int questionCount;
  final bool randomizeQuestions;
  final bool randomizeOptions;
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ExamQuestion> questions;

  const Exam({
    required this.examId,
    required this.examName,
    required this.description,
    this.programId,
    required this.subjectIds,
    required this.questionSelectionMode,
    this.automaticQuestionSelection,
    required this.durationMinutes,
    required this.totalMarks,
    required this.passPercentage,
    required this.questionCount,
    required this.randomizeQuestions,
    required this.randomizeOptions,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.questions,
  });

  Map<String, dynamic> toMap() {
    return {
      'examId': examId,
      'examName': examName,
      'description': description,
      'programId': programId,
      'subjectIds': subjectIds,
      'questionSelectionMode': questionSelectionMode.name,
      'automaticQuestionSelection':
      automaticQuestionSelection?.toMap(),
      'totalMarks': totalMarks,
      'questionCount': questionCount,
      'durationMinutes': durationMinutes,
      'passPercentage': passPercentage,
      'randomizeQuestions': randomizeQuestions,
      'randomizeOptions': randomizeOptions,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'questions': questions
          .map((question) => question.toMap())
          .toList(),
    };
  }

  factory Exam.fromMap(Map<String, dynamic> map) {
    DateTime readDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }

      if (value is DateTime) {
        return value;
      }

      return DateTime.now();
    }

    ExamQuestionSelectionMode readQuestionSelectionMode(
        dynamic value,
        ) {
      if (value is String) {
        return ExamQuestionSelectionMode.values.firstWhere(
              (mode) => mode.name == value,
          orElse: () => ExamQuestionSelectionMode.manual,
        );
      }

      // Backward compatibility for existing exam documents.
      return ExamQuestionSelectionMode.manual;
    }

    AutomaticQuestionSelection? readAutomaticQuestionSelection(
        dynamic value,
        ) {
      if (value is Map) {
        return AutomaticQuestionSelection.fromMap(
          Map<String, dynamic>.from(value),
        );
      }

      return null;
    }

    final questionData = map['questions'];
    final subjectData = map['subjectIds'];

    final List<String> subjectIds;

    if (subjectData is List) {
      subjectIds = subjectData.whereType<String>().toList();
    } else if (map['subjectId'] is String &&
        (map['subjectId'] as String).isNotEmpty) {
      // Backward compatibility with an older exam document.
      subjectIds = [map['subjectId'] as String];
    } else {
      subjectIds = [];
    }

    return Exam(
      examId: map['examId'] as String? ?? '',
      examName: map['examName'] as String? ?? '',
      description: map['description'] as String? ?? '',
      programId: map['programId'] as String?,
      subjectIds: subjectIds,
      questionSelectionMode: readQuestionSelectionMode(
        map['questionSelectionMode'],
      ),
      automaticQuestionSelection:
      readAutomaticQuestionSelection(
        map['automaticQuestionSelection'],
      ),
      durationMinutes:
      (map['durationMinutes'] as num?)?.toInt() ?? 0,
      totalMarks:
      (map['totalMarks'] as num?)?.toDouble() ?? 0.0,
      passPercentage:
      (map['passPercentage'] as num?)?.toDouble() ?? 0.0,
      questionCount:
      (map['questionCount'] as num?)?.toInt() ?? 0,
      randomizeQuestions:
      map['randomizeQuestions'] as bool? ?? false,
      randomizeOptions:
      map['randomizeOptions'] as bool? ?? false,
      isActive:
      map['isActive'] as bool? ?? true,
      createdBy:
      map['createdBy'] as String? ?? '',
      createdAt:
      readDate(map['createdAt']),
      updatedAt:
      readDate(map['updatedAt']),
      questions: questionData is List
          ? questionData
          .whereType<Map>()
          .map(
            (item) => ExamQuestion.fromMap(
          Map<String, dynamic>.from(item),
        ),
      )
          .toList()
          : const [],
    );
  }

  Exam copyWith({
    String? examId,
    String? examName,
    String? description,
    String? programId,
    List<String>? subjectIds,
    ExamQuestionSelectionMode? questionSelectionMode,
    AutomaticQuestionSelection?
    automaticQuestionSelection,
    int? durationMinutes,
    double? totalMarks,
    double? passPercentage,
    int? questionCount,
    bool? randomizeQuestions,
    bool? randomizeOptions,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ExamQuestion>? questions,
  }) {
    return Exam(
      examId: examId ?? this.examId,
      examName: examName ?? this.examName,
      description: description ?? this.description,
      programId: programId ?? this.programId,
      subjectIds: subjectIds ?? this.subjectIds,
      questionSelectionMode:
      questionSelectionMode ??
          this.questionSelectionMode,
      automaticQuestionSelection:
      automaticQuestionSelection ??
          this.automaticQuestionSelection,
      durationMinutes:
      durationMinutes ?? this.durationMinutes,
      totalMarks:
      totalMarks ?? this.totalMarks,
      passPercentage:
      passPercentage ?? this.passPercentage,
      questionCount:
      questionCount ?? this.questionCount,
      randomizeQuestions:
      randomizeQuestions ??
          this.randomizeQuestions,
      randomizeOptions:
      randomizeOptions ??
          this.randomizeOptions,
      isActive:
      isActive ?? this.isActive,
      createdBy:
      createdBy ?? this.createdBy,
      createdAt:
      createdAt ?? this.createdAt,
      updatedAt:
      updatedAt ?? this.updatedAt,
      questions:
      questions ?? this.questions,
    );
  }
}