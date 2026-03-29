import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../app/routes/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  final Color _bgDark = const Color(
    0xFFE6EDF5,
  ); // Xám xanh bạc (Frost Silver) - Rất dịu mắt, không bị chói
  final Color _neonGreen = const Color(
    0xFF0F766E,
  ); // Xanh Teal đậm (Tính y tế, chuyên môn cao)
  final Color _accentGold = const Color(0xFF0369A1); // Xanh dương sậm (AI)
  final Color _textGrey = const Color(0xFF475569); // Xám đậm chữ phụ
  final Color _cardDark = const Color(0xFFFFFFFF); // Khối nền nổi bật màu trắng
  final Color _cardBorder = const Color(0xFFCBD5E1); // Viền xám bạc

  final List<Map<String, dynamic>> onboardingData = [
    {
      "badge": "HỆ THỐNG Y TẾ HM",
      "icon": Icons.medical_services_outlined,
      "titlePart1": "Trải nghiệm",
      "titlePart2": "Hiện đại",
      "metric1": "HIS",
      "metric1Label": "Tích hợp",
      "metric2": "24/7",
      "metric2Label": "Hỗ trợ y tế",
      "metric3": "98%",
      "metric3Label": "Chính xác",
      "cardTitle": "Hệ thống Quản lý Y tế Toàn diện",
      "cardDesc":
          "Khám chữa bệnh nhanh chóng với hệ thống quản lý hiện đại, hỗ trợ chẩn đoán và quản lý hiệu quả.",
      "feature1Icon": Icons.dashboard_outlined,
      "feature1Label": "Quản lý tập trung",
      "feature2Icon": Icons.security,
      "feature2Label": "Bảo mật cao",
      "feature3Icon": Icons.speed,
      "feature3Label": "Tốc độ xử lý",
    },
    {
      "badge": "CHUYÊN MÔN CAO CẤP",
      "icon": Icons.favorite_border_rounded,
      "titlePart1": "Chăm sóc",
      "titlePart2": "Tận tâm",
      "metric1": "100+",
      "metric1Label": "Bác sĩ chuyên gia",
      "metric2": "98%",
      "metric2Label": "Bệnh nhân hài lòng",
      "metric3": "24/7",
      "metric3Label": "Hỗ trợ trực tuyến",
      "cardTitle": "Quy trình chuẩn quốc tế WHO",
      "cardDesc":
          "Toàn bộ quy trình thăm khám diễn ra riêng tư, nhanh chóng và đề cao sự thoải mái của bạn.",
      "feature1Icon": Icons.person_outline,
      "feature1Label": "Bác sĩ đầu ngành",
      "feature2Icon": Icons.access_time,
      "feature2Label": "Phản hồi nhanh",
      "feature3Icon": Icons.star_border,
      "feature3Label": "Chất lượng 5 sao",
    },
    {
      "badge": "TIẾT KIỆM THỜI GIAN",
      "icon": Icons.edit_calendar_rounded,
      "titlePart1": "Đặt lịch",
      "titlePart2": "Thông minh",
      "metric1": "10s",
      "metric1Label": "Thời gian chờ",
      "metric2": "3",
      "metric2Label": "Chạm đặt",
      "metric3": "99%",
      "metric3Label": "Chủ động",
      "cardTitle": "Chọn bác sĩ theo yêu cầu",
      "cardDesc":
          "Xem chi tiết hồ sơ các y bác sĩ đầu ngành và chủ động đặt ca khám phù hợp nhất với bạn.",
      "feature1Icon": Icons.calendar_month,
      "feature1Label": "Đa dạng giờ",
      "feature2Icon": Icons.notifications_active_outlined,
      "feature2Label": "Nhắc nhở khám",
      "feature3Icon": Icons.history,
      "feature3Label": "Lịch sử khám",
    },
    {
      "badge": "BẢO MẬT TUYỆT ĐỐI",
      "icon": Icons.shield_outlined,
      "titlePart1": "Hồ sơ",
      "titlePart2": "Thống nhất",
      "metric1": "RSA",
      "metric1Label": "Mã hóa 2 lớp",
      "metric2": "Cloud",
      "metric2Label": "Lưu trữ số",
      "metric3": "99.9%",
      "metric3Label": "Bảo mật",
      "cardTitle": "Bảo mật Hồ sơ bệnh án",
      "cardDesc":
          "Toàn bộ thông tin cá nhân và hồ sơ bệnh án của bạn được mã hóa và bảo mật tuyệt đối trên hệ thống.",
      "feature1Icon": Icons.shield_outlined,
      "feature1Label": "Mã hóa thông tin",
      "feature2Icon": Icons.folder_shared_outlined,
      "feature2Label": "Dễ chia sẻ",
      "feature3Icon": Icons.data_usage,
      "feature3Label": "Lưu trữ trọn đời",
    },
  ];

  Future<void> _completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
    } catch (_) {
      // Continue navigation even if persisting flag fails.
    }

    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _neonGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _neonGreen.withOpacity(0.2),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(Icons.add, color: _neonGreen, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "HM SYSTEM",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: Color(0xFF0F172A), // Slate 900
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _completeOnboarding,
                    style: TextButton.styleFrom(foregroundColor: _textGrey),
                    child: const Text(
                      "Bỏ qua",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Expanded PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingData.length,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final data = onboardingData[index];
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double value = 1.0;
                      if (_pageController.position.haveDimensions) {
                        value = _pageController.page! - index;
                        value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                      }
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 30 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),

                            // Glowing Circular Radar Graphic
                            Center(
                              child: SizedBox(
                                height: 200, // Reduced from 260
                                width: double.infinity,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Rotating Orbits with Trails
                                    RotatingOrbit(
                                      animation: _rotationController,
                                      size: 190, // Reduced from 240
                                      color: _neonGreen,
                                      reverse: false,
                                      speedMultiplier: 0.8,
                                    ),
                                    RotatingOrbit(
                                      animation: _rotationController,
                                      size: 140, // Reduced from 180
                                      color: _neonGreen,
                                      reverse: true,
                                      speedMultiplier: 1.2,
                                    ),
                                    RotatingOrbit(
                                      animation: _rotationController,
                                      size: 100, // Reduced from 130
                                      color: _accentGold,
                                      reverse: false,
                                      speedMultiplier: 2.0,
                                    ),

                                    // Inner glowing rounded square
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Colors
                                            .white, // Pristine clean white
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: _neonGreen.withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _neonGreen.withOpacity(0.15),
                                            blurRadius: 30,
                                            spreadRadius: 2,
                                          ),
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.05,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _neonGreen.withOpacity(0.15),
                                            border: Border.all(
                                              color: _neonGreen,
                                              width: 2,
                                            ),
                                          ),
                                          child: Icon(
                                            data["icon"] ?? Icons.check,
                                            color: _neonGreen,
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Badge Pill at bottom of graphic
                                    Positioned(
                                      bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFFF0FDFA,
                                          ), // Teal 50
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFF99F6E4),
                                          ), // Teal 200
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 5,
                                              height: 5,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: _neonGreen,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              data["badge"]!,
                                              style: TextStyle(
                                                color: _neonGreen,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Line + Small Badge
                            Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 1.5,
                                  color: _accentGold,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  data["badge"]!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                    color: _accentGold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Large Title
                            Text(
                              data["titlePart1"]!,
                              style: const TextStyle(
                                fontSize: 40, // Increased
                                height: 1.1,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.0,
                                color: Color(0xFF0F172A), // Slate 900
                              ),
                            ),
                            Text(
                              data["titlePart2"]!,
                              style: TextStyle(
                                fontSize: 38, // Increased
                                height: 1.1,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.0,
                                color: _neonGreen,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Metrics Grid (Row of 3)
                            Row(
                              children: [
                                _buildMetricCard(
                                  data["metric1"],
                                  data["metric1Label"],
                                ),
                                const SizedBox(width: 10),
                                _buildMetricCard(
                                  data["metric2"],
                                  data["metric2Label"],
                                ),
                                const SizedBox(width: 10),
                                _buildMetricCard(
                                  data["metric3"],
                                  data["metric3Label"],
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Large Feature Description Card
                            Container(
                              padding: const EdgeInsets.all(18), // Increased
                              decoration: BoxDecoration(
                                color: _cardDark,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _cardBorder),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0FDFA), // Teal 50
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.check_circle_outline,
                                      color: _neonGreen.withOpacity(0.8),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data["cardTitle"]!,
                                          style: const TextStyle(
                                            color: Color(
                                              0xFF0F172A,
                                            ), // Slate 900
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          data["cardDesc"]!,
                                          style: TextStyle(
                                            color: _textGrey,
                                            fontSize: 13,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // 3 Mini Features Row
                            Row(
                              children: [
                                _buildMiniFeatureCard(
                                  data["feature1Icon"],
                                  data["feature1Label"],
                                ),
                                const SizedBox(width: 10),
                                _buildMiniFeatureCard(
                                  data["feature2Icon"],
                                  data["feature2Label"],
                                ),
                                const SizedBox(width: 10),
                                _buildMiniFeatureCard(
                                  data["feature3Icon"],
                                  data["feature3Label"],
                                ),
                              ],
                            ),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button (only show if not on first page)
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _currentPage > 0 ? 1.0 : 0.0,
                    child: IgnorePointer(
                      ignoring: _currentPage == 0,
                      child: GestureDetector(
                        onTap: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.fastOutSlowIn,
                          );
                        },
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFF0FDFA),
                            border: Border.all(
                              color: _neonGreen.withOpacity(0.3),
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: _neonGreen,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Next / Finish Button
                  GestureDetector(
                    onTap: () {
                      if (_currentPage == onboardingData.length - 1) {
                        _completeOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.fastOutSlowIn,
                        );
                      }
                    },
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF0FDFA),
                        border: Border.all(color: _neonGreen.withOpacity(0.3)),
                      ),
                      child: Icon(
                        _currentPage == onboardingData.length - 1
                            ? Icons.check
                            : Icons.arrow_forward_rounded,
                        color: _neonGreen,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String value, String label) {
    return Expanded(
      child: Container(
        height: 90,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(
          color: _cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cardBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                color: _neonGreen,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textGrey,
                fontSize: 11,
                height: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniFeatureCard(IconData icon, String label) {
    return Expanded(
      child: Container(
        height: 95,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(
          color: _cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cardBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _neonGreen.withOpacity(0.7), size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textGrey,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RotatingOrbit extends StatelessWidget {
  final Animation<double> animation;
  final double size;
  final Color color;
  final bool reverse;
  final double speedMultiplier;

  const RotatingOrbit({
    Key? key,
    required this.animation,
    required this.size,
    required this.color,
    this.reverse = false,
    this.speedMultiplier = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final angle = animation.value * 2 * 3.14159265359 * speedMultiplier;
        return Transform.rotate(angle: reverse ? -angle : angle, child: child);
      },
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            // Sweep Gradient Trail
            Positioned.fill(
              child: CustomPaint(painter: OrbitPainter(color: color)),
            ),
            // Glowing Dot at angle 0 (right edge vertically centered)
            Align(
              alignment: Alignment.centerRight,
              child: Transform.translate(
                offset: const Offset(3, 0), // Adjust for dot radius
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.9),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrbitPainter extends CustomPainter {
  final Color color;
  OrbitPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Draw the faint full circle track
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = color.withOpacity(0.04);
    canvas.drawOval(rect, trackPaint);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    paint.shader = SweepGradient(
      colors: [
        Colors.transparent,
        Colors.transparent,
        color.withOpacity(0.1),
        color.withOpacity(0.8),
        color,
      ],
      stops: const [0.0, 0.5, 0.8, 0.98, 1.0],
    ).createShader(rect);

    // Draw the glowing trail
    canvas.drawArc(rect, 0, 2 * 3.14159265359, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
