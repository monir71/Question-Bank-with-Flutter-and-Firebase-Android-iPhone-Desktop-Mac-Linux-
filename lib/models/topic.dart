import 'package:cloud_firestore/cloud_firestore.dart';

class Topic {
  final String topicId;
  final String subjectId;
  final String name;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  Topic({
    required this.topicId,
    required this.subjectId,
    required this.name,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'topicId': topicId,
      'subjectId': subjectId,
      'name': name,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Topic.fromMap(
      Map<String, dynamic> map,
      ) {
    final createdAtValue = map['createdAt'];
    final updatedAtValue = map['updatedAt'];

    return Topic(
      topicId:
      map['topicId'] as String? ?? '',
      subjectId:
      map['subjectId'] as String? ?? '',
      name:
      map['name'] as String? ?? '',
      isActive:
      map['isActive'] as bool? ?? true,
      sortOrder:
      map['sortOrder'] as int? ?? 0,
      createdAt:
      createdAtValue is Timestamp
          ? createdAtValue.toDate()
          : DateTime.now(),
      updatedAt:
      updatedAtValue is Timestamp
          ? updatedAtValue.toDate()
          : DateTime.now(),
    );
  }
}