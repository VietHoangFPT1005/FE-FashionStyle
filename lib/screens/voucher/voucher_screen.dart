import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/voucher/voucher.dart';
import '../../services/service_locator.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/empty_widget.dart';
import '../../utils/helpers.dart';

class VoucherScreen extends StatefulWidget {
  const VoucherScreen({super.key});

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  List<Voucher> _vouchers = [];
  bool _isLoading = true;
  String? _error;


  @override
  void initState() {
    super.initState();
    // services from sl
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await sl.voucherService.getAvailableVouchers();
      if (res.success) {
        setState(() => _vouchers = res.data ?? []);
      } else {
        setState(() => _error = res.message.isNotEmpty ? res.message : 'Không tải được voucher');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Voucher của tôi',
          style: GoogleFonts.cormorantGaramond(
              color: Colors.black, fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const LoadingWidget();
    if (_error != null) return AppErrorWidget(message: _error!, onRetry: _loadVouchers);
    if (_vouchers.isEmpty) {
      return const EmptyWidget(
          icon: Icons.confirmation_number_outlined,
          message: 'Hiện chưa có voucher nào đang hoạt động');
    }

    return RefreshIndicator(
      color: Colors.black,
      onRefresh: _loadVouchers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _vouchers.length,
        itemBuilder: (_, i) => _buildVoucherCard(_vouchers[i]),
      ),
    );
  }

  Widget _buildVoucherCard(Voucher voucher) {
    final isExpired = !voucher.isValid;
    return Opacity(
      opacity: isExpired ? 0.55 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left: discount badge
              Container(
                width: 90,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                color: isExpired ? Colors.grey.shade400 : Colors.black,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(voucher.displayDiscount,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                      textAlign: TextAlign.center),
                    const SizedBox(height: 2),
                    Text(voucher.isPercentage ? 'GIẢM' : 'VNĐ',
                      style: const TextStyle(color: Colors.white70, fontSize: 10,
                          letterSpacing: 1)),
                  ],
                ),
              ),
              // Dashed divider
              Container(
                width: 1,
                color: Colors.grey.shade200,
              ),
              // Right: info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(voucher.code,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15,
                                letterSpacing: 1.5)),
                        ),
                        if (!isExpired)
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: voucher.code));
                              Helpers.showSnackBar(context, 'Đã sao chép mã ${voucher.code}');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black),
                              ),
                              child: const Text('Sao chép',
                                style: TextStyle(
                                    color: Colors.black, fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                            ),
                          ),
                      ]),
                      if (voucher.description != null) ...[
                        const SizedBox(height: 6),
                        Text(voucher.description!,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        children: [
                          if (voucher.minimumOrderAmount != null)
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.info_outline,
                                  size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 3),
                              Text(
                                'Đơn tối thiểu: ${Helpers.formatCurrency(voucher.minimumOrderAmount!)}',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade500)),
                            ]),
                          if (voucher.endDate != null)
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.schedule,
                                  size: 12,
                                  color: isExpired
                                      ? Colors.red : Colors.grey.shade500),
                              const SizedBox(width: 3),
                              Text(
                                'HSD: ${Helpers.formatDate(voucher.endDate!)}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: isExpired
                                        ? Colors.red : Colors.grey.shade500)),
                            ]),
                        ],
                      ),
                      if (isExpired) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          color: Colors.grey.shade200,
                          child: const Text('Đã hết hạn',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey,
                                fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
