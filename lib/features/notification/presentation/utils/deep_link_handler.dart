import 'package:flutter/material.dart';

import '../../../appointment/presentation/pages/appointment_management_page.dart';
import '../../../appointment/presentation/pages/patient_appointment_detail_page.dart';
import '../../../doctor/presentation/pages/doctor_examination_list_page.dart';
import '../../../doctor/presentation/pages/doctor_queue_page.dart';
import '../../../doctor/presentation/pages/doctor_schedule_page.dart';
import '../../../doctor/presentation/pages/doctor_service_queue_page.dart';

class DeepLinkHandler {
  static Route<dynamic>? handleDeepLink(Uri deepLink) {
    final path = deepLink.path;
    final queryParams = deepLink.queryParameters;

    if (path.contains('appointment-management')) {
      return _buildRoute(const AppointmentManagementPage());
    }

    if (path.contains('doctor-queue')) {
      return _buildRoute(const DoctorQueuePage());
    }

    if (path.contains('doctor-schedule')) {
      return _buildRoute(const DoctorSchedulePage());
    }

    if (path.contains('doctor-service-queue')) {
      return _buildRoute(const DoctorServiceQueuePage());
    }

    if (path.contains('doctor-examination-list')) {
      return _buildRoute(const DoctorExaminationListPage());
    }

    if (path.contains('appointment-detail')) {
      final id = queryParams['id'] ?? '';
      if (id.isNotEmpty) {
        return _buildRoute(PatientAppointmentDetailPage(appointmentId: id));
      }
      return _buildRoute(_PlaceholderPage(title: 'Chi tiết lịch hẹn', id: id));
    }

    if (path.contains('prescription-detail')) {
      return _buildRoute(_PlaceholderPage(title: 'Chi tiết đơn thuốc', id: queryParams['id'] ?? ''));
    }

    if (path.contains('examination-detail')) {
      return _buildRoute(_PlaceholderPage(title: 'Kết quả khám', id: queryParams['id'] ?? ''));
    }

    return null;
  }

  static PageRouteBuilder _buildRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        final slide = Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        return FadeTransition(opacity: fade, child: SlideTransition(position: slide, child: child));
      },
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  final String id;

  const _PlaceholderPage({required this.title, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(id.isEmpty ? title : '$title\nID: $id', textAlign: TextAlign.center)),
    );
  }
}
