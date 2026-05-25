import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';

class HealthInsuranceReminder {
  HealthInsuranceReminder._();

  static bool _shownThisSession = false;

  static Future<void> showIfNeeded(BuildContext context) async {
    if (_shownThisSession) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final firestore = FirebaseFirestore.instance;
    final data = await _getUserData(firestore, user.uid);
    if (data == null) return;

    final role = data['role']?.toString().toLowerCase().trim();
    final healthInsuranceNumber =
    (data['healthInsuranceNumber'] ?? data['insuranceNumber'])
        ?.toString()
        .trim();

    if (role != 'patient') return;
    if (healthInsuranceNumber != null && healthInsuranceNumber.isNotEmpty) return;

    _shownThisSession = true;

    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Bạn chưa thêm BHYT'),
          content: const Text(
            'Hãy thêm mã số thẻ Bảo hiểm y tế để thuận tiện khi đặt lịch, thanh toán và đối chiếu thông tin khám chữa bệnh.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Để sau'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pushNamed(context, AppRoutes.healthInsurance);
              },
              child: const Text('Thêm ngay'),
            ),
          ],
        );
      },
    );
  }

  static Future<Map<String, dynamic>?> _getUserData(
      FirebaseFirestore firestore,
      String uid,
      ) async {
    final lower = await firestore.collection('users').doc(uid).get();
    if (lower.exists) return lower.data();

    final upper = await firestore.collection('Users').doc(uid).get();
    if (upper.exists) return upper.data();

    return null;
  }
}
