import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/appointment_entities.dart';
import '../../domain/usecases/appointment_usecases.dart';
import '../../../../shared/utils/id_formatter.dart';

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

      // AUTO-SEED: If Firestore is empty, we seed it automatically for the user
      if (departments.isEmpty) {
        await _autoSeedFirestore();
        departments = await getDepartments();
      }

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

  Future<void> _autoSeedFirestore() async {
    final db = FirebaseFirestore.instance;
    final batch = db.batch();

    // 1. Departments (Added more)
    final depts = [
      {
        'id': 'tim_mach',
        'name': 'Tim mạch',
        'desc': 'Khoa chuyên tim mạch',
        'loc': 'Tầng 2',
      },
      {
        'id': 'nhi_khoa',
        'name': 'Nhi khoa',
        'desc': 'Chăm sóc trẻ em',
        'loc': 'Tầng 1',
      },
      {
        'id': 'noi_tiet',
        'name': 'Nội tiết',
        'desc': 'Điều trị nội tiết',
        'loc': 'Tầng 3',
      },
      {
        'id': 'da_lieu',
        'name': 'Da liễu',
        'desc': 'Chăm sóc da',
        'loc': 'Tầng 4',
      },
      {
        'id': 'rang_ham_mat',
        'name': 'Răng Hàm Mặt',
        'desc': 'Nha khoa chuyên sâu',
        'loc': 'Tầng 1',
      },
      {
        'id': 'tai_mui_hong',
        'name': 'Tai Mũi Họng',
        'desc': 'Khám tai mũi họng',
        'loc': 'Tầng 2',
      },
      {'id': 'mat', 'name': 'Mắt', 'desc': 'Khoa mắt', 'loc': 'Tầng 5'},
    ];

    for (var dept in depts) {
      batch.set(
        db.collection('Departments').doc(dept['id'] as String),
        {
          'name': dept['name'],
          'description': dept['desc'],
          'location': dept['loc'],
          'phone': '0123456789',
        },
        SetOptions(merge: true),
      );
    }

    // 2. Doctors (Comprehensive list)
    final doctors = [
      {
        'id': 'dr_tim_1',
        'name': 'BS Nguyễn Văn A',
        'dept': 'tim_mach',
        'fee': 500000.0,
      },
      {
        'id': 'dr_tim_2',
        'name': 'BS Phạm Minh B',
        'dept': 'tim_mach',
        'fee': 450000.0,
      },
      {
        'id': 'dr_nhi_1',
        'name': 'BS Trần Thị C',
        'dept': 'nhi_khoa',
        'fee': 350000.0,
      },
      {
        'id': 'dr_nhi_2',
        'name': 'BS Lê Hoàng D',
        'dept': 'nhi_khoa',
        'fee': 300000.0,
      },
      {
        'id': 'dr_da_1',
        'name': 'BS Hoàng Gia E',
        'dept': 'da_lieu',
        'fee': 600000.0,
      },
      {
        'id': 'dr_da_2',
        'name': 'BS Vũ Đức F',
        'dept': 'da_lieu',
        'fee': 550000.0,
      },
      {
        'id': 'dr_mat_1',
        'name': 'BS Đặng Minh G',
        'dept': 'mat',
        'fee': 400000.0,
      },
      {
        'id': 'dr_rhm_1',
        'name': 'BS Phan Thanh H',
        'dept': 'rang_ham_mat',
        'fee': 400000.0,
      },
      {
        'id': 'dr_tmh_1',
        'name': 'BS Ngô Bảo K',
        'dept': 'tai_mui_hong',
        'fee': 380000.0,
      },
      {
        'id': 'dr_nt_1',
        'name': 'BS Lý Tiểu L',
        'dept': 'noi_tiet',
        'fee': 420000.0,
      },
    ];

    for (var dr in doctors) {
      final doctorId = dr['id'] as String;
      batch.set(db.collection('Doctors').doc(dr['id'] as String), {
        'name': dr['name'],
        'specialization': dr['dept'],
        'departmentId': dr['dept'],
        'yearsOfExperience': 10 + (doctors.indexOf(dr) % 5),
        'consultationFee': dr['fee'],
        'isActive': true,
        'licenseNumber': 'BS${(dr['id'] as String).toUpperCase()}',
        'doctorCode': IdFormatter.format(prefix: 'DOC', rawId: doctorId),
      }, SetOptions(merge: true));

      // 3. Create Schedules for each doctor (Next 7 days)
      for (int i = 0; i < 7; i++) {
        final date = DateTime.now().add(Duration(days: i));
        final dateStr = '${date.year}-${date.month}-${date.day}';

        // Morning shift
        batch.set(
          db.collection('DoctorSchedules').doc('${dr['id']}_$dateStr\_morning'),
          {
            'doctorId': dr['id'],
            'scheduleDate': Timestamp.fromDate(
              DateTime(date.year, date.month, date.day),
            ), // FIXED: Use scheduleDate
            'shiftId': 'morning',
            'isAvailable': true,
            'maxSlots': 20,
          },
          SetOptions(merge: true),
        );

        // Afternoon shift
        batch.set(
          db
              .collection('DoctorSchedules')
              .doc('${dr['id']}_$dateStr\_afternoon'),
          {
            'doctorId': dr['id'],
            'scheduleDate': Timestamp.fromDate(
              DateTime(date.year, date.month, date.day),
            ), // FIXED: Use scheduleDate
            'shiftId': 'afternoon',
            'isAvailable': true,
            'maxSlots': 20,
          },
          SetOptions(merge: true),
        );
      }
    }

    // 3. Shifts
    final shiftList = [
      {
        'id': 'morning',
        'name': 'Sáng',
        'start': '07:30',
        'end': '11:30',
        'max': 20,
      },
      {
        'id': 'afternoon',
        'name': 'Chiều',
        'start': '13:30',
        'end': '17:00',
        'max': 20,
      },
    ];
    for (var s in shiftList) {
      batch.set(
        db.collection('Shifts').doc(s['id'] as String),
        s,
        SetOptions(merge: true),
      );
    }

    await batch.commit();
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
      // Logic 1: Check if patient already has active appointment with THIS doctor
      final hasDuplicateDoctor = state.patientAppointments.any(
        (app) => app.doctorId == event.doctor.id,
      );

      if (hasDuplicateDoctor) {
        emit(
          state.copyWith(
            status: BookingStatus.failure,
            errorMessage:
                'Bạn đang có lịch hẹn chưa hoàn thành với bác sĩ ${event.doctor.name}. Vui lòng hoàn thành trước khi đặt thêm.',
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
      state.copyWith(status: BookingStatus.loading, selectedShift: event.shift),
    );
    try {
      // Logic 2: Check for time slot conflict (Same DATE + Same SHIFT)
      final conflict = state.patientAppointments.where((app) {
        final isSameDate =
            app.appointmentDate.year == state.selectedDate!.year &&
            app.appointmentDate.month == state.selectedDate!.month &&
            app.appointmentDate.day == state.selectedDate!.day;
        return isSameDate && app.shiftId == event.shift.id;
      }).toList();

      if (conflict.isNotEmpty) {
        final conflictingDept = conflict.first.departmentName;
        emit(
          state.copyWith(
            status: BookingStatus.failure,
            errorMessage:
                'Bạn đã có lịch khám tại khoa $conflictingDept vào thời gian này. Vui lóng chọn ca khác.',
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
        state.selectedShift == null) {
      return;
    }

    emit(state.copyWith(status: BookingStatus.loading));
    try {
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
        patientName: event.patientName,
        doctorId: state.selectedDoctor!.id,
        doctorName: state.selectedDoctor!.name,
        departmentId: state.selectedDepartment!.id,
        departmentName: state.selectedDepartment!.name,
        appointmentDate: state.selectedDate!,
        shiftId: state.selectedShift!.id,
        timeSlot: state.selectedShift!.startTime,
        queueNumber: queueNumber,
        roomNumber: 'Phòng ${state.selectedDepartment!.location}', // Mock logic
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

  void _onStepBack(StepBack event, Emitter<BookingState> emit) {
    if (state.currentStep > 0) {
      emit(state.copyWith(currentStep: state.currentStep - 1));
    }
  }

  void _onResetBooking(ResetBooking event, Emitter<BookingState> emit) {
    emit(const BookingState());
    add(LoadInitialData());
  }
}
