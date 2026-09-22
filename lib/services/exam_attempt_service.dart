import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:questionbank/models/exam.dart';
import 'package:questionbank/models/exam_attempt.dart';
import 'package:questionbank/models/question.dart';
import 'package:questionbank/services/question_service.dart';

import '../models/exam_result.dart';
import 'exam_result_service.dart';
import 'exam_scoring_service.dart';

class ExamAttemptService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final QuestionService _questionService =
  QuestionService();

  final ExamScoringService _scoringService =
  const ExamScoringService();

  final Random _random = Random();

  final ExamResultService _resultService =
  ExamResultService();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('examAttempts');

  /// Creates a new attempt for an examinee.
  ///
  /// If the examinee already has an in-progress attempt
  /// for this exam, that attempt is returned instead of
  /// creating another one.
  Future<ExamAttempt> createNewAttempt({
    required Exam exam,
    required String userId,
  }) async {
    if (exam.questions.isEmpty) {
      throw Exception(
        'This exam does not have any questions yet.',
      );
    }

    // Check for an existing unfinished attempt first.
    final existingAttempt =
    await getInProgressAttempt(
      examId: exam.examId,
      userId: userId,
    );

    if (existingAttempt != null) {
      return existingAttempt;
    }

    final attemptId = _collection.doc().id;

    // Start with the question order configured in the exam.
    final examQuestions =
    exam.questions.toList()
      ..sort(
            (a, b) => a.order.compareTo(b.order),
      );

    final questionIds = examQuestions
        .map(
          (question) => question.questionId,
    )
        .toList();

    // Randomize only this particular attempt.
    if (exam.randomizeQuestions) {
      questionIds.shuffle(_random);
    }

    // Load the questions so we can preserve the
    // option order for this particular attempt.
    final allQuestions =
    await _questionService.getAllQuestions();

    final questionsById = <String, Question>{
      for (final question in allQuestions)
        question.questionId: question,
    };

    final optionOrder = <String, List<String>>{};

    for (final questionId in questionIds) {
      final question =
      questionsById[questionId];

      if (question == null) {
        continue;
      }

      final optionIds = question.options
          .map(
            (option) => option.optionId,
      )
          .toList();

      if (exam.randomizeOptions) {
        optionIds.shuffle(_random);
      }

      optionOrder[questionId] = optionIds;
    }

    final now = DateTime.now();

    final attempt = ExamAttempt(
      attemptId: attemptId,
      examId: exam.examId,
      userId: userId,
      startedAt: now,
      completedAt: null,
      status: ExamAttemptStatus.inProgress,
      questionOrder: questionIds,
      optionOrder: optionOrder,
      answers: const [],
      answeredCount: 0,
      currentQuestionIndex: 0,
      score: 0.0,
      percentage: 0.0,
    );

    await createAttempt(attempt);

    return attempt;
  }

  /// Saves a prepared exam attempt to Firestore.
  Future<void> createAttempt(
      ExamAttempt attempt,
      ) async {
    final data = attempt.toMap();

    data['startedAt'] =
        FieldValue.serverTimestamp();

    data['createdAt'] =
        FieldValue.serverTimestamp();

    data['updatedAt'] =
        FieldValue.serverTimestamp();

    await _collection
        .doc(attempt.attemptId)
        .set(data);
  }

  /// Gets an attempt by its ID.
  Future<ExamAttempt?> getAttemptById(
      String attemptId,
      ) async {
    final document =
    await _collection.doc(attemptId).get();

    if (!document.exists ||
        document.data() == null) {
      return null;
    }

    return ExamAttempt.fromMap(
      document.data()!,
    );
  }

  /// Gets all attempts belonging to an examinee.
  Future<List<ExamAttempt>> getAttemptsByUser(
      String userId,
      ) async {
    final snapshot = await _collection
        .where(
      'userId',
      isEqualTo: userId,
    )
        .orderBy(
      'startedAt',
      descending: true,
    )
        .get();

    return snapshot.docs
        .map(
          (document) => ExamAttempt.fromMap(
        document.data(),
      ),
    )
        .toList();
  }

  /// Gets the examinee's in-progress attempt
  /// for a particular exam.
  Future<ExamAttempt?> getInProgressAttempt({
    required String examId,
    required String userId,
  }) async {
    final snapshot = await _collection
        .where(
      'examId',
      isEqualTo: examId,
    )
        .where(
      'userId',
      isEqualTo: userId,
    )
        .where(
      'status',
      isEqualTo:
      ExamAttemptStatus.inProgress.name,
    )
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return ExamAttempt.fromMap(
      snapshot.docs.first.data(),
    );
  }

  /// Updates an existing attempt.
  Future<void> updateAttempt(
      ExamAttempt attempt,
      ) async {
    final data = attempt.toMap();

    data.remove('startedAt');

    data['updatedAt'] =
        FieldValue.serverTimestamp();

    await _collection
        .doc(attempt.attemptId)
        .update(data);
  }

  /// Updates the examinee's current progress.
  Future<void> updateProgress({
    required String attemptId,
    required List<ExamAttemptAnswer> answers,
    required int answeredCount,
    required int currentQuestionIndex,
  }) async {
    await _collection.doc(attemptId).update({
      'answers': answers
          .map(
            (answer) => answer.toMap(),
      )
          .toList(),
      'answeredCount': answeredCount,
      'currentQuestionIndex':
      currentQuestionIndex,
      'updatedAt':
      FieldValue.serverTimestamp(),
    });
  }

  /// Completes an attempt after normal submission.
  Future<void> completeAttempt({
    required Exam exam,
    required ExamAttempt attempt,
    required double score,
    required double percentage,
  }) async {
    final questions =
    await _questionService.getAllQuestions();

    final examScore =
    _scoringService.calculateScore(
      exam: exam,
      questions: questions,
      attempt: attempt,
    );

    await _collection.doc(attempt.attemptId).update({
      'status':
      ExamAttemptStatus.completed.name,
      'completedAt':
      FieldValue.serverTimestamp(),
      'score': examScore.score,
      'percentage': examScore.percentage,
      'updatedAt':
      FieldValue.serverTimestamp(),
    });

    await _resultService.createResult(
      exam: exam,
      attempt: attempt,
      submissionType:
      ExamResultSubmissionType.manual,
      correctAnswers:
      examScore.correctAnswers,
      wrongAnswers:
      examScore.wrongAnswers,
      answeredQuestions:
      examScore.answeredQuestions,
      unansweredQuestions:
      examScore.unansweredQuestions,
      score: examScore.score,
      percentage: examScore.percentage,
      passed: examScore.passed,
      questionResults:
      examScore.questionResults,
    );
  }

  /// Automatically submits an attempt when
  /// the exam timer expires.
  Future<void> autoSubmitAttempt({
    required Exam exam,
    required ExamAttempt attempt,
    required double score,
    required double percentage,
  }) async {
    final questions =
    await _questionService.getAllQuestions();

    final examScore =
    _scoringService.calculateScore(
      exam: exam,
      questions: questions,
      attempt: attempt,
    );

    await _collection.doc(attempt.attemptId).update({
      'status':
      ExamAttemptStatus.autoSubmitted.name,
      'completedAt':
      FieldValue.serverTimestamp(),
      'score': examScore.score,
      'percentage': examScore.percentage,
      'updatedAt':
      FieldValue.serverTimestamp(),
    });

    await _resultService.createResult(
      exam: exam,
      attempt: attempt,
      submissionType:
      ExamResultSubmissionType.automatic,
      correctAnswers:
      examScore.correctAnswers,
      wrongAnswers:
      examScore.wrongAnswers,
      answeredQuestions:
      examScore.answeredQuestions,
      unansweredQuestions:
      examScore.unansweredQuestions,
      score: examScore.score,
      percentage: examScore.percentage,
      passed: examScore.passed,
      questionResults:
      examScore.questionResults,
    );
  }
}