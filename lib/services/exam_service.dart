import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:questionbank/models/exam.dart';

class ExamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('exams');

  // ------------------------------------------------------------
  // Create
  // ------------------------------------------------------------

  Future<void> createExam(Exam exam) async {
    final data = exam.toMap();

    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _collection.doc(exam.examId).set(data);
  }

  // ------------------------------------------------------------
  // Get all exams
  // ------------------------------------------------------------

  Future<List<Exam>> getAllExams() async {
    final snapshot = await _collection.orderBy('examName').get();

    return snapshot.docs
        .map((document) => Exam.fromMap(document.data()))
        .toList();
  }

  // ------------------------------------------------------------
  // Get active exams
  // ------------------------------------------------------------

  Future<List<Exam>> getActiveExams() async {
    final snapshot = await _collection
        .where('isActive', isEqualTo: true)
        .orderBy('examName')
        .get();

    return snapshot.docs
        .map((document) => Exam.fromMap(document.data()))
        .toList();
  }

  // ------------------------------------------------------------
  // Get exam by ID
  // ------------------------------------------------------------

  Future<Exam?> getExamById(String examId) async {
    final document = await _collection.doc(examId).get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    return Exam.fromMap(document.data()!);
  }

  // ------------------------------------------------------------
  // Update exam
  // ------------------------------------------------------------

  Future<void> updateExam(Exam exam) async {
    final data = exam.toMap();

    // createdAt should never be replaced during an update.
    data.remove('createdAt');

    data['updatedAt'] = FieldValue.serverTimestamp();

    await _collection.doc(exam.examId).update(data);
  }

  // ------------------------------------------------------------
  // Update exam status
  // ------------------------------------------------------------

  Future<void> updateExamStatus({
    required String examId,
    required bool isActive,
  }) async {
    await _collection.doc(examId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ------------------------------------------------------------
  // Update exam questions
  // ------------------------------------------------------------

  Future<void> updateExamQuestions({
    required String examId,
    required List<ExamQuestion> questions,
  }) async {
    await _collection.doc(examId).update({
      'questions': questions
          .map((question) => question.toMap())
          .toList(),
      'questionCount': questions.length,
      'totalMarks': questions.fold<double>(
        0.0,
            (total, question) => total + question.marks,
      ),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ------------------------------------------------------------
  // Add one question
  // ------------------------------------------------------------

  Future<void> addQuestionToExam({
    required String examId,
    required ExamQuestion question,
  }) async {
    final exam = await getExamById(examId);

    if (exam == null) {
      throw Exception('Exam not found.');
    }

    final questions = List<ExamQuestion>.from(exam.questions);

    // Prevent the same question from being added twice.
    final alreadyExists = questions.any(
      (item) => item.questionId == question.questionId,
    );

    if (alreadyExists) {
      throw Exception('This question is already added to the exam.');
    }

    questions.add(question);

    await updateExamQuestions(examId: examId, questions: questions);
  }

  // ------------------------------------------------------------
  // Remove one question
  // ------------------------------------------------------------

  Future<void> removeQuestionFromExam({
    required String examId,
    required String questionId,
  }) async {
    final exam = await getExamById(examId);

    if (exam == null) {
      throw Exception('Exam not found.');
    }

    final questions = exam.questions
        .where((question) => question.questionId != questionId)
        .toList();

    await updateExamQuestions(examId: examId, questions: questions);
  }
}
