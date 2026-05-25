import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/usecases/notification_usecases.dart';

part 'notification_event.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository repository;
  final RegisterNotificationDeviceUseCase registerDevice;
  final SendAppointmentConfirmationUseCase sendAppointmentConfirmation;
  final SendAppointmentCancelledUseCase sendAppointmentCancelled;
  final ScheduleAppointmentRemindersUseCase scheduleAppointmentReminders;
  final SendPreparationInstructionsUseCase sendPreparationInstructions;
  final SendExaminationCompleteUseCase sendExaminationComplete;
  final SendResultAvailableUseCase sendResultAvailable;
  final SendDoctorNotificationUseCase sendDoctorNotification;
  final ScheduleMedicationRemindersUseCase scheduleMedicationReminders;
  final GetNotificationsUseCase getNotifications;
  final GetNotificationTemplatesByDepartmentUseCase getTemplates;

  StreamSubscription<List<NotificationEntity>>? _subscription;

  NotificationBloc({
    required this.repository,
    required this.registerDevice,
    required this.sendAppointmentConfirmation,
    required this.sendAppointmentCancelled,
    required this.scheduleAppointmentReminders,
    required this.sendPreparationInstructions,
    required this.sendExaminationComplete,
    required this.sendResultAvailable,
    required this.sendDoctorNotification,
    required this.scheduleMedicationReminders,
    required this.getNotifications,
    required this.getTemplates,
  }) : super(const NotificationInitial()) {
    on<RegisterNotificationDeviceEvent>(_onRegisterDevice);
    on<WatchNotificationsEvent>(_onWatchNotifications);
    on<GetNotificationsEvent>(_onGetNotifications);
    on<_NotificationsStreamUpdated>(_onStreamUpdated);
    on<SendAppointmentConfirmationEvent>(_onSendAppointmentConfirmation);
    on<SendAppointmentCancelledEvent>(_onSendAppointmentCancelled);
    on<ScheduleAppointmentRemindersEvent>(_onScheduleAppointmentReminders);
    on<SendPreparationInstructionsEvent>(_onSendPreparationInstructions);
    on<SendExaminationCompleteEvent>(_onSendExaminationComplete);
    on<SendResultAvailableEvent>(_onSendResultAvailable);
    on<SendDoctorNotificationEvent>(_onSendDoctorNotification);
    on<ScheduleMedicationRemindersEvent>(_onScheduleMedicationReminders);
    on<MarkAsReadEvent>(_onMarkAsRead);
    on<MarkAllAsReadEvent>(_onMarkAllAsRead);
    on<DeleteNotificationEvent>(_onDeleteNotification);
    on<LoadNotificationTemplatesEvent>(_onLoadTemplates);
  }

  Future<void> _onRegisterDevice(RegisterNotificationDeviceEvent event, Emitter<NotificationState> emit) async {
    final result = await registerDevice(role: event.role, email: event.email);
    result.fold(
      (failure) => emit(NotificationError(message: failure.toString())),
      (_) => emit(const NotificationSuccess(message: 'Đã đăng ký thiết bị nhận thông báo')),
    );
  }

  Future<void> _onWatchNotifications(WatchNotificationsEvent event, Emitter<NotificationState> emit) async {
    emit(const NotificationLoading());
    await _subscription?.cancel();
    _subscription = repository
        .watchNotifications(event.userId, role: event.role, limit: event.limit)
        .listen((items) => add(_NotificationsStreamUpdated(items)));
  }

  void _onStreamUpdated(_NotificationsStreamUpdated event, Emitter<NotificationState> emit) {
    emit(NotificationsLoaded(notifications: event.notifications));
  }

  Future<void> _onGetNotifications(GetNotificationsEvent event, Emitter<NotificationState> emit) async {
    emit(const NotificationLoading());
    final result = await getNotifications(event.userId, role: event.role, limit: event.limit);
    result.fold(
      (failure) => emit(NotificationError(message: failure.toString())),
      (items) => emit(NotificationsLoaded(notifications: items)),
    );
  }

  Future<void> _onSendAppointmentConfirmation(SendAppointmentConfirmationEvent event, Emitter<NotificationState> emit) async {
    final result = await sendAppointmentConfirmation(
      userId: event.userId,
      appointmentId: event.appointmentId,
      doctorName: event.doctorName,
      appointmentTime: event.appointmentTime,
      departmentName: event.departmentName,
      email: event.email,
    );
    _emitResult(result, emit, 'Đã gửi xác nhận lịch khám');
  }

  Future<void> _onSendAppointmentCancelled(SendAppointmentCancelledEvent event, Emitter<NotificationState> emit) async {
    final result = await sendAppointmentCancelled(
      userId: event.userId,
      appointmentId: event.appointmentId,
      doctorName: event.doctorName,
      email: event.email,
    );
    _emitResult(result, emit, 'Đã gửi thông báo hủy lịch');
  }

  Future<void> _onScheduleAppointmentReminders(ScheduleAppointmentRemindersEvent event, Emitter<NotificationState> emit) async {
    final result = await scheduleAppointmentReminders(
      userId: event.userId,
      appointmentId: event.appointmentId,
      doctorName: event.doctorName,
      appointmentTime: event.appointmentTime,
      departmentId: event.departmentId,
      departmentName: event.departmentName,
      patientEmail: event.patientEmail,
    );
    _emitResult(result, emit, 'Đã lập lịch nhắc khám');
  }

  Future<void> _onSendPreparationInstructions(SendPreparationInstructionsEvent event, Emitter<NotificationState> emit) async {
    final result = await sendPreparationInstructions(
      userId: event.userId,
      appointmentId: event.appointmentId,
      departmentId: event.departmentId,
      departmentName: event.departmentName,
      appointmentTime: event.appointmentTime,
    );
    _emitResult(result, emit, 'Đã gửi hướng dẫn chuẩn bị');
  }

  Future<void> _onSendExaminationComplete(SendExaminationCompleteEvent event, Emitter<NotificationState> emit) async {
    final result = await sendExaminationComplete(
      userId: event.userId,
      appointmentId: event.appointmentId,
      doctorName: event.doctorName,
    );
    _emitResult(result, emit, 'Đã gửi thông báo hoàn tất khám');
  }

  Future<void> _onSendResultAvailable(SendResultAvailableEvent event, Emitter<NotificationState> emit) async {
    final result = await sendResultAvailable(
      patientId: event.patientId,
      appointmentId: event.appointmentId,
      serviceName: event.serviceName,
    );
    _emitResult(result, emit, 'Đã gửi thông báo có kết quả');
  }

  Future<void> _onSendDoctorNotification(SendDoctorNotificationEvent event, Emitter<NotificationState> emit) async {
    final result = await sendDoctorNotification(
      doctorId: event.doctorId,
      type: event.type,
      title: event.title,
      body: event.body,
      data: event.data,
      deepLink: event.deepLink,
      category: event.category,
    );
    _emitResult(result, emit, 'Đã gửi thông báo cho bác sĩ');
  }

  Future<void> _onScheduleMedicationReminders(ScheduleMedicationRemindersEvent event, Emitter<NotificationState> emit) async {
    final result = await scheduleMedicationReminders(
      userId: event.userId,
      prescriptionId: event.prescriptionId,
      reminderTimes: event.reminderTimes,
    );
    _emitResult(result, emit, 'Đã lập lịch nhắc uống thuốc');
  }

  Future<void> _onMarkAsRead(MarkAsReadEvent event, Emitter<NotificationState> emit) async {
    await repository.markAsRead(event.notificationId);
  }

  Future<void> _onMarkAllAsRead(MarkAllAsReadEvent event, Emitter<NotificationState> emit) async {
    await repository.markAllAsRead(event.userId, role: event.role);
  }

  Future<void> _onDeleteNotification(DeleteNotificationEvent event, Emitter<NotificationState> emit) async {
    await repository.deleteNotification(event.notificationId);
  }

  Future<void> _onLoadTemplates(LoadNotificationTemplatesEvent event, Emitter<NotificationState> emit) async {
    emit(const NotificationLoading());
    final result = await getTemplates(event.departmentId);
    result.fold(
      (failure) => emit(NotificationError(message: failure.toString())),
      (templates) => emit(TemplatesLoaded(templates: templates)),
    );
  }

  void _emitResult(dynamic result, Emitter<NotificationState> emit, String successMessage) {
    result.fold(
      (failure) => emit(NotificationError(message: failure.toString())),
      (_) => emit(NotificationSuccess(message: successMessage)),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
