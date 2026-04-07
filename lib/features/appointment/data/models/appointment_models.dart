import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/appointment_entities.dart';

class DepartmentModel extends DepartmentEntity {
  const DepartmentModel({
    required super.id,
    required super.name,
    required super.description,
    required super.location,
    required super.phone,
  });

  factory DepartmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DepartmentModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      phone: data['phone'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'location': location,
      'phone': phone,
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
      yearsOfExperience: (data['yearsOfExperience'] ?? 0) as int,
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
      maxSlots: (data['maxSlots'] ?? 10) as int,
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
      availableSlots: (data['availableSlots'] ?? 0) as int,
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
    required super.status,
    required super.paymentMethod,
    required super.createdAt,
  });

  factory HospitalAppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HospitalAppointmentModel(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      doctorId: data['doctorId'] ?? '',
      doctorName: data['doctorName'] ?? '',
      departmentId: data['departmentId'] ?? '',
      departmentName: data['departmentName'] ?? '',
      appointmentDate: (data['appointmentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      shiftId: data['shiftId'] ?? '',
      timeSlot: data['timeSlot'] ?? '',
      queueNumber: (data['queueNumber'] ?? 0) as int,
      roomNumber: data['roomNumber'] ?? '',
      consultationFee: (data['consultationFee'] ?? 0.0).toDouble(),
      insuranceNumber: data['insuranceNumber'] as String?,
      symptoms: data['symptoms'] ?? '',
      status: data['status'] ?? 'pending',
      paymentMethod: data['paymentMethod'] ?? 'CASH',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
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
      'status': status,
      'paymentMethod': paymentMethod,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
