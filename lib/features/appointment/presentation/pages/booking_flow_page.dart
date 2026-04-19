import 'package:flutter/material.dart';
import '../../domain/entities/appointment_entities.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:baitaplon/app/theme/app_colors.dart';
import 'package:baitaplon/config/service_locator.dart';
import 'package:baitaplon/features/appointment/presentation/bloc/booking_bloc.dart';
import 'package:baitaplon/features/appointment/presentation/pages/steps/select_department_step.dart';
import 'package:baitaplon/features/appointment/presentation/pages/steps/select_doctor_date_step.dart';
import 'package:baitaplon/features/appointment/presentation/pages/steps/select_time_slot_step.dart';
import 'package:baitaplon/features/appointment/presentation/pages/steps/booking_summary_step.dart';
import 'package:baitaplon/features/appointment/presentation/pages/steps/booking_ticket_step.dart';

class BookingFlowPage extends StatelessWidget {
  final DepartmentEntity? initialDepartment;
  final DoctorEntity? initialDoctor;

  const BookingFlowPage({
    super.key,
    this.initialDepartment,
    this.initialDoctor,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = getIt<BookingBloc>()..add(LoadInitialData());
        
        // If we have a department, select it to skip step 0
        if (initialDepartment != null) {
          bloc.add(SelectDepartment(initialDepartment!));
          
          // Note: If we have a doctor too, we'll need to ensure the Bloc 
          // knows about it. Currently, SelectDepartment only takes a dept.
          // We'll handle this by letting the Bloc stay at Step 1 with doctor pre-filled
          // OR we could add a specialized initiation event if needed.
          // For now, this logic will land us on Step 1.
        }
        
        return bloc;
      },
      child: BookingFlowView(initialDoctor: initialDoctor),
    );
  }
}

class BookingFlowView extends StatefulWidget {
  final DoctorEntity? initialDoctor;
  const BookingFlowView({super.key, this.initialDoctor});

  @override
  State<BookingFlowView> createState() => _BookingFlowViewState();
}

class _BookingFlowViewState extends State<BookingFlowView> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookingBloc, BookingState>(
      listenWhen: (prev, curr) => prev.currentStep != curr.currentStep || prev.status != curr.status,
      listener: (context, state) {
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            state.currentStep,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
          );
        }

        if (state.status == BookingStatus.failure && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${state.errorMessage}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: AppColors.text),
          ),
          centerTitle: true,
          title: const Text(
            'ĐẶT LỊCH KHÁM',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: 1.2,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildProgressIndicator(),
              const SizedBox(height: 10),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    const SelectDepartmentStep(),
                    SelectDoctorDateStep(initialDoctor: widget.initialDoctor),
                    const SelectTimeSlotStep(),
                    BookingSummaryStep(),
                    BookingTicketStep(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        if (state.currentStep == 4) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: List.generate(4, (index) {
              final isActive = index <= state.currentStep;
              final isCurrent = index == state.currentStep;

              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primaryDark : AppColors.border,
                        shape: BoxShape.circle,
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: AppColors.primaryDark.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                      child: Text(
                        (index + 1).toString(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.white : AppColors.hint,
                        ),
                      ),
                    ),
                    if (index < 3)
                      Expanded(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: isActive && index < state.currentStep
                                ? AppColors.primaryDark
                                : AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
