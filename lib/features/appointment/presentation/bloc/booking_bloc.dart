import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/appointment_entities.dart';
import '../../domain/usecases/appointment_usecases.dart';
import '../../../notification/presentation/utils/notification_facade.dart';
import '../../../payment/data/services/billing_calculation_service.dart';
import '../../../../services/firestore_sequence_service.dart';

part 'booking_event.dart';
part 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  static const String _scheduleConflictMessage =
      'Bạn đã có lịch khám trong ca này. Vui lòng chọn ngày, buổi hoặc bác sĩ khác.';

  final GetDepartmentsUsecase getDepartments;
  final GetDoctorsByDeptUsecase getDoctorsByDept;
  final GetDoctorSchedulesUsecase getDoctorSchedules;
  final CreateAppointmentUsecase createAppointment;
  final GetNextQueueNumberUsecase getNextQueueNumber;
  final GetTakenQueueNumbersUsecase getTakenQueueNumbers;
  final HasScheduleConflictUsecase hasScheduleConflict;
  final GetPatientActiveAppointmentsUsecase getPatientActiveAppointments;

  BookingBloc({
    required this.getDepartments,
    required this.getDoctorsByDept,
    required this.getDoctorSchedules,
    required this.createAppointment,
    required this.getNextQueueNumber,
    required this.getTakenQueueNumbers,
    required this.hasScheduleConflict,
    required this.getPatientActiveAppointments,
  }) : super(const BookingState()) {
    on<LoadInitialData>(_onLoadInitialData);
    on<SelectDepartment>(_onSelectDepartment);
    on<SelectAppointmentDate>(_onSelectAppointmentDate);
    on<SelectAppointmentSession>(_onSelectAppointmentSession);
    on<SelectDoctorForSession>(_onSelectDoctorForSession);
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
          maxSlots: 10,
        ),
        const ShiftEntity(
          id: 'afternoon',
          name: 'Chiều',
          startTime: '13:30',
          endTime: '17:00',
          maxSlots: 10,
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
      /*
      final message = e.toString();
      final isConflict =
          message.contains('lịch khám trong ca này') ||
          message.contains('lich kham trong ca nay');
      */
      emit(
        state.copyWith(
          status: BookingStatus.failure,
          isCheckingConflict: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSelectDepartment(
    SelectDepartment event,
    Emitter<BookingState> emit,
  ) async {
    emit(
      state.copyWith(
        status: BookingStatus.initial,
        selectedDepartment: event.department,
        doctors: const [],
        schedules: const [],
        takenQueueNumbers: const [],
        currentStep: 1,
        resetSelectedTime: true,
        clearConflict: true,
        clearErrorMessage: true,
        clearSelectedDoctor: true,
        clearSelectedDate: true,
        clearSelectedSession: true,
      ),
    );
  }

  Future<void> _onSelectAppointmentDate(
    SelectAppointmentDate event,
    Emitter<BookingState> emit,
  ) async {
    await _loadDoctorsForSelectedSession(emit, date: event.date);
  }

  Future<void> _onSelectAppointmentSession(
    SelectAppointmentSession event,
    Emitter<BookingState> emit,
  ) async {
    await _loadDoctorsForSelectedSession(emit, session: event.session);
  }

  Future<void> _onSelectDoctorForSession(
    SelectDoctorForSession event,
    Emitter<BookingState> emit,
  ) async {
    final date = state.selectedDate;
    final session = state.selectedSession;
    if (date == null || session == null) {
      emit(
        state.copyWith(
          status: BookingStatus.failure,
          errorMessage: 'Vui lòng chọn ngày khám và buổi khám trước.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: BookingStatus.loading));
    try {
      var doctorSchedules = state.schedules
          .where(
            (schedule) =>
                schedule.doctorId == event.doctor.id &&
                _scheduleMatchesSession(schedule, session) &&
                schedule.isActive &&
                schedule.availableSlots > 0 &&
                !_isScheduleFinished(date, schedule),
          )
          .toList();

      if (doctorSchedules.isEmpty) {
        final latestSchedules = await getDoctorSchedules(event.doctor.id, date);
        doctorSchedules = latestSchedules
            .where(
              (schedule) =>
                  _scheduleMatchesSession(schedule, session) &&
                  schedule.isActive &&
                  schedule.availableSlots > 0 &&
                  !_isScheduleFinished(date, schedule),
            )
            .toList();
      }

      if (doctorSchedules.isEmpty) {
        emit(
          state.copyWith(
            status: BookingStatus.failure,
            errorMessage: 'Bác sĩ này không còn lịch trống trong buổi đã chọn.',
            resetSelectedTime: true,
            clearSelectedDoctor: true,
          ),
        );
        return;
      }

      doctorSchedules.sort((a, b) => a.shiftId.compareTo(b.shiftId));
      emit(
        state.copyWith(
          status: BookingStatus.initial,
          selectedDoctor: event.doctor,
          takenQueueNumbers: const [],
          currentStep: 2,
          resetSelectedTime: true,
          clearConflict: true,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BookingStatus.failure,
          isCheckingConflict: false,
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
        status: BookingStatus.initial,
        selectedShift: event.shift,
        selectedSchedule: event.schedule,
        isCheckingConflict: true,
        clearSelectedQueueNumber: true,
        clearConflict: true,
        clearErrorMessage: true,
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

      final conflict = await _hasConflictForSelection(
        selectedDate,
        event.shift,
      );

      if (conflict) {
        emit(
          state.copyWith(
            status: BookingStatus.initial,
            selectedShift: event.shift,
            selectedSchedule: event.schedule,
            hasScheduleConflict: true,
            conflictMessage: _scheduleConflictMessage,
            isCheckingConflict: false,
            currentStep: 2,
            clearSelectedQueueNumber: true,
          ),
        );
        return;
        /*
        emit(
          state.copyWith(
            status: BookingStatus.failure,
            errorMessage:
                'Bạn đã có lịch hẹn trong ca ${event.shift.name} ngày ${_formatDate(selectedDate)} tại khoa ${conflicting.departmentName} với bác sĩ ${conflicting.doctorName}. Một bệnh nhân không thể đặt 2 lịch trong cùng một ca. Vui lòng chọn ca khác hoặc đổi ngày khám.',
          ),
        );
        return;
        */
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
          isCheckingConflict: false,
          clearConflict: true,
          clearSelectedQueueNumber: true,
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

  Future<void> _onSelectQueueNumber(
    SelectQueueNumber event,
    Emitter<BookingState> emit,
  ) async {
    final selectedDate = state.selectedDate;
    final selectedShift = state.selectedShift;
    final selectedSchedule = state.selectedSchedule;
    if (selectedDate == null ||
        selectedShift == null ||
        selectedSchedule == null ||
        selectedSchedule.availableSlots <= 0 ||
        state.takenQueueNumbers.contains(event.queueNumber)) {
      emit(
        state.copyWith(
          status: BookingStatus.initial,
          clearSelectedQueueNumber: true,
          hasScheduleConflict: selectedSchedule?.availableSlots == 0
              ? true
              : state.hasScheduleConflict,
          conflictMessage: selectedSchedule?.availableSlots == 0
              ? 'Slot này đã hết chỗ. Vui lòng chọn ca hoặc bác sĩ khác.'
              : state.conflictMessage,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        selectedQueueNumber: event.queueNumber,
        isCheckingConflict: true,
        clearConflict: true,
        clearErrorMessage: true,
      ),
    );

    final conflict = await _hasConflictForSelection(
      selectedDate,
      selectedShift,
    );
    if (conflict) {
      emit(
        state.copyWith(
          hasScheduleConflict: true,
          conflictMessage: _scheduleConflictMessage,
          isCheckingConflict: false,
          clearSelectedQueueNumber: true,
          currentStep: 2,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        selectedQueueNumber: event.queueNumber,
        isCheckingConflict: false,
        clearConflict: true,
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
    if (!state.canSubmit ||
        state.selectedDoctor == null ||
        state.selectedDate == null ||
        state.selectedShift == null ||
        state.selectedSchedule == null) {
      if (state.hasScheduleConflict) {
        emit(
          state.copyWith(
            status: BookingStatus.initial,
            conflictMessage: state.conflictMessage ?? _scheduleConflictMessage,
          ),
        );
      }
      return;
    }

    emit(
      state.copyWith(
        status: BookingStatus.loading,
        isSubmitting: true,
        clearErrorMessage: true,
      ),
    );
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

      final finalConflict = await _hasConflictForSelection(
        state.selectedDate!,
        state.selectedShift!,
      );
      if (finalConflict) {
        emit(
          state.copyWith(
            status: BookingStatus.initial,
            isSubmitting: false,
            hasScheduleConflict: true,
            conflictMessage: _scheduleConflictMessage,
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
      final patientCode =
          _firstText(patientData, const ['patientCode', 'userCode', 'code']) ??
          '';
      final doctorCode =
          _firstText(doctorData, const ['doctorCode', 'userCode', 'code']) ??
          state.selectedDoctor!.id;
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
        patientCode: patientCode,
        patientDOB: dob,
        patientGender: gender,
        patientName: patientName,
        doctorId: state.selectedDoctor!.id,
        doctorCode: doctorCode,
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
        paymentStatus: 'unpaid',
        paymentMethod: state.selectedPaymentMethod,
        createdAt: DateTime.now(),
      );

      final created = await createAppointment(appointment);

      try {
        final appointmentTime = NotificationFacade.combineDateAndTimeSlot(
          created.appointmentDate,
          created.timeSlot,
        );
        await NotificationFacade.onAppointmentCreated(
          appointmentId: created.id,
          appointmentCode: created.appointmentCode,
          patientId: created.patientId,
          patientName: created.patientName,
          doctorId: created.doctorId,
          doctorName: created.doctorName,
          departmentId: created.departmentId,
          departmentName: created.departmentName,
          appointmentTime: appointmentTime,
          patientEmail: FirebaseAuth.instance.currentUser?.email,
        );
      } catch (e) {
        debugPrint('Notification error after appointment creation: $e');
      }

      emit(
        state.copyWith(
          status: BookingStatus.success,
          isSubmitting: false,
          createdAppointment: created,
          clearConflict: true,
          currentStep: 4,
        ),
      );
    } catch (e) {
      final message = e.toString();
      final isConflict =
          message.contains('lịch khám trong ca này') ||
          message.contains('lich kham trong ca nay');
      emit(
        state.copyWith(
          status: isConflict ? BookingStatus.initial : BookingStatus.failure,
          isSubmitting: false,
          hasScheduleConflict: isConflict,
          conflictMessage: isConflict ? _scheduleConflictMessage : null,
          errorMessage: isConflict ? null : message,
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
      final sequenceService = FirestoreSequenceService(firestore: db);
      final paymentCode = await sequenceService.generateNextCode('payments');
      final invoiceCode = await sequenceService.generateNextCode('invoices');
      final billing = await BillingCalculationService(
        firestore: db,
      ).calculate(patientId: event.patientId, originalAmount: event.amount);
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
        'status': requestedStatus,
        'paymentStatus': requestedStatus,
        'paymentCode': paymentCode,
        'invoiceCode': invoiceCode,
        ...billing.toFirestoreFields(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'method': requestedMethod,
        'paymentMethod': requestedMethod,
      });

      // 2. Create Invoice Record
      final invoiceRef = db.collection('Invoices').doc(invoiceId);
      batch.set(invoiceRef, {
        'id': invoiceId,
        'paymentId': paymentId,
        'appointmentId': event.appointmentId,
        'patientId': event.patientId,
        'tax': 0.0,
        ...billing.toFirestoreFields(),
        'paymentStatus': requestedStatus,
        'method': requestedMethod,
        'paymentMethod': requestedMethod,
        'paymentCode': paymentCode,
        'invoiceCode': invoiceCode,
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

      // Refresh appointment in state (for Ticket UI updates if any)
      if (state.createdAppointment != null) {
        final updated = HospitalAppointment(
          id: state.createdAppointment!.id,
          appointmentCode: state.createdAppointment!.appointmentCode,
          patientId: state.createdAppointment!.patientId,
          patientCode: state.createdAppointment!.patientCode,
          patientDOB: state.createdAppointment!.patientDOB,
          patientGender: state.createdAppointment!.patientGender,
          patientName: state.createdAppointment!.patientName,
          doctorId: state.createdAppointment!.doctorId,
          doctorCode: state.createdAppointment!.doctorCode,
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
          paymentStatus: requestedStatus,
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

  Future<void> _loadDoctorsForSelectedSession(
    Emitter<BookingState> emit, {
    DateTime? date,
    String? session,
  }) async {
    final selectedDepartment = state.selectedDepartment;
    final selectedDate = date ?? state.selectedDate;
    final selectedSession = session ?? state.selectedSession;

    if (selectedDepartment == null) return;

    if (selectedDate != null && _isPastDate(selectedDate)) {
      emit(
        state.copyWith(
          status: BookingStatus.failure,
          selectedDate: selectedDate,
          doctors: const [],
          schedules: const [],
          errorMessage:
              'Ngày khám đã qua nên không thể đặt lịch. Vui lòng chọn hôm nay hoặc một ngày sau hôm nay.',
          resetSelectedTime: true,
          clearSelectedDoctor: true,
        ),
      );
      return;
    }

    if (selectedDate == null || selectedSession == null) {
      emit(
        state.copyWith(
          status: BookingStatus.initial,
          selectedDate: selectedDate,
          selectedSession: selectedSession,
          doctors: const [],
          schedules: const [],
          takenQueueNumbers: const [],
          currentStep: 1,
          resetSelectedTime: true,
          clearSelectedDoctor: true,
          clearConflict: true,
          clearErrorMessage: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: BookingStatus.loading,
        selectedDate: selectedDate,
        selectedSession: selectedSession,
        doctors: const [],
        schedules: const [],
        takenQueueNumbers: const [],
        resetSelectedTime: true,
        clearSelectedDoctor: true,
      ),
    );

    try {
      final departmentDoctors = await getDoctorsByDept(selectedDepartment.id);
      final availableDoctors = <DoctorEntity>[];
      final availableSchedules = <ScheduleEntity>[];

      for (final doctor in departmentDoctors) {
        final schedules = await getDoctorSchedules(doctor.id, selectedDate);
        final matchingSchedules = schedules
            .where(
              (schedule) =>
                  schedule.isActive &&
                  schedule.id.isNotEmpty &&
                  schedule.availableSlots > 0 &&
                  _scheduleMatchesSession(schedule, selectedSession) &&
                  !_isScheduleFinished(selectedDate, schedule),
            )
            .toList();

        if (matchingSchedules.isEmpty) continue;
        availableDoctors.add(doctor);
        availableSchedules.addAll(matchingSchedules);
      }

      emit(
        state.copyWith(
          status: BookingStatus.initial,
          selectedDate: selectedDate,
          selectedSession: selectedSession,
          doctors: availableDoctors,
          schedules: availableSchedules,
          takenQueueNumbers: const [],
          currentStep: 1,
          resetSelectedTime: true,
          clearSelectedDoctor: true,
          clearConflict: true,
          clearErrorMessage: true,
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

  Future<bool> _hasConflictForSelection(
    DateTime date,
    ShiftEntity shift,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      return await hasScheduleConflict(
        patientId: user.uid,
        date: date,
        shiftId: shift.id,
        timeSlot: shift.startTime,
      );
    } catch (e) {
      debugPrint('Schedule conflict query failed, using local cache: $e');
      return state.patientAppointments.any((appointment) {
        if (!_isSameDay(appointment.appointmentDate, date)) return false;
        if (!_isHoldingAppointment(appointment)) return false;
        return appointment.shiftId == shift.id ||
            appointment.timeSlot.trim() == shift.startTime.trim();
      });
    }
  }

  bool _isHoldingAppointment(HospitalAppointment appointment) {
    final status = appointment.status.trim().toLowerCase();
    if (status == 'scheduled' ||
        status == 'confirmed' ||
        status == 'pending' ||
        status == 'cancel_requested' ||
        status.startsWith('waiting')) {
      return true;
    }
    if (status == 'completed') {
      return !_isAppointmentInPast(appointment);
    }
    return false;
  }

  bool _scheduleMatchesSession(ScheduleEntity schedule, String session) {
    return schedule.shiftId.toLowerCase().trim() ==
        session.toLowerCase().trim();
  }

  bool _isScheduleFinished(DateTime date, ScheduleEntity schedule) {
    final matchingShift = state.shifts.where(
      (shift) => shift.id == schedule.shiftId,
    );
    if (matchingShift.isEmpty) return false;
    return _isShiftFinished(date, matchingShift.first);
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
