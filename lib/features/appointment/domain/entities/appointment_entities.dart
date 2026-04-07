import 'package:equatable/equatable.dart';

class DepartmentEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final String location;
  final String phone;

  const DepartmentEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.phone,
  });

  @override
  List<Object?> get props => [id, name, description, location, phone];
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
  final int availableSlots;
  final bool isActive;

  const ScheduleEntity({
    required this.id,
    required this.doctorId,
    required this.departmentId,
    required this.shiftId,
    required this.date,
    required this.availableSlots,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id, doctorId, date, shiftId];
}

class HospitalAppointment extends Equatable {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String departmentId;
  final String departmentName;
  final DateTime appointmentDate;
  final String shiftId;
  final String timeSlot;
  final int queueNumber;
  final String roomNumber;
  final double consultationFee;
  final String? insuranceNumber;
  final String symptoms;
  final String status;
  final String paymentMethod;
  final DateTime createdAt;

  const HospitalAppointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.departmentId,
    required this.departmentName,
    required this.appointmentDate,
    required this.shiftId,
    required this.timeSlot,
    required this.queueNumber,
    required this.roomNumber,
    required this.consultationFee,
    this.insuranceNumber,
    required this.symptoms,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, patientId, doctorId, appointmentDate, queueNumber];
}
