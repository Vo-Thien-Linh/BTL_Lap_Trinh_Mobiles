import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:baitaplon/features/appointment/presentation/bloc/booking_bloc.dart';
import 'package:baitaplon/features/appointment/domain/entities/appointment_entities.dart';
import 'package:baitaplon/app/theme/app_colors.dart';

class SelectDoctorDateStep extends StatefulWidget {
  final DoctorEntity? initialDoctor;
  const SelectDoctorDateStep({super.key, this.initialDoctor});

  @override
  State<SelectDoctorDateStep> createState() => _SelectDoctorDateStepState();
}

class _SelectDoctorDateStepState extends State<SelectDoctorDateStep> {
  @override
  void initState() {
    super.initState();
    if (widget.initialDoctor != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final state = context.read<BookingBloc>().state;
        if (state.selectedDate != null && state.selectedSession != null) {
          context.read<BookingBloc>().add(
            SelectDoctorForSession(widget.initialDoctor!),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        final waitingForFilters =
            state.selectedDate == null || state.selectedSession == null;
        final isLoading = state.status == BookingStatus.loading;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () =>
                        context.read<BookingBloc>().add(StepBack()),
                    icon: Icon(Icons.arrow_back_ios_rounded, size: 18),
                  ),
                  Expanded(
                    child: Text(
                      'Chọn ngày, buổi và bác sĩ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _DatePicker(selectedDate: state.selectedDate),
            _SessionPicker(selectedSession: state.selectedSession),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                'Bác sĩ có lịch trống',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : waitingForFilters
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Vui lòng chọn ngày khám và buổi khám để xem bác sĩ còn lịch.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.hint,
                          ),
                        ),
                      ),
                    )
                  : state.doctors.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Không có bác sĩ còn lịch trống trong ngày và buổi này.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.hint,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: state.doctors.length,
                      itemBuilder: (context, index) {
                        final doctor = state.doctors[index];
                        final schedules = state.schedules
                            .where((schedule) => schedule.doctorId == doctor.id)
                            .toList();
                        final availableSlots = schedules.fold<int>(
                          0,
                          (sum, schedule) => sum + schedule.availableSlots,
                        );
                        final isSelected =
                            state.selectedDoctor?.id == doctor.id;
                        return _DoctorListItem(
                          doctor: doctor,
                          availableSlots: availableSlots,
                          isSelected: isSelected,
                          onTap: () => context.read<BookingBloc>().add(
                            SelectDoctorForSession(doctor),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _DatePicker extends StatelessWidget {
  final DateTime? selectedDate;

  const _DatePicker({required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        physics: BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.fromLTRB(20, 10, 8, 0),
        itemCount: 14,
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final selected =
              selectedDate != null && DateUtils.isSameDay(date, selectedDate);

          return GestureDetector(
            onTap: () =>
                context.read<BookingBloc>().add(SelectAppointmentDate(date)),
            child: Container(
              width: 64,
              margin: EdgeInsets.only(right: 12, top: 4, bottom: 4),
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white70 : AppColors.hint,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    DateFormat('dd').format(date),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.white : AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SessionPicker extends StatelessWidget {
  final String? selectedSession;

  const _SessionPicker({required this.selectedSession});

  @override
  Widget build(BuildContext context) {
    const sessions = [
      _SessionOption(
        id: 'morning',
        label: 'Buổi sáng',
        time: '07:30 - 11:30',
        icon: Icons.wb_sunny_rounded,
      ),
      _SessionOption(
        id: 'afternoon',
        label: 'Buổi chiều',
        time: '13:30 - 17:00',
        icon: Icons.nights_stay_rounded,
      ),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: sessions.map((option) {
          final selected = selectedSession == option.id;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 10),
              child: InkWell(
                onTap: () => context.read<BookingBloc>().add(
                  SelectAppointmentSession(option.id),
                ),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primaryDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected
                          ? AppColors.primaryDark
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        option.icon,
                        color: selected ? Colors.white : AppColors.primaryDark,
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: selected ? Colors.white : AppColors.text,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              option.time,
                              style: TextStyle(
                                fontSize: 11,
                                color: selected
                                    ? Colors.white70
                                    : AppColors.hint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SessionOption {
  final String id;
  final String label;
  final String time;
  final IconData icon;

  const _SessionOption({
    required this.id,
    required this.label,
    required this.time,
    required this.icon,
  });
}

class _DoctorListItem extends StatelessWidget {
  final DoctorEntity doctor;
  final int availableSlots;
  final bool isSelected;
  final VoidCallback onTap;

  _DoctorListItem({
    required this.doctor,
    required this.availableSlots,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final doctorName = doctor.name.trim().isNotEmpty
        ? doctor.name.trim()
        : 'Bác sĩ chưa cập nhật tên';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.secondary : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? AppColors.primaryDark : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.primary.withOpacity(0.2),
          backgroundImage: doctor.imageUrl != null
              ? NetworkImage(doctor.imageUrl!)
              : null,
          child: doctor.imageUrl == null
              ? Icon(Icons.person_outline_rounded, color: AppColors.primaryDark)
              : null,
        ),
        title: Text(
          doctorName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: AppColors.text,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              '${doctor.specialization} - ${doctor.yearsOfExperience} năm KN',
              style: TextStyle(fontSize: 13, color: AppColors.hint),
            ),
            SizedBox(height: 4),
            Text(
              'Còn $availableSlots chỗ - Phí khám: ${NumberFormat.decimalPattern().format(doctor.consultationFee)} đ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle_rounded, color: AppColors.primaryDark)
            : Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.hint,
              ),
      ),
    );
  }
}
