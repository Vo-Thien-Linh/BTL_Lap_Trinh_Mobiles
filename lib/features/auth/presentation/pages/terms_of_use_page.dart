import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Điều khoản sử dụng',
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
                                  Icons.gavel_rounded,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'ĐIỀU KHOẢN SỬ DỤNG',
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
                            'Chào mừng bạn đến với ứng dụng của chúng tôi. Vui lòng đọc kỹ các Điều khoản sử dụng dưới đây trước khi đăng ký tài khoản hoặc sử dụng ứng dụng.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textBody,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Khi truy cập, đăng ký hoặc sử dụng ứng dụng, bạn xác nhận rằng bạn đã đọc, hiểu và đồng ý bị ràng buộc bởi các điều khoản được quy định trong tài liệu này.',
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

                    // Section 1
                    _buildSectionCard(
                      title: '1. Giới thiệu ứng dụng',
                      icon: Icons.info_outline_rounded,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ứng dụng này được phát triển bởi nhóm sinh viên thuộc Khoa Công nghệ Thông tin nhằm phục vụ cho đồ án học phần Lập trình Mobile.',
                            style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textBody),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Đây là sản phẩm phục vụ mục đích:',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textBody),
                          ),
                          const SizedBox(height: 4),
                          _buildBulletPoint('Học tập'),
                          _buildBulletPoint('Nghiên cứu'),
                          _buildBulletPoint('Thực hành phát triển ứng dụng di động'),
                          _buildBulletPoint('Báo cáo và đánh giá học phần'),
                          const SizedBox(height: 8),
                          const Text(
                            'Ứng dụng không mang mục đích thương mại, không kinh doanh và không thu phí người dùng.',
                            style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textBody, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),

                    // Section 2
                    _buildSectionCard(
                      title: '2. Điều kiện sử dụng',
                      icon: Icons.assignment_turned_in_outlined,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Khi sử dụng ứng dụng, người dùng cam kết:',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textBody),
                          ),
                          const SizedBox(height: 6),
                          _buildBulletPoint('Cung cấp thông tin chính xác khi đăng ký tài khoản.'),
                          _buildBulletPoint('Không sử dụng ứng dụng vào các hành vi vi phạm pháp luật.'),
                          _buildBulletPoint('Không can thiệp, phá hoại hoặc gây ảnh hưởng đến hệ thống ứng dụng.'),
                          _buildBulletPoint('Không sử dụng dữ liệu hoặc nội dung trong ứng dụng cho mục đích trái phép.'),
                          const SizedBox(height: 8),
                          const Text(
                            'Chúng tôi có quyền từ chối hoặc tạm ngừng quyền truy cập nếu phát hiện hành vi vi phạm điều khoản.',
                            style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textBody),
                          ),
                        ],
                      ),
                    ),

                    // Section 3
                    _buildSectionCard(
                      title: '3. Quyền sở hữu nội dung',
                      icon: Icons.copyright_rounded,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Toàn bộ giao diện, mã nguồn, hình ảnh, dữ liệu và nội dung liên quan đến ứng dụng thuộc quyền quản lý của nhóm phát triển đồ án.',
                            style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textBody),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Nghiêm cấm mọi hành vi:',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textBody),
                          ),
                          const SizedBox(height: 6),
                          _buildBulletPoint('Sao chép'),
                          _buildBulletPoint('Chỉnh sửa'),
                          _buildBulletPoint('Phân phối'),
                          _buildBulletPoint('Khai thác trái phép'),
                          const SizedBox(height: 8),
                          const Text(
                            'khi chưa có sự đồng ý của nhóm phát triển.',
                            style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textBody),
                          ),
                        ],
                      ),
                    ),

                    // Section 4
                    _buildSectionCard(
                      title: '4. Giới hạn trách nhiệm',
                      icon: Icons.report_problem_outlined,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ứng dụng được phát triển dưới hình thức đồ án học tập nên có thể tồn tại:',
                            style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textBody),
                          ),
                          const SizedBox(height: 6),
                          _buildBulletPoint('Lỗi kỹ thuật'),
                          _buildBulletPoint('Sai sót dữ liệu'),
                          _buildBulletPoint('Gián đoạn hệ thống'),
                          _buildBulletPoint('Hạn chế chức năng'),
                          const SizedBox(height: 8),
                          const Text(
                            'Nhóm phát triển không chịu trách nhiệm đối với:',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textBody),
                          ),
                          const SizedBox(height: 6),
                          _buildBulletPoint('Thiệt hại phát sinh do lỗi hệ thống'),
                          _buildBulletPoint('Mất mát dữ liệu ngoài ý muốn'),
                          _buildBulletPoint('Gián đoạn trong quá trình sử dụng ứng dụng'),
                          const SizedBox(height: 8),
                          const Text(
                            'Người dùng tự chịu trách nhiệm đối với thông tin được cung cấp và các hoạt động thực hiện trên tài khoản của mình.',
                            style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textBody),
                          ),
                        ],
                      ),
                    ),

                    // Section 5
                    _buildSectionCard(
                      title: '5. Thay đổi điều khoản',
                      icon: Icons.update_rounded,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chúng tôi có quyền cập nhật hoặc chỉnh sửa Điều khoản sử dụng vào bất kỳ thời điểm nào nhằm phù hợp với quá trình phát triển ứng dụng và yêu cầu học tập.',
                            style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textBody),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Phiên bản cập nhật sẽ có hiệu lực ngay khi được đăng tải trên ứng dụng.',
                            style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textBody, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),

                    // Section 6
                    _buildSectionCard(
                      title: '6. Liên hệ',
                      icon: Icons.contact_mail_outlined,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nếu có thắc mắc hoặc góp ý liên quan đến ứng dụng, vui lòng liên hệ nhóm phát triển thông qua:',
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

                    // Section 7
                    _buildSectionCard(
                      title: '7. Xác nhận đồng ý',
                      icon: Icons.check_circle_outline_rounded,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bằng việc nhấn nút “Đăng ký”, “Đăng nhập” hoặc tiếp tục sử dụng ứng dụng, bạn xác nhận rằng:',
                            style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textBody),
                          ),
                          const SizedBox(height: 6),
                          _buildBulletPoint('Đã đọc và hiểu Điều khoản sử dụng'),
                          _buildBulletPoint('Đồng ý với các quy định được nêu'),
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
