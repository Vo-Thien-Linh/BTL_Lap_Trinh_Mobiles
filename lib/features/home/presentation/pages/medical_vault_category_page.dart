import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:baitaplon/features/appointment/data/models/appointment_models.dart';
import 'package:baitaplon/app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';

class MedicalVaultCategoryPage extends StatefulWidget {
  final String category;
  const MedicalVaultCategoryPage({super.key, required this.category});

  @override
  State<MedicalVaultCategoryPage> createState() => _MedicalVaultCategoryPageState();
}

class _MedicalVaultCategoryPageState extends State<MedicalVaultCategoryPage> {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.category.toUpperCase(),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đang cập nhật danh mục ${widget.category}...'),
                  duration: const Duration(seconds: 1),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
          ),
        ],
        flexibleSpace: FlexibleSpaceBar(
          background: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, Color(0xFF3B82F6)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: uid == null
            ? null
            : FirebaseFirestore.instance
                .collection('Appointments')
                .where('patientId', isEqualTo: uid)
                .where('status', isEqualTo: 'completed')
                .orderBy('appointmentDate', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          List<HospitalAppointmentModel> appointments = [];
          
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            appointments = snapshot.data!.docs.map((d) => HospitalAppointmentModel.fromFirestore(d)).toList();
          } else {
            appointments = _getMockAppointments();
          }

          if (widget.category == 'Sổ Xét Nghiệm') return _buildLabsList(appointments);
          if (widget.category == 'Đơn Thuốc') return _buildPrescriptionsList(appointments);
          if (widget.category == 'Chẩn Đoán HA') return _buildImagingGrid(appointments);

          return _buildEmptyState();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
            child: const Icon(Icons.folder_open_rounded, size: 64, color: AppColors.textHint),
          ),
          const SizedBox(height: 24),
          const Text(
            'Chưa có dữ liệu cho mục này',
            style: TextStyle(color: AppColors.textBody, fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const Text(
            'Dữ liệu sẽ hiển thị sau khi hoàn tất khám bệnh',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildLabsList(List<HospitalAppointmentModel> appointments) {
    final List<Map<String, dynamic>> allLabs = [];
    for (var app in appointments) {
      if (app.labResults != null) {
        for (var lab in app.labResults!) {
          allLabs.add({
            ...lab,
            'date': app.appointmentDate,
            'doctor': app.doctorName,
            'dept': app.departmentName,
          });
        }
      }
    }

    if (allLabs.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: allLabs.length,
      itemBuilder: (context, index) {
        final lab = allLabs[index];
        final dateStr = DateFormat('dd/MM/yyyy').format(lab['date'] as DateTime);
        final status = lab['status'] ?? 'Bình thường';
        final isWarning = status.toString().toLowerCase().contains('cao') || status.toString().toLowerCase().contains('thấp');

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: AppColors.textBody.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isWarning ? AppColors.warning.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isWarning ? Icons.warning_amber_rounded : Icons.science_rounded,
                  color: isWarning ? AppColors.warning : AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lab['name'] ?? 'Xét nghiệm', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textBody)),
                    const SizedBox(height: 2),
                    Text('$dateStr • ${lab['dept']}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${lab['result'] ?? "--"} ${lab['unit'] ?? ""}',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isWarning ? AppColors.error : AppColors.primary),
                  ),
                  Text(
                    status.toString().toUpperCase(),
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isWarning ? AppColors.error : AppColors.success),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrescriptionsList(List<HospitalAppointmentModel> appointments) {
    final prescApps = appointments.where((a) => a.prescription != null && a.prescription!.isNotEmpty).toList();

    if (prescApps.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: prescApps.length,
      itemBuilder: (context, index) {
        final app = prescApps[index];
        final meds = app.prescription!;

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: AppColors.textBody.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))],
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  gradient: LinearGradient(colors: [AppColors.primary, Color(0xFF3B82F6)]),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Toa thuốc ngày ${DateFormat('dd/MM/yyyy').format(app.appointmentDate)}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                          ),
                          Text('BS: ${app.doctorName}', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.prescriptionDetail, arguments: app),
                      icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: meds.map((m) => _buildMedRow(m)).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMedRow(Map<String, dynamic> med) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.medication_outlined, color: AppColors.success, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(med['name'] ?? 'Thuốc', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textBody)),
                const SizedBox(height: 2),
                Text('${med['dosage'] ?? ""} • ${med['usage'] ?? ""}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(med['quantity'] ?? "", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildImagingGrid(List<HospitalAppointmentModel> appointments) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: 4, 
      itemBuilder: (context, index) {
        final mockTitles = ['X-Quang Phổi Thẳng', 'Siêu âm Ổ bụng', 'MRI Khớp Gối', 'CT Scan Đầu'];
        final mockDates = ['12/04/2026', '08/03/2026', '15/02/2026', '10/01/2026'];
        final mockImages = [
            'https://media.istockphoto.com/id/1142517865/photo/chest-x-ray-of-human-lungs.jpg?s=612x612&w=0&k=20&c=pXvIe-G-hXGjL0m-hYvX-YQ_zX4-I1-p9qO-G9pL-U=',
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR_x-T-tG-M-K9_u-N-tU-v-y-s-d-A-m-D-Q&s',
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT_u-N-tU-v-y-s-d-A-m-D-Q&s',
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR_x-T-tG-M-K9_u-N-tU-v-y-s-d-A-m-D-Q&s'
        ];

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: AppColors.textBody.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    image: DecorationImage(
                      image: NetworkImage(mockImages[index % mockImages.length]),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                        begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      ),
                    ),
                    alignment: Alignment.bottomLeft,
                    padding: const EdgeInsets.all(12),
                    child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mockTitles[index % mockTitles.length], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.textBody)),
                    const SizedBox(height: 4),
                    Text(mockDates[index % mockDates.length], style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<HospitalAppointmentModel> _getMockAppointments() {
    return [
      HospitalAppointmentModel(
        id: 'MOCK-001',
        patientId: 'demo',
        patientName: 'Người Dùng Thử Nghiệm',
        doctorId: 'doc-001',
        doctorName: 'ThS.BS Nguyễn Văn An',
        departmentId: 'dep-001',
        departmentName: 'Khoa Nội Tổng Quát',
        appointmentDate: DateTime.now().subtract(const Duration(days: 5)),
        shiftId: 's1',
        timeSlot: '08:00 - 08:30',
        queueNumber: 12,
        roomNumber: 'A102',
        consultationFee: 150000,
        symptoms: 'Đau đầu, mệt mỏi, khó ngủ',
        diagnosis: 'Suy nhược cơ thể nhẹ, thiếu máu nhẹ',
        notes: 'Cần nghỉ ngơi nhiều hơn, uống thuốc đúng giờ và tái khám sau 10 ngày.',
        status: 'completed',
        paymentMethod: 'CASH',
        createdAt: DateTime.now().subtract(const Duration(days: 6)),
        prescription: [
          {'name': 'Panadol Extra', 'dosage': '1 viên/lần', 'usage': 'Uống sau ăn (Sáng, Tối)', 'quantity': '20 viên'},
          {'name': 'Hapacol 650', 'dosage': '1 viên/lần', 'usage': 'Khi đau đầu nhiều', 'quantity': '10 viên'},
          {'name': 'Vitamin C 500mg', 'dosage': '1 viên/ngày', 'usage': 'Uống buổi sáng', 'quantity': '30 viên'},
        ],
        labResults: [
          {'name': 'Đường huyết (Glucose)', 'value': '5.2', 'unit': 'mmol/L', 'status': 'Bình thường'},
          {'name': 'Cholesterol Toàn Phần', 'value': '6.8', 'unit': 'mmol/L', 'status': 'Cao'},
          {'name': 'Huyết sắc tố (Hb)', 'value': '110', 'unit': 'g/L', 'status': 'Thấp'},
        ],
      ),
      HospitalAppointmentModel(
        id: 'MOCK-002',
        patientId: 'demo',
        patientName: 'Người Dùng Thử Nghiệm',
        doctorId: 'doc-002',
        doctorName: 'BSCKII. Lê Thị Minh',
        departmentId: 'dep-002',
        departmentName: 'Khoa Tai Mũi Họng',
        appointmentDate: DateTime.now().subtract(const Duration(days: 15)),
        shiftId: 's2',
        timeSlot: '14:00 - 14:30',
        queueNumber: 5,
        roomNumber: 'B205',
        consultationFee: 200000,
        symptoms: 'Viêm họng hạt, ho kéo dài',
        diagnosis: 'Viêm họng mãn tính',
        status: 'completed',
        paymentMethod: 'BANK',
        createdAt: DateTime.now().subtract(const Duration(days: 16)),
        prescription: [
          {'name': 'Augmentin 1g', 'dosage': '1 viên/lần', 'usage': 'Uống sau ăn (Sáng, Tối)', 'quantity': '14 viên'},
          {'name': 'Alpha Choay', 'dosage': '2 viên/lần', 'usage': 'Uống hoặc ngậm (Ngày 3 lần)', 'quantity': '30 viên'},
        ],
      ),
    ];
  }
}
