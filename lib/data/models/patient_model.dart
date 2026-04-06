import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/enums/gender_type.dart';

class PatientModel {
  final String id;
  final String userId;
  final DateTime? dateOfBirth;
  final GenderType gender;
  final String address;
  final String insuranceNumber;
  final String bloodType;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PatientModel({
    required this.id,
    required this.userId,
    required this.dateOfBirth,
    required this.gender,
    required this.address,
    required this.insuranceNumber,
    required this.bloodType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PatientModel.empty(String userId) {
    final now = DateTime.now();
    return PatientModel(
      id: userId,
      userId: userId,
      dateOfBirth: null,
      gender: GenderType.other,
      address: '',
      insuranceNumber: '',
      bloodType: '',
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'dateOfBirth':
      dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'gender': gender.value,
      'address': address,
      'insuranceNumber': insuranceNumber,
      'bloodType': bloodType,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory PatientModel.fromMap(String id, Map<String, dynamic> map) {
    return PatientModel(
      id: id,
      userId: map['userId'] ?? '',
      dateOfBirth: (map['dateOfBirth'] as Timestamp?)?.toDate(),
      gender: GenderTypeX.fromString(map['gender'] ?? 'other'),
      address: map['address'] ?? '',
      insuranceNumber: map['insuranceNumber'] ?? '',
      bloodType: map['bloodType'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}