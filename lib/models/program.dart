import 'package:cloud_firestore/cloud_firestore.dart';

class Program {
  final String programId;
  final String learningAreaId;
  final String name;
  final String? parentProgramId;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Program({
    required this.programId,
    required this.learningAreaId,
    required this.name,
    this.parentProgramId,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'programId': programId,
      'learningAreaId': learningAreaId,
      'name': name,
      'parentProgramId': parentProgramId,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Program.fromMap(Map<String, dynamic> map) {
    return Program(
      programId: map['programId'] as String? ?? '',
      learningAreaId:
      map['learningAreaId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      parentProgramId:
      map['parentProgramId'] as String?,
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