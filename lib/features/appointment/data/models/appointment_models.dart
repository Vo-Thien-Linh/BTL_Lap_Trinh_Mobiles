import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/appointment_entities.dart';

class DepartmentModel extends DepartmentEntity {
  const DepartmentModel({
    required super.id,
    required super.name,
    required super.description,
    required super.location,
    required super.phone,
    super.doctorCount = 0,
    super.isActive = true,
  });

  factory DepartmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DepartmentModel(
      id: doc.id,
      name: data['departmentName']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      location: data['location']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      doctorCount: int.tryParse(data['doctorCount']?.toString() ?? '0') ?? 0,
      isActive: (data['isActive'] ?? true) as bool,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'departmentName': name,
      'description': description,
      'location': location,
      'phone': phone,
      'doctorCount': doctorCount,
      'isActive': isActive,
    };
  }
}

class DoctorModel extends DoctorEntity {
  const DoctorModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.specialization,
    required super.departmentId,
    required super.departmentName,
    required super.yearsOfExperience,
    required super.consultationFee,
    required super.isActive,
    required super.licenseNumber,
    super.imageUrl,
  });

  factory DoctorModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final id = doc.id;
    
    // Fallback name map
    final fallbackNames = {
      // Cardio
      'dr_cardio_1': 'GS.TS. Nguyễn Mạnh Phan',
      'dr_cardio_2': 'TS.BS. Lê Thị Kim Anh',
      'dr_cardio_3': 'ThS.BS. Trần Quốc Bảo',
      'dr_cardio_4': 'BS.CKII. Phạm Hoàng Minh',
      'dr_cardio_5': 'BS.CKI. Võ Minh Thuận',
      'dr_cardio_6': 'BS. Nguyễn Thị Ngọc',
      'dr_cardio_7': 'BS. Đỗ Hoàng Long',
      'dr_cardio_8': 'BS. Trương Gia Bình',
      'dr_cardio_9': 'BS. Lưu Trọng Ninh',
      'dr_cardio_10': 'BS. Nguyễn Kim Ngân',
      'dr_cardio_11': 'BS. Hà Văn Thắm',
      'dr_cardio_12': 'BS. Phạm Nhật Vượng',
      'dr_cardio_13': 'BS. Nguyễn Thị Tâm',
      'dr_cardio_14': 'BS. Trần Văn Khang',
      // Derma
      'dr_derma_1': 'BS. Trương Mỹ Lan',
      'dr_derma_2': 'BS. Quách Thành Danh',
      'dr_derma_3': 'TS.BS. Trần Ngọc Ánh',
      'dr_derma_4': 'BS.CKII. Nguyễn Thị Phan Nam',
      'dr_derma_5': 'ThS.BS. Hoàng Văn Minh',
      // Pedia
      'dr_pedia_1': 'BS. Đặng Lê Nguyên Vũ',
      'dr_pedia_2': 'BS. Mai Kiều Liên',
      'dr_pedia_3': 'PGS.TS. Nguyễn Thanh Liêm',
      'dr_pedia_4': 'BS.CKII. Phạm Mai Đằng',
      'dr_pedia_5': 'BS. Trần Thu Hà',
      // Internal
      'dr_internal_1': 'PGS.TS.BS. Nguyễn Văn Kính',
      'dr_internal_2': 'TS.BS. Phạm Hồng Hải',
      'dr_internal_3': 'BS.CKII. Lê Hoàng Nam',
      'dr_internal_4': 'ThS.BS. Nguyễn Thu Thủy',
      'dr_internal_5': 'BS.CKI. Vũ Trường Phi',
      // OBGYN
      'dr_obgyn_1': 'GS.TS.BS. Nguyễn Thị Ngọc Phượng',
      'dr_obgyn_2': 'BS.CKII. Huỳnh Thị Thu Thủy',
      'dr_obgyn_3': 'ThS.BS. Lê Văn Hiền',
      'dr_obgyn_4': 'BS.CKI. Nguyễn Thu Hằng',
      // BookingBloc seed fallbacks
      'dr_tim_1': 'BS Nguyễn Văn A',
      'dr_tim_2': 'BS Phạm Minh B',
      'dr_nhi_1': 'BS Trần Thị C',
      'dr_nhi_2': 'BS Lê Hoàng D',
      'dr_da_1': 'BS Hoàng Gia E',
      'dr_da_2': 'BS Vũ Đức F',
      'dr_mat_1': 'BS Đặng Minh G',
      'dr_rhm_1': 'BS Phan Thanh H',
      'dr_tmh_1': 'BS Ngô Bảo K',
      'dr_nt_1': 'BS Lý Tiểu L',
    };

    String rawName = data['name']?.toString() ?? '';
    if (rawName.isEmpty) {
      rawName = fallbackNames[id] ?? '';
    }

    String rawDeptId = data['departmentId']?.toString() ?? '';
    // Map internal specs to the visual category/ID if needed
    if (rawDeptId.isEmpty) {
      final spec = data['specialization']?.toString() ?? '';
      if (spec == 'tim_mach' || id.contains('cardio') || id.contains('tim')) {
        rawDeptId = 'dept_cardio';
      } else if (spec == 'da_lieu' || id.contains('derma') || id.contains('da')) {
        rawDeptId = 'dept_dermatology';
      } else if (spec == 'nhi_khoa' || id.contains('pedia') || id.contains('nhi')) {
        rawDeptId = 'dept_pedia';
      } else if (spec == 'obgyn' || id.contains('obgyn')) {
        rawDeptId = 'dept_obgyn';
      } else if (id.contains('internal')) {
        rawDeptId = 'dept_internal';
      }
    }

    // Fallback department name map
    final fallbackDeptNames = {
      'dept_cardio': 'Tim mạch',
      'dept_internal': 'Nội tổng quát',
      'dept_pedia': 'Nhi khoa',
      'dept_obgyn': 'Phụ sản',
      'dept_dermatology': 'Da liễu',
      'tim_mach': 'Tim mạch',
      'nhi_khoa': 'Nhi khoa',
      'noi_tiet': 'Nội tiết',
      'da_lieu': 'Da liễu',
      'rang_ham_mat': 'Răng Hàm Mặt',
      'tai_mui_hong': 'Tai Mũi Họng',
      'mat': 'Mắt',
    };

    String rawDeptName = data['departmentName']?.toString() ?? '';
    if (rawDeptName.isEmpty) {
      rawDeptName = fallbackDeptNames[rawDeptId] ?? '';
    }

    final fallbackImages = {
      'dr_cardio_1': 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?q=80&w=256&h=256&auto=format&fit=crop',
      'dr_cardio_2': 'https://images.unsplash.com/photo-1594824476967-48c8b964273f?q=80&w=256&h=256&auto=format&fit=crop',
      'dr_cardio_3': 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?q=80&w=256&h=256&auto=format&fit=crop',
      'dr_cardio_4': 'https://images.unsplash.com/photo-1612349317150-e413f6a5b1a8?q=80&w=256&h=256&auto=format&fit=crop',
      'dr_cardio_5': 'https://images.unsplash.com/photo-1622902046580-2b47f47f0871?q=80&w=256&h=256&auto=format&fit=crop',
      'dr_cardio_6': 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?q=80&w=256&h=256&auto=format&fit=crop',
      'dr_cardio_7': 'https://images.unsplash.com/photo-1625492930267-31779628bb14?q=80&w=256&h=256&auto=format&fit=crop',
      'dr_cardio_8': 'https://images.unsplash.com/photo-1527613426441-4316671f66ef?q=80&w=256&h=256&auto=format&fit=crop',
      'dr_cardio_9': 'https://images.unsplash.com/photo-1582750433449-648ed127bb54?q=80&w=256&h=256&auto=format&fit=crop',
      'dr_cardio_10': 'https://images.unsplash.com/photo-1643297654416-05795d62e39c?q=80&w=256&h=256&auto=format&fit=crop',
      'dr_cardio_11': 'https://images.unsplash.com/photo-1614608682850-e0d6ed316d47?q=80&w=256&h=256&auto=format&fit=crop',
      'dr_cardio_12': 'https://images.unsplash.com/photo-1605684954278-9f015ab553c6?q=80&w=256&h=256&auto=format&fit=crop',
      'dr_cardio_13': 'https://images.unsplash.com/photo-1594824476967-48c8b964273f?q=80&w=256&h=256&auto=format&fit=crop',
      'dr_cardio_14': 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?q=80&w=256&h=256&auto=format&fit=crop',
      'dr_derma_1': 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?q=80&w=256&h=256&auto=format&fit=crop',
      'dr_derma_2': 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?q=80&w=256&h=256&auto=format&fit=crop',
      'dr_derma_3': 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?q=80&w=256&h=256&auto=format&fit=crop',
      'dr_derma_4': 'https://images.unsplash.com/photo-1594824476967-48c8b964273f?q=80&w=256&h=256&auto=format&fit=crop',
      'dr_derma_5': 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?q=80&w=256&h=256&auto=format&fit=crop',
      'dr_pedia_1': 'https://images.unsplash.com/photo-1612349317150-e413f6a5b1a8?q=80&w=256&h=256&auto=format&fit=crop',
      'dr_pedia_2': 'https://images.unsplash.com/photo-1594824476967-48c8b964273f?q=80&w=256&h=256&auto=format&fit=crop',
      'dr_pedia_3': 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?q=80&w=256&h=256&auto=format&fit=crop',
      'dr_pedia_4': 'https://images.unsplash.com/photo-1612349317150-e413f6a5b1a8?q=80&w=256&h=256&auto=format&fit=crop',
      'dr_pedia_5': 'https://images.unsplash.com/photo-1594824476967-48c8b964273f?q=80&w=256&h=256&auto=format&fit=crop',
      'dr_internal_1': 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?q=80&w=256&h=256&auto=format&fit=crop',
      'dr_internal_2': 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?q=80&w=256&h=256&auto=format&fit=crop',
      'dr_internal_3': 'https://images.unsplash.com/photo-1612349317150-e413f6a5b1a8?q=80&w=256&h=256&auto=format&fit=crop',
      'dr_internal_4': 'https://images.unsplash.com/photo-1594824476967-48c8b964273f?q=80&w=256&h=256&auto=format&fit=crop',
      'dr_internal_5': 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?q=80&w=256&h=256&auto=format&fit=crop',
      'dr_obgyn_1': 'https://images.unsplash.com/photo-1594824476967-48c8b964273f?q=80&w=256&h=256&auto=format&fit=crop',
      'dr_obgyn_2': 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?q=80&w=256&h=256&auto=format&fit=crop',
      'dr_obgyn_3': 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?q=80&w=256&h=256&auto=format&fit=crop',
      'dr_obgyn_4': 'https://images.unsplash.com/photo-1643297654416-05795d62e39c?q=80&w=256&h=256&auto=format&fit=crop',
    };

    String? imageUrl = data['imageUrl']?.toString();
    if (imageUrl == null || imageUrl.isEmpty) {
      imageUrl = fallbackImages[id];
    }

    return DoctorModel(
      id: id,
      userId: data['userId']?.toString() ?? '',
      name: rawName,
      specialization: data['specialization']?.toString() ?? '',
      departmentId: rawDeptId,
      departmentName: rawDeptName,
      yearsOfExperience: int.tryParse(data['yearsOfExperience']?.toString() ?? '0') ?? 0,
      consultationFee: double.tryParse(data['consultationFee']?.toString() ?? '0') ?? 0.0,
      isActive: (data['isActive'] ?? true) as bool,
      licenseNumber: data['licenseNumber']?.toString() ?? '',
      imageUrl: imageUrl,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'specialization': specialization,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'yearsOfExperience': yearsOfExperience,
      'consultationFee': consultationFee,
      'isActive': isActive,
      'licenseNumber': licenseNumber,
      'imageUrl': imageUrl,
    };
  }
}

class ShiftModel extends ShiftEntity {
  const ShiftModel({
    required super.id,
    required super.name,
    required super.startTime,
    required super.endTime,
    required super.maxSlots,
  });

  factory ShiftModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShiftModel(
      id: doc.id,
      name: data['name'] ?? '',
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      maxSlots: int.tryParse(data['maxSlots']?.toString() ?? '10') ?? 10,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'startTime': startTime,
      'endTime': endTime,
      'maxSlots': maxSlots,
    };
  }
}

class ScheduleModel extends ScheduleEntity {
  const ScheduleModel({
    required super.id,
    required super.doctorId,
    required super.departmentId,
    required super.shiftId,
    required super.date,
    required super.availableSlots,
    required super.isActive,
  });

  factory ScheduleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScheduleModel(
      id: doc.id,
      doctorId: data['doctorId'] ?? '',
      departmentId: data['departmentId'] ?? '',
      shiftId: data['shiftId'] ?? '',
      date: (data['scheduleDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      availableSlots: int.tryParse(data['availableSlots']?.toString() ?? '0') ?? 0,
      isActive: (data['isActive'] ?? true) as bool,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'doctorId': doctorId,
      'departmentId': departmentId,
      'shiftId': shiftId,
      'scheduleDate': Timestamp.fromDate(date),
      'availableSlots': availableSlots,
      'isActive': isActive,
    };
  }
}

class HospitalAppointmentModel extends HospitalAppointment {
  const HospitalAppointmentModel({
    required super.id,
    required super.patientId,
    super.patientDOB,
    super.patientGender,
    required super.patientName,
    required super.doctorId,
    required super.doctorName,
    required super.departmentId,
    required super.departmentName,
    required super.appointmentDate,
    required super.shiftId,
    required super.timeSlot,
    required super.queueNumber,
    required super.roomNumber,
    required super.consultationFee,
    super.insuranceNumber,
    required super.symptoms,
    super.diagnosis,
    super.physicalExam,
    super.treatment,
    super.notes,
    super.prescription,
    super.labResults,
    super.vitals,
    required super.status,
    required super.paymentMethod,
    required super.createdAt,
  });

  factory HospitalAppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HospitalAppointmentModel(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      patientDOB: data['patientDOB'] as String?,
      patientGender: data['patientGender'] as String?,
      patientName: data['patientName'] ?? '',
      doctorId: data['doctorId'] ?? '',
      doctorName: data['doctorName'] ?? '',
      departmentId: data['departmentId'] ?? '',
      departmentName: data['departmentName'] ?? '',
      appointmentDate:
          (data['appointmentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      shiftId: data['shiftId'] ?? '',
      timeSlot: data['timeSlot'] ?? '',
      queueNumber: int.tryParse(data['queueNumber']?.toString() ?? '0') ?? 0,
      roomNumber: data['roomNumber'] ?? '',
      consultationFee: (data['consultationFee'] ?? 0.0).toDouble(),
      insuranceNumber: data['insuranceNumber'] as String?,
      symptoms: data['symptoms'] ?? '',
      diagnosis: data['diagnosis'] as String?,
      physicalExam: data['physicalExam'] as String?,
      treatment: data['treatment'] as String?,
      notes: data['notes'] as String?,
      prescription: (data['prescription'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      labResults: (data['labResults'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      vitals: data['vitals'] as Map<String, dynamic>?,
      status: data['status'] ?? 'pending',
      paymentMethod: data['paymentMethod'] ?? 'CASH',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'patientDOB': patientDOB,
      'patientGender': patientGender,
      'patientName': patientName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'shiftId': shiftId,
      'timeSlot': timeSlot,
      'queueNumber': queueNumber,
      'roomNumber': roomNumber,
      'consultationFee': consultationFee,
      'insuranceNumber': insuranceNumber,
      'symptoms': symptoms,
      'diagnosis': diagnosis,
      'physicalExam': physicalExam,
      'treatment': treatment,
      'notes': notes,
      'prescription': prescription,
      'labResults': labResults,
      'vitals': vitals,
      'status': status,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt,
    };
  }
}
