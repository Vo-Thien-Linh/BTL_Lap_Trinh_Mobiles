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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.read<BookingBloc>().add(StepBack()),
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
                    const Icon(Icons.info_outline_rounded, color: AppColors.primaryDark),
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
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  ...state.shifts.map((shift) {
                    final schedule = state.schedules.firstWhere(
                      (s) => s.shiftId == shift.id,
                      orElse: () => ScheduleEntity(
                        id: '',
                        doctorId: '',
                        departmentId: '',
                        shiftId: shift.id,
                        date: DateTime.now(),
                        availableSlots: shift.maxSlots,
                        isActive: true,
                      ),
                    );

                    final isSelected = state.selectedShift?.id == shift.id;
                    
                    return Column(
                      children: [
                        _ShiftListItem(
                          shift: shift,
                          schedule: schedule,
                          isSelected: isSelected,
                          onTap: () => context.read<BookingBloc>().add(SelectShift(shift)),
                        ),
                        if (isSelected) _buildQueueNumberGrid(context, state, shift),
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

  Widget _buildQueueNumberGrid(BuildContext context, BookingState state, ShiftEntity shift) {
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
            itemCount: shift.maxSlots,
            itemBuilder: (context, index) {
              final number = index + 1;
              final isTaken = state.takenQueueNumbers.contains(number);
              final isBookedByMe = state.selectedQueueNumber == number;
              
              return GestureDetector(
                onTap: isTaken ? null : () {
                  context.read<BookingBloc>().add(SelectQueueNumber(number));
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isBookedByMe 
                        ? AppColors.primaryDark 
                        : (isTaken ? Colors.grey.shade300 : Colors.white),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isBookedByMe ? AppColors.primaryDark : Colors.grey.shade200,
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
  final VoidCallback onTap;

  const _ShiftListItem({
    required this.shift,
    required this.schedule,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFull = schedule.availableSlots <= 0;

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
          onTap: isFull ? null : onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withOpacity(0.2) : AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    shift.id == 'morning' ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
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
                      isFull ? 'Hết chỗ' : '${schedule.availableSlots} chỗ trống',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isFull ? AppColors.error : AppColors.success),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
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
