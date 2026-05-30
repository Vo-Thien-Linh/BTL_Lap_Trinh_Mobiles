import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../appointment/data/models/appointment_models.dart';
import '../../../appointment/domain/entities/appointment_entities.dart';
import '../widgets/doctor_profile_sheet.dart';

class DepartmentDetailPage extends StatefulWidget {
  final DepartmentEntity department;
  final IconData icon;
  final List<Color> colors;

  final DoctorEntity? showSpecificDoctor;

  const DepartmentDetailPage({
    super.key,
    required this.department,
    required this.icon,
    required this.colors,
    this.showSpecificDoctor,
  });

  @override
  State<DepartmentDetailPage> createState() => _DepartmentDetailPageState();
}

class _DepartmentDetailPageState extends State<DepartmentDetailPage> {
  final GlobalKey _doctorsKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  void _scrollToDoctors() {
    // Show quick feedback
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đang tìm bác sĩ khoa ${widget.department.name}...'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: widget.colors.last,
      ),
    );

    final contextObj = _doctorsKey.currentContext;
    if (contextObj != null) {
      Scrollable.ensureVisible(
        contextObj,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showRatingInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Icon(Icons.stars_rounded, color: widget.colors.last, size: 64),
            const SizedBox(height: 16),
            const Text('Đánh giá chất lượng', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            const Text(
              'Xếp hạng này dựa trên phản hồi của hơn 5,000 bệnh nhân đã trải nghiệm dịch vụ tại chuyên khoa. Chúng tôi luôn cam kết duy trì tiêu chuẩn chăm sóc cao nhất.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF5C6477), fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showSupportInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Icon(Icons.headset_mic_rounded, color: widget.colors.last, size: 60),
            const SizedBox(height: 16),
            const Text('Hỗ trợ chuyên khoa 24/7', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text(
              'Mọi thắc mắc của bạn về Khoa ${widget.department.name} sẽ được giải đáp qua hotline nội bộ:',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF5C6477), fontSize: 15),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone_forwarded_rounded, color: widget.colors.last),
                  const SizedBox(width: 12),
                  const Text('1900 6000', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickStats(),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Hành trình chăm sóc', 'Thế mạnh của chuyên khoa'),
                  const SizedBox(height: 16),
                  _buildDescription(),
                  const SizedBox(height: 32),
                  Container(
                    key: _doctorsKey, // Connect the scroll target here
                    child: _buildSectionHeader('Đội ngũ bác sĩ', 'Chuyên gia giỏi nhất'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _buildDoctorsList(),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildBookButton(context),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: widget.colors.last,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              right: -50,
              top: -20,
              child: Icon(widget.icon, size: 240, color: Colors.white.withOpacity(0.1)),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 50),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.department.name.replaceAll('Khoa ', ''),
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text(widget.department.location, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _buildStatItem(Icons.people_rounded, '${widget.department.doctorCount}', 'Bác sĩ', _scrollToDoctors),
        const SizedBox(width: 12),
        _buildStatItem(Icons.star_rounded, '4.9', 'Đánh giá', _showRatingInfo),
        const SizedBox(width: 12),
        _buildStatItem(Icons.access_time_filled_rounded, '24/7', 'Hỗ trợ', _showSupportInfo),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEDF0F7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: widget.colors.last, size: 22),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF131826),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF8B92A6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(subtitle.toUpperCase(), style: TextStyle(color: widget.colors.last, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Color(0xFF131826), fontSize: 24, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFEDF0F7))),
      child: Text(widget.department.description, style: const TextStyle(color: Color(0xFF5C6477), fontSize: 15, height: 1.6, fontWeight: FontWeight.w500)),
    );
  }

  List<DoctorEntity> _getLocalMockDoctors(String deptId, String deptName) {
    final cleanId = deptId.toLowerCase();
    final cleanName = deptName.toLowerCase();

    if (cleanId.contains('cardio') || cleanId.contains('tim') || cleanName.contains('tim')) {
      return [
        const DoctorModel(id: 'dr_cardio_1', userId: 'u1', name: 'GS.TS. Nguyễn Mạnh Phan', specialization: 'Tim mạch can thiệp', departmentId: 'dept_cardio', departmentName: 'Tim mạch', yearsOfExperience: 35, consultationFee: 800000.0, isActive: true, licenseNumber: 'LIC-C1', imageUrl: 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?q=80&w=256&h=256&auto=format&fit=crop'),
        const DoctorModel(id: 'dr_cardio_2', userId: 'u2', name: 'TS.BS. Lê Thị Kim Anh', specialization: 'Tim mạch nhi', departmentId: 'dept_cardio', departmentName: 'Tim mạch', yearsOfExperience: 22, consultationFee: 600000.0, isActive: true, licenseNumber: 'LIC-C2', imageUrl: 'https://images.unsplash.com/photo-1594824476967-48c8b964273f?q=80&w=256&h=256&auto=format&fit=crop'),
        const DoctorModel(id: 'dr_cardio_3', userId: 'u3', name: 'ThS.BS. Trần Quốc Bảo', specialization: 'Loạn nhịp tim', departmentId: 'dept_cardio', departmentName: 'Tim mạch', yearsOfExperience: 15, consultationFee: 500000.0, isActive: true, licenseNumber: 'LIC-C3', imageUrl: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?q=80&w=256&h=256&auto=format&fit=crop'),
        const DoctorModel(id: 'dr_cardio_4', userId: 'u4', name: 'BS.CKII. Phạm Hoàng Minh', specialization: 'Phẫu thuật tim mạch', departmentId: 'dept_cardio', departmentName: 'Tim mạch', yearsOfExperience: 18, consultationFee: 700000.0, isActive: true, licenseNumber: 'LIC-C4', imageUrl: 'https://images.unsplash.com/photo-1612349317150-e413f6a5b1a8?q=80&w=256&h=256&auto=format&fit=crop'),
      ];
    } else if (cleanId.contains('internal') || cleanId.contains('noi_tong') || cleanName.contains('nội tổng')) {
      return [
        const DoctorModel(id: 'dr_internal_1', userId: 'u5', name: 'PGS.TS.BS. Nguyễn Văn Kính', specialization: 'Nội tiêu hóa', departmentId: 'dept_internal', departmentName: 'Nội tổng quát', yearsOfExperience: 30, consultationFee: 600000.0, isActive: true, licenseNumber: 'LIC-I1', imageUrl: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?q=80&w=256&h=256&auto=format&fit=crop'),
        const DoctorModel(id: 'dr_internal_2', userId: 'u6', name: 'TS.BS. Phạm Hồng Hải', specialization: 'Nội hô hấp', departmentId: 'dept_internal', departmentName: 'Nội tổng quát', yearsOfExperience: 25, consultationFee: 500000.0, isActive: true, licenseNumber: 'LIC-I2', imageUrl: 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?q=80&w=256&h=256&auto=format&fit=crop'),
        const DoctorModel(id: 'dr_internal_3', userId: 'u7', name: 'BS.CKII. Lê Hoàng Nam', specialization: 'Nội nội tiết', departmentId: 'dept_internal', departmentName: 'Nội tổng quát', yearsOfExperience: 20, consultationFee: 450000.0, isActive: true, licenseNumber: 'LIC-I3', imageUrl: 'https://images.unsplash.com/photo-1612349317150-e413f6a5b1a8?q=80&w=256&h=256&auto=format&fit=crop'),
        const DoctorModel(id: 'dr_internal_5', userId: 'u8', name: 'BS.CKI. Vũ Trường Phi', specialization: 'Nội tổng quát', departmentId: 'dept_internal', departmentName: 'Nội tổng quát', yearsOfExperience: 10, consultationFee: 350000.0, isActive: true, licenseNumber: 'LIC-I5', imageUrl: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?q=80&w=256&h=256&auto=format&fit=crop'),
      ];
    } else if (cleanId.contains('pedia') || cleanId.contains('nhi') || cleanName.contains('nhi')) {
      return [
        const DoctorModel(id: 'dr_pedia_1', userId: 'u9', name: 'BS. Đặng Lê Nguyên Vũ', specialization: 'Nhi sơ sinh', departmentId: 'dept_pedia', departmentName: 'Nhi khoa', yearsOfExperience: 25, consultationFee: 350000.0, isActive: true, licenseNumber: 'LIC-P1', imageUrl: 'https://images.unsplash.com/photo-1612349317150-e413f6a5b1a8?q=80&w=256&h=256&auto=format&fit=crop'),
        const DoctorModel(id: 'dr_pedia_2', userId: 'u10', name: 'BS. Mai Kiều Liên', specialization: 'Dinh dưỡng nhi', departmentId: 'dept_pedia', departmentName: 'Nhi khoa', yearsOfExperience: 30, consultationFee: 300000.0, isActive: true, licenseNumber: 'LIC-P2', imageUrl: 'https://images.unsplash.com/photo-1594824476967-48c8b964273f?q=80&w=256&h=256&auto=format&fit=crop'),
        const DoctorModel(id: 'dr_pedia_3', userId: 'u11', name: 'PGS.TS. Nguyễn Thanh Liêm', specialization: 'Ngoại nhi', departmentId: 'dept_pedia', departmentName: 'Nhi khoa', yearsOfExperience: 38, consultationFee: 800000.0, isActive: true, licenseNumber: 'LIC-P3', imageUrl: 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?q=80&w=256&h=256&auto=format&fit=crop'),
      ];
    } else if (cleanId.contains('obgyn') || cleanId.contains('sản') || cleanName.contains('sản') || cleanName.contains('phụ')) {
      return [
        const DoctorModel(id: 'dr_obgyn_1', userId: 'u12', name: 'GS.TS.BS. Nguyễn Thị Ngọc Phượng', specialization: 'Sản khoa', departmentId: 'dept_obgyn', departmentName: 'Phụ sản', yearsOfExperience: 32, consultationFee: 700000.0, isActive: true, licenseNumber: 'LIC-O1', imageUrl: 'https://images.unsplash.com/photo-1594824476967-48c8b964273f?q=80&w=256&h=256&auto=format&fit=crop'),
        const DoctorModel(id: 'dr_obgyn_2', userId: 'u13', name: 'BS.CKII. Huỳnh Thị Thu Thủy', specialization: 'Phụ khoa', departmentId: 'dept_obgyn', departmentName: 'Phụ sản', yearsOfExperience: 26, consultationFee: 550000.0, isActive: true, licenseNumber: 'LIC-O2', imageUrl: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?q=80&w=256&h=256&auto=format&fit=crop'),
      ];
    } else if (cleanId.contains('derma') || cleanId.contains('da_lieu') || cleanName.contains('da liễu')) {
      return [
        const DoctorModel(id: 'dr_derma_1', userId: 'u14', name: 'BS. Trương Mỹ Lan', specialization: 'Da liễu thẩm mỹ', departmentId: 'dept_dermatology', departmentName: 'Da liễu', yearsOfExperience: 12, consultationFee: 400000.0, isActive: true, licenseNumber: 'LIC-D1', imageUrl: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?q=80&w=256&h=256&auto=format&fit=crop'),
        const DoctorModel(id: 'dr_derma_2', userId: 'u15', name: 'BS. Quách Thành Danh', specialization: 'Laser thẩm mỹ', departmentId: 'dept_dermatology', departmentName: 'Da liễu', yearsOfExperience: 18, consultationFee: 600000.0, isActive: true, licenseNumber: 'LIC-D2', imageUrl: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?q=80&w=256&h=256&auto=format&fit=crop'),
        const DoctorModel(id: 'dr_derma_3', userId: 'u16', name: 'TS.BS. Trần Ngọc Ánh', specialization: 'Da liễu tổng quát', departmentId: 'dept_dermatology', departmentName: 'Da liễu', yearsOfExperience: 24, consultationFee: 500000.0, isActive: true, licenseNumber: 'LIC-D3', imageUrl: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?q=80&w=256&h=256&auto=format&fit=crop'),
      ];
    } else if (cleanId.contains('tai_mui_hong') || cleanName.contains('tai mũi họng')) {
      return [
        const DoctorModel(id: 'dr_tmh_1', userId: 'u17', name: 'BS. Ngô Bảo K', specialization: 'Tai Mũi Họng', departmentId: 'tai_mui_hong', departmentName: 'Tai Mũi Họng', yearsOfExperience: 15, consultationFee: 380000.0, isActive: true, licenseNumber: 'LIC-T1', imageUrl: 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?q=80&w=256&h=256&auto=format&fit=crop'),
        const DoctorModel(id: 'dr_tmh_2', userId: 'u18', name: 'TS.BS. Nguyễn Thị Mai', specialization: 'Nội soi tai mũi họng', departmentId: 'tai_mui_hong', departmentName: 'Tai Mũi Họng', yearsOfExperience: 18, consultationFee: 450000.0, isActive: true, licenseNumber: 'LIC-T2', imageUrl: 'https://images.unsplash.com/photo-1594824476967-48c8b964273f?q=80&w=256&h=256&auto=format&fit=crop'),
        const DoctorModel(id: 'dr_ent_1', userId: 'u_ent_1', name: 'PGS.TS.BS. Nhan Trừng Sơn', specialization: 'Tai Mũi Họng Nhi', departmentId: 'tai_mui_hong', departmentName: 'Tai Mũi Họng', yearsOfExperience: 35, consultationFee: 600000.0, isActive: true, licenseNumber: 'LIC-ENT1', imageUrl: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?q=80&w=256&h=256&auto=format&fit=crop'),
        const DoctorModel(id: 'dr_ent_2', userId: 'u_ent_2', name: 'BS.CKII. Nguyễn Thanh Tuấn', specialization: 'Phẫu thuật Tai Mũi Họng', departmentId: 'tai_mui_hong', departmentName: 'Tai Mũi Họng', yearsOfExperience: 20, consultationFee: 500000.0, isActive: true, licenseNumber: 'LIC-ENT2', imageUrl: 'https://images.unsplash.com/photo-1612349317150-e413f6a5b1a8?q=80&w=256&h=256&auto=format&fit=crop'),
        const DoctorModel(id: 'dr_ent_3', userId: 'u_ent_3', name: 'ThS.BS. Đinh Văn Sang', specialization: 'Khám Tai Mũi Họng', departmentId: 'tai_mui_hong', departmentName: 'Tai Mũi Họng', yearsOfExperience: 15, consultationFee: 400000.0, isActive: true, licenseNumber: 'LIC-ENT3', imageUrl: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?q=80&w=256&h=256&auto=format&fit=crop'),
        const DoctorModel(id: 'dr_ent_4', userId: 'u_ent_4', name: 'BS.CKI. Lê Văn Dũng', specialization: 'Tai Mũi Họng', departmentId: 'tai_mui_hong', departmentName: 'Tai Mũi Họng', yearsOfExperience: 12, consultationFee: 350000.0, isActive: true, licenseNumber: 'LIC-ENT4', imageUrl: 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?q=80&w=256&h=256&auto=format&fit=crop'),
        const DoctorModel(id: 'dr_ent_5', userId: 'u_ent_5', name: 'BS. Trần Hữu Phúc', specialization: 'Tai Mũi Họng', departmentId: 'tai_mui_hong', departmentName: 'Tai Mũi Họng', yearsOfExperience: 10, consultationFee: 300000.0, isActive: true, licenseNumber: 'LIC-ENT5', imageUrl: 'https://images.unsplash.com/photo-1594824476967-48c8b964273f?q=80&w=256&h=256&auto=format&fit=crop'),
        const DoctorModel(id: 'dr_ent_6', userId: 'u_ent_6', name: 'ThS.BS. Phạm Hữu Tài', specialization: 'Thính học', departmentId: 'tai_mui_hong', departmentName: 'Tai Mũi Họng', yearsOfExperience: 14, consultationFee: 450000.0, isActive: true, licenseNumber: 'LIC-ENT6', imageUrl: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?q=80&w=256&h=256&auto=format&fit=crop'),
        const DoctorModel(id: 'dr_ent_7', userId: 'u_ent_7', name: 'BS.CKII. Hoàng Tuấn', specialization: 'Phẫu thuật đầu cổ', departmentId: 'tai_mui_hong', departmentName: 'Tai Mũi Họng', yearsOfExperience: 25, consultationFee: 550000.0, isActive: true, licenseNumber: 'LIC-ENT7', imageUrl: 'https://images.unsplash.com/photo-1612349317150-e413f6a5b1a8?q=80&w=256&h=256&auto=format&fit=crop'),
        const DoctorModel(id: 'dr_ent_8', userId: 'u_ent_8', name: 'BS. Vũ Đức Hải', specialization: 'Tai Mũi Họng', departmentId: 'tai_mui_hong', departmentName: 'Tai Mũi Họng', yearsOfExperience: 8, consultationFee: 300000.0, isActive: true, licenseNumber: 'LIC-ENT8', imageUrl: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?q=80&w=256&h=256&auto=format&fit=crop'),
        const DoctorModel(id: 'dr_ent_9', userId: 'u_ent_9', name: 'BS. Lê Minh Tiến', specialization: 'Nội soi tai mũi họng', departmentId: 'tai_mui_hong', departmentName: 'Tai Mũi Họng', yearsOfExperience: 11, consultationFee: 400000.0, isActive: true, licenseNumber: 'LIC-ENT9', imageUrl: 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?q=80&w=256&h=256&auto=format&fit=crop'),
      ];
    } else if (cleanId.contains('rang_ham_mat') || cleanName.contains('răng hàm mặt')) {
      return [
        const DoctorModel(id: 'dr_rhm_1', userId: 'u19', name: 'BS. Phan Thanh H', specialization: 'Răng Hàm Mặt', departmentId: 'rang_ham_mat', departmentName: 'Răng Hàm Mặt', yearsOfExperience: 12, consultationFee: 400000.0, isActive: true, licenseNumber: 'LIC-R1', imageUrl: 'https://images.unsplash.com/photo-1612349317150-e413f6a5b1a8?q=80&w=256&h=256&auto=format&fit=crop'),
      ];
    } else if (cleanId.contains('mat') || cleanName.contains('mắt') || cleanName.contains('nhãn khoa')) {
      return [
        const DoctorModel(id: 'dr_mat_1', userId: 'u20', name: 'BS. Đặng Minh G', specialization: 'Nhãn khoa', departmentId: 'mat', departmentName: 'Mắt', yearsOfExperience: 14, consultationFee: 400000.0, isActive: true, licenseNumber: 'LIC-M1', imageUrl: 'https://images.unsplash.com/photo-1622902046580-2b47f47f0871?q=80&w=256&h=256&auto=format&fit=crop'),
      ];
    } else if (cleanId.contains('noi_tiet') || cleanName.contains('nội tiết')) {
      return [
        const DoctorModel(id: 'dr_nt_1', userId: 'u21', name: 'BS. Lý Tiểu L', specialization: 'Nội tiết', departmentId: 'noi_tiet', departmentName: 'Nội tiết', yearsOfExperience: 11, consultationFee: 420000.0, isActive: true, licenseNumber: 'LIC-N1', imageUrl: 'https://images.unsplash.com/photo-1582750433449-648ed127bb54?q=80&w=256&h=256&auto=format&fit=crop'),
      ];
    }

    // Default fallback
    return [
      DoctorModel(
        id: 'dr_default',
        userId: 'udef',
        name: 'BS. Nguyễn Văn A',
        specialization: 'Chuyên khoa tổng quát',
        departmentId: deptId,
        departmentName: deptName,
        yearsOfExperience: 10,
        consultationFee: 300000.0,
        isActive: true,
        licenseNumber: 'LIC-DEF',
        imageUrl: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?q=80&w=256&h=256&auto=format&fit=crop',
      ),
    ];
  }

  Widget _buildDoctorsList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('Doctors').where('departmentId', isEqualTo: widget.department.id).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
          
          List<DoctorEntity> doctors = [];
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            doctors = snapshot.data!.docs.map(DoctorModel.fromFirestore).toList();
          }

          // Local fallback if empty
          if (doctors.isEmpty) {
            doctors = _getLocalMockDoctors(widget.department.id, widget.department.name);
          }

          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => GestureDetector(onTap: () => _onDoctorProfileTap(doctors[index]), child: _buildDoctorCard(context, doctors[index])),
              childCount: doctors.length,
            ),
          );
        },
      ),
    );
  }

  Widget _buildDoctorCard(BuildContext context, DoctorEntity doctor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFEDF0F7))),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFFF1F5F9),
            backgroundImage: doctor.imageUrl != null ? NetworkImage(doctor.imageUrl!) : null,
            child: doctor.imageUrl == null ? Icon(Icons.person_rounded, color: widget.colors.last, size: 32) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doctor.name, style: const TextStyle(color: Color(0xFF131826), fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(doctor.specialization, style: const TextStyle(color: Color(0xFF5C6477), fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 18, color: widget.colors.last),
        ],
      ),
    );
  }

  void _onDoctorProfileTap(DoctorEntity doctor) {
    DoctorProfileSheet.show(context, doctor, widget.department, widget.colors);
  }

  Widget _buildBookButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.booking, arguments: widget.department),
        style: ElevatedButton.styleFrom(backgroundColor: widget.colors.last, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        child: const Text('ĐẶT LỊCH NGAY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
      ),
    );
  }
}
