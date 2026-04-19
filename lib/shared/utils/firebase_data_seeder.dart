import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseDataSeeder {
  static Future<void> seedAll(String uid) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    // 1. Seed Departments
    final departments = [
      {'id': 'dept_cardio', 'name': 'Tim mạch', 'loc': 'Tầng 3, Khu B', 'phone': '028-1234-568', 'docs': 14, 'active': true},
      {'id': 'dept_internal', 'name': 'Nội tổng quát', 'loc': 'Tầng 2, Khu A', 'phone': '028-1234-567', 'docs': 22, 'active': true},
      {'id': 'dept_pedia', 'name': 'Nhi khoa', 'loc': 'Tầng 1, Khu C', 'phone': '028-1234-569', 'docs': 18, 'active': true},
      {'id': 'dept_obgyn', 'name': 'Phụ sản', 'loc': 'Tầng 4, Khu A', 'phone': '028-1234-570', 'docs': 12, 'active': true},
      {'id': 'dept_dermatology', 'name': 'Da liễu', 'loc': 'Tầng 4, Khu B', 'phone': '028-1234-571', 'docs': 9, 'active': true},
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

    // 2. Comprehensive Doctor Seeding (14 just for Cardio!)
    final doctors = [
      // Tim mạch (Cardiology) - 14 Doctors as promised
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

      // Nhi khoa (Pediatrics)
      {'id': 'dr_pedia_1', 'name': 'BS. Đặng Lê Nguyên Vũ', 'dept': 'dept_pedia', 'spec': 'Nhi sơ sinh', 'fee': 350000.0, 'exp': 25, 'img': 'https://images.unsplash.com/photo-1612349317150-e413f6a5b1a8?q=80&w=256&h=256&auto=format&fit=crop'},
      {'id': 'dr_pedia_2', 'name': 'BS. Mai Kiều Liên', 'dept': 'dept_pedia', 'spec': 'Dinh dưỡng nhi', 'fee': 300000.0, 'exp': 30, 'img': 'https://images.unsplash.com/photo-1594824476967-48c8b964273f?q=80&w=256&h=256&auto=format&fit=crop'},
    ];

    for (var dr in doctors) {
      batch.set(firestore.collection('Doctors').doc(dr['id'] as String), {
        'userId': 'user_${dr['id'] as String}',
        'specialization': dr['spec'] as String,
        'departmentId': dr['dept'] as String,
        'licenseNumber': 'LIC-${(dr['id'] as String).toUpperCase()}',
        'yearsOfExperience': dr['exp'] as int,
        'consultationFee': dr['fee'] as double,
        'imageUrl': dr['img'] as String,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Mock User for Doctor
      batch.set(firestore.collection('Users').doc('user_${dr['id']}'), {
        'fullName': dr['name'],
        'role': 'doctor',
        'email': '${dr['id']}@bright.gov.vn',
        'avatarUrl': dr['img'],
      });
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
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }
}
