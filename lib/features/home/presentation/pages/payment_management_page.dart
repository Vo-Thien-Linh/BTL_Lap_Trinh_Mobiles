import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../appointment/presentation/payment_management_bloc/payment_bloc.dart';
import '../../../appointment/data/models/invoice_models.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';

class PaymentManagementPage extends StatefulWidget {
  const PaymentManagementPage({super.key});

  @override
  State<PaymentManagementPage> createState() => _PaymentManagementPageState();
}

class _PaymentManagementPageState extends State<PaymentManagementPage> {
  String _selectedStatus = 'Tất cả trạng thái';
  String _selectedType = 'Tất cả loại';

  final List<String> _statusOptions = ['Tất cả trạng thái', 'Đã thanh toán', 'Chưa thanh toán'];
  final List<String> _typeOptions = ['Tất cả loại', 'Tiền khám', 'Xét nghiệm', 'Thuốc'];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Vui lòng đăng nhập')));
    }

    return BlocProvider(
      create: (context) => PaymentBloc()..add(LoadInvoices(user.uid)),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: [
            _buildSliverAppBar(user.uid),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildFinancialSummary(),
                  _buildReminderBanner(),
                  _buildFilterSection(),
                ],
              ),
            ),
            _buildInvoiceListSliver(user.uid),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(String uid) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      centerTitle: true,
      expandedHeight: 120,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'THANH TOÁN & HÓA ĐƠN',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.2),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFF3B82F6)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
            ),
            Opacity(
              opacity: 0.1,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage('https://www.transparenttextures.com/patterns/white-diamond.png'),
                    repeat: ImageRepeat.repeat,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 24),
            onPressed: () => context.read<PaymentBloc>().add(RefreshInvoices(uid)),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialSummary() {
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        double paidTotal = 0;
        double pendingTotal = 0;
        
        for (var inv in state.allInvoices) {
          if (inv.status == 'paid') {
            paidTotal += inv.amount;
          } else {
            pendingTotal += inv.amount;
          }
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TỔNG CHI TIÊU Y TẾ', style: TextStyle(color: AppColors.textHint, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                    child: const Text('THÁNG NÀY', style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${NumberFormat('#,###').format(paidTotal + pendingTotal)} đ',
                style: const TextStyle(color: AppColors.textBody, fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildSummaryItem('Đã thanh toán', paidTotal, AppColors.success),
                  const SizedBox(width: 24),
                  Container(width: 1, height: 30, color: AppColors.border),
                  const SizedBox(width: 24),
                  _buildSummaryItem('Chờ xử lý', pendingTotal, AppColors.warning),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 4),
        Text('${NumberFormat('#,###').format(amount)} đ', style: const TextStyle(color: AppColors.textBody, fontSize: 13, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildReminderBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCE8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFEF9C3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle),
            child: const Icon(Icons.alarm_on_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lưu ý thanh toán', style: TextStyle(color: Color(0xFF854D0E), fontWeight: FontWeight.w900, fontSize: 13)),
                SizedBox(height: 2),
                Text(
                  'Thanh toán trước 19:30 để giữ lịch khám.',
                  style: TextStyle(color: Color(0xFFA16207), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          _buildScrollableChips(_statusOptions, _selectedStatus, (val) {
            setState(() => _selectedStatus = val);
          }),
          const SizedBox(height: 12),
          _buildScrollableChips(_typeOptions, _selectedType, (val) {
            setState(() => _selectedType = val);
          }),
        ],
      ),
    );
  }

  Widget _buildScrollableChips(List<String> options, String current, Function(String) onSelected) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = current == option;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                onSelected(option);
                context.read<PaymentBloc>().add(FilterInvoices(
                  status: _selectedStatus == _statusOptions[0] ? null : _selectedStatus,
                  type: _selectedType == _typeOptions[0] ? null : _selectedType,
                ));
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                  boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))] : null,
                ),
                child: Center(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInvoiceListSliver(String uid) {
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        if (state.status == PaymentStatus.loading || state.status == PaymentStatus.processing) {
          return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
        }

        final invoices = state.filteredInvoices;

        if (invoices.isEmpty) {
          return SliverFillRemaining(child: _buildEmptyState());
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final invoice = invoices[index];
                return _PremiumInvoiceCard(
                  invoice: invoice,
                  onPay: () => Navigator.pushNamed(context, AppRoutes.invoiceDetail, arguments: invoice),
                );
              },
              childCount: invoices.length,
            ),
          ),
        );
      },
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
            child: const Icon(Icons.receipt_long_rounded, size: 64, color: Color(0xFFCBD5E1)),
          ),
          const SizedBox(height: 24),
          const Text('Không tìm thấy hóa đơn', style: TextStyle(color: AppColors.textBody, fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Thử thay đổi bộ lọc hoặc làm mới danh sách', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _PremiumInvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;
  final VoidCallback onPay;

  const _PremiumInvoiceCard({required this.invoice, required this.onPay});

  @override
  Widget build(BuildContext context) {
    final bool isPaid = invoice.status == 'paid';
    final Color statusColor = isPaid ? AppColors.success : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: AppColors.textBody.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8)),
        ],
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: onPay,
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(_getIconForType(invoice.expenseType), color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              invoice.id.toUpperCase(),
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                isPaid ? 'ĐÃ TRẢ' : 'CHỜ TRẢ',
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          invoice.serviceContent,
                          style: const TextStyle(color: AppColors.textBody, fontWeight: FontWeight.w900, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd/MM/yyyy • HH:mm').format(invoice.createdAt),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TỔNG THANH TOÁN', style: TextStyle(color: AppColors.textHint, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      Text(
                        '${NumberFormat('#,###').format(invoice.amount)} đ',
                        style: const TextStyle(color: AppColors.textBody, fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                    ],
                  ),
                  isPaid
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(14)),
                          child: const Row(
                            children: [
                              Text('Chi tiết', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textSecondary)),
                              Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textSecondary),
                            ],
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF3B82F6)]),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: const Text('Thanh toán', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Tiền khám': return Icons.medical_services_rounded;
      case 'Xét nghiệm': return Icons.biotech_rounded;
      case 'Thuốc': return Icons.medication_rounded;
      default: return Icons.receipt_long_rounded;
    }
  }
}
