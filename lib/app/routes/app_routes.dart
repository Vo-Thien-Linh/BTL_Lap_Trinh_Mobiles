import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/user_model.dart';
import '../../features/appointment/data/models/invoice_models.dart';
import '../../features/appointment/domain/entities/appointment_entities.dart';
import '../../features/appointment/presentation/pages/appointment_management_page.dart';
import '../../features/appointment/presentation/pages/booking_flow_page.dart';
import '../../features/appointment/presentation/payment_management_bloc/payment_bloc.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/register_success_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';
import '../../features/doctor/presentation/pages/doctor_appointment_detail_page.dart';
import '../../features/doctor/presentation/pages/doctor_examination_list_page.dart';
import '../../features/doctor/presentation/pages/doctor_home_page.dart';
import '../../features/doctor/presentation/pages/doctor_patient_records_page.dart';
import '../../features/doctor/presentation/pages/doctor_queue_page.dart';
import '../../features/doctor/presentation/pages/doctor_schedule_page.dart';
import '../../features/doctor/presentation/pages/doctor_search_page.dart';
import '../../features/doctor/presentation/pages/doctor_service_queue_page.dart';
import '../../features/home/presentation/pages/digital_receipt_page.dart';
import '../../features/home/presentation/pages/examination_history_page.dart';
import '../../features/home/presentation/pages/examination_result_detail_page.dart';
import '../../features/home/presentation/pages/examination_results_dashboard_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/invoice_detail_page.dart';
import '../../features/home/presentation/pages/medical_emergency_id_page.dart';
import '../../features/home/presentation/pages/medical_record_dashboard_page.dart';
import '../../features/home/presentation/pages/medical_vault_category_page.dart';
import '../../features/home/presentation/pages/patient_search_page.dart';
import '../../features/home/presentation/pages/payment_management_page.dart';
import '../../features/home/presentation/pages/payment_success_page.dart';
import '../../features/home/presentation/pages/prescription_detail_page.dart';
import '../../features/notification/presentation/pages/doctor_notifications_page.dart';
import '../../features/notification/presentation/pages/notifications_page.dart';
import '../../features/notification/presentation/utils/deep_link_handler.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/health_insurance/presentation/pages/health_insurance_page.dart';

class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String registerSuccess = '/register-success';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';

  static const String home = '/home';
  static const String doctorHome = '/doctor-home';

  static const String booking = '/booking';
  static const String appointmentManagement = '/appointment-management';

  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';

  static const String notifications = '/notifications';
  static const String doctorNotifications = '/doctor-notifications';

  static const String doctorSearch = '/doctor-search';
  static const String doctorQueue = '/doctor-queue';
  static const String doctorServiceQueue = '/doctor-service-queue';
  static const String doctorExaminationList = '/doctor-examination-list';
  static const String doctorSchedule = '/doctor-schedule';
  static const String doctorPatientRecords = '/doctor-patient-records';
  static const String doctorAppointmentDetail = '/doctor-appointment-detail';

  static const String patientSearch = '/patient-search';
  static const String healthInsurance = '/health-insurance';

  static const String examinationDetail = '/examination-detail';
  static const String examinationHistory = '/examination-history';
  static const String resultsDashboard = '/results-dashboard';
  static const String medicalVaultCategory = '/medical-vault-category';
  static const String prescriptionDetail = '/prescription-detail';
  static const String medicalRecordDashboard = '/medical-record-dashboard';
  static const String medicalEmergencyId = '/medical-emergency-id';

  static const String paymentManagement = '/payment-management';
  static const String invoiceDetail = '/invoice-detail';
  static const String paymentSuccess = '/payment-success';
  static const String digitalReceipt = '/digital-receipt';

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    final routeName = routeSettings.name ?? login;

    // Ưu tiên xử lý deep link từ notification/FCM trước.
    try {
      final uri = Uri.parse(routeName);
      final deepLinkRoute = DeepLinkHandler.handleDeepLink(uri);
      if (deepLinkRoute != null) {
        return deepLinkRoute;
      }
    } catch (e) {
      debugPrint('Error parsing deep link: $e');
    }

    switch (routeName) {
      case onboarding:
        return _buildRoute(const OnboardingScreen());

      case login:
        return _buildRoute(const LoginPage());

      case register:
        return _buildRoute(const RegisterPage());

      case registerSuccess:
        final email = routeSettings.arguments as String?;
        return _buildRoute(RegisterSuccessPage(email: email));

      case forgotPassword:
        return _buildRoute(const ForgotPasswordPage());

      case verifyEmail:
        return _buildRoute(const VerifyEmailPage());

      case home:
        return _buildRoute(const HomePage());

      case doctorHome:
        return _buildRoute(const DoctorHomePage());

      case booking:
        DepartmentEntity? initialDepartment;
        DoctorEntity? initialDoctor;

        final args = routeSettings.arguments;
        if (args is DepartmentEntity) {
          initialDepartment = args;
        } else if (args is Map<String, dynamic>) {
          initialDepartment = args['department'] as DepartmentEntity?;
          initialDoctor = args['doctor'] as DoctorEntity?;
        }

        return _buildRoute(
          BookingFlowPage(
            initialDepartment: initialDepartment,
            initialDoctor: initialDoctor,
          ),
        );

      case appointmentManagement:
        return _buildRoute(const AppointmentManagementPage());

      case profile:
        final tab = routeSettings.arguments as int? ?? 0;
        return _buildRoute(ProfilePage(initialTab: tab));

      case editProfile:
        final args = routeSettings.arguments;
        if (args is UserModel) {
          return _buildRoute(EditProfilePage(user: args));
        }
        return _buildErrorRoute('Thiếu thông tin người dùng để chỉnh sửa hồ sơ.');

      case settings:
        return _buildRoute(const SettingsPage());

      case notifications:
        return _buildRoute(const NotificationsPage());

      case doctorNotifications:
        return _buildRoute(const DoctorNotificationsPage());

      case doctorSearch:
        return _buildRoute(const DoctorSearchPage());

      case doctorQueue:
        return _buildRoute(const DoctorQueuePage());

      case doctorServiceQueue:
        return _buildRoute(const DoctorServiceQueuePage());

      case doctorExaminationList:
        return _buildRoute(const DoctorExaminationListPage());

      case doctorSchedule:
        return _buildRoute(const DoctorSchedulePage());

      case doctorPatientRecords:
        return _buildRoute(const DoctorPatientRecordsPage());

      case doctorAppointmentDetail:
        final args = routeSettings.arguments;
        if (args is Map<String, dynamic>) {
          final appointmentId = (args['appointmentId'] ?? args['id'] ?? '').toString();
          final initialData = args['initialData'] is Map<String, dynamic>
              ? args['initialData'] as Map<String, dynamic>
              : args;

          if (appointmentId.isNotEmpty) {
            return _buildRoute(
              DoctorAppointmentDetailPage(
                appointmentId: appointmentId,
                initialData: initialData,
              ),
            );
          }
        }
        return _buildErrorRoute('Thiếu thông tin lịch khám của bác sĩ.');

      case patientSearch:
        return _buildRoute(const PatientSearchPage());

      case examinationDetail:
        final args = routeSettings.arguments;
        if (args is HospitalAppointment) {
          return _buildRoute(ExaminationResultDetailPage(appointment: args));
        }
        return _buildErrorRoute('Thiếu thông tin lịch khám để xem kết quả.');

      case examinationHistory:
        final filter = routeSettings.arguments as String?;
        return _buildRoute(ExaminationHistoryPage(defaultFilter: filter));

      case resultsDashboard:
        return _buildRoute(const ExaminationResultsDashboardPage());

      case medicalVaultCategory:
        final args = routeSettings.arguments;
        if (args is String) {
          return _buildRoute(MedicalVaultCategoryPage(category: args));
        }
        return _buildErrorRoute('Thiếu danh mục hồ sơ y tế.');

      case prescriptionDetail:
        final args = routeSettings.arguments;
        if (args is HospitalAppointment) {
          return _buildRoute(PrescriptionDetailPage(appointment: args));
        }
        return _buildErrorRoute('Thiếu thông tin lịch khám để xem đơn thuốc.');

      case medicalRecordDashboard:
        return _buildRoute(const MedicalRecordDashboardPage());

      case medicalEmergencyId:
        return _buildRoute(const MedicalEmergencyIdPage());

      case paymentManagement:
        return _buildRoute(const PaymentManagementPage());

      case invoiceDetail:
        final args = routeSettings.arguments;
        if (args is InvoiceModel) {
          return _buildRoute(
            BlocProvider(
              create: (_) => PaymentBloc(),
              child: InvoiceDetailPage(invoice: args),
            ),
          );
        }
        return _buildErrorRoute('Thiếu thông tin hóa đơn.');

      case paymentSuccess:
        final args = routeSettings.arguments;
        if (args is InvoiceModel) {
          return _buildRoute(PaymentSuccessPage(invoice: args));
        }
        return _buildErrorRoute('Thiếu thông tin thanh toán.');

      case digitalReceipt:
        final args = routeSettings.arguments;
        if (args is InvoiceModel) {
          return _buildRoute(DigitalReceiptPage(invoice: args));
        }
        return _buildErrorRoute('Thiếu thông tin biên lai.');

      case healthInsurance:
        return _buildRoute(const HealthInsurancePage());

      default:
        return _buildRoute(const LoginPage());
    }
  }

  static PageRouteBuilder<dynamic> _buildRoute(Widget page) {
    return PageRouteBuilder<dynamic>(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        final fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );

        final slide = Tween<Offset>(
          begin: const Offset(0.08, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
        );

        return FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: slide,
            child: child,
          ),
        );
      },
    );
  }

  static Route<dynamic> _buildErrorRoute(String message) {
    return _buildRoute(
      Scaffold(
        appBar: AppBar(title: const Text('Lỗi điều hướng')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
