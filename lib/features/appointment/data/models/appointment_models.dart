import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/appointment_entities.dart';

class DepartmentModel extends DepartmentEntity {
  const DepartmentModel({
    required super.id,
    required super.name,
    required super.description,
    required super.location,
    required super.phone,
    super.rooms,
    super.doctorCount = 0,
    super.isActive = true,
    super.imageUrl,
  });

  factory DepartmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DepartmentModel(
      id: doc.id,
      name: data['departmentName']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      location: data['location']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      rooms: _stringList(data['rooms']),
      doctorCount: int.tryParse(data['doctorCount']?.toString() ?? '0') ?? 0,
      isActive: (data['isActive'] ?? true) as bool,
      imageUrl: data['imageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'departmentName': name,
      'description': description,
      'location': location,
      'phone': phone,
      'rooms': rooms,
      'doctorCount': doctorCount,
      'isActive': isActive,
      'imageUrl': imageUrl,
    };
  }

  static List<String> _stringList(dynamic value) {
    if (value is Iterable) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
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

    String rawName = _firstText(data, const [
      'fullName',
      'doctorName',
      'name',
      'displayName',
    ]);
    String rawDeptId = data['departmentId']?.toString() ?? '';
    // Map internal specs to the visual category/ID if needed
    if (rawDeptId.isEmpty) {
      final spec = data['specialization']?.toString() ?? '';
      if (spec == 'tim_mach' || id.contains('cardio') || id.contains('tim')) {
        rawDeptId = 'dept_cardio';
      } else if (spec == 'da_lieu' ||
          id.contains('derma') ||
          id.contains('da')) {
        rawDeptId = 'dept_dermatology';
      } else if (spec == 'nhi_khoa' ||
          id.contains('pedia') ||
          id.contains('nhi')) {
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

    final imageUrl = _firstText(data, const ['imageUrl', 'avatarUrl']);

    return DoctorModel(
      id: id,
      userId: _firstText(data, const ['userId', 'uid']),
      name: rawName,
      specialization: data['specialization']?.toString() ?? '',
      departmentId: rawDeptId,
      departmentName: rawDeptName,
      yearsOfExperience:
          int.tryParse(data['yearsOfExperience']?.toString() ?? '0') ?? 0,
      consultationFee:
          double.tryParse(data['consultationFee']?.toString() ?? '0') ?? 0.0,
      isActive: (data['isActive'] ?? true) as bool,
      licenseNumber: data['licenseNumber']?.toString() ?? '',
      imageUrl: imageUrl.isEmpty ? null : imageUrl,
    );
  }

  factory DoctorModel.withUserProfile(
    DoctorModel doctor,
    Map<String, dynamic>? userData,
  ) {
    final data = userData ?? const <String, dynamic>{};
    final imageUrl = _firstText(data, const ['avatarUrl']);
    return DoctorModel(
      id: doctor.id,
      userId: doctor.userId,
      name: _firstText(data, const [
        'fullName',
        'name',
        'displayName',
      ], fallback: doctor.name),
      specialization: doctor.specialization,
      departmentId: doctor.departmentId,
      departmentName: doctor.departmentName,
      yearsOfExperience: doctor.yearsOfExperience,
      consultationFee: doctor.consultationFee,
      isActive: doctor.isActive,
      licenseNumber: doctor.licenseNumber,
      imageUrl: imageUrl.isEmpty ? doctor.imageUrl : imageUrl,
    );
  }

  static String _firstText(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return fallback;
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
    super.roomId,
    super.roomNumber,
    required super.maxSlots,
    required super.availableSlots,
    super.bookedSlots = 0,
    required super.isActive,
  });

  factory ScheduleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final maxSlots =
        int.tryParse(
          (data['slotCapacity'] ?? data['maxSlots'] ?? 10).toString(),
        ) ??
        10;
    final availableSlots =
        int.tryParse(
          (data['remainingSlots'] ?? data['availableSlots'] ?? maxSlots)
              .toString(),
        ) ??
        maxSlots;
    final bookedSlots =
        int.tryParse(
          (data['bookedSlots'] ?? (maxSlots - availableSlots)).toString(),
        ) ??
        0;
    return ScheduleModel(
      id: doc.id,
      doctorId: data['doctorId'] ?? '',
      departmentId: data['departmentId'] ?? '',
      shiftId: data['shiftId'] ?? '',
      date: (data['scheduleDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      roomId: data['roomId'] as String?,
      roomNumber: data['roomNumber'] as String?,
      maxSlots: maxSlots,
      availableSlots: availableSlots,
      bookedSlots: bookedSlots,
      isActive: (data['isActive'] ?? true) as bool,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'doctorId': doctorId,
      'departmentId': departmentId,
      'shiftId': shiftId,
      'scheduleDate': Timestamp.fromDate(date),
      'roomId': roomId,
      'roomNumber': roomNumber,
      'maxSlots': maxSlots,
      'availableSlots': availableSlots,
      'slotCapacity': maxSlots,
      'remainingSlots': availableSlots,
      'bookedSlots': bookedSlots,
      'isActive': isActive,
    };
  }
}

class HospitalAppointmentModel extends HospitalAppointment {
  const HospitalAppointmentModel({
    required super.id,
    super.appointmentCode,
    required super.patientId,
    super.patientCode,
    super.patientDOB,
    super.patientGender,
    required super.patientName,
    required super.doctorId,
    super.doctorCode,
    required super.doctorName,
    required super.departmentId,
    required super.departmentName,
    required super.appointmentDate,
    super.scheduleId,
    required super.shiftId,
    required super.timeSlot,
    required super.queueNumber,
    super.queueOrder,
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
    super.cancelRequestStatus,
    super.paymentStatus,
    required super.paymentMethod,
    required super.createdAt,
  });

  factory HospitalAppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HospitalAppointmentModel(
      id: doc.id,
      appointmentCode:
          _firstText(data, const ['appointmentCode', 'code', 'bookingCode']) ??
          doc.id,
      patientId: _text(data['patientId']),
      patientCode: _firstText(data, const ['patientCode', 'userCode']) ?? '',
      patientDOB: _nullableText(data['patientDOB']),
      patientGender: _nullableText(data['patientGender']),
      patientName: _text(data['patientName']),
      doctorId: _text(data['doctorId']),
      doctorCode: _firstText(data, const ['doctorCode']) ?? '',
      doctorName: _text(data['doctorName']),
      departmentId: _text(data['departmentId']),
      departmentName: _text(data['departmentName']),
      appointmentDate: _date(data['appointmentDate']),
      scheduleId: _nullableText(data['scheduleId']),
      shiftId: _text(data['shiftId']),
      timeSlot: _text(data['timeSlot']),
      queueNumber: int.tryParse(data['queueNumber']?.toString() ?? '0') ?? 0,
      queueOrder: int.tryParse(data['queueOrder']?.toString() ?? ''),
      roomNumber: _text(data['roomNumber']),
      consultationFee: _double(data['consultationFee']),
      insuranceNumber: _nullableText(data['insuranceNumber']),
      symptoms: _text(data['symptoms']),
      diagnosis: _nullableText(data['diagnosis']),
      physicalExam: _nullableText(data['physicalExam']),
      treatment: _nullableText(data['treatment']),
      notes: _nullableText(data['notes']),
      prescription: _mapList(data['prescription']),
      labResults: _mapList(data['labResults']),
      vitals: _map(data['vitals']),
      status: _text(data['status'], fallback: 'pending'),
      cancelRequestStatus: data['cancelRequestStatus']?.toString() ?? '',
      paymentStatus: data['paymentStatus']?.toString() ?? '',
      paymentMethod: _text(data['paymentMethod'], fallback: 'BANK_TRANSFER'),
      createdAt: _date(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'appointmentCode': appointmentCode.isEmpty ? null : appointmentCode,
      'patientCode': patientCode.isEmpty ? null : patientCode,
      'patientDOB': patientDOB,
      'patientGender': patientGender,
      'patientName': patientName,
      'doctorId': doctorId,
      'doctorCode': doctorCode.isEmpty ? null : doctorCode,
      'doctorName': doctorName,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'scheduleId': scheduleId,
      'shiftId': shiftId,
      'timeSlot': timeSlot,
      'queueNumber': queueNumber,
      if (queueOrder != null) 'queueOrder': queueOrder,
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
      'cancelRequestStatus': cancelRequestStatus.isEmpty
          ? null
          : cancelRequestStatus,
      'paymentStatus': paymentStatus.isEmpty ? null : paymentStatus,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt,
    };
  }

  static String? _firstText(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static String _text(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String? _nullableText(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }

  static Map<String, dynamic>? _map(dynamic value) {
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return null;
  }

  static List<Map<String, dynamic>>? _mapList(dynamic value) {
    if (value is! Iterable) return null;
    return value
        .whereType<Map>()
        .map(
          (item) => item.map((key, value) => MapEntry(key.toString(), value)),
        )
        .toList();
  }
}
