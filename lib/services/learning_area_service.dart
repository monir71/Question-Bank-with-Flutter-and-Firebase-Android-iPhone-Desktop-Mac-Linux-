import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:questionbank/models/learning_area.dart';

class LearningAreaService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>>
  get _collection =>
      _firestore.collection('learningAreas');

  Future<void> createLearningArea(
      LearningArea learningArea,
      ) async {
    final data = learningArea.toMap();

    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _collection
        .doc(learningArea.learningAreaId)
        .set(data);
  }

  Future<List<LearningArea>> getAllLearningAreas() async {
    final snapshot = await _collection
        .orderBy('sortOrder')
        .get();

    return snapshot.docs
        .map(
          (document) =>
          LearningArea.fromMap(document.data()),
    )
        .toList();
  }

  Future<void> updateLearningArea(
      LearningArea learningArea,
      ) async {
    final data = learningArea.toMap();

    data.remove('createdAt');
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _collection
        .doc(learningArea.learningAreaId)
        .update(data);
  }

  Future<void> updateLearningAreaStatus({
    required String learningAreaId,
    required bool isActive,
  }) async {
    await _collection
        .doc(learningAreaId)
        .update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}