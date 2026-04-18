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
      name: data['departmentName'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      phone: data['phone'] ?? '',
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
    return DoctorModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      specialization: data['specialization'] ?? '',
      departmentId: data['departmentId'] ?? '',
      departmentName: data['departmentName'] ?? '',
      yearsOfExperience: int.tryParse(data['yearsOfExperience']?.toString() ?? '0') ?? 0,
      consultationFee: (data['consultationFee'] ?? 0.0).toDouble(),
      isActive: (data['isActive'] ?? true) as bool,
      licenseNumber: data['licenseNumber'] ?? '',
      imageUrl: data['imageUrl'] as String?,
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
