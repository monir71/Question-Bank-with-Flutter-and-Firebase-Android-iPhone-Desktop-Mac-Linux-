import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:questionbank/models/program.dart';

class ProgramService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>>
  get _collection =>
      _firestore.collection('programs');

  Future<void> createProgram(
      Program program,
      ) async {
    final data = program.toMap();

    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _collection
        .doc(program.programId)
        .set(data);
  }

  Future<List<Program>> getAllPrograms() async {
    final snapshot = await _collection
        .orderBy('sortOrder')
        .get();

    return snapshot.docs
        .map(
          (document) => Program.fromMap(
        document.data(),
      ),
    )
        .toList();
  }

  Future<List<Program>> getProgramsByLearningArea(
      String learningAreaId,
      ) async {
    final snapshot = await _collection
        .where(
      'learningAreaId',
      isEqualTo: learningAreaId,
    )
        .orderBy('sortOrder')
        .get();

    return snapshot.docs
        .map(
          (document) => Program.fromMap(
        document.data(),
      ),
    )
        .toList();
  }

  Future<List<Program>> getChildPrograms(
      String parentProgramId,
      ) async {
    final snapshot = await _collection
        .where(
      'parentProgramId',
      isEqualTo: parentProgramId,
    )
        .orderBy('sortOrder')
        .get();

    return snapshot.docs
        .map(
          (document) => Program.fromMap(
        document.data(),
      ),
    )
        .toList();
  }

  Future<void> updateProgram(
      Program program,
      ) async {
    final data = program.toMap();

    data.remove('createdAt');
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _collection
        .doc(program.programId)
        .update(data);
  }

  Future<void> updateProgramStatus({
    required String programId,
    required bool isActive,
  }) async {
    await _collection
        .doc(programId)
        .update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}