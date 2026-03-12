import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/refund/refund.dart';
import '../../services/service_locator.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/custom_button.dart';
import '../../utils/helpers.dart';

class RefundScreen extends StatefulWidget {
  final int orderId;
  const RefundScreen({super.key, required this.orderId});

  @override
  State<RefundScreen> createState() => _RefundScreenState();
}

class _RefundScreenState extends State<RefundScreen> {
  final _reasonCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Refund? _refund;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _hasExistingRefund = false;


  @override
  void initState() {
    super.initState();
    // services from sl
    _checkExistingRefund();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkExistingRefund() async {
    try {
      final res = await sl.refundService.getRefund(widget.orderId);
      if (res.success && res.data != null) {
        setState(() { _refund = res.data; _hasExistingRefund = true; });
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _submitRefund() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final request = CreateRefundRequest(reason: _reasonCtrl.text.trim());
      final res = await sl.refundService.requestRefund(widget.orderId, request);
      if (res.success && res.data != null) {
        setState(() { _refund = res.data; _hasExistingRefund = true; });
        if (mounted) Helpers.showSnackBar(context, 'Đã gửi yêu cầu hoàn trả!');
      } else {
        if (mounted) Helpers.showSnackBar(context, res.message ?? 'Gửi thất bại', isError: true);
      }
    } catch (_) {
      if (mounted) Helpers.showSnackBar(context, 'Gửi yêu cầu thất bại. Vui lòng thử lại.', isError: true);
    }
    setState(() => _isSubmitting = false);
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
          'Yêu cầu hoàn trả',
          style: GoogleFonts.cormorantGaramond(
              color: Colors.black, fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : (_hasExistingRefund ? _buildRefundStatus() : _buildRefundForm()),
    );
  }

  Widget _buildRefundForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Vui lòng mô tả lý do bạn muốn hoàn trả đơn hàng này.',
                    style: TextStyle(fontSize: 13)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            const Text('Lý do hoàn trả *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 10),
            // Quick reason chips
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                _buildReasonChip('Sản phẩm bị lỗi'),
                _buildReasonChip('Sai sản phẩm'),
                _buildReasonChip('Không đúng mô tả'),
                _buildReasonChip('Thay đổi ý định'),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reasonCtrl,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Mô tả chi tiết lý do hoàn trả...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Colors.black)),
                contentPadding: const EdgeInsets.all(14),
                filled: true, fillColor: Colors.white,
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Vui lòng nhập lý do' : null,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'GỬI YÊU CẦU HOÀN TRẢ',
              isLoading: _isSubmitting,
              onPressed: _submitRefund,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonChip(String reason) {
    return ActionChip(
      label: Text(reason, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade300),
      onPressed: () {
        if (_reasonCtrl.text.isNotEmpty && !_reasonCtrl.text.endsWith('. ')) {
          _reasonCtrl.text += '. ';
        }
        _reasonCtrl.text += reason;
      },
    );
  }

  Widget _buildRefundStatus() {
    final refund = _refund!;
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (refund.isPending) {
      statusColor = Colors.orange;
      statusIcon = Icons.hourglass_top_rounded;
      statusText = 'Đang chờ xử lý';
    } else if (refund.isApproved) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_rounded;
      statusText = 'Đã chấp nhận';
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.cancel_rounded;
      statusText = 'Đã từ chối';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Status card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            color: Colors.white,
            child: Column(
              children: [
                Icon(statusIcon, size: 64, color: statusColor),
                const SizedBox(height: 12),
                Text(statusText,
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: statusColor)),
                if (refund.isPending) ...[
                  const SizedBox(height: 8),
                  Text('Yêu cầu của bạn đang được xem xét',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Details card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chi tiết yêu cầu',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                _buildDetailRow('Mã đơn hàng', refund.orderCode ?? '#${refund.orderId}'),
                _buildDivider(),
                _buildDetailRow('Ngày yêu cầu',
                    refund.createdAt != null ? Helpers.formatDateTime(refund.createdAt!) : '-'),
                _buildDivider(),
                _buildDetailRow('Trạng thái', statusText),
                if (refund.orderTotal != null) ...[
                  _buildDivider(),
                  _buildDetailRow('Giá trị đơn', Helpers.formatCurrency(refund.orderTotal!)),
                ],
                if (refund.processedAt != null) ...[
                  _buildDivider(),
                  _buildDetailRow('Ngày xử lý', Helpers.formatDateTime(refund.processedAt!)),
                ],
                if (refund.processedByName != null) ...[
                  _buildDivider(),
                  _buildDetailRow('Xử lý bởi', refund.processedByName!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Reason card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lý do hoàn trả',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                Text(refund.reason,
                    style: const TextStyle(height: 1.5, fontSize: 14, color: Colors.black87)),
              ],
            ),
          ),

          if (refund.adminNote != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(left: BorderSide(color: statusColor, width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Phản hồi từ quản trị',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  Text(refund.adminNote!,
                      style: const TextStyle(height: 1.5, fontSize: 14)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDivider() =>
      Divider(color: Colors.grey.shade100, height: 16, thickness: 1);

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  // fix submit messages
}
