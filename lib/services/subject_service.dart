import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:questionbank/models/subject.dart';

class SubjectService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('subjects');

  Future<void> createSubject(Subject subject) async {
    final data = subject.toMap();

    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _collection.doc(subject.subjectId).set(data);
  }

  Future<List<Subject>> getAllSubjects() async {
    final snapshot = await _collection
        .orderBy('sortOrder')
        .get();

    return snapshot.docs
        .map(
          (document) => Subject.fromMap(
        document.data(),
      ),
    )
        .toList();
  }

  Future<List<Subject>> getSubjectsByProgram(
      String programId,
      ) async {
    final snapshot = await _collection
        .where(
      'programId',
      isEqualTo: programId,
    )
        .orderBy('sortOrder')
        .get();

    return snapshot.docs
        .map(
          (document) => Subject.fromMap(
        document.data(),
      ),
    )
        .toList();
  }

  Future<void> updateSubject(
      Subject subject,
      ) async {
    final data = subject.toMap();

    data.remove('createdAt');
    data['updatedAt'] =
        FieldValue.serverTimestamp();

    await _collection
        .doc(subject.subjectId)
        .update(data);
  }

  Future<void> updateSubjectStatus({
    required String subjectId,
    required bool isActive,
  }) async {
    await _collection
        .doc(subjectId)
        .update({
      'isActive': isActive,
      'updatedAt':
      FieldValue.serverTimestamp(),
    });
  }
}