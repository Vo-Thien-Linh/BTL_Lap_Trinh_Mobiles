class AppointmentEntity {
  final String id;
  final String doctorName;
  final String specialization;
  final DateTime appointmentDate;
  final String time;
  final String status;
  final String doctorImage;

  AppointmentEntity({
    required this.id,
    required this.doctorName,
    required this.specialization,
    required this.appointmentDate,
    required this.time,
    required this.status,
    required this.doctorImage,
  });
}
