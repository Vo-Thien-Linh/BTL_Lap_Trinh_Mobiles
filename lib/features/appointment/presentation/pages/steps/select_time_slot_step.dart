import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../domain/entities/appointment_entities.dart';
import '../../bloc/booking_bloc.dart';

class SelectTimeSlotStep extends StatelessWidget {
  const SelectTimeSlotStep({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        final activeSchedules = state.schedules
            .where(
              (schedule) =>
                  schedule.isActive &&
                  schedule.id.isNotEmpty &&
                  schedule.doctorId == state.selectedDoctor?.id,
            )
            .toList();

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
                      'Chọn ca và số thứ tự khám',
                      maxLines: 2,
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
            Padding(
              padding: EdgeInsets.all(20),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primaryDark,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bác sĩ ${state.selectedDoctor?.name ?? ''} nhận khám vào các ca còn slot dưới đây.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (state.hasScheduleConflict)
              Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: _buildConflictPanel(
                  state.conflictMessage ??
                      'Bạn đã có lịch khám trong ca này. Vui lòng chọn ngày, buổi hoặc bác sĩ khác.',
                ),
              ),
            Expanded(
              child: activeSchedules.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Bác sĩ chưa có lịch làm việc vào ngày này. Vui lòng chọn ngày khác hoặc bác sĩ khác.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.hint,
                          ),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        ...activeSchedules.map((schedule) {
                          final shift = state.shifts.firstWhere(
                            (shift) => shift.id == schedule.shiftId,
                            orElse: () => ShiftEntity(
                              id: schedule.shiftId,
                              name: schedule.shiftId,
                              startTime: '',
                              endTime: '',
                              maxSlots: schedule.maxSlots,
                            ),
                          );
                          final isSelected =
                              state.selectedSchedule?.id == schedule.id;
                          final isFinished = _isShiftFinished(
                            state.selectedDate,
                            shift,
                          );

                          return Column(
                            children: [
                              _ShiftListItem(
                                shift: shift,
                                schedule: schedule,
                                isSelected: isSelected,
                                isFinished: isFinished,
                                onTap: () => context.read<BookingBloc>().add(
                                  SelectShift(shift, schedule: schedule),
                                ),
                              ),
                              if (isSelected)
                                _buildQueueNumberGrid(
                                  context,
                                  state,
                                  shift,
                                  schedule,
                                ),
                            ],
                          );
                        }),
                        const SizedBox(height: 20),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQueueNumberGrid(
    BuildContext context,
    BookingState state,
    ShiftEntity shift,
    ScheduleEntity schedule,
  ) {
    final maxSlots = schedule.maxSlots > 0 ? schedule.maxSlots : shift.maxSlots;

    return Container(
      margin: EdgeInsets.only(bottom: 20, left: 4, right: 4),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chọn số thứ tự khám (STT):',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Thời gian chỉ là dự kiến và có thể thay đổi theo thực tế khám.',
            style: TextStyle(fontSize: 12, color: AppColors.hint),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.45,
            ),
            itemCount: maxSlots,
            itemBuilder: (context, index) {
              final number = index + 1;
              final isTaken = state.takenQueueNumbers.contains(number);
              final isBookedByMe = state.selectedQueueNumber == number;
              final timeRange = _estimatedTimeRange(shift, number, maxSlots);

              return InkWell(
                onTap: isTaken
                    ? null
                    : () {
                        context.read<BookingBloc>().add(
                          SelectQueueNumber(number),
                        );
                      },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: isBookedByMe
                        ? AppColors.primaryDark
                        : (isTaken ? Colors.grey.shade300 : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isBookedByMe
                          ? AppColors.primaryDark
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'STT $number',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: isBookedByMe
                              ? Colors.white
                              : (isTaken
                                    ? Colors.grey.shade500
                                    : AppColors.text),
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        timeRange,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: isBookedByMe
                              ? Colors.white.withValues(alpha: 0.9)
                              : (isTaken
                                    ? Colors.grey.shade500
                                    : AppColors.hint),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConflictPanel(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _estimatedTimeRange(
    ShiftEntity shift,
    int queueNumber,
    int slotCount,
  ) {
    final start = _timeOnDate(shift.startTime);
    final end = _timeOnDate(shift.endTime);
    if (start == null || end == null || !end.isAfter(start)) {
      return shift.startTime;
    }

    final safeSlotCount = slotCount <= 0 ? 1 : slotCount;
    final slotMinutes = end.difference(start).inMinutes / safeSlotCount;
    final slotStart = start.add(
      Duration(minutes: ((queueNumber - 1) * slotMinutes).round()),
    );
    final slotEnd = start.add(
      Duration(minutes: (queueNumber * slotMinutes).round()),
    );

    return '${DateFormat('HH:mm').format(slotStart)} - ${DateFormat('HH:mm').format(slotEnd)}';
  }

  DateTime? _timeOnDate(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  bool _isShiftFinished(DateTime? selectedDate, ShiftEntity shift) {
    if (selectedDate == null) return false;
    final now = DateTime.now();
    final selectedDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    if (selectedDay.isAfter(today)) return false;
    if (selectedDay.isBefore(today)) return true;

    final end = _timeOnDate(shift.endTime);
    return end != null && now.isAfter(end);
  }
}

class _ShiftListItem extends StatelessWidget {
  const _ShiftListItem({
    required this.shift,
    required this.schedule,
    required this.isSelected,
    required this.isFinished,
    required this.onTap,
  });

  final ShiftEntity shift;
  final ScheduleEntity schedule;
  final bool isSelected;
  final bool isFinished;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isAvailable =
        schedule.availableSlots > 0 && schedule.isActive && !isFinished;

    return InkWell(
      onTap: isAvailable ? onTap : null,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primaryDark : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              color: isSelected ? Colors.white : AppColors.primaryDark,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${shift.name} (${shift.startTime} - ${shift.endTime})',
                    maxLines: 2,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    isFinished
                        ? 'Ca này đã qua'
                        : 'Còn ${schedule.availableSlots} slot',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.82)
                          : AppColors.hint,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.chevron_right_rounded,
              color: isSelected ? Colors.white : AppColors.hint,
            ),
          ],
        ),
      ),
    );
  }
}
