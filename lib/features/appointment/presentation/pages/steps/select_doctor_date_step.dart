import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:baitaplon/features/appointment/presentation/bloc/booking_bloc.dart';
import 'package:baitaplon/features/appointment/domain/entities/appointment_entities.dart';
import 'package:baitaplon/app/theme/app_colors.dart';

class SelectDoctorDateStep extends StatefulWidget {
  const SelectDoctorDateStep({super.key});

  @override
  State<SelectDoctorDateStep> createState() => _SelectDoctorDateStepState();
}

class _SelectDoctorDateStepState extends State<SelectDoctorDateStep> {
  DateTime _selectedDate = DateTime.now();
  DoctorEntity? _selectedDoctor;

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
                    'Chọn bác sĩ & ngày khám',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
            _buildDatePicker(),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                'Bác sĩ khả dụng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ),
            Expanded(
              child: state.doctors.isEmpty
                  ? const Center(child: Text('Không có bác sĩ khả dụng cho khoa này.'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: state.doctors.length,
                      itemBuilder: (context, index) {
                        final doctor = state.doctors[index];
                        final isSelected = _selectedDoctor?.id == doctor.id;
                        return _DoctorListItem(
                          doctor: doctor,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() => _selectedDoctor = doctor);
                            context.read<BookingBloc>().add(
                                  SelectDoctorAndDate(doctor, _selectedDate),
                                );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: SizedBox(
            height: 90,
            child: ShaderMask(
              shaderCallback: (Rect rect) {
                return const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.purple,
                    Colors.transparent,
                    Colors.transparent,
                    Colors.purple
                  ],
                  stops: [0.0, 0.05, 0.95, 1.0],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstOut,
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: 14,
                itemBuilder: (context, index) {
                  final date = DateTime.now().add(Duration(days: index));
                  final isSelected = DateUtils.isSameDay(date, _selectedDate);
                  final dayName = DateFormat('EEE').format(date);
                  final dayNum = DateFormat('dd').format(date);

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedDate = date);
                      if (_selectedDoctor != null) {
                        context.read<BookingBloc>().add(
                              SelectDoctorAndDate(_selectedDoctor!, date),
                            );
                      }
                    },
                    child: Container(
                      width: 64,
                      margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryDark : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white70 : AppColors.hint,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dayNum,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppColors.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DoctorListItem extends StatelessWidget {
  final DoctorEntity doctor;
  final bool isSelected;
  final VoidCallback onTap;

  const _DoctorListItem({
    required this.doctor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.primary.withOpacity(0.2),
          backgroundImage: doctor.imageUrl != null ? NetworkImage(doctor.imageUrl!) : null,
          child: doctor.imageUrl == null
              ? const Icon(Icons.person_outline_rounded, color: AppColors.primaryDark)
              : null,
        ),
        title: Text(
          doctor.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: AppColors.text,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${doctor.specialization} • ${doctor.yearsOfExperience} năm KN',
              style: const TextStyle(fontSize: 13, color: AppColors.hint),
            ),
            const SizedBox(height: 4),
            Text(
              'Phí khám: ${NumberFormat.decimalPattern().format(doctor.consultationFee)} đ',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryDark)
            : const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.hint),
      ),
    );
  }
}
