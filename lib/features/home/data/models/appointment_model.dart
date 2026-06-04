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
    final rawDate = json['appointmentDate'];
    final parsedDate = DateTime.tryParse(rawDate?.toString() ?? '');
    return AppointmentModel(
      id: json['id']?.toString() ?? '',
      doctorName: json['doctorName']?.toString() ?? '',
      specialization: json['specialization']?.toString() ?? '',
      appointmentDate: parsedDate ?? DateTime.now(),
      time: json['time']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      doctorImage: json['doctorImage']?.toString() ?? '',
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
