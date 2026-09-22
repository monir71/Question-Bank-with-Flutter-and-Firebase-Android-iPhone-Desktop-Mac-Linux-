import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:questionbank/models/exam.dart';
import 'package:questionbank/models/exam_attempt.dart';
import 'package:questionbank/models/exam_result.dart';

class ExamResultService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('examResults');

  Future<void> createResult({
    required Exam exam,
    required ExamAttempt attempt,
    required ExamResultSubmissionType submissionType,
  }) async {
    final resultId = _collection.doc().id;

    final totalQuestions = attempt.questionOrder.length;
    final answeredQuestions = attempt.answeredCount;

    final unansweredQuestions =
        totalQuestions - answeredQuestions;

    final result = ExamResult(
      resultId: resultId,
      examId: exam.examId,
      attemptId: attempt.attemptId,
      userId: attempt.userId,
      totalQuestions: totalQuestions,
      answeredQuestions: answeredQuestions,
      unansweredQuestions: unansweredQuestions,
      correctAnswers: 0,
      wrongAnswers: 0,
      totalMarks: exam.totalMarks,
      score: 0.0,
      percentage: 0.0,
      passed: false,
      submissionType: submissionType,
      startedAt: attempt.startedAt,
      completedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    final data = result.toMap();

    data['completedAt'] =
        FieldValue.serverTimestamp();

    data['createdAt'] =
        FieldValue.serverTimestamp();

    await _collection
        .doc(result.resultId)
        .set(data);
  }

  Future<ExamResult?> getResultByAttemptId(
      String attemptId,
      ) async {
    final snapshot = await _collection
        .where(
      'attemptId',
      isEqualTo: attemptId,
    )
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return ExamResult.fromMap(
      snapshot.docs.first.data(),
    );
  }

  Future<ExamResult?> getResultById(
      String resultId,
      ) async {
    final document =
    await _collection.doc(resultId).get();

    if (!document.exists ||
        document.data() == null) {
      return null;
    }

    return ExamResult.fromMap(
      document.data()!,
    );
  }

  Future<List<ExamResult>> getResultsByUser(
      String userId,
      ) async {
    final snapshot = await _collection
        .where(
      'userId',
      isEqualTo: userId,
    )
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