import 'package:cloud_firestore/cloud_firestore.dart';

class DepartmentModel {
  final String id;
  final String departmentName;
  final String description;
  final String location;
  final String phone;
  final List<String> rooms;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DepartmentModel({
    required this.id,
    required this.departmentName,
    required this.description,
    required this.location,
    required this.phone,
    this.rooms = const [],
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'departmentName': departmentName,
      'description': description,
      'location': location,
      'phone': phone,
      'rooms': rooms,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory DepartmentModel.fromMap(String id, Map<String, dynamic> map) {
    return DepartmentModel(
      id: id,
      departmentName: map['departmentName'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      phone: map['phone'] ?? '',
      rooms: _stringList(map['rooms']),
      imageUrl: map['imageUrl']?.toString(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is Iterable) {
      return value
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList();
    }
    return const [];
  }
}
