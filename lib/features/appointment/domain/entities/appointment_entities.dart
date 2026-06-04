import 'package:equatable/equatable.dart';

class DepartmentEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final String location;
  final String phone;
  final List<String> rooms;
  final int doctorCount;
  final bool isActive;
  final String? imageUrl;

  const DepartmentEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.phone,
    this.rooms = const [],
    this.doctorCount = 0,
    this.isActive = true,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    location,
    phone,
    rooms,
    doctorCount,
    isActive,
    imageUrl,
  ];
}

class DoctorEntity extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String specialization;
  final String departmentId;
  final String departmentName;
  final int yearsOfExperience;
  final double consultationFee;
  final bool isActive;
  final String licenseNumber;
  final String? imageUrl;

  const DoctorEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.specialization,
    required this.departmentId,
    required this.departmentName,
    required this.yearsOfExperience,
    required this.consultationFee,
    required this.isActive,
    required this.licenseNumber,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [id, name, specialization, departmentId];
}

class ShiftEntity extends Equatable {
  final String id;
  final String name; // Sáng, Chiều
  final String startTime;
  final String endTime;
  final int maxSlots;

  const ShiftEntity({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.maxSlots,
  });

  @override
  List<Object?> get props => [id, name, startTime, endTime];
}

class ScheduleEntity extends Equatable {
  final String id;
  final String doctorId;
  final String departmentId;
  final String shiftId;
  final DateTime date;
  final String? roomId;
  final String? roomNumber;
  final int maxSlots;
  final int availableSlots;
  final int bookedSlots;
  final bool isActive;

  const ScheduleEntity({
    required this.id,
    required this.doctorId,
    required this.departmentId,
    required this.shiftId,
    required this.date,
    this.roomId,
    this.roomNumber,
    required this.maxSlots,
    required this.availableSlots,
    this.bookedSlots = 0,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
    id,
    doctorId,
    date,
    shiftId,
    roomId,
    roomNumber,
    maxSlots,
    availableSlots,
    bookedSlots,
  ];
}

class HospitalAppointment extends Equatable {
  final String id;
  final String appointmentCode;
  final String patientId;
  final String patientCode;
  final String? patientDOB;
  final String? patientGender;
  final String patientName;
  final String doctorId;
  final String doctorCode;
  final String doctorName;
  final String departmentId;
  final String departmentName;
  final DateTime appointmentDate;
  final String? scheduleId;
  final String shiftId;
  final String timeSlot;
  final int queueNumber;
  final int? queueOrder;
  final String roomNumber;
  final double consultationFee;
  final String? insuranceNumber;
  final String symptoms;
  final String? diagnosis;
  final String? physicalExam;
  final String? treatment;
  final String? notes;
  final List<Map<String, dynamic>>? prescription;
  final List<Map<String, dynamic>>? labResults;
  final Map<String, dynamic>? vitals;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final DateTime createdAt;

  const HospitalAppointment({
    required this.id,
    this.appointmentCode = '',
    required this.patientId,
    this.patientCode = '',
    this.patientDOB,
    this.patientGender,
    required this.patientName,
    required this.doctorId,
    this.doctorCode = '',
    required this.doctorName,
    required this.departmentId,
    required this.departmentName,
    required this.appointmentDate,
    this.scheduleId,
    required this.shiftId,
    required this.timeSlot,
    required this.queueNumber,
    this.queueOrder,
    required this.roomNumber,
    required this.consultationFee,
    this.insuranceNumber,
    required this.symptoms,
    this.diagnosis,
    this.physicalExam,
    this.treatment,
    this.notes,
    this.prescription,
    this.labResults,
    this.vitals,
    required this.status,
    this.paymentStatus = '',
    required this.paymentMethod,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    appointmentCode,
    patientId,
    patientCode,
    doctorId,
    doctorCode,
    appointmentDate,
    scheduleId,
    queueNumber,
    queueOrder,
  ];
}
