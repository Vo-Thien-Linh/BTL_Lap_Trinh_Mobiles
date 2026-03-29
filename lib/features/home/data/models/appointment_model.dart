class AppointmentModel {
  final String id;
  final String doctorName;
  final String specialization;
  final DateTime appointmentDate;
  final String time;
  final String status; // 'upcoming', 'completed', 'cancelled'
  final String doctorImage;

  AppointmentModel({
    required this.id,
    required this.doctorName,
    required this.specialization,
    required this.appointmentDate,
    required this.time,
    required this.status,
    required this.doctorImage,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as String,
      doctorName: json['doctorName'] as String,
      specialization: json['specialization'] as String,
      appointmentDate: DateTime.parse(json['appointmentDate'] as String),
      time: json['time'] as String,
      status: json['status'] as String,
      doctorImage: json['doctorImage'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctorName': doctorName,
      'specialization': specialization,
      'appointmentDate': appointmentDate.toIso8601String(),
      'time': time,
      'status': status,
      'doctorImage': doctorImage,
    };
  }
}
