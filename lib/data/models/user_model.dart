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
  final String? avatarUrl;

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
    this.avatarUrl,
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
    String? avatarUrl,
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
      healthInsuranceNumber: healthInsuranceNumber ?? this.healthInsuranceNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
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
      'avatarUrl': avatarUrl,
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
      avatarUrl: map['avatarUrl'] as String?,
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
      avatarUrl: avatarUrl,
    );
  }
}