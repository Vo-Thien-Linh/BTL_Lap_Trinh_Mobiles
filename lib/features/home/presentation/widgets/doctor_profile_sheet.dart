import 'package:flutter/material.dart';
import '../../../appointment/domain/entities/appointment_entities.dart';

class DoctorProfileSheet extends StatelessWidget {
  final DoctorEntity doctor;
  final DepartmentEntity department;
  final List<Color> colors;

  const DoctorProfileSheet({
    super.key,
    required this.doctor,
    required this.department,
    required this.colors,
  });

  static void show(BuildContext context, DoctorEntity doctor, DepartmentEntity department, List<Color> colors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DoctorProfileSheet(
        doctor: doctor,
        department: department,
        colors: colors,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 45, height: 5, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10))),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // --- Header Area ---
                      Center(
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [colors.last.withOpacity(0.1), colors.last.withOpacity(0)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                                CircleAvatar(
                                  radius: 58,
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  backgroundImage: doctor.imageUrl != null ? NetworkImage(doctor.imageUrl!) : null,
                                  child: doctor.imageUrl == null ? Icon(Icons.person_rounded, color: colors.last, size: 50) : null,
                                ),
                                Positioned(
                                  bottom: 5,
                                  right: 5,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                                    child: const Icon(Icons.verified_rounded, color: Color(0xFF2563EB), size: 24),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(doctor.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5)),
                            const SizedBox(height: 4),
                            Text(doctor.specialization.toUpperCase(), style: TextStyle(fontSize: 14, color: colors.last, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // --- Stats Bar ---
                      Row(
                        children: [
                          _buildStatItem('Kinh nghiệm', '${doctor.yearsOfExperience}+ năm', Icons.work_history_rounded),
                          _buildStatDivider(),
                          _buildStatItem('Bệnh nhân', '1.2k+', Icons.groups_rounded),
                          _buildStatDivider(),
                          _buildStatItem('Đánh giá', '4.9', Icons.star_rounded),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // --- Bio ---
                      const Text('Giới thiệu chuyên môn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      const SizedBox(height: 12),
                      Text(
                        'BS. ${doctor.name} là một trong những chuyên gia hàng đầu tại khoa ${department.name}. Với tinh thần tận tâm và tay nghề cao, bác sĩ đã giúp hàng ngàn bệnh nhân hồi phục và cải thiện chất lượng cuộc sống thông qua các phương pháp điều trị tiên tiến nhất.',
                        style: const TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.6, fontWeight: FontWeight.w500),
                      ),

                      const SizedBox(height: 24),

                      // --- Expertise ---
                      const Text('Thế mạnh chuyên sâu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildExpertiseChip('Tư vấn lâm sàng'),
                          _buildExpertiseChip('Chẩn đoán hình ảnh'),
                          _buildExpertiseChip('Phẫu thuật chuyên sâu'),
                          _buildExpertiseChip('Theo dõi hậu phẫu'),
                        ],
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // --- Back Button ---
          Positioned(
            top: 20,
            left: 20,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Color(0xFF475569),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: colors.last, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 35, color: const Color(0xFFE2E8F0));
  }

  Widget _buildExpertiseChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colors.last.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.last.withOpacity(0.1)),
      ),
      child: Text(
        label,
        style: TextStyle(color: colors.last, fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}
