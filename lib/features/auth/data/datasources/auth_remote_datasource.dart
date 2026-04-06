import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/app_user_entity.dart';
import '../../domain/entities/register_request_entity.dart';

abstract class AuthRemoteDatasource {
  Future<AppUserEntity> login({
    required String email,
    required String password,
  });
  Future<AppUserEntity> register(RegisterRequestEntity request);
  Future<void> logout();
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRemoteDatasourceImpl({
    required this.firebaseAuth,
    required this.firestore,
  });

  @override
  Future<AppUserEntity> login({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-missing',
        message: 'Cannot find signed-in user.',
      );
    }

    return _readOrBuildProfile(user);
  }

  @override
  Future<AppUserEntity> register(RegisterRequestEntity request) async {
    final normalizedEmail = request.email.trim().toLowerCase();
    final normalizedFullName = request.fullName.trim();
    final normalizedPhone = request.phone.trim();

    final credential = await firebaseAuth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: request.password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-missing',
        message: 'Cannot create account.',
      );
    }

    final userDocRef = firestore.collection('Users').doc(user.uid);

    final appUser = AppUserEntity(
      uid: user.uid,
      email: normalizedEmail,
      fullName: normalizedFullName,
      phone: normalizedPhone,
      role: 'patient',
      status: 'active',
    );

    try {
      final existing = await userDocRef.get();
      final payload = {
        'username': normalizedEmail.split('@').first,
        'email': appUser.email,
        'phone': appUser.phone,
        'fullName': appUser.fullName,
        'role': appUser.role,
        'status': appUser.status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!existing.exists) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }

      await userDocRef.set(payload, SetOptions(merge: true));
    } catch (error) {
      // Roll back auth account if profile creation fails.
      await user.delete();

      if (error is FirebaseException) {
        throw FirebaseException(
          plugin: error.plugin,
          code: error.code,
          message: error.message,
        );
      }

      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'profile-write-failed',
        message: 'Khong the tao ho so nguoi dung.',
      );
    }

    await firebaseAuth.signOut();
    return appUser;
  }

  @override
  Future<void> logout() async {
    await firebaseAuth.signOut();
  }

  Future<AppUserEntity> _readOrBuildProfile(User user) async {
    final snapshot = await firestore.collection('Users').doc(user.uid).get();
    final data = snapshot.data();

    return AppUserEntity(
      uid: user.uid,
      email: user.email ?? (data?['email'] as String? ?? ''),
      fullName: data?['fullName'] as String? ?? '',
      phone: data?['phone'] as String? ?? '',
      role: data?['role'] as String? ?? 'patient',
      status: data?['status'] as String? ?? 'active',
    );
  }
}
