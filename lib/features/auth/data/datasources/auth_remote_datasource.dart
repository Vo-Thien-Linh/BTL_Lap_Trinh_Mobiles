import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../data/models/patient_model.dart';
import '../../../../data/models/user_model.dart';
import '../../domain/entities/register_request_entity.dart';
import '../../../../core/enums/app_role.dart';
import '../../../../core/enums/user_status.dart';
import '../../../../shared/utils/id_formatter.dart';

abstract class AuthRemoteDatasource {
  Future<UserModel> register(RegisterRequestEntity request);

  Future<UserModel> login({required String email, required String password});

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
    final userCode = IdFormatter.format(prefix: 'USR', rawId: user.uid);
    final patientCode = IdFormatter.format(prefix: 'PT', rawId: user.uid);

    final batch = firestore.batch();

    batch.set(firestore.collection('users').doc(user.uid), {
      ...userModel.toMap(),
      'userCode': userCode,
    });

    batch.set(firestore.collection('patients').doc(user.uid), {
      ...patientModel.toMap(),
      'patientCode': patientCode,
    });

    await batch.commit();

    return userModel;
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final stopwatch = Stopwatch()..start();
    print('--- [PERF] 1. Bat dau dang nhap Firebase...');

    try {
      // Thêm timeout 15 giây để tránh bị treo vô hạn do App Check/Emulator lag
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        print('--- [PERF] ERROR: Firebase Auth bi timeout sau 15s!');
        throw Exception('Kết nối tới Firebase quá chậm. Vui lòng kiểm tra mạng hoặc khởi động lại máy ảo.');
      });
      print('--- [PERF] 2. Firebase Auth xong trong: ${stopwatch.elapsedMilliseconds}ms');

      final user = credential.user;
      if (user == null) throw Exception('Không tìm thấy người dùng.');

      final currentUser = firebaseAuth.currentUser;
      if (currentUser == null) throw Exception('Không thể tải thông tin người dùng.');

      final userRef = firestore.collection('users').doc(currentUser.uid);
      
      print('--- [PERF] 3. Bat dau lay Firestore...');
      final startTimeFirestore = stopwatch.elapsedMilliseconds;
      final doc = await userRef.get();
      print('--- [PERF] 4. Lay Firestore xong trong: ${stopwatch.elapsedMilliseconds - startTimeFirestore}ms');

      if (!doc.exists) {
        throw Exception('Không tìm thấy hồ sơ người dùng.');
      }

      final userData = doc.data() ?? <String, dynamic>{};
      
      // Chạy các cập nhật ngầm, không dùng await để không làm chậm login
      _runBackgroundUpdates(userRef, currentUser, userData);

      print('--- [PERF] TOTAL LOGIN TIME: ${stopwatch.elapsedMilliseconds}ms');
      return UserModel.fromDocument(doc);
    } finally {
      stopwatch.stop();
    }
  }

  void _runBackgroundUpdates(DocumentReference userRef, User currentUser, Map<String, dynamic> userData) {
    try {
      final Map<String, dynamic> updates = {};
      if (userData['emailVerified'] != true) updates['emailVerified'] = true;
      if ((userData['userCode'] ?? '').toString().trim().isEmpty) {
        updates['userCode'] = IdFormatter.format(prefix: 'USR', rawId: currentUser.uid);
      }
      
      if (updates.isNotEmpty) {
        updates['updatedAt'] = FieldValue.serverTimestamp();
        userRef.update(updates).catchError((e) => print('--- [BG] User update fail: $e'));
      }

      // Sync patient code if exists
      firestore.collection('patients').doc(currentUser.uid).get().then((pDoc) {
        if (pDoc.exists) {
          final pData = pDoc.data() ?? {};
          if ((pData['patientCode'] ?? '').toString().trim().isEmpty) {
            pDoc.reference.update({
              'patientCode': IdFormatter.format(prefix: 'PT', rawId: currentUser.uid),
              'updatedAt': FieldValue.serverTimestamp(),
            }).catchError((e) => print('--- [BG] Patient update fail: $e'));
          }
        }
      });
    } catch (e) {
      print('--- [BG] Error: $e');
    }
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
