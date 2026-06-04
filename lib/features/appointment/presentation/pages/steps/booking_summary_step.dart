import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../shared/widgets/custom_button.dart';
import '../../bloc/booking_bloc.dart';

class BookingSummaryStep extends StatefulWidget {
  const BookingSummaryStep({super.key});

  @override
  State<BookingSummaryStep> createState() => _BookingSummaryStepState();
}

class _BookingSummaryStepState extends State<BookingSummaryStep> {
  final TextEditingController _symptomsController = TextEditingController();

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () =>
                        context.read<BookingBloc>().add(StepBack()),
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                  ),
                  const Expanded(
                    child: Text(
                      'Xác nhận đặt lịch',
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
              const SizedBox(height: 10),
              _buildSummaryCard(state),
              const SizedBox(height: 20),
              const Text(
                'Triệu chứng / Lý do khám',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _symptomsController,
                maxLines: 3,
                onChanged: (val) =>
                    context.read<BookingBloc>().add(UpdateSymptoms(val)),
                decoration: InputDecoration(
                  hintText: 'Mô tả ngắn gọn tình trạng sức khỏe của bạn...',
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: AppColors.hint,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _buildArrivalNote(),
              const SizedBox(height: 20),
              if (state.hasScheduleConflict)
                _buildConflictPanel(
                  state.conflictMessage ??
                      'Bạn đã có lịch khám trong ca này. Vui lòng chọn ngày, buổi hoặc bác sĩ khác.',
                ),
              if (state.hasScheduleConflict) const SizedBox(height: 16),
              CustomButton(
                text: 'Xác nhận đặt lịch',
                isLoading: state.isSubmitting || state.isCheckingConflict,
                onPressed: state.canSubmit
                    ? () {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          context.read<BookingBloc>().add(
                            ConfirmBooking(
                              patientId: user.uid,
                              patientName: user.displayName ?? 'Người bệnh',
                            ),
                          );
                        }
                      }
                    : null,
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(BookingState state) {
    final estimatedTime = _estimatedTimeRange(state);
    final fee = state.selectedDoctor?.consultationFee ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            Icons.local_hospital_rounded,
            'Chuyên khoa',
            state.selectedDepartment?.name ?? '-',
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            Icons.person_rounded,
            'Bác sĩ',
            state.selectedDoctor?.name ?? '-',
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            Icons.calendar_month_rounded,
            'Ngày khám',
            state.selectedDate != null
                ? DateFormat('dd/MM/yyyy').format(state.selectedDate!)
                : '-',
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            Icons.wb_sunny_outlined,
            'Buổi khám',
            state.selectedShift?.name ?? state.selectedSession ?? '-',
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            Icons.format_list_numbered_rounded,
            'Số thứ tự khám',
            state.selectedQueueNumber == null
                ? '-'
                : 'STT ${state.selectedQueueNumber}',
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            Icons.access_time_filled_rounded,
            'Thời gian khám dự kiến',
            estimatedTime,
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            Icons.payments_outlined,
            'Chi phí khám dự kiến',
            '${NumberFormat.decimalPattern().format(fee)} đ',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryDark, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppColors.hint),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildArrivalNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.access_time_filled_rounded, color: Color(0xFFC2410C)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Bạn nên đến sớm hơn khoảng 30 phút để đảm bảo việc khám diễn ra thuận lợi.',
              style: TextStyle(
                color: Color(0xFF9A3412),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictPanel(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
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

  String _estimatedTimeRange(BookingState state) {
    final shift = state.selectedShift;
    final queueNumber = state.selectedQueueNumber;
    if (shift == null) return '-';

    if (queueNumber == null) {
      return '${shift.startTime} - ${shift.endTime}';
    }

    final start = _timeOnDate(shift.startTime);
    final end = _timeOnDate(shift.endTime);
    if (start == null || end == null || !end.isAfter(start)) {
      return shift.startTime;
    }

    final slotCount = state.selectedSchedule?.maxSlots ?? shift.maxSlots;
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
}
