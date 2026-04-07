import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../data/models/patient_model.dart';
import '../../../../data/models/user_model.dart';
import '../../domain/entities/register_request_entity.dart';
import '../../../../core/enums/app_role.dart';
import '../../../../core/enums/user_status.dart';

abstract class AuthRemoteDatasource {
  Future<UserModel> register(RegisterRequestEntity request);

  Future<UserModel> login({
    required String email,
    required String password,
  });

  Future<void> logout();

  Future<void> forgotPassword(String email);

  Future<UserModel?> getCurrentUser();
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRemoteDatasourceImpl({
    required this.firebaseAuth,
    required this.firestore,
  });

  @override
  Future<UserModel> register(RegisterRequestEntity request) async {
    final credential = await firebaseAuth.createUserWithEmailAndPassword(
      email: request.email.trim(),
      password: request.password,
    );

    final user = credential.user;
    if (user == null) {
      throw Exception('Không thể tạo tài khoản.');
    }

    await user.updateDisplayName(request.fullName);
    await user.sendEmailVerification();

    final now = DateTime.now();

    final userModel = UserModel(
      uid: user.uid,
      username: request.email.trim(),
      email: request.email.trim(),
      phone: request.phone.trim(),
      fullName: request.fullName.trim(),
      cccd: request.cccd.trim(),
      role: AppRole.patient,
      status: UserStatus.active,
      emailVerified: user.emailVerified,
      createdAt: now,
      updatedAt: now,
    );

    final patientModel = PatientModel.empty(user.uid);

    final batch = firestore.batch();

    batch.set(
      firestore.collection('users').doc(user.uid),
      userModel.toMap(),
    );

    batch.set(
      firestore.collection('patients').doc(user.uid),
      patientModel.toMap(),
    );

    await batch.commit();

    return userModel;
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw Exception('Không tìm thấy người dùng.');
    }

    await user.reload();
    final currentUser = firebaseAuth.currentUser;

    if (currentUser == null) {
      throw Exception('Không thể tải thông tin người dùng.');
    }

    if (!currentUser.emailVerified) {
      throw FirebaseAuthException(
        code: 'email-not-verified',
        message: 'Email chưa được xác thực.',
      );
    }

    await firestore.collection('users').doc(currentUser.uid).update({
      'emailVerified': true,
      'updatedAt': Timestamp.now(),
    });

    final doc = await firestore.collection('users').doc(currentUser.uid).get();

    if (!doc.exists) {
      throw Exception('Không tìm thấy hồ sơ người dùng.');
    }

    return UserModel.fromDocument(doc);
  }

  @override
  Future<void> logout() async {
    await firebaseAuth.signOut();
  }

  @override
  Future<void> forgotPassword(String email) async {
    await firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final currentUser = firebaseAuth.currentUser;
    if (currentUser == null) return null;

    final doc = await firestore.collection('users').doc(currentUser.uid).get();
    if (!doc.exists) return null;

    return UserModel.fromDocument(doc);
  }
}