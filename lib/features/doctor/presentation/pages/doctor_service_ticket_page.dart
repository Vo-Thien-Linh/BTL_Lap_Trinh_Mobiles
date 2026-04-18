import 'package:flutter/material.dart';

class DoctorServiceTicketPage extends StatelessWidget {
  final Map<String, dynamic> patientData;
  final List<Map<String, dynamic>> services;

  const DoctorServiceTicketPage({
    super.key,
    required this.patientData,
    required this.services,
  });

  @override
  Widget build(BuildContext context) {
    // For demo, we show the first service details or a summary
    final primaryService = services.isNotEmpty ? services[0] : {'name': 'Chưa chọn', 'price': '0đ', 'category': '-'};
    final totalAmount = services.fold<int>(0, (sum, item) {
      final priceStr = item['price'].replaceAll('đ', '').replaceAll(',', '');
      return sum + int.parse(priceStr);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      appBar: AppBar(
        title: const Text('Phiếu Chỉ Định Dịch Vụ', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF15233D),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                children: [
                  // Branding & Header
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text(
                          'Bệnh viện Đa khoa MedCare',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF15233D)),
                        ),
                        const Text(
                          '123 Đường Số 1, Phường Bến Nghé, Quận 1, TP. HCM',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: Color(0xFF8A95AC)),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'PHIẾU CHỈ ĐỊNH DỊCH VỤ',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0E47B5), letterSpacing: 1.2),
                        ),
                        Text(
                          'Mã phiếu: SR${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF8A95AC)),
                        ),
                      ],
                    ),
                  ),
                  
                  // Service Spotlight
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    color: const Color(0xFFF8FAFD),
                    child: Column(
                      children: [
                        Text(
                          primaryService['name'].toUpperCase(),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF15233D)),
                        ),
                        const Text(
                          'Phòng Kỹ Thuật Chuyên Khoa - Tầng 2',
                          style: TextStyle(fontSize: 13, color: Color(0xFF0E9F6E), fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        const Text('STT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8A95AC))),
                        const SizedBox(height: 4),
                        Container(
                          width: 50,
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF0E9F6E), width: 2),
                          ),
                          child: const Text('1', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0E9F6E))),
                        ),
                      ],
                    ),
                  ),

                  // Patient Grid
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _infoGridRow('Họ tên:', patientData['patientName'].toUpperCase()),
                        _infoGridRow('Mã người bệnh:', 'BNHY1000'),
                        _infoGridRow('Ngày sinh:', patientData['dob']),
                        _infoGridRow('Ngày chỉ định:', '16/04/2026 (19:30)'),
                        _infoGridRow('Tiền dịch vụ:', '${totalAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]},")} đồng', valueColor: const Color(0xFF0E9F6E)),
                        _infoGridRow('Đối tượng:', 'BHYT'),
                        _infoGridRow('Chẩn đoán:', 'Đau đầu chưa rõ nguyên nhân'),
                      ],
                    ),
                  ),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      children: List.generate(20, (index) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 1,
                          color: Colors.grey[300],
                        ),
                      )),
                    ),
                  ),

                  // Payment Section
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text(
                          'QUÉT MÃ THANH TOÁN NGAY',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0E47B5)),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[200]!, width: 2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Image.network(
                            'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=PAYMENT_MOCK',
                            width: 150,
                            height: 150,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${totalAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]},")} VND',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFD32F2F)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildActionButtons(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _infoGridRow(String label, String value, {Color valueColor = const Color(0xFF15233D)}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF8A95AC), fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0E9F6E).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã gửi yêu cầu in phiếu!')),
          );
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0E9F6E),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: const Text('XÁC NHẬN & IN PHIẾU', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
      ),
    );
  }
}
