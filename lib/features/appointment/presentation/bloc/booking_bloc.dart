import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/appointment_entities.dart';
import '../../domain/usecases/appointment_usecases.dart';
import '../../../notification/presentation/utils/notification_facade.dart';

part 'booking_event.dart';
part 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final GetDepartmentsUsecase getDepartments;
  final GetDoctorsByDeptUsecase getDoctorsByDept;
  final GetDoctorSchedulesUsecase getDoctorSchedules;
  final CreateAppointmentUsecase createAppointment;
  final GetNextQueueNumberUsecase getNextQueueNumber;
  final GetTakenQueueNumbersUsecase getTakenQueueNumbers;
  final GetPatientActiveAppointmentsUsecase getPatientActiveAppointments;

  BookingBloc({
    required this.getDepartments,
    required this.getDoctorsByDept,
    required this.getDoctorSchedules,
    required this.createAppointment,
    required this.getNextQueueNumber,
    required this.getTakenQueueNumbers,
    required this.getPatientActiveAppointments,
  }) : super(const BookingState()) {
    on<LoadInitialData>(_onLoadInitialData);
    on<SelectDepartment>(_onSelectDepartment);
    on<SelectDoctorAndDate>(_onSelectDoctorAndDate);
    on<SelectShift>(_onSelectShift);
    on<SelectQueueNumber>(_onSelectQueueNumber);
    on<SelectPaymentMethod>(_onSelectPaymentMethod);
    on<UpdateSymptoms>(_onUpdateSymptoms);
    on<ConfirmBooking>(_onConfirmBooking);
    on<FinalizePaymentAndConfirm>(_onFinalizePaymentAndConfirm);
    on<StepBack>(_onStepBack);
    on<ResetBooking>(_onResetBooking);
  }

  Future<void> _onLoadInitialData(
    LoadInitialData event,
    Emitter<BookingState> emit,
  ) async {
    emit(state.copyWith(status: BookingStatus.loading));
    try {
      var departments = await getDepartments();

      // For demo, if shifts collection is empty, we use default ones
      final shifts = [
        const ShiftEntity(
          id: 'morning',
          name: 'Sáng',
          startTime: '07:30',
          endTime: '11:30',
          maxSlots: 20,
        ),
        const ShiftEntity(
          id: 'afternoon',
          name: 'Chiều',
          startTime: '13:30',
          endTime: '17:00',
          maxSlots: 20,
        ),
      ];
      // Fetch patient's active appointments if patientId is provided
      List<HospitalAppointment> activeAppointments = [];
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        activeAppointments = await getPatientActiveAppointments(user.uid);
      }

      emit(
        state.copyWith(
          status: BookingStatus.initial,
          departments: departments,
          shifts: shifts,
          patientAppointments: activeAppointments,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BookingStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSelectDepartment(
    SelectDepartment event,
    Emitter<BookingState> emit,
  ) async {
    emit(state.copyWith(status: BookingStatus.loading));
    try {
      final doctors = await getDoctorsByDept(event.department.id);
      emit(
        state.copyWith(
          status: BookingStatus.initial,
          selectedDepartment: event.department,
          doctors: doctors,
          currentStep: 1,
          resetSelectedTime: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BookingStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSelectDoctorAndDate(
    SelectDoctorAndDate event,
    Emitter<BookingState> emit,
  ) async {
    emit(state.copyWith(status: BookingStatus.loading));
    try {
      if (_isPastDate(event.date)) {
        emit(
          state.copyWith(
            status: BookingStatus.failure,
            errorMessage:
                'Ngày khám đã qua nên không thể đặt lịch. Vui lòng chọn hôm nay hoặc một ngày sau hôm nay.',
          ),
        );
        return;
      }
      final schedules = await getDoctorSchedules(event.doctor.id, event.date);
      emit(
        state.copyWith(
          status: BookingStatus.initial,
          selectedDoctor: event.doctor,
          selectedDate: event.date,
          schedules: List<ScheduleEntity>.from(
            schedules,
          ), // Explicit cast to Entity
          currentStep: 2,
          resetSelectedTime: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BookingStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSelectShift(
    SelectShift event,
    Emitter<BookingState> emit,
  ) async {
    emit(
      state.copyWith(
        status: BookingStatus.loading,
        selectedShift: event.shift,
        selectedSchedule: event.schedule,
      ),
    );
    try {
      final selectedDate = state.selectedDate;
      if (selectedDate == null) {
        emit(
          state.copyWith(
            status: BookingStatus.failure,
            errorMessage:
                'Bạn chưa chọn ngày khám. Vui lòng quay lại chọn ngày khám trước.',
          ),
        );
        return;
      }

      if (_isPastDate(selectedDate) ||
          _isShiftFinished(selectedDate, event.shift)) {
        emit(
          state.copyWith(
            status: BookingStatus.failure,
            errorMessage:
                'Ca ${event.shift.name} ngày ${_formatDate(selectedDate)} đã qua giờ nhận lịch. Vui lòng chọn ca khác, ngày khác hoặc bác sĩ khác.',
            resetSelectedTime: true,
          ),
        );
        return;
      }

      // Logic 2: Check for time slot conflict (Same DATE + Same SHIFT)
      final conflict = state.patientAppointments.where((app) {
        final isSameDate =
            app.appointmentDate.year == selectedDate.year &&
            app.appointmentDate.month == selectedDate.month &&
            app.appointmentDate.day == selectedDate.day;
        return isSameDate &&
            app.shiftId == event.shift.id &&
            !_isAppointmentInPast(app);
      }).toList();

      if (conflict.isNotEmpty) {
        final conflicting = conflict.first;
        emit(
          state.copyWith(
            status: BookingStatus.failure,
            errorMessage:
                'Bạn đã có lịch hẹn trong ca ${event.shift.name} ngày ${_formatDate(selectedDate)} tại khoa ${conflicting.departmentName} với bác sĩ ${conflicting.doctorName}. Một bệnh nhân không thể đặt 2 lịch trong cùng một ca. Vui lòng chọn ca khác hoặc đổi ngày khám.',
          ),
        );
        return;
      }

      final taken = await getTakenQueueNumbers(
        state.selectedDoctor!.id,
        state.selectedDate!,
        event.shift.id,
      );
      emit(
        state.copyWith(
          status: BookingStatus.initial,
          selectedShift: event.shift,
          takenQueueNumbers: taken,
          selectedQueueNumber: null, // Reset when shift changes
          currentStep: 2, // Stay on Step 2 to select STT
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BookingStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onSelectQueueNumber(
    SelectQueueNumber event,
    Emitter<BookingState> emit,
  ) {
    emit(
      state.copyWith(
        selectedQueueNumber: event.queueNumber,
        currentStep: 3, // Auto-advance to Booking Summary
      ),
    );
  }

  void _onSelectPaymentMethod(
    SelectPaymentMethod event,
    Emitter<BookingState> emit,
  ) {
    emit(state.copyWith(selectedPaymentMethod: event.method));
  }

  void _onUpdateSymptoms(UpdateSymptoms event, Emitter<BookingState> emit) {
    emit(state.copyWith(symptoms: event.symptoms));
  }

  Future<void> _onConfirmBooking(
    ConfirmBooking event,
    Emitter<BookingState> emit,
  ) async {
    if (state.selectedDoctor == null ||
        state.selectedDate == null ||
        state.selectedShift == null ||
        state.selectedSchedule == null) {
      return;
    }

    emit(state.copyWith(status: BookingStatus.loading));
    try {
      if (_isPastDate(state.selectedDate!) ||
          _isShiftFinished(state.selectedDate!, state.selectedShift!)) {
        emit(
          state.copyWith(
            status: BookingStatus.failure,
            errorMessage:
                'Ca ${state.selectedShift!.name} ngày ${_formatDate(state.selectedDate!)} đã qua giờ nhận lịch. Vui lòng quay lại chọn ca khác, ngày khác hoặc bác sĩ khác.',
          ),
        );
        return;
      }

      final patientData = await _getUserData(event.patientId);
      final doctorData =
          (await _getUserData(state.selectedDoctor!.userId)) ??
          (await _getUserData(state.selectedDoctor!.id));

      final dob = _firstText(patientData, const ['dateOfBirth']);
      final gender = _firstText(patientData, const ['gender']);
      final patientName =
          _firstText(patientData, const [
            'fullName',
            'name',
            'displayName',
            'patientName',
          ]) ??
          event.patientName;
      final doctorName =
          _firstText(doctorData, const [
            'fullName',
            'name',
            'displayName',
            'doctorName',
          ]) ??
          state.selectedDoctor!.name;

      // Use selectedQueueNumber if user picked one, otherwise fetch next
      int queueNumber;
      if (state.selectedQueueNumber != null) {
        queueNumber = state.selectedQueueNumber!;
      } else {
        queueNumber = await getNextQueueNumber(
          state.selectedDoctor!.id,
          state.selectedDate!,
          state.selectedShift!.id,
        );
      }

      final appointment = HospitalAppointment(
        id: '', // Will be set by Firestore
        patientId: event.patientId,
        patientDOB: dob,
        patientGender: gender,
        patientName: patientName,
        doctorId: state.selectedDoctor!.id,
        doctorName: doctorName,
        departmentId: state.selectedDepartment!.id,
        departmentName: state.selectedDepartment!.name,
        appointmentDate: state.selectedDate!,
        scheduleId: _nonEmptyText(state.selectedSchedule?.id),
        shiftId: state.selectedShift!.id,
        timeSlot: state.selectedShift!.startTime,
        queueNumber: queueNumber,
        roomNumber:
            _nonEmptyText(state.selectedSchedule?.roomNumber) ??
            'Phòng ${state.selectedDepartment!.location}',
        consultationFee: state.selectedDoctor!.consultationFee,
        insuranceNumber: event.insuranceNumber,
        symptoms: state.symptoms,
        status: 'pending',
        paymentMethod: state.selectedPaymentMethod,
        createdAt: DateTime.now(),
      );

      final created = await createAppointment(appointment);
      emit(
        state.copyWith(
          status: BookingStatus.success,
          createdAppointment: created,
          currentStep: 4,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BookingStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onFinalizePaymentAndConfirm(
    FinalizePaymentAndConfirm event,
    Emitter<BookingState> emit,
  ) async {
    emit(state.copyWith(status: BookingStatus.loading));
    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      final paymentId = 'PAY_${DateTime.now().millisecondsSinceEpoch}';
      final invoiceId = 'INV_${DateTime.now().millisecondsSinceEpoch}';
      final requestedStatus = state.selectedPaymentMethod == 'CASH'
          ? 'pay_at_counter'
          : 'waiting_confirmation';
      final requestedMethod = state.selectedPaymentMethod == 'CASH'
          ? 'cash'
          : state.selectedPaymentMethod.toLowerCase();

      // 1. Create Payment Record (Pending as requested)
      final paymentRef = db.collection('Payments').doc(paymentId);
      batch.set(paymentRef, {
        'id': paymentId,
        'invoiceId': invoiceId,
        'appointmentId': event.appointmentId,
        'patientId': event.patientId,
        'amount': event.amount,
        'status': requestedStatus,
        'paymentStatus': requestedStatus,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'method': requestedMethod,
        'paymentMethod': requestedMethod,
        'paymentCode': invoiceId,
      });

      // 2. Create Invoice Record
      final invoiceRef = db.collection('Invoices').doc(invoiceId);
      batch.set(invoiceRef, {
        'id': invoiceId,
        'paymentId': paymentId,
        'appointmentId': event.appointmentId,
        'patientId': event.patientId,
        'subtotal': event.amount,
        'discount': 0.0,
        'tax': 0.0,
        'total': event.amount,
        'amount': event.amount,
        'totalAmount': event.amount,
        'discountAmount': 0.0,
        'paymentStatus': requestedStatus,
        'method': requestedMethod,
        'paymentMethod': requestedMethod,
        'paymentCode': invoiceId,
        'expenseType': 'Tien kham',
        'serviceContent': 'Thanh toan phi kham',
        'status': requestedStatus,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Update Appointment Status to Confirmed
      final appointmentRef = db
          .collection('Appointments')
          .doc(event.appointmentId);
      batch.update(appointmentRef, {
        'status': 'confirmed',
        'paymentId': paymentId,
        'invoiceId': invoiceId,
        'lastInvoiceId': invoiceId,
        'paymentStatus': requestedStatus,
        'paymentMethod': requestedMethod,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Gửi thông báo sau khi đặt lịch/thanh toán thành công.
      // Lỗi thông báo không được làm hỏng flow đặt lịch.
      try {
        final appointment = state.createdAppointment;
        if (appointment != null) {
          final appointmentTime = NotificationFacade.combineDateAndTimeSlot(
            appointment.appointmentDate,
            appointment.timeSlot,
          );

          await NotificationFacade.onAppointmentCreated(
            appointmentId: event.appointmentId,
            patientId: event.patientId,
            patientName: appointment.patientName,
            doctorId: appointment.doctorId,
            doctorName: appointment.doctorName,
            departmentId: appointment.departmentId,
            departmentName: appointment.departmentName,
            appointmentTime: appointmentTime,
            patientEmail: FirebaseAuth.instance.currentUser?.email,
          );
        }
      } catch (e) {
        // Không throw lại để tránh người dùng bị báo lỗi thanh toán/đặt lịch
        // chỉ vì phần gửi thông báo gặp sự cố.
        debugPrint('Notification error after booking confirmation: $e');
      }

      // Refresh appointment in state (for Ticket UI updates if any)
      if (state.createdAppointment != null) {
        final updated = HospitalAppointment(
          id: state.createdAppointment!.id,
          patientId: state.createdAppointment!.patientId,
          patientDOB: state.createdAppointment!.patientDOB,
          patientGender: state.createdAppointment!.patientGender,
          patientName: state.createdAppointment!.patientName,
          doctorId: state.createdAppointment!.doctorId,
          doctorName: state.createdAppointment!.doctorName,
          departmentId: state.createdAppointment!.departmentId,
          departmentName: state.createdAppointment!.departmentName,
          appointmentDate: state.createdAppointment!.appointmentDate,
          scheduleId: state.createdAppointment!.scheduleId,
          shiftId: state.createdAppointment!.shiftId,
          timeSlot: state.createdAppointment!.timeSlot,
          queueNumber: state.createdAppointment!.queueNumber,
          roomNumber: state.createdAppointment!.roomNumber,
          consultationFee: state.createdAppointment!.consultationFee,
          insuranceNumber: state.createdAppointment!.insuranceNumber,
          symptoms: state.createdAppointment!.symptoms,
          status: 'confirmed',
          paymentMethod: state.createdAppointment!.paymentMethod,
          createdAt: state.createdAppointment!.createdAt,
        );
        emit(
          state.copyWith(
            status: BookingStatus.success,
            createdAppointment: updated,
          ),
        );
      } else {
        emit(state.copyWith(status: BookingStatus.success));
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: BookingStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onStepBack(StepBack event, Emitter<BookingState> emit) {
    if (state.currentStep > 0) {
      emit(state.copyWith(currentStep: state.currentStep - 1));
    }
  }

  void _onResetBooking(ResetBooking event, Emitter<BookingState> emit) {
    emit(const BookingState());
    add(LoadInitialData());
  }

  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    if (userId.trim().isEmpty) return null;

    final db = FirebaseFirestore.instance;
    final lowerDoc = await db.collection('users').doc(userId).get();
    if (lowerDoc.exists) return lowerDoc.data();

    return null;
  }

  String? _firstText(
    Map<String, dynamic>? data,
    List<String> keys, {
    String? fallback,
  }) {
    if (data == null) return fallback;
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return fallback;
  }

  String? _nonEmptyText(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  bool _isPastDate(DateTime date) {
    final today = DateTime.now();
    final selectedDay = DateTime(date.year, date.month, date.day);
    final currentDay = DateTime(today.year, today.month, today.day);
    return selectedDay.isBefore(currentDay);
  }

  bool _isShiftFinished(DateTime date, ShiftEntity shift) {
    if (!_isSameDay(date, DateTime.now())) return false;

    final end = _timeOnDate(date, shift.endTime);
    if (end == null) return false;

    return !DateTime.now().isBefore(end);
  }

  bool _isAppointmentInPast(HospitalAppointment appointment) {
    final matchingShift = state.shifts.where(
      (shift) => shift.id == appointment.shiftId,
    );
    final endTime = matchingShift.isNotEmpty
        ? matchingShift.first.endTime
        : appointment.timeSlot;
    final end = _timeOnDate(appointment.appointmentDate, endTime);
    if (end != null) return end.isBefore(DateTime.now());

    final day = DateTime(
      appointment.appointmentDate.year,
      appointment.appointmentDate.month,
      appointment.appointmentDate.day,
    );
    final today = DateTime.now();
    final currentDay = DateTime(today.year, today.month, today.day);
    return day.isBefore(currentDay);
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  DateTime? _timeOnDate(DateTime date, String time) {
    final parts = time.trim().split(':');
    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
