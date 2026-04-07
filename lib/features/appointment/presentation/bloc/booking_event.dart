part of 'booking_bloc.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => [];
}

class LoadInitialData extends BookingEvent {}

class SelectDepartment extends BookingEvent {
  final DepartmentEntity department;
  const SelectDepartment(this.department);

  @override
  List<Object?> get props => [department];
}

class SelectDoctorAndDate extends BookingEvent {
  final DoctorEntity doctor;
  final DateTime date;
  const SelectDoctorAndDate(this.doctor, this.date);

  @override
  List<Object?> get props => [doctor, date];
}

class SelectShift extends BookingEvent {
  final ShiftEntity shift;
  const SelectShift(this.shift);

  @override
  List<Object?> get props => [shift];
}

class SelectQueueNumber extends BookingEvent {
  final int queueNumber;
  const SelectQueueNumber(this.queueNumber);

  @override
  List<Object?> get props => [queueNumber];
}

class SelectPaymentMethod extends BookingEvent {
  final String method;
  const SelectPaymentMethod(this.method);

  @override
  List<Object?> get props => [method];
}

class UpdateSymptoms extends BookingEvent {
  final String symptoms;
  const UpdateSymptoms(this.symptoms);

  @override
  List<Object?> get props => [symptoms];
}

class ConfirmBooking extends BookingEvent {
  final String patientId;
  final String patientName;
  final String? insuranceNumber;
  const ConfirmBooking({
    required this.patientId,
    required this.patientName,
    this.insuranceNumber,
  });

  @override
  List<Object?> get props => [patientId, patientName, insuranceNumber];
}

class StepBack extends BookingEvent {}

class ResetBooking extends BookingEvent {}
