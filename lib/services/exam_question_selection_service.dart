import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:questionbank/models/automatic_question_selection.dart';
import 'package:questionbank/models/exam.dart';
import 'package:questionbank/models/question.dart';

class ExamQuestionSelectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _questionCollection =>
      _firestore.collection('questions');

  final Random _random = Random();

  /// Generates exam questions automatically according to
  /// the exam's configured selection rules.
  ///
  /// Only approved questions belonging to the exam's
  /// selected program and subjects are considered.
  Future<List<ExamQuestion>> generateQuestions({required Exam exam}) async {
    final automaticSelection = exam.automaticQuestionSelection;

    if (exam.questionSelectionMode != ExamQuestionSelectionMode.automatic) {
      throw Exception(
        'Automatic question selection is not enabled for this exam.',
      );
    }

    if (automaticSelection == null) {
      throw Exception('Automatic question selection settings are missing.');
    }

    if (exam.programId == null || exam.programId!.isEmpty) {
      throw Exception(
        'A program must be selected for automatic question selection.',
      );
    }

    if (exam.subjectIds.isEmpty) {
      throw Exception('At least one subject must be selected.');
    }

    final requestedCount = automaticSelection.questionCount;

    if (requestedCount <= 0) {
      throw Exception('The number of questions must be greater than zero.');
    }

    final questions = await _loadEligibleQuestions(
      programId: exam.programId!,
      subjectIds: exam.subjectIds,
    );

    if (questions.isEmpty) {
      throw Exception(
        'No approved questions are available for the selected program and subjects.',
      );
    }

    final selectedQuestions = _selectQuestions(
      questions: questions,
      selection: automaticSelection,
    );

    return _convertToExamQuestions(selectedQuestions);
  }

  /// Loads approved questions belonging to the exam's
  /// selected program and subjects.
  ///
  /// Questions are returned newest-first. When
  /// randomizeSelection is false, this order becomes
  /// the deterministic selection order.
  Future<List<Question>> _loadEligibleQuestions({
    required String programId,
    required List<String> subjectIds,
  }) async {
    final snapshot = await _questionCollection
        .where('status', isEqualTo: QuestionStatus.approved.name)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((document) => Question.fromMap(document.data()))
        .where(
          (question) =>
              question.programId == programId &&
              subjectIds.contains(question.subjectId),
        )
        .toList();
  }

  /// Selects questions according to the configured
  /// difficulty rule and randomization setting.
  List<Question> _selectQuestions({
    required List<Question> questions,
    required AutomaticQuestionSelection selection,
  }) {
    if (selection.difficultyMode == DifficultySelectionMode.any) {
      return _selectQuestionsByCount(
        questions: questions,
        requestedCount: selection.questionCount,
        randomize: selection.randomizeSelection,
      );
    }

    return _selectByDifficultyDistribution(
      questions: questions,
      selection: selection,
    );
  }

  /// Selects the requested number of questions.
  ///
  /// When randomize is true, questions are randomly selected.
  /// When randomize is false, questions are selected in the
  /// order supplied by the database query.
  List<Question> _selectQuestionsByCount({
    required List<Question> questions,
    required int requestedCount,
    required bool randomize,
  }) {
    if (questions.length < requestedCount) {
      throw Exception(
        'Only ${questions.length} eligible questions are available, '
        'but $requestedCount questions were requested.',
      );
    }

    if (!randomize) {
      return questions.take(requestedCount).toList();
    }

    final shuffled = List<Question>.from(questions)..shuffle(_random);

    return shuffled.take(requestedCount).toList();
  }

  /// Selects the exact requested number of Easy,
  /// Medium and Hard questions.
  ///
  /// The configured difficulty distribution is always
  /// respected.
  ///
  /// When randomizeSelection is true, questions within
  /// each difficulty group are selected randomly.
  ///
  /// When randomizeSelection is false, questions within
  /// each difficulty group are selected in database order.
  List<Question> _selectByDifficultyDistribution({
    required List<Question> questions,
    required AutomaticQuestionSelection selection,
  }) {
    final distribution = selection.difficultyDistribution;

    if (distribution.total != selection.questionCount) {
      throw Exception(
        'Difficulty distribution total '
        '(${distribution.total}) does not match '
        'the requested question count '
        '(${selection.questionCount}).',
      );
    }

    final easyQuestions = questions
        .where((question) => question.difficulty == DifficultyLevel.easy)
        .toList();

    final mediumQuestions = questions
        .where((question) => question.difficulty == DifficultyLevel.medium)
        .toList();

    final hardQuestions = questions
        .where((question) => question.difficulty == DifficultyLevel.hard)
        .toList();

    _validateDifficultyAvailability(
      label: 'Easy',
      available: easyQuestions.length,
      required: distribution.easy,
    );

    _validateDifficultyAvailability(
      label: 'Medium',
      available: mediumQuestions.length,
      required: distribution.medium,
    );

    _validateDifficultyAvailability(
      label: 'Hard',
      available: hardQuestions.length,
      required: distribution.hard,
    );

    final selectedQuestions = <Question>[];

    selectedQuestions.addAll(
      _takeQuestions(
        questions: easyQuestions,
        count: distribution.easy,
        randomize: selection.randomizeSelection,
      ),
    );

    selectedQuestions.addAll(
      _takeQuestions(
        questions: mediumQuestions,
        count: distribution.medium,
        randomize: selection.randomizeSelection,
      ),
    );

    selectedQuestions.addAll(
      _takeQuestions(
        questions: hardQuestions,
        count: distribution.hard,
        randomize: selection.randomizeSelection,
      ),
    );

    // Only shuffle the final list when random selection
    // is enabled. Otherwise the configured difficulty
    // groups remain deterministic: Easy → Medium → Hard.
    if (selection.randomizeSelection) {
      selectedQuestions.shuffle(_random);
    }

    return selectedQuestions;
  }

  void _validateDifficultyAvailability({
    required String label,
    required int available,
    required int required,
  }) {
    if (available < required) {
      throw Exception(
        'Not enough $label questions are available. '
        '$required required, but only $available available.',
      );
    }
  }

  /// Takes questions either randomly or in their existing
  /// database order.
  List<Question> _takeQuestions({
    required List<Question> questions,
    required int count,
    required bool randomize,
  }) {
    if (count <= 0) {
      return [];
    }

    if (!randomize) {
      return questions.take(count).toList();
    }

    final shuffled = List<Question>.from(questions)..shuffle(_random);

    return shuffled.take(count).toList();
  }

  /// Converts Question objects into the lightweight
  /// ExamQuestion objects stored inside an Exam.
  List<ExamQuestion> _convertToExamQuestions(List<Question> questions) {
    final examQuestions = <ExamQuestion>[];

    for (int index = 0; index < questions.length; index++) {
      final question = questions[index];

      examQuestions.add(
        ExamQuestion(
          questionId: question.questionId,
          marks: question.marks,
          order: index + 1,
        ),
      );
    }

    return examQuestions;
  }
}
