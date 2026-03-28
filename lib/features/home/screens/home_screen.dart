import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/theme/app_colors.dart';
import '../../../config/service_locator.dart' as sl;
import '../presentation/bloc/home_bloc.dart';
import '../presentation/bloc/home_event.dart';
import '../presentation/bloc/home_state.dart';
import '../presentation/widgets/appointment_card.dart';
import '../presentation/widgets/home_greeting_header.dart';
import '../presentation/widgets/quick_action_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeBloc>(
      create: (context) => sl.getIt<HomeBloc>(),
      child: const _HomeScreenContent(),
    );
  }
}

class _HomeScreenContent extends StatefulWidget {
  const _HomeScreenContent();

  @override
  State<_HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<_HomeScreenContent> {
  @override
  void initState() {
    super.initState();
    // Fetch appointments khi màn hình load
    context.read<HomeBloc>().add(const FetchAppointmentsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryDark),
            );
          }

          if (state is HomeError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Lỗi: ${state.message}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.text, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<HomeBloc>().add(
                        const FetchAppointmentsEvent(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                    ),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (state is HomeLoaded) {
            final upcomingAppointments = state.appointments
                .where((apt) => apt.status == 'upcoming')
                .toList();

            return RefreshIndicator(
              onRefresh: () async {
                context.read<HomeBloc>().add(const RefreshAppointmentsEvent());
              },
              color: AppColors.primaryDark,
              child: CustomScrollView(
                slivers: [
                  // Header Greeting
                  SliverAppBar(
                    backgroundColor: AppColors.primary,
                    expandedHeight: 180,
                    pinned: true,
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      background: HomeGreetingHeader(userName: state.userName),
                      collapseMode: CollapseMode.parallax,
                    ),
                  ),
                  // Body Content
                  SliverToBoxAdapter(
                    child: Container(
                      color: AppColors.background,
                      child: Column(
                        children: [
                          // Quick Actions Section
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Thao tác nhanh',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.text,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    QuickActionButton(
                                      icon: Icons.add_rounded,
                                      label: 'Đặt lịch\nmới',
                                      onPressed: () {
                                        // TODO: Navigate to booking
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Tiến tới đặt lịch khám',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    QuickActionButton(
                                      icon: Icons.history_rounded,
                                      label: 'Lịch sử\nkhám',
                                      onPressed: () {
                                        // TODO: Navigate to history
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Xem lịch sử khám'),
                                          ),
                                        );
                                      },
                                    ),
                                    QuickActionButton(
                                      icon: Icons.person_rounded,
                                      label: 'Hồ sơ',
                                      onPressed: () {
                                        // TODO: Navigate to profile
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Xem hồ sơ'),
                                          ),
                                        );
                                      },
                                    ),
                                    QuickActionButton(
                                      icon: Icons.settings_rounded,
                                      label: 'Cài đặt',
                                      onPressed: () {
                                        // TODO: Navigate to settings
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Cài đặt'),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Upcoming Appointments Section
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Lịch khám sắp tới',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.text,
                                      ),
                                    ),
                                    if (upcomingAppointments.isNotEmpty)
                                      Text(
                                        '${upcomingAppointments.length} lịch',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.hint,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (upcomingAppointments.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.event_note_rounded,
                                          color: AppColors.hint,
                                          size: 40,
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Hiện không có lịch khám sắp tới',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: AppColors.hint,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: upcomingAppointments.length,
                                    itemBuilder: (context, index) {
                                      return AppointmentCard(
                                        appointment:
                                            upcomingAppointments[index],
                                        onTap: () {
                                          // TODO: Navigate to appointment details
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Chi tiết lịch khám: ${upcomingAppointments[index].doctorName}',
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
