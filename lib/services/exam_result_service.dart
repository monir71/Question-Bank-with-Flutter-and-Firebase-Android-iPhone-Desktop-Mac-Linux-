import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:questionbank/models/exam.dart';
import 'package:questionbank/models/exam_attempt.dart';
import 'package:questionbank/models/exam_result.dart';

import '../models/exam_question_result.dart';

class ExamResultService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('examResults');

  Future<void> createResult({
    required Exam exam,
    required ExamAttempt attempt,
    required ExamResultSubmissionType submissionType,
    required int correctAnswers,
    required int wrongAnswers,
    required int answeredQuestions,
    required int unansweredQuestions,
    required double score,
    required double percentage,
    required bool passed,
    required List<ExamQuestionResult> questionResults,
  }) async {
    final resultId = _collection.doc().id;

    final result = ExamResult(
      resultId: resultId,
      examId: exam.examId,
      attemptId: attempt.attemptId,
      userId: attempt.userId,
      totalQuestions: attempt.questionOrder.length,
      answeredQuestions: answeredQuestions,
      unansweredQuestions: unansweredQuestions,
      correctAnswers: correctAnswers,
      wrongAnswers: wrongAnswers,
      totalMarks: exam.totalMarks,
      score: score,
      percentage: percentage,
      passed: passed,
      passPercentage: exam.passPercentage,
      submissionType: submissionType,
      startedAt: attempt.startedAt,
      completedAt: DateTime.now(),
      createdAt: DateTime.now(),
      questionResults: questionResults,
    );

    final data = result.toMap();

    data['completedAt'] = FieldValue.serverTimestamp();

    data['createdAt'] = FieldValue.serverTimestamp();

    await _collection.doc(result.resultId).set(data);
  }

  Future<ExamResult?> getResultByAttemptId(String attemptId) async {
    final snapshot = await _collection
        .where('attemptId', isEqualTo: attemptId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return ExamResult.fromMap(snapshot.docs.first.data());
  }

  Future<ExamResult?> getResultById(String resultId) async {
    final document = await _collection.doc(resultId).get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    return ExamResult.fromMap(document.data()!);
  }

  Future<List<ExamResult>> getResultsByUser(String userId) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .orderBy('completedAt', descending: true)
        .get();

    return snapshot.docs
        .map((document) => ExamResult.fromMap(document.data()))
        .toList();
  }

  Future<List<ExamResult>> getAllResults() async {
    final snapshot = await _collection
        .orderBy(
      'completedAt',
      descending: true,
    )
        .get();

    return snapshot.docs
        .map(
          (document) => ExamResult.fromMap(
        document.data(),
      ),
    )
        .toList();
  }
}
