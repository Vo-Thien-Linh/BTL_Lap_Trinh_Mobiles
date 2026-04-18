import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/enums/app_role.dart';
import '../../core/enums/user_status.dart';
import '../../features/auth/domain/entities/app_user_entity.dart';

class UserModel {
  final String uid;
  final String username;
  final String email;
  final String phone;
  final String fullName;
  final String cccd;
  final AppRole role;
  final UserStatus status;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? dateOfBirth;
  final String? gender;
  final String? healthInsuranceNumber;
  final String? bloodType;
  final String? address;
  final String? emergencyPhone;
  final String? avatarUrl;
  final List<String>? allergies;
  final List<String>? chronicConditions;
  final double? weight;
  final double? height;

  const UserModel({
    required this.uid,
    required this.username,
    required this.email,
    required this.phone,
    required this.fullName,
    required this.cccd,
    required this.role,
    required this.status,
    required this.emailVerified,
    required this.createdAt,
    required this.updatedAt,
    this.dateOfBirth,
    this.gender,
    this.healthInsuranceNumber,
    this.bloodType,
    this.address,
    this.emergencyPhone,
    this.avatarUrl,
    this.allergies,
    this.chronicConditions,
    this.weight,
    this.height,
  });

  factory UserModel.empty() {
    final now = DateTime.now();
    return UserModel(
      uid: '',
      username: '',
      email: '',
      phone: '',
      fullName: '',
      cccd: '',
      role: AppRole.patient,
      status: UserStatus.active,
      emailVerified: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  UserModel copyWith({
    String? uid,
    String? username,
    String? email,
    String? phone,
    String? fullName,
    String? cccd,
    AppRole? role,
    UserStatus? status,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? dateOfBirth,
    String? gender,
    String? healthInsuranceNumber,
    String? bloodType,
    String? address,
    String? emergencyPhone,
    String? avatarUrl,
    List<String>? allergies,
    List<String>? chronicConditions,
    double? weight,
    double? height,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      cccd: cccd ?? this.cccd,
      role: role ?? this.role,
      status: status ?? this.status,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      healthInsuranceNumber:
          healthInsuranceNumber ?? this.healthInsuranceNumber,
      bloodType: bloodType ?? this.bloodType,
      address: address ?? this.address,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      allergies: allergies ?? this.allergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      weight: weight ?? this.weight,
      height: height ?? this.height,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'phone': phone,
      'fullName': fullName,
      'cccd': cccd,
      'role': role.value,
      'status': status.value,
      'emailVerified': emailVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'healthInsuranceNumber': healthInsuranceNumber,
      'bloodType': bloodType,
      'address': address,
      'emergencyPhone': emergencyPhone,
      'avatarUrl': avatarUrl,
      'allergies': allergies,
      'chronicConditions': chronicConditions,
      'weight': weight,
      'height': height,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      fullName: map['fullName'] ?? '',
      cccd: map['cccd'] ?? '',
      role: AppRoleX.fromString(map['role'] ?? 'patient'),
      status: UserStatusX.fromString(map['status'] ?? 'active'),
      emailVerified: map['emailVerified'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateOfBirth: map['dateOfBirth'] as String?,
      gender: map['gender'] as String?,
      healthInsuranceNumber: map['healthInsuranceNumber'] as String?,
      bloodType: map['bloodType'] as String?,
      address: map['address'] as String?,
      emergencyPhone: map['emergencyPhone'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      allergies: map['allergies'] != null ? List<String>.from(map['allergies']) : null,
      chronicConditions: map['chronicConditions'] != null ? List<String>.from(map['chronicConditions']) : null,
      weight: (map['weight'] as num?)?.toDouble(),
      height: (map['height'] as num?)?.toDouble(),
    );
  }

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromMap({
      ...data,
      'uid': doc.id,
    });
  }

  AppUserEntity toEntity() {
    return AppUserEntity(
      uid: uid,
      username: username,
      email: email,
      phone: phone,
      fullName: fullName,
      cccd: cccd,
      role: role.value,
      status: status.value,
      emailVerified: emailVerified,
      createdAt: createdAt,
      updatedAt: updatedAt,
      dateOfBirth: dateOfBirth,
      gender: gender,
      healthInsuranceNumber: healthInsuranceNumber,
      bloodType: bloodType,
      address: address,
      avatarUrl: avatarUrl,
    );
  }
}