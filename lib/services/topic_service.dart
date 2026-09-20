import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:questionbank/models/topic.dart';

class TopicService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('topics');

  Future<void> createTopic(Topic topic) async {
    final data = topic.toMap();

    data['createdAt'] =
        FieldValue.serverTimestamp();

    data['updatedAt'] =
        FieldValue.serverTimestamp();

    await _collection
        .doc(topic.topicId)
        .set(data);
  }

  Future<List<Topic>> getAllTopics() async {
    final snapshot = await _collection
        .orderBy('sortOrder')
        .get();

    return snapshot.docs
        .map(
          (document) => Topic.fromMap(
        document.data(),
      ),
    )
        .toList();
  }

  Future<List<Topic>> getTopicsBySubject(
      String subjectId,
      ) async {
    final snapshot = await _collection
        .where(
      'subjectId',
      isEqualTo: subjectId,
    )
        .orderBy('sortOrder')
        .get();

    return snapshot.docs
        .map(
          (document) => Topic.fromMap(
        document.data(),
      ),
    )
        .toList();
  }

  Future<void> updateTopic(
      Topic topic,
      ) async {
    final data = topic.toMap();

    data.remove('createdAt');

    data['updatedAt'] =
        FieldValue.serverTimestamp();

    await _collection
        .doc(topic.topicId)
        .update(data);
  }

  Future<void> updateTopicStatus({
    required String topicId,
    required bool isActive,
  }) async {
    await _collection
        .doc(topicId)
        .update({
      'isActive': isActive,
      'updatedAt':
      FieldValue.serverTimestamp(),
    });
  }
}