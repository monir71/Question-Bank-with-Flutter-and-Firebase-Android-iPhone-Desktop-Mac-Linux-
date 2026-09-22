import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:questionbank/models/exam_question_result.dart';
import 'package:questionbank/models/exam_result.dart';

class ExamManualAssessmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('examResults');

  Future<void> assessWrittenQuestion({
    required String resultId,
    required String questionId,
    required double awardedMarks,
    required String assessedBy,
    String? feedback,
  }) async {
    if (awardedMarks < 0) {
      throw Exception('Awarded marks cannot be negative.');
    }

    if (assessedBy.trim().isEmpty) {
      throw Exception('Assessor information is required.');
    }

    final document = await _collection.doc(resultId).get();

    if (!document.exists || document.data() == null) {
      throw Exception('Exam result not found.');
    }

    final result = ExamResult.fromMap(document.data()!);

    final questionIndex = result.questionResults.indexWhere(
      (question) => question.questionId == questionId,
    );

    if (questionIndex == -1) {
      throw Exception('Question result not found.');
    }

    final questionResult = result.questionResults[questionIndex];

    if (questionResult.assessmentStatus == QuestionAssessmentStatus.automatic) {
      throw Exception(
        'Automatically assessed questions cannot be manually assessed.',
      );
    }

    if (awardedMarks > questionResult.maximumMarks) {
      throw Exception('Awarded marks cannot exceed the maximum marks.');
    }

    final updatedQuestionResult = questionResult.copyWith(
      awardedMarks: awardedMarks,
      assessmentStatus: QuestionAssessmentStatus.manuallyAssessed,
      assessedBy: assessedBy,
      assessedAt: DateTime.now(),
      feedback: feedback?.trim().isEmpty == true ? null : feedback?.trim(),
    );

    final updatedQuestionResults = List<ExamQuestionResult>.from(
      result.questionResults,
    );

    updatedQuestionResults[questionIndex] = updatedQuestionResult;

    final updatedScore = updatedQuestionResults.fold<double>(
      0.0,
      (total, question) => total + question.awardedMarks,
    );

    final updatedPercentage = _calculatePercentage(
      score: updatedScore,
      totalMarks: result.totalMarks,
    );

    final updatedPassed = updatedPercentage >= result.passPercentage;

    await _collection.doc(resultId).update({
      'questionResults': updatedQuestionResults
          .map((question) => question.toMap())
          .toList(),
      'score': updatedScore,
      'percentage': updatedPercentage,
      'passed': updatedPassed,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  double _calculatePercentage({
    required double score,
    required double totalMarks,
  }) {
    if (totalMarks <= 0) {
      return 0.0;
    }

    final percentage = (score / totalMarks) * 100;

    return percentage.clamp(0.0, 100.0);
  }
}
