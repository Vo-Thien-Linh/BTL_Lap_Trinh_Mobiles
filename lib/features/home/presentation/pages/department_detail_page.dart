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

  Widget _buildDoctorsList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('Doctors').where('departmentId', isEqualTo: widget.department.id).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SliverToBoxAdapter(child: Center(child: Text('Chưa có thông tin bác sĩ.')));
          final doctors = snapshot.data!.docs.map(DoctorModel.fromFirestore).toList();
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
