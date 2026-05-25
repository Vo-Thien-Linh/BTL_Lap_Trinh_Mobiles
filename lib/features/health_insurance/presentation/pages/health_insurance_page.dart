import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/health_insurance_service.dart';
import '../../utils/health_insurance_validator.dart';

class HealthInsurancePage extends StatefulWidget {
  const HealthInsurancePage({super.key});

  @override
  State<HealthInsurancePage> createState() => _HealthInsurancePageState();
}

class _HealthInsurancePageState extends State<HealthInsurancePage> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  final _service = HealthInsuranceService();

  bool _isLoading = true;
  bool _isSaving = false;
  HealthInsuranceInfo? _currentInfo;

  @override
  void initState() {
    super.initState();
    _loadInsurance();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadInsurance() async {
    setState(() => _isLoading = true);

    try {
      final info = await _service.getCurrentInsurance();
      if (!mounted) return;

      _currentInfo = info;
      _controller.text = info?.number ?? '';
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Không thể tải thông tin BHYT: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveInsurance() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      await _service.saveInsuranceNumber(_controller.text);
      await _loadInsurance();

      if (!mounted) return;
      _showSnackBar(
        'Đã cập nhật mã BHYT thành công. Thông tin đang chờ xác minh.',
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Không thể lưu BHYT: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'verified':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('BHYT'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 18),
              _buildFormCard(),
              const SizedBox(height: 18),
              _buildNoteCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final status = _currentInfo?.status ?? 'unverified';
    final hasNumber = _currentInfo?.hasNumber == true;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.health_and_safety_outlined,
                  color: Colors.green,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bảo hiểm y tế',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Hỗ trợ đặt lịch và đối chiếu thông tin khám chữa bệnh',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (hasNumber) ...[
            Text(
              _currentInfo!.number,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _statusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              hasNumber ? _currentInfo!.statusLabel : 'Chưa thêm BHYT',
              style: TextStyle(
                color: _statusColor(status),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentInfo?.hasNumber == true
                  ? 'Cập nhật mã BHYT'
                  : 'Thêm mã BHYT',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
              ],
              decoration: InputDecoration(
                labelText: 'Mã số thẻ BHYT',
                hintText: 'Ví dụ: DN4010123456789',
                prefixIcon: const Icon(Icons.credit_card),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              validator: HealthInsuranceValidator.validate,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveInsurance,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  'Lưu thông tin BHYT',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'Lưu ý: Hệ thống hiện chỉ kiểm tra định dạng mã BHYT. Việc xác minh mã có tồn tại, còn hạn hoặc đúng người cần kết nối dữ liệu chính thức hoặc được nhân viên/admin xác nhận.',
        style: TextStyle(height: 1.45),
      ),
    );
  }
}
