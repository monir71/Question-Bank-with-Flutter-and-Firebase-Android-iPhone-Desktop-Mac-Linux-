import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:questionbank/models/question.dart';

class QuestionService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>>
  get _collection =>
      _firestore.collection('questions');

  Future<List<Question>> getAllQuestions() async {
    final snapshot = await _collection
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map(
          (document) => Question.fromMap(
        document.data(),
      ),
    )
        .toList();
  }

  Future<List<Question>> getQuestionsByTopic(
      String topicId,
      ) async {
    final snapshot = await _collection
        .where(
      'topicId',
      isEqualTo: topicId,
    )
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map(
          (document) => Question.fromMap(
        document.data(),
      ),
    )
        .toList();
  }

  Future<void> updateQuestion(
      Question question,
      ) async {
    final data = question.toMap();

    data.remove('createdAt');
    data['updatedAt'] =
        FieldValue.serverTimestamp();

    await _collection
        .doc(question.questionId)
        .update(data);
  }

  Future<List<Question>> getQuestionsByStatus(
      QuestionStatus status,
      ) async {
    final snapshot = await _collection
        .where(
      'status',
      isEqualTo: status.name,
    )
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map(
          (document) => Question.fromMap(
        document.data(),
      ),
    )
        .toList();
  }

  Future<void> approveQuestion({
    required String questionId,
    required String adminUserId,
  }) async {
    await _collection
        .doc(questionId)
        .update({
      'status': QuestionStatus.approved.name,
      'approvedBy': adminUserId,
      'approvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectQuestion({
    required String questionId,
  }) async {
    await _collection
        .doc(questionId)
        .update({
      'status': QuestionStatus.rejected.name,
      'approvedBy': null,
      'approvedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createAdminQuestion(
      Question question,
      ) async {
    final data = question.toMap();

    data['status'] =
        QuestionStatus.approved.name;

    data['approvedBy'] = question.createdBy;
    data['approvedAt'] =
        FieldValue.serverTimestamp();

    data['createdAt'] =
        FieldValue.serverTimestamp();

    data['updatedAt'] =
        FieldValue.serverTimestamp();

    await _collection
        .doc(question.questionId)
        .set(data);
  }

  Future<void> submitQuestion(
      Question question,
      ) async {
    final data = question.toMap();

    data['status'] =
        QuestionStatus.pending.name;

    data['approvedBy'] = null;
    data['approvedAt'] = null;

    data['createdAt'] =
        FieldValue.serverTimestamp();

    data['updatedAt'] =
        FieldValue.serverTimestamp();

    await _collection
        .doc(question.questionId)
        .set(data);
  }
}