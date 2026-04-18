import 'package:flutter/material.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/register_success_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';
import '../../features/doctor/presentation/pages/doctor_home_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/appointment/presentation/pages/appointment_management_page.dart';
import '../../features/notification/presentation/pages/notifications_page.dart';
import '../../features/appointment/presentation/pages/booking_flow_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/doctor/presentation/pages/doctor_search_page.dart';
import '../../features/doctor/presentation/pages/doctor_queue_page.dart';
import '../../features/doctor/presentation/pages/doctor_examination_list_page.dart';
import '../../features/doctor/presentation/pages/doctor_schedule_page.dart';
import '../../features/doctor/presentation/pages/doctor_patient_records_page.dart';
import '../../features/notification/presentation/pages/doctor_notifications_page.dart';
import '../../features/home/presentation/pages/patient_search_page.dart';
import '../../data/models/user_model.dart';

import '../../features/home/presentation/pages/examination_result_detail_page.dart';
import '../../features/appointment/domain/entities/appointment_entities.dart';

import '../../features/home/presentation/pages/examination_history_page.dart';
import '../../features/home/presentation/pages/examination_results_dashboard_page.dart';
import '../../features/home/presentation/pages/medical_vault_category_page.dart';
import '../../features/home/presentation/pages/prescription_detail_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/appointment/presentation/payment_management_bloc/payment_bloc.dart';
import '../../features/appointment/data/models/invoice_models.dart';

import '../../features/home/presentation/pages/payment_management_page.dart';
import '../../features/home/presentation/pages/invoice_detail_page.dart';
import '../../features/home/presentation/pages/payment_success_page.dart';
import '../../features/home/presentation/pages/medical_record_dashboard_page.dart';
import '../../features/home/presentation/pages/medical_emergency_id_page.dart';
import '../../features/home/presentation/pages/digital_receipt_page.dart';

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
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String examinationDetail = '/examination-detail';
  static const String examinationHistory = '/examination-history';
  static const String resultsDashboard = '/results-dashboard';
  static const String medicalVaultCategory = '/medical-vault-category';
  static const String prescriptionDetail = '/prescription-detail';
  static const String paymentManagement = '/payment-management';
  static const String invoiceDetail = '/invoice-detail';
  static const String paymentSuccess = '/payment-success';
  static const String medicalRecordDashboard = '/medical-record-dashboard';
  static const String medicalEmergencyId = '/medical-emergency-id';
  static const String digitalReceipt = '/digital-receipt';
  static const String appointmentManagement = '/appointment-management';
  static const String notifications = '/notifications';
  static const String doctorSearch = '/doctor-search';
  static const String doctorNotifications = '/doctor-notifications';
  static const String patientSearch = '/patient-search';
  static const String doctorQueue = '/doctor-queue';
  static const String doctorExaminationList = '/doctor-examination-list';
  static const String doctorSchedule = '/doctor-schedule';
  static const String doctorPatientRecords = '/doctor-patient-records';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case onboarding:
        return _buildRoute(const OnboardingScreen());
      case login:
        return _buildRoute(const LoginPage());
      case register:
        return _buildRoute(const RegisterPage());
      case registerSuccess:
        final email = settings.arguments as String?;
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

        if (settings.arguments is DepartmentEntity) {
          initialDepartment = settings.arguments as DepartmentEntity;
        } else if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          initialDepartment = args['department'] as DepartmentEntity?;
          initialDoctor = args['doctor'] as DoctorEntity?;
        }

        return _buildRoute(BookingFlowPage(
          initialDepartment: initialDepartment,
          initialDoctor: initialDoctor,
        ));
      case profile:
        final tab = settings.arguments as int? ?? 0;
        return _buildRoute(ProfilePage(initialTab: tab));
      case editProfile:
        final user = settings.arguments as UserModel;
        return _buildRoute(EditProfilePage(user: user));
      case examinationDetail:
        final appointment = settings.arguments as HospitalAppointment;
        return _buildRoute(ExaminationResultDetailPage(appointment: appointment));
      case examinationHistory:
        final filter = settings.arguments as String?;
        return _buildRoute(ExaminationHistoryPage(defaultFilter: filter));
      case resultsDashboard:
        return _buildRoute(const ExaminationResultsDashboardPage());
      case medicalVaultCategory:
        final category = settings.arguments as String;
        return _buildRoute(MedicalVaultCategoryPage(category: category));
      case prescriptionDetail:
        final appointment = settings.arguments as HospitalAppointment;
        return _buildRoute(PrescriptionDetailPage(appointment: appointment));
      case paymentManagement:
        return _buildRoute(const PaymentManagementPage());
      case invoiceDetail:
        final invoice = settings.arguments as InvoiceModel;
        return _buildRoute(
          BlocProvider(
            create: (context) => PaymentBloc(),
            child: InvoiceDetailPage(invoice: invoice),
          ),
        );
      case paymentSuccess:
        final invoice = settings.arguments as InvoiceModel;
        return _buildRoute(PaymentSuccessPage(invoice: invoice));
      case medicalRecordDashboard:
        return _buildRoute(const MedicalRecordDashboardPage());
      case medicalEmergencyId:
        return _buildRoute(const MedicalEmergencyIdPage());
      case digitalReceipt:
        final invoice = settings.arguments as InvoiceModel;
        return _buildRoute(DigitalReceiptPage(invoice: invoice));
      case appointmentManagement:
        return _buildRoute(const AppointmentManagementPage());
      case notifications:
        return _buildRoute(const NotificationsPage());
      case doctorSearch:
        return _buildRoute(const DoctorSearchPage());
      case doctorNotifications:
        return _buildRoute(const DoctorNotificationsPage());
      case patientSearch:
        return _buildRoute(const PatientSearchPage());
      case doctorQueue:
        return _buildRoute(const DoctorQueuePage());
      case doctorExaminationList:
        return _buildRoute(const DoctorExaminationListPage());
      case doctorSchedule:
        return _buildRoute(const DoctorSchedulePage());
      case doctorPatientRecords:
        return _buildRoute(const DoctorPatientRecordsPage());
      default:
        return _buildRoute(const LoginPage());
    }
  }

  static PageRouteBuilder _buildRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);

        final slide =
            Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }
}
