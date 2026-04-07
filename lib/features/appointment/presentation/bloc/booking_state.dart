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
  final ShiftEntity? selectedShift;
  final int? selectedQueueNumber;
  final List<int> takenQueueNumbers;
  final String selectedPaymentMethod;
  final String symptoms;
  
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
    this.selectedShift,
    this.selectedQueueNumber,
    this.takenQueueNumbers = const [],
    this.selectedPaymentMethod = 'CASH',
    this.symptoms = '',
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
    ShiftEntity? selectedShift,
    int? selectedQueueNumber,
    List<int>? takenQueueNumbers,
    String? selectedPaymentMethod,
    String? symptoms,
    HospitalAppointment? createdAppointment,
    String? errorMessage,
    List<HospitalAppointment>? patientAppointments,
  }) {
    return BookingState(
      status: status ?? this.status,
      currentStep: currentStep ?? this.currentStep,
      departments: departments ?? this.departments,
      doctors: doctors ?? this.doctors,
      schedules: schedules ?? this.schedules,
      shifts: shifts ?? this.shifts,
      selectedDepartment: selectedDepartment ?? this.selectedDepartment,
      selectedDoctor: selectedDoctor ?? this.selectedDoctor,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedShift: selectedShift ?? this.selectedShift,
      selectedQueueNumber: selectedQueueNumber ?? this.selectedQueueNumber,
      takenQueueNumbers: takenQueueNumbers ?? this.takenQueueNumbers,
      selectedPaymentMethod: selectedPaymentMethod ?? this.selectedPaymentMethod,
      symptoms: symptoms ?? this.symptoms,
      createdAppointment: createdAppointment ?? this.createdAppointment,
      errorMessage: errorMessage ?? this.errorMessage,
      patientAppointments: patientAppointments ?? this.patientAppointments,
    );
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
        selectedShift,
        selectedQueueNumber,
        takenQueueNumbers,
        selectedPaymentMethod,
        symptoms,
        createdAppointment,
        errorMessage,
      ];
}
