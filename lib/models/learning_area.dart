import 'package:cloud_firestore/cloud_firestore.dart';

class LearningArea {
  final String learningAreaId;
  final String name;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LearningArea({
    required this.learningAreaId,
    required this.name,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'learningAreaId': learningAreaId,
      'name': name,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory LearningArea.fromMap(Map<String, dynamic> map) {
    return LearningArea(
      learningAreaId:
      map['learningAreaId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      sortOrder: map['sortOrder'] as int? ?? 0,
      createdAt: _parseDateTime(map['createdAt']) ??
          DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']) ??
          DateTime.now(),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }
}