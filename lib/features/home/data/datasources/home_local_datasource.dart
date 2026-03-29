import '../models/appointment_model.dart';

abstract class HomeLocalDatasource {
  Future<List<AppointmentModel>> getAppointments();
  Future<void> saveAppointments(List<AppointmentModel> appointments);
}

class HomeLocalDatasourceImpl implements HomeLocalDatasource {
  // Mock data - trong thực tế sẽ sử dụng Hive/SharedPreferences
  static const List<Map<String, dynamic>> mockAppointments = [
    {
      'id': '1',
      'doctorName': 'Dr. Nguyễn Văn A',
      'specialization': 'Nhi khoa',
      'appointmentDate': '2026-04-05T10:00:00.000Z',
      'time': '10:00 - 10:30',
      'status': 'upcoming',
      'doctorImage': 'assets/avatars/doctor1.jpg',
    },
    {
      'id': '2',
      'doctorName': 'Dr. Trần Thị B',
      'specialization': 'Tim mạch',
      'appointmentDate': '2026-03-30T14:00:00.000Z',
      'time': '14:00 - 14:30',
      'status': 'upcoming',
      'doctorImage': 'assets/avatars/doctor2.jpg',
    },
    {
      'id': '3',
      'doctorName': 'Dr. Lê Văn C',
      'specialization': 'Xương khớp',
      'appointmentDate': '2026-03-20T09:00:00.000Z',
      'time': '09:00 - 09:30',
      'status': 'completed',
      'doctorImage': 'assets/avatars/doctor3.jpg',
    },
  ];

  @override
  Future<List<AppointmentModel>> getAppointments() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    return mockAppointments
        .map((json) => AppointmentModel.fromJson(json))
        .toList();
  }

  @override
  Future<void> saveAppointments(List<AppointmentModel> appointments) async {
    // Implement actual storage logic here
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
