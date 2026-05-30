import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Chính sách bảo mật',
          style: TextStyle(
            color: AppColors.textBody,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textBody),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Header Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryLight,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.security_rounded,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'CHÍNH SÁCH BẢO MẬT',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryDark,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Chính sách bảo mật này giải thích cách chúng tôi thu thập, sử dụng và bảo vệ thông tin cá nhân của bạn khi sử dụng ứng dụng.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textBody,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Bằng việc tiếp tục đăng ký, đăng nhập hoặc sử dụng ứng dụng, bạn đồng ý với việc thu thập và xử lý dữ liệu phục vụ mục đích học tập và nghiên cứu theo quy định của chính sách này.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textBody,
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 1: Thu thập thông tin
                    _buildSectionCard(
                      title: '1. Thu thập thông tin người dùng',
                      icon: Icons.person_search_outlined,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Trong quá trình sử dụng, ứng dụng có thể thu thập một số thông tin cơ bản bao gồm:',
                            style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textBody),
                          ),
                          const SizedBox(height: 6),
                          _buildBulletPoint('Họ và tên'),
                          _buildBulletPoint('Địa chỉ email'),
                          _buildBulletPoint('Số điện thoại'),
                          _buildBulletPoint('Thông tin đăng nhập'),
                          _buildBulletPoint('Dữ liệu sử dụng ứng dụng (nhật ký hoạt động trong hệ thống)'),
                        ],
                      ),
                    ),

                    // Section 2: Sử dụng thông tin
                    _buildSectionCard(
                      title: '2. Mục đích sử dụng thông tin',
                      icon: Icons.help_outline_rounded,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Các thông tin này được thu thập nhằm mục đích phục vụ cho đồ án học phần Lập trình Mobile, cụ thể:',
                            style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textBody),
                          ),
                          const SizedBox(height: 6),
                          _buildBulletPoint('Xác thực tài khoản người dùng'),
                          _buildBulletPoint('Hỗ trợ đăng nhập và sử dụng các tính năng của hệ thống'),
                          _buildBulletPoint('Phục vụ kiểm thử chức năng của ứng dụng di động'),
                          _buildBulletPoint('Phân tích và cải thiện trải nghiệm người dùng phục vụ nghiên cứu'),
                          _buildBulletPoint('Hoàn thiện đồ án học tập và báo cáo học phần'),
                        ],
                      ),
                    ),

                    // Section 3: Cam kết bảo mật
                    _buildSectionCard(
                      title: '3. Cam kết bảo mật dữ liệu',
                      icon: Icons.vpn_key_outlined,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nhóm phát triển cam kết thực hiện bảo mật dữ liệu của bạn:',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textBody),
                          ),
                          const SizedBox(height: 6),
                          _buildBulletPoint('Không bán, chia sẻ hoặc trao đổi dữ liệu người dùng cho bất kỳ bên thứ ba nào.'),
                          _buildBulletPoint('Không sử dụng thông tin cá nhân cho bất kỳ mục đích thương mại nào.'),
                          _buildBulletPoint('Chỉ sử dụng dữ liệu trong phạm vi học tập, nghiên cứu và báo cáo học phần.'),
                          _buildBulletPoint('Áp dụng các biện pháp kỹ thuật phù hợp nhằm bảo vệ dữ liệu người dùng trên Firebase Database.'),
                          const SizedBox(height: 8),
                          const Text(
                            'Lưu ý: Do đây là dự án học tập phục vụ nghiên cứu của sinh viên, chúng tôi không thể đảm bảo tuyệt đối 100% về tính an toàn và bảo mật hoàn hảo trước các cuộc tấn công mạng bên ngoài.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Section 4: Liên hệ
                    _buildSectionCard(
                      title: '4. Thông tin liên hệ',
                      icon: Icons.contact_mail_outlined,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nếu có thắc mắc hoặc góp ý liên quan đến chính sách bảo mật này, vui lòng liên hệ nhóm phát triển thông qua:',
                            style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textBody),
                          ),
                          const SizedBox(height: 8),
                          _buildContactRow(Icons.email_outlined, 'Email: 6451071023@st.utc2.edu.vn'),
                          const SizedBox(height: 6),
                          _buildContactRow(Icons.location_on_outlined, 'Địa chỉ: 450-451 Lê Văn Việt, Phường Tăng Nhơn Phú A, Thành Phố Thủ Đức, Thành Phố Hồ Chí Minh'),
                          const SizedBox(height: 6),
                          _buildContactRow(Icons.group_outlined, 'Nhóm phát triển: Sinh viên Khoa Công nghệ Thông tin'),
                        ],
                      ),
                    ),

                    // Section 5: Xác nhận
                    _buildSectionCard(
                      title: '5. Xác nhận đồng ý',
                      icon: Icons.check_circle_outline_rounded,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bằng việc nhấn nút “Đăng ký”, “Đăng nhập” hoặc tiếp tục sử dụng ứng dụng, bạn xác nhận rằng:',
                            style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textBody),
                          ),
                          const SizedBox(height: 6),
                          _buildBulletPoint('Đã đọc và hiểu Chính sách bảo mật dữ liệu này'),
                          _buildBulletPoint('Chấp nhận việc thu thập và xử lý dữ liệu phục vụ mục đích học tập và nghiên cứu như đã nêu'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Đóng',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textBody,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: AppColors.border, height: 1),
          ),
          content,
        ],
      ),
    );
  }

  static Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(
              Icons.circle,
              size: 6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textBody,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textBody,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
