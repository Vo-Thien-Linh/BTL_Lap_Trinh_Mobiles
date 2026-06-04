part of 'booking_bloc.dart';

enum BookingStatus { initial, loading, success, failure }

class BookingState extends Equatable {
  final BookingStatus status;
  final int currentStep;
  final List<DepartmentEntity> departments;
  final List<DoctorEntity> doctors;
  final List<ScheduleEntity> schedules;
  final List<ShiftEntity> shifts;

  final DepartmentEntity? selectedDepartment;
  final DoctorEntity? selectedDoctor;
  final DateTime? selectedDate;
  final ScheduleEntity? selectedSchedule;
  final ShiftEntity? selectedShift;
  final int? selectedQueueNumber;
  final String? selectedSession;
  final List<int> takenQueueNumbers;
  final String selectedPaymentMethod;
  final String symptoms;
  final bool hasScheduleConflict;
  final String? conflictMessage;
  final bool isSubmitting;
  final bool isCheckingConflict;

  final HospitalAppointment? createdAppointment;
  final String? errorMessage;
  final List<HospitalAppointment> patientAppointments;

  const BookingState({
    this.status = BookingStatus.initial,
    this.currentStep = 0,
    this.departments = const [],
    this.doctors = const [],
    this.schedules = const [],
    this.shifts = const [],
    this.selectedDepartment,
    this.selectedDoctor,
    this.selectedDate,
    this.selectedSchedule,
    this.selectedShift,
    this.selectedQueueNumber,
    this.selectedSession,
    this.takenQueueNumbers = const [],
    this.selectedPaymentMethod = 'CASH',
    this.symptoms = '',
    this.hasScheduleConflict = false,
    this.conflictMessage,
    this.isSubmitting = false,
    this.isCheckingConflict = false,
    this.createdAppointment,
    this.errorMessage,
    this.patientAppointments = const [],
  });

  BookingState copyWith({
    BookingStatus? status,
    int? currentStep,
    List<DepartmentEntity>? departments,
    List<DoctorEntity>? doctors,
    List<ScheduleEntity>? schedules,
    List<ShiftEntity>? shifts,
    DepartmentEntity? selectedDepartment,
    DoctorEntity? selectedDoctor,
    DateTime? selectedDate,
    ScheduleEntity? selectedSchedule,
    ShiftEntity? selectedShift,
    int? selectedQueueNumber,
    String? selectedSession,
    List<int>? takenQueueNumbers,
    String? selectedPaymentMethod,
    String? symptoms,
    bool? hasScheduleConflict,
    String? conflictMessage,
    bool? isSubmitting,
    bool? isCheckingConflict,
    HospitalAppointment? createdAppointment,
    String? errorMessage,
    List<HospitalAppointment>? patientAppointments,
    bool resetSelectedTime = false,
    bool clearSelectedDoctor = false,
    bool clearSelectedDate = false,
    bool clearSelectedSession = false,
    bool clearSelectedQueueNumber = false,
    bool clearConflict = false,
    bool clearErrorMessage = false,
  }) {
    return BookingState(
      status: status ?? this.status,
      currentStep: currentStep ?? this.currentStep,
      departments: departments ?? this.departments,
      doctors: doctors ?? this.doctors,
      schedules: schedules ?? this.schedules,
      shifts: shifts ?? this.shifts,
      selectedDepartment: selectedDepartment ?? this.selectedDepartment,
      selectedDoctor: clearSelectedDoctor
          ? null
          : selectedDoctor ?? this.selectedDoctor,
      selectedDate: clearSelectedDate
          ? null
          : selectedDate ?? this.selectedDate,
      selectedSchedule: resetSelectedTime
          ? null
          : selectedSchedule ?? this.selectedSchedule,
      selectedShift: resetSelectedTime
          ? null
          : selectedShift ?? this.selectedShift,
      selectedQueueNumber: resetSelectedTime || clearSelectedQueueNumber
          ? null
          : selectedQueueNumber ?? this.selectedQueueNumber,
      selectedSession: clearSelectedSession
          ? null
          : selectedSession ?? this.selectedSession,
      takenQueueNumbers: takenQueueNumbers ?? this.takenQueueNumbers,
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
      symptoms: symptoms ?? this.symptoms,
      hasScheduleConflict: clearConflict
          ? false
          : hasScheduleConflict ?? this.hasScheduleConflict,
      conflictMessage: clearConflict
          ? null
          : conflictMessage ?? this.conflictMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isCheckingConflict: isCheckingConflict ?? this.isCheckingConflict,
      createdAppointment: createdAppointment ?? this.createdAppointment,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      patientAppointments: patientAppointments ?? this.patientAppointments,
    );
  }

  bool get hasSelectedAvailableSlot {
    final schedule = selectedSchedule;
    final queueNumber = selectedQueueNumber;
    return schedule != null &&
        schedule.isActive &&
        schedule.availableSlots > 0 &&
        queueNumber != null &&
        queueNumber > 0 &&
        !takenQueueNumbers.contains(queueNumber);
  }

  bool get hasRequiredBookingSelection {
    return selectedDepartment != null &&
        selectedDate != null &&
        selectedSession != null &&
        selectedDoctor != null &&
        selectedShift != null &&
        selectedSchedule != null &&
        selectedQueueNumber != null;
  }

  bool get canSubmit {
    return hasRequiredBookingSelection &&
        hasSelectedAvailableSlot &&
        !hasScheduleConflict &&
        !isSubmitting &&
        !isCheckingConflict;
  }

  @override
  List<Object?> get props => [
    status,
    currentStep,
    departments,
    doctors,
    schedules,
    shifts,
    selectedDepartment,
    selectedDoctor,
    selectedDate,
    selectedSchedule,
    selectedShift,
    selectedQueueNumber,
    selectedSession,
    takenQueueNumbers,
    selectedPaymentMethod,
    symptoms,
    hasScheduleConflict,
    conflictMessage,
    isSubmitting,
    isCheckingConflict,
    createdAppointment,
    errorMessage,
  ];
}
