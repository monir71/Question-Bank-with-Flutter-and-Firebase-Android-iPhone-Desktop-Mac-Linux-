import 'package:questionbank/models/exam.dart';
import 'package:questionbank/models/exam_attempt.dart';
import 'package:questionbank/models/exam_question_result.dart';
import 'package:questionbank/models/question.dart';

class ExamScore {
  final int correctAnswers;
  final int wrongAnswers;
  final int answeredQuestions;
  final int unansweredQuestions;

  final double score;
  final double percentage;
  final bool passed;

  final List<ExamQuestionResult> questionResults;

  const ExamScore({
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.answeredQuestions,
    required this.unansweredQuestions,
    required this.score,
    required this.percentage,
    required this.passed,
    required this.questionResults,
  });
}

class ExamScoringService {
  const ExamScoringService();

  ExamScore calculateScore({
    required Exam exam,
    required List<Question> questions,
    required ExamAttempt attempt,
  }) {
    final questionsById = <String, Question>{
      for (final question in questions) question.questionId: question,
    };

    final answersByQuestionId = <String, ExamAttemptAnswer>{
      for (final answer in attempt.answers) answer.questionId: answer,
    };

    int correctAnswers = 0;
    int wrongAnswers = 0;
    int answeredQuestions = 0;

    double score = 0.0;

    final questionResults = <ExamQuestionResult>[];

    for (final examQuestion in exam.questions) {
      final question = questionsById[examQuestion.questionId];

      if (question == null) {
        continue;
      }

      final answer = answersByQuestionId[question.questionId];

      final isWritten = question.questionType == QuestionType.written;

      final hasAnswer =
          answer != null &&
          (answer.selectedOptionIds.isNotEmpty ||
              answer.writtenAnswer.trim().isNotEmpty);

      if (hasAnswer) {
        answeredQuestions++;
      }

      // ----------------------------------------------------------
      // Written question
      // ----------------------------------------------------------

      if (isWritten) {
        questionResults.add(
          ExamQuestionResult(
            questionId: question.questionId,
            maximumMarks: examQuestion.marks,
            awardedMarks: 0.0,
            answered: hasAnswer,
            correct: false,
            selectedOptionIds: answer?.selectedOptionIds ?? const [],
            writtenAnswer: answer?.writtenAnswer ?? '',
            assessmentStatus: QuestionAssessmentStatus.pending,
          ),
        );

        continue;
      }

      // ----------------------------------------------------------
      // Objective question
      // ----------------------------------------------------------

      if (!hasAnswer) {
        questionResults.add(
          ExamQuestionResult(
            questionId: question.questionId,
            maximumMarks: examQuestion.marks,
            awardedMarks: 0.0,
            answered: false,
            correct: false,
            selectedOptionIds: const [],
            writtenAnswer: '',
            assessmentStatus: QuestionAssessmentStatus.automatic,
          ),
        );

        continue;
      }

      final isCorrect = _isCorrectObjectiveAnswer(
        question: question,
        answer: answer!,
      );

      if (isCorrect) {
        correctAnswers++;
        score += examQuestion.marks;
      } else {
        wrongAnswers++;
      }

      questionResults.add(
        ExamQuestionResult(
          questionId: question.questionId,
          maximumMarks: examQuestion.marks,
          awardedMarks: isCorrect ? examQuestion.marks : 0.0,
          answered: true,
          correct: isCorrect,
          selectedOptionIds: answer.selectedOptionIds,
          writtenAnswer: '',
          assessmentStatus: QuestionAssessmentStatus.automatic,
        ),
      );
    }

    final totalQuestions = attempt.questionOrder.length;

    final unansweredQuestions = totalQuestions - answeredQuestions;

    final percentage = _calculatePercentage(
      score: score,
      totalMarks: exam.totalMarks,
    );

    final passed = percentage >= exam.passPercentage;

    return ExamScore(
      correctAnswers: correctAnswers,
      wrongAnswers: wrongAnswers,
      answeredQuestions: answeredQuestions,
      unansweredQuestions: unansweredQuestions,
      score: score,
      percentage: percentage,
      passed: passed,
      questionResults: questionResults,
    );
  }

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
