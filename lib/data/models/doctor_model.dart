import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorModel {
  final String id;
  final String userId;
  final String specialization;
  final String departmentId;
  final String licenseNumber;
  final int yearsOfExperience;
  final double consultationFee;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DoctorModel({
    required this.id,
    required this.userId,
    required this.specialization,
    required this.departmentId,
    required this.licenseNumber,
    required this.yearsOfExperience,
    required this.consultationFee,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'specialization': specialization,
      'departmentId': departmentId,
      'licenseNumber': licenseNumber,
      'yearsOfExperience': yearsOfExperience,
      'consultationFee': consultationFee,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory DoctorModel.fromMap(String id, Map<String, dynamic> map) {
    return DoctorModel(
      id: id,
      userId: map['userId'] ?? '',
      specialization: map['specialization'] ?? '',
      departmentId: map['departmentId'] ?? '',
      licenseNumber: map['licenseNumber'] ?? '',
      yearsOfExperience: map['yearsOfExperience'] ?? 0,
      consultationFee: (map['consultationFee'] ?? 0).toDouble(),
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}