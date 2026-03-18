import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_routes.dart';
import '../../services/service_locator.dart';
import '../../services/local_notification_service.dart';
import '../../utils/helpers.dart';
import '../../widgets/common/custom_button.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> paymentData;
  const PaymentScreen({super.key, required this.paymentData});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Timer? _pollTimer;
  bool _isPaid = false;


  String get _bankAccount => widget.paymentData['bankAccount'] ?? '';
  String get _bankName => widget.paymentData['bankName'] ?? 'Ngân hàng';
  String get _transferContent => widget.paymentData['transferContent'] ?? '';
  double get _amount => (widget.paymentData['amount'] as num?)?.toDouble() ?? 0;
  int get _orderId => widget.paymentData['orderId'] ?? 0;
  String get _qrUrl => widget.paymentData['qrUrl'] ?? '';

  @override
  void initState() {
    super.initState();
    // services from sl
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final res = await sl.paymentService.pollPaymentStatus(_orderId);
        if (res.success && res.data != null) {
          final data = res.data!;
          final isPaid = data['isPaid'] == true;
          final status = data['status'] as String? ?? '';
          if (isPaid || status == 'COMPLETED') {
            _pollTimer?.cancel();
            if (mounted) {
              final orderTotal = (widget.paymentData['orderTotal'] as num?)?.toDouble() ?? _amount;
              // Show local notification
              await LocalNotificationService.showPaymentSuccessNotification(
                orderId: _orderId,
                amount: orderTotal,
              );
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.orderSuccess,
                (r) => r.settings.name == AppRoutes.main,
                arguments: {
                  'orderId': _orderId,
                  'total': orderTotal,
                  'paymentMethod': 'SEPAY',
                },
              );
            }
          }
        }
      } catch (_) {}
    });
  }

  Future<bool> _onWillPop() async {
    if (_isPaid) return true;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(),
        title: Text('Hủy thanh toán?',
            style: GoogleFonts.cormorantGaramond(
                fontSize: 20, fontWeight: FontWeight.w700)),
        content: const Text(
            'Bạn chưa hoàn thành thanh toán. Đơn hàng sẽ bị hủy nếu bạn thoát.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Tiếp tục thanh toán',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Thoát & Hủy đơn',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      _pollTimer?.cancel();
      try {
        await sl.orderService.cancelOrder(_orderId, reason: 'Khách hàng không hoàn thành thanh toán');
      } catch (_) {}
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            'Thanh toán chuyển khoản',
            style: GoogleFonts.cormorantGaramond(
                color: Colors.black, fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        body: _isPaid ? _buildSuccessView() : _buildPaymentView(),
      ),
    );
  }

  Widget _buildPaymentView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // QR Code
          if (_qrUrl.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
                    blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(children: [
                Image.network(_qrUrl, width: 240, height: 240, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    width: 240, height: 240,
                    child: Center(child: Icon(Icons.qr_code, size: 100, color: Colors.grey)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Quét mã QR để thanh toán',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          // Bank info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                _buildInfoRow('Ngân hàng', _bankName),
                _buildDivider(),
                _buildInfoRow('Số tài khoản', _bankAccount, canCopy: true),
                _buildDivider(),
                _buildInfoRow('Số tiền', Helpers.formatCurrency(_amount)),
                _buildDivider(),
                _buildInfoRow('Nội dung CK', _transferContent, canCopy: true),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Warning
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(children: [
              Icon(Icons.warning_amber_outlined, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Vui lòng nhập đúng nội dung chuyển khoản để hệ thống tự động xác nhận.',
                  style: TextStyle(fontSize: 13)),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Status indicator
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)),
                const SizedBox(width: 10),
                const Text('Đang chờ xác nhận thanh toán...',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success icon
            Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green.shade200, width: 2),
              ),
              child: Icon(Icons.check_circle_rounded, size: 68, color: Colors.green.shade500),
            ),
            const SizedBox(height: 24),
            Text(
              'Thanh toán thành công!',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 28, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Đơn hàng #$_orderId của bạn đã được xác nhận\nvà đang được xử lý.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Amount paid badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border.all(color: Colors.green.shade200),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                Helpers.formatCurrency(_amount),
                style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold,
                  color: Colors.green.shade700),
              ),
            ),
            const SizedBox(height: 40),
            // Button: View Order Detail
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.orderDetail,
                  (r) => r.settings.name == AppRoutes.main,
                  arguments: _orderId,
                ),
                child: const Text('XEM ĐƠN HÀNG',
                  style: TextStyle(letterSpacing: 2.0, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
            const SizedBox(height: 12),
            // Button: Continue Shopping
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context, AppRoutes.main, (r) => false),
                child: const Text('TIẾP TỤC MUA SẮM',
                  style: TextStyle(letterSpacing: 2.0, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() =>
      Divider(color: Colors.grey.shade100, height: 16, thickness: 1);

  Widget _buildInfoRow(String label, String value, {bool canCopy = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Row(children: [
            Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            if (canCopy) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  Helpers.showSnackBar(context, 'Đã sao chép!');
                },
                child: const Icon(Icons.copy, size: 15, color: Colors.black54),
              ),
            ],
          ]),
        ],
      ),
    );
  }
}
