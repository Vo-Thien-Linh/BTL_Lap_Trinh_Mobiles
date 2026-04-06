import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String departmentId;
  final String scheduleId;
  final String shiftId;
  final DateTime appointmentDate;
  final int appointmentNumber;
  final String symptoms;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.departmentId,
    required this.scheduleId,
    required this.shiftId,
    required this.appointmentDate,
    required this.appointmentNumber,
    required this.symptoms,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'departmentId': departmentId,
      'scheduleId': scheduleId,
      'shiftId': shiftId,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'appointmentNumber': appointmentNumber,
      'symptoms': symptoms,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory AppointmentModel.fromMap(String id, Map<String, dynamic> map) {
    return AppointmentModel(
      id: id,
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      departmentId: map['departmentId'] ?? '',
      scheduleId: map['scheduleId'] ?? '',
      shiftId: map['shiftId'] ?? '',
      appointmentDate:
      (map['appointmentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      appointmentNumber: map['appointmentNumber'] ?? 0,
      symptoms: map['symptoms'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}