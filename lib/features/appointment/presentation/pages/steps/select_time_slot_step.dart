import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:baitaplon/features/appointment/presentation/bloc/booking_bloc.dart';
import 'package:baitaplon/features/appointment/domain/entities/appointment_entities.dart';
import 'package:baitaplon/app/theme/app_colors.dart';

class SelectTimeSlotStep extends StatelessWidget {
  const SelectTimeSlotStep({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        final activeSchedules = state.schedules
            .where((schedule) => schedule.isActive && schedule.id.isNotEmpty)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () =>
                        context.read<BookingBloc>().add(StepBack()),
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                  ),
                  const Text(
                    'Chọn thời gian khám',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primaryDark,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bác sĩ ${state.selectedDoctor?.name} nhận khám vào các ca sau:',
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
            Expanded(
              child: activeSchedules.isEmpty
                  ? const Center(
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
                        }).toList(),
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
      margin: const EdgeInsets.only(bottom: 20, left: 4, right: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chọn số thứ tự khám (STT):',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: maxSlots,
            itemBuilder: (context, index) {
              final number = index + 1;
              final isTaken = state.takenQueueNumbers.contains(number);
              final isBookedByMe = state.selectedQueueNumber == number;

              return GestureDetector(
                onTap: isTaken
                    ? null
                    : () {
                        context.read<BookingBloc>().add(
                          SelectQueueNumber(number),
                        );
                      },
                child: Container(
                  decoration: BoxDecoration(
                    color: isBookedByMe
                        ? AppColors.primaryDark
                        : (isTaken ? Colors.grey.shade300 : Colors.white),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isBookedByMe
                          ? AppColors.primaryDark
                          : Colors.grey.shade200,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$number',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isBookedByMe
                          ? Colors.white
                          : (isTaken ? Colors.grey.shade500 : AppColors.text),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ShiftListItem extends StatelessWidget {
  final ShiftEntity shift;
  final ScheduleEntity schedule;
  final bool isSelected;
  final bool isFinished;
  final VoidCallback onTap;

  const _ShiftListItem({
    required this.shift,
    required this.schedule,
    required this.isSelected,
    required this.isFinished,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFull = schedule.availableSlots <= 0;
    final bool isUnavailable = isFull || isFinished;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isUnavailable ? null : onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.2)
                        : AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    shift.id == 'morning'
                        ? Icons.wb_sunny_rounded
                        : Icons.nights_stay_rounded,
                    color: isSelected ? Colors.white : AppColors.primaryDark,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ca ${shift.name}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${shift.startTime} - ${shift.endTime}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? Colors.white70 : AppColors.hint,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isFinished
                          ? 'Đã qua giờ'
                          : (isFull
                                ? 'Hết chỗ'
                                : '${schedule.availableSlots} chỗ trống'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isUnavailable
                                  ? AppColors.error
                                  : AppColors.success),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

bool _isShiftFinished(DateTime? date, ShiftEntity shift) {
  if (date == null || !_isSameDay(date, DateTime.now())) return false;

  final end = _timeOnDate(date, shift.endTime);
  if (end == null) return false;

  return !DateTime.now().isBefore(end);
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
