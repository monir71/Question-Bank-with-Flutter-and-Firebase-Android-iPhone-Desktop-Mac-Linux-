import 'package:questionbank/models/exam.dart';
import 'package:questionbank/models/exam_attempt.dart';
import 'package:questionbank/models/question.dart';

class ExamScoringService {
  const ExamScoringService();

  /// Calculates the score for objective questions only.
  ///
  /// Supported question types in this step:
  /// - multiple
  /// - trueFalse
  ///
  /// Written questions are ignored for now and will be handled
  /// in the written/manual/hybrid assessment step.
  double calculateObjectiveScore({
    required Exam exam,
    required List<Question> questions,
    required ExamAttempt attempt,
  }) {
    double score = 0.0;

    final questionsById = <String, Question>{
      for (final question in questions) question.questionId: question,
    };

    final answersByQuestionId = <String, ExamAttemptAnswer>{
      for (final answer in attempt.answers) answer.questionId: answer,
    };

    for (final examQuestion in exam.questions) {
      final question = questionsById[examQuestion.questionId];

      if (question == null) {
        continue;
      }

      if (question.questionType == QuestionType.written) {
        continue;
      }

      final answer = answersByQuestionId[question.questionId];

      if (answer == null) {
        continue;
      }

      if (_isCorrectObjectiveAnswer(question: question, answer: answer)) {
        score += examQuestion.marks;
      }
    }

    return score;
  }

  /// Calculates the percentage based on the exam's configured total marks.
  double calculatePercentage({
    required double score,
    required double totalMarks,
  }) {
    if (totalMarks <= 0) {
      return 0.0;
    }

    final percentage = (score / totalMarks) * 100;

    return percentage.clamp(0.0, 100.0);
  }

  /// Determines whether the submitted objective answer is completely correct.
  bool _isCorrectObjectiveAnswer({
    required Question question,
    required ExamAttemptAnswer answer,
  }) {
    final selectedAnswers = Set<String>.from(answer.selectedOptionIds);

    final correctAnswers = Set<String>.from(question.correctAnswers);

    if (selectedAnswers.length != correctAnswers.length) {
      return false;
    }

    return selectedAnswers.containsAll(correctAnswers);
  }
}
