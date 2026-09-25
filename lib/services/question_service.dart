import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:questionbank/models/question.dart';

class QuestionService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>>
  get _collection =>
      _firestore.collection('questions');

  // ---------------------------------------------------------------------------
  // GET ALL QUESTIONS
  // ---------------------------------------------------------------------------

  Future<List<Question>> getAllQuestions() async {
    final snapshot = await _collection
        .orderBy(
      'createdAt',
      descending: true,
    )
        .get();

    return snapshot.docs
        .map(
          (document) => Question.fromMap(
        document.data(),
      ),
    )
        .toList();
  }

  // ---------------------------------------------------------------------------
  // GET QUESTIONS BY CREATOR
  // ---------------------------------------------------------------------------

  Future<List<Question>> getQuestionsByCreator(
      String userId,
      ) async {
    final snapshot = await _collection
        .where(
      'createdBy',
      isEqualTo: userId,
    )
        .get();

    final questions = snapshot.docs
        .map(
          (document) => Question.fromMap(
        document.data(),
      ),
    )
        .toList();

    // Sort locally so no composite index is required.
    questions.sort(
          (a, b) => b.createdAt.compareTo(
        a.createdAt,
      ),
    );

    return questions;
  }

  // ---------------------------------------------------------------------------
  // GET QUESTIONS FROM OTHER USERS
  // ---------------------------------------------------------------------------

  Future<List<Question>> getQuestionsFromOthers(
      String currentUserId,
      ) async {
    final questions = await getAllQuestions();

    return questions
        .where(
          (question) =>
      question.createdBy != currentUserId,
    )
        .toList();
  }

  // ---------------------------------------------------------------------------
  // GET QUESTION BY ID
  // ---------------------------------------------------------------------------

  Future<Question?> getQuestionById(
      String questionId,
      ) async {
    final document =
    await _collection.doc(questionId).get();

    if (!document.exists ||
        document.data() == null) {
      return null;
    }

    return Question.fromMap(
      document.data()!,
    );
  }

  // ---------------------------------------------------------------------------
  // GET QUESTIONS BY STATUS
  // ---------------------------------------------------------------------------

  Future<List<Question>> getQuestionsByStatus(
      QuestionStatus status,
      ) async {
    final snapshot = await _collection
        .where(
      'status',
      isEqualTo: status.name,
    )
        .orderBy(
      'createdAt',
      descending: true,
    )
        .get();

    return snapshot.docs
        .map(
          (document) => Question.fromMap(
        document.data(),
      ),
    )
        .toList();
  }

  // ---------------------------------------------------------------------------
  // UPDATE QUESTION
  // ---------------------------------------------------------------------------
  //
  // General update method.
  // Used when the complete Question object is intentionally being updated.
  //

  Future<void> updateQuestion(
      Question question,
      ) async {
    final data = question.toMap();

    // Preserve original creation time.
    data.remove('createdAt');

    data['updatedAt'] =
        FieldValue.serverTimestamp();

    await _collection
        .doc(question.questionId)
        .update(data);
  }

  // ---------------------------------------------------------------------------
  // UPDATE PENDING QUESTION
  // ---------------------------------------------------------------------------
  //
  // Used by Admin when correcting an examinee's pending question.
  //
  // The following submission/approval information must NOT be changed here:
  //   - questionId
  //   - createdAt
  //   - createdBy
  //   - status
  //   - approvedBy
  //   - approvedAt
  //
  // This allows Admin to correct the actual question content without
  // accidentally changing ownership or approval state.
  //

  Future<void> updatePendingQuestion(
      Question question,
      ) async {
    final data = question.toMap();

    data.remove('questionId');
    data.remove('createdAt');
    data.remove('createdBy');
    data.remove('status');
    data.remove('approvedBy');
    data.remove('approvedAt');

    data['updatedAt'] =
        FieldValue.serverTimestamp();

    await _collection
        .doc(question.questionId)
        .update(data);
  }

  // ---------------------------------------------------------------------------
  // APPROVE QUESTION
  // ---------------------------------------------------------------------------

  Future<void> approveQuestion({
    required String questionId,
    required String adminUserId,
  }) async {
    await _collection
        .doc(questionId)
        .update({
      'status':
      QuestionStatus.approved.name,
      'approvedBy': adminUserId,
      'approvedAt':
      FieldValue.serverTimestamp(),
      'updatedAt':
      FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------------
  // REJECT QUESTION
  // ---------------------------------------------------------------------------

  Future<void> rejectQuestion(
      String questionId,
      ) async {
    await _collection
        .doc(questionId)
        .update({
      'status':
      QuestionStatus.rejected.name,
      'approvedBy': null,
      'approvedAt': null,
      'updatedAt':
      FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------------
  // CREATE ADMIN QUESTION
  // ---------------------------------------------------------------------------
  //
  // Questions created directly by Admin are immediately approved.
  //

  Future<void> createAdminQuestion(
      Question question,
      ) async {
    final data = question.toMap();

    data['status'] =
        QuestionStatus.approved.name;

    data['approvedBy'] =
        question.createdBy;

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

  // ---------------------------------------------------------------------------
  // SUBMIT QUESTION
  // ---------------------------------------------------------------------------
  //
  // Questions submitted by Examinees start as Pending.
  //

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