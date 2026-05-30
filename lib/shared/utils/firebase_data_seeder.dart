import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseDataSeeder {
  static Future<void> seedAll(String uid) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    // 1. Seed Departments
    final departments = [
      {'id': 'dept_cardio', 'name': 'Tim mạch', 'loc': 'Tầng 3, Khu B', 'phone': '028-1234-568', 'docs': 14, 'active': true},
      {'id': 'dept_internal', 'name': 'Nội tổng quát', 'loc': 'Tầng 2, Khu A', 'phone': '028-1234-567', 'docs': 5, 'active': true},
      {'id': 'dept_pedia', 'name': 'Nhi khoa', 'loc': 'Tầng 1, Khu C', 'phone': '028-1234-569', 'docs': 5, 'active': true},
      {'id': 'dept_obgyn', 'name': 'Phụ sản', 'loc': 'Tầng 4, Khu A', 'phone': '028-1234-570', 'docs': 4, 'active': true},
      {'id': 'dept_dermatology', 'name': 'Da liễu', 'loc': 'Tầng 4, Khu B', 'phone': '028-1234-571', 'docs': 5, 'active': true},
      {'id': 'dept_ent', 'name': 'Tai Mũi Họng', 'loc': 'Tầng 2, Khu B', 'phone': '028-1234-572', 'docs': 11, 'active': true},
    ];

    for (var d in departments) {
      batch.set(firestore.collection('Departments').doc(d['id'] as String), {
        'departmentName': d['name'] as String,
        'description': 'Đội ngũ chuyên gia hàng đầu trong lĩnh vực ${d['name'] as String} với hệ thống trang thiết bị hiện đại bậc nhất.',
        'location': d['loc'] as String,
        'phone': d['phone'] as String,
        'doctorCount': d['docs'] as int,
        'isActive': d['active'] as bool,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // 2. Comprehensive Doctor Seeding (14 for Cardio, 5 for Internal, 5 for Pedia, 4 for OBGYN, 5 for Derma)
    final doctors = [
      // Tim mạch (Cardiology) - 14 Doctors
      {'id': 'dr_cardio_1', 'name': 'GS.TS. Nguyễn Mạnh Phan', 'dept': 'dept_cardio', 'spec': 'Tim mạch can thiệp', 'fee': 800000.0, 'exp': 35, 'img': 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_cardio_2', 'name': 'TS.BS. Lê Thị Kim Anh', 'dept': 'dept_cardio', 'spec': 'Tim mạch nhi', 'fee': 600000.0, 'exp': 22, 'img': 'https://images.unsplash.com/photo-1594824476967-48c8b964273f?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_cardio_3', 'name': 'ThS.BS. Trần Quốc Bảo', 'dept': 'dept_cardio', 'spec': 'Loạn nhịp tim', 'fee': 500000.0, 'exp': 15, 'img': 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_cardio_4', 'name': 'BS.CKII. Phạm Hoàng Minh', 'dept': 'dept_cardio', 'spec': 'Phẫu thuật tim mạch', 'fee': 700000.0, 'exp': 18, 'img': 'https://images.unsplash.com/photo-1612349317150-e413f6a5b1a8?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_cardio_5', 'name': 'BS.CKI. Võ Minh Thuận', 'dept': 'dept_cardio', 'spec': 'Tim mạch can thiệp', 'fee': 400000.0, 'exp': 12, 'img': 'https://images.unsplash.com/photo-1622902046580-2b47f47f0871?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_cardio_6', 'name': 'BS. Nguyễn Thị Ngọc', 'dept': 'dept_cardio', 'spec': 'Siêu âm tim', 'fee': 300000.0, 'exp': 8, 'img': 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_cardio_7', 'name': 'BS. Đỗ Hoàng Long', 'dept': 'dept_cardio', 'spec': 'Tim mạch can thiệp', 'fee': 450000.0, 'exp': 10, 'img': 'https://images.unsplash.com/photo-1625492930267-31779628bb14?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_cardio_8', 'name': 'BS. Trương Gia Bình', 'dept': 'dept_cardio', 'spec': 'Tim mạch lão khoa', 'fee': 550000.0, 'exp': 20, 'img': 'https://images.unsplash.com/photo-1527613426441-4316671f66ef?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_cardio_9', 'name': 'BS. Lưu Trọng Ninh', 'dept': 'dept_cardio', 'spec': 'Chẩn đoán hình ảnh', 'fee': 400000.0, 'exp': 11, 'img': 'https://images.unsplash.com/photo-1582750433449-648ed127bb54?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_cardio_10', 'name': 'BS. Nguyễn Kim Ngân', 'dept': 'dept_cardio', 'spec': 'Phục hồi chức năng', 'fee': 350000.0, 'exp': 7, 'img': 'https://images.unsplash.com/photo-1643297654416-05795d62e39c?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_cardio_11', 'name': 'BS. Hà Văn Thắm', 'dept': 'dept_cardio', 'spec': 'Tim mạch can thiệp', 'fee': 500000.0, 'exp': 14, 'img': 'https://images.unsplash.com/photo-1614608682850-e0d6ed316d47?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_cardio_12', 'name': 'BS. Phạm Nhật Vượng', 'dept': 'dept_cardio', 'spec': 'Phẫu thuật lồng ngực', 'fee': 900000.0, 'exp': 28, 'img': 'https://images.unsplash.com/photo-1605684954278-9f015ab553c6?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_cardio_13', 'name': 'BS. Nguyễn Thị Tâm', 'dept': 'dept_cardio', 'spec': 'Nội tim mạch', 'fee': 300000.0, 'exp': 9, 'img': 'https://images.unsplash.com/photo-1594824476967-48c8b964273f?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_cardio_14', 'name': 'BS. Trần Văn Khang', 'dept': 'dept_cardio', 'spec': 'Gây mê hồi sức', 'fee': 400000.0, 'exp': 13, 'img': 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?q=80&w=256&h=256&auto=format&fit=crop'},

      // Da liễu (Dermatology)
      {'id': 'dr_derma_1', 'name': 'BS. Trương Mỹ Lan', 'dept': 'dept_dermatology', 'spec': 'Da liễu thẩm mỹ', 'fee': 400000.0, 'exp': 12, 'img': 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_derma_2', 'name': 'BS. Quách Thành Danh', 'dept': 'dept_dermatology', 'spec': 'Laser thẩm mỹ', 'fee': 600000.0, 'exp': 18, 'img': 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_derma_3', 'name': 'TS.BS. Trần Ngọc Ánh', 'dept': 'dept_dermatology', 'spec': 'Da liễu tổng quát', 'fee': 500000.0, 'exp': 24, 'img': 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_derma_4', 'name': 'BS.CKII. Nguyễn Thị Phan Nam', 'dept': 'dept_dermatology', 'spec': 'Trị liệu da', 'fee': 450000.0, 'exp': 17, 'img': 'https://images.unsplash.com/photo-1594824476967-48c8b964273f?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_derma_5', 'name': 'ThS.BS. Hoàng Văn Minh', 'dept': 'dept_dermatology', 'spec': 'Bệnh lý da liễu', 'fee': 600000.0, 'exp': 29, 'img': 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?q=80&w=256&h=256&auto=format&fit=crop'},

      // Nhi khoa (Pediatrics)
      {'id': 'dr_pedia_1', 'name': 'BS. Đặng Lê Nguyên Vũ', 'dept': 'dept_pedia', 'spec': 'Nhi sơ sinh', 'fee': 350000.0, 'exp': 25, 'img': 'https://images.unsplash.com/photo-1612349317150-e413f6a5b1a8?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_pedia_2', 'name': 'BS. Mai Kiều Liên', 'dept': 'dept_pedia', 'spec': 'Dinh dưỡng nhi', 'fee': 300000.0, 'exp': 30, 'img': 'https://images.unsplash.com/photo-1594824476967-48c8b964273f?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_pedia_3', 'name': 'PGS.TS. Nguyễn Thanh Liêm', 'dept': 'dept_pedia', 'spec': 'Ngoại nhi', 'fee': 800000.0, 'exp': 38, 'img': 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_pedia_4', 'name': 'BS.CKII. Phạm Mai Đằng', 'dept': 'dept_pedia', 'spec': 'Nhi hô hấp', 'fee': 450000.0, 'exp': 22, 'img': 'https://images.unsplash.com/photo-1612349317150-e413f6a5b1a8?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_pedia_5', 'name': 'BS. Trần Thu Hà', 'dept': 'dept_pedia', 'spec': 'Nhi tổng quát', 'fee': 300000.0, 'exp': 8, 'img': 'https://images.unsplash.com/photo-1594824476967-48c8b964273f?q=80&w=256&h=256&auto=format&fit=crop'},

      // Nội tổng quát (Internal Medicine)
      {'id': 'dr_internal_1', 'name': 'PGS.TS.BS. Nguyễn Văn Kính', 'dept': 'dept_internal', 'spec': 'Nội tiêu hóa', 'fee': 600000.0, 'exp': 30, 'img': 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_internal_2', 'name': 'TS.BS. Phạm Hồng Hải', 'dept': 'dept_internal', 'spec': 'Nội hô hấp', 'fee': 500000.0, 'exp': 25, 'img': 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_internal_3', 'name': 'BS.CKII. Lê Hoàng Nam', 'dept': 'dept_internal', 'spec': 'Nội nội tiết', 'fee': 450000.0, 'exp': 20, 'img': 'https://images.unsplash.com/photo-1612349317150-e413f6a5b1a8?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_internal_4', 'name': 'ThS.BS. Nguyễn Thu Thủy', 'dept': 'dept_internal', 'spec': 'Nội cơ xương khớp', 'fee': 400000.0, 'exp': 12, 'img': 'https://images.unsplash.com/photo-1594824476967-48c8b964273f?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_internal_5', 'name': 'BS.CKI. Vũ Trường Phi', 'dept': 'dept_internal', 'spec': 'Nội tổng quát', 'fee': 350000.0, 'exp': 10, 'img': 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?q=80&w=256&h=256&auto=format&fit=crop'},

      // Phụ sản (Obstetrics and Gynecology)
      {'id': 'dr_obgyn_1', 'name': 'GS.TS.BS. Nguyễn Thị Ngọc Phượng', 'dept': 'dept_obgyn', 'spec': 'Sản khoa', 'fee': 700000.0, 'exp': 32, 'img': 'https://images.unsplash.com/photo-1594824476967-48c8b964273f?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_obgyn_2', 'name': 'BS.CKII. Huỳnh Thị Thu Thủy', 'dept': 'dept_obgyn', 'spec': 'Phụ khoa', 'fee': 550000.0, 'exp': 26, 'img': 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_obgyn_3', 'name': 'ThS.BS. Lê Văn Hiền', 'dept': 'dept_obgyn', 'spec': 'Nội soi phụ khoa', 'fee': 500000.0, 'exp': 18, 'img': 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_obgyn_4', 'name': 'BS.CKI. Nguyễn Thu Hằng', 'dept': 'dept_obgyn', 'spec': 'Chăm sóc thai sản', 'fee': 400000.0, 'exp': 11, 'img': 'https://images.unsplash.com/photo-1643297654416-05795d62e39c?q=80&w=256&h=256&auto=format&fit=crop'},
      // Tai Mũi Họng (ENT)
      {'id': 'dr_ent_1', 'name': 'PGS.TS.BS. Nhan Trừng Sơn', 'dept': 'dept_ent', 'spec': 'Tai Mũi Họng Nhi', 'fee': 600000.0, 'exp': 35, 'img': 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_ent_2', 'name': 'BS.CKII. Nguyễn Thanh Tuấn', 'dept': 'dept_ent', 'spec': 'Phẫu thuật Tai Mũi Họng', 'fee': 500000.0, 'exp': 20, 'img': 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_ent_3', 'name': 'ThS.BS. Đinh Văn Sang', 'dept': 'dept_ent', 'spec': 'Khám Tai Mũi Họng', 'fee': 400000.0, 'exp': 15, 'img': 'https://images.unsplash.com/photo-1612349317150-e413f6a5b1a8?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_ent_4', 'name': 'BS.CKI. Lê Văn Dũng', 'dept': 'dept_ent', 'spec': 'Tai Mũi Họng', 'fee': 350000.0, 'exp': 12, 'img': 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_ent_5', 'name': 'BS. Trần Hữu Phúc', 'dept': 'dept_ent', 'spec': 'Tai Mũi Họng', 'fee': 300000.0, 'exp': 10, 'img': 'https://images.unsplash.com/photo-1594824476967-48c8b964273f?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_ent_6', 'name': 'ThS.BS. Phạm Hữu Tài', 'dept': 'dept_ent', 'spec': 'Thính học', 'fee': 450000.0, 'exp': 14, 'img': 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_ent_7', 'name': 'BS.CKII. Hoàng Tuấn', 'dept': 'dept_ent', 'spec': 'Phẫu thuật đầu cổ', 'fee': 550000.0, 'exp': 25, 'img': 'https://images.unsplash.com/photo-1612349317150-e413f6a5b1a8?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_ent_8', 'name': 'BS. Vũ Đức Hải', 'dept': 'dept_ent', 'spec': 'Tai Mũi Họng', 'fee': 300000.0, 'exp': 8, 'img': 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_ent_9', 'name': 'BS. Lê Minh Tiến', 'dept': 'dept_ent', 'spec': 'Nội soi tai mũi họng', 'fee': 400000.0, 'exp': 11, 'img': 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_tmh_1', 'name': 'BS. Ngô Bảo K', 'dept': 'dept_ent', 'spec': 'Tai Mũi Họng', 'fee': 380000.0, 'exp': 15, 'img': 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_tmh_2', 'name': 'TS.BS. Nguyễn Thị Mai', 'dept': 'dept_ent', 'spec': 'Nội soi tai mũi họng', 'fee': 450000.0, 'exp': 18, 'img': 'https://images.unsplash.com/photo-1594824476967-48c8b964273f?q=80&w=256&h=256&auto=format&fit=crop'},
    ];

    // Build department name map for quick lookup
    final departmentNameMap = <String, String>{};
    for (var d in departments) {
      departmentNameMap[d['id'] as String] = d['name'] as String;
    }

    for (var dr in doctors) {
      final deptId = dr['dept'] as String;
      final doctorId = dr['id'] as String;
      
      batch.set(firestore.collection('Doctors').doc(doctorId), {
        'userId': 'user_$doctorId',
        'name': dr['name'] as String,
        'specialization': dr['spec'] as String,
        'departmentId': deptId,
        'departmentName': departmentNameMap[deptId] ?? '',
        'licenseNumber': 'LIC-${doctorId.toUpperCase()}',
        'yearsOfExperience': dr['exp'] as int,
        'consultationFee': dr['fee'] as double,
        'imageUrl': dr['img'] as String,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        // Also add doctorCode required by BookingBloc
        'doctorCode': 'DOC-${doctorId.toUpperCase()}',
      });
      // Mock User for Doctor
      batch.set(firestore.collection('Users').doc('user_$doctorId'), {
        'fullName': dr['name'],
        'role': 'doctor',
        'email': '$doctorId@bright.gov.vn',
        'avatarUrl': dr['img'],
      });
      
      // Seed Schedules for the next 7 days for this doctor
      for (int i = 0; i < 7; i++) {
        final date = DateTime.now().add(Duration(days: i));
        final dateStr = '${date.year}-${date.month}-${date.day}';

        // Morning shift
        batch.set(
          firestore.collection('DoctorSchedules').doc('${doctorId}_${dateStr}_morning'),
          {
            'doctorId': doctorId,
            'scheduleDate': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
            'shiftId': 'morning',
            'isAvailable': true,
            'maxSlots': 20,
            'availableSlots': 20,
          },
          SetOptions(merge: true),
        );

        // Afternoon shift
        batch.set(
          firestore.collection('DoctorSchedules').doc('${doctorId}_${dateStr}_afternoon'),
          {
            'doctorId': doctorId,
            'scheduleDate': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
            'shiftId': 'afternoon',
            'isAvailable': true,
            'maxSlots': 20,
            'availableSlots': 20,
          },
          SetOptions(merge: true),
        );
      }
    }
    
    // Seed Shifts
    final shiftList = [
      {'id': 'morning', 'name': 'Sáng', 'start': '07:30', 'end': '11:30', 'max': 20},
      {'id': 'afternoon', 'name': 'Chiều', 'start': '13:30', 'end': '17:00', 'max': 20},
    ];
    for (var shift in shiftList) {
      batch.set(
        firestore.collection('Shifts').doc(shift['id'] as String),
        {
          'shiftName': shift['name'],
          'startTime': shift['start'],
          'endTime': shift['end'],
          'maxSlots': shift['max'],
        },
        SetOptions(merge: true),
      );
    }

    // 3. Update Patient Profile (Ensure unique data for the logged-in user)
    batch.set(firestore.collection('Users').doc(uid), {
      'fullName': 'Nguyễn Hoàng Nam',
      'email': 'nam.hoang@bright.gov.vn',
      'role': 'patient',
      'bloodType': 'O+',
      'height': 178,
      'weight': 74.5,
      'gender': 'Nam',
      'dateOfBirth': '15/05/1995',
      'phoneNumber': '0901 234 567',
      'healthInsuranceNumber': 'GD4791234567890',
      'address': 'Quận 1, TP. Hồ Chí Minh',
      'avatarUrl': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=256&h=256&auto=format&fit=crop',
      'membership': 'PREMIUM',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    try {
      await batch.commit();
      print('✅ [FirebaseDataSeeder] Seeded mock data successfully');
    } catch (e) {
      print('⚠️ [FirebaseDataSeeder] Failed to seed mock data: $e');
      print('This might be due to Firestore security rules blocking write operations for this user.');
    }
  }
}
