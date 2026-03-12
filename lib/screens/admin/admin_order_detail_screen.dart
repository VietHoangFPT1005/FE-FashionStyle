import 'package:flutter/material.dart';
import '../../services/service_locator.dart';
import '../../utils/helpers.dart';
import '../../widgets/common/loading_widget.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  final int orderId;
  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await sl.adminService.getOrderDetail(widget.orderId);
      if (res.success && res.data is Map<String, dynamic>) {
        setState(() => _order = res.data as Map<String, dynamic>);
      } else {
        setState(() => _error = res.message ?? 'Không tìm thấy đơn hàng');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _isLoading = false);
  }

  Future<void> _confirmOrder() async {
    try {
      final res = await sl.adminService.confirmOrder(widget.orderId);
      if (res.success) {
        Helpers.showSnackBar(context, 'Đã xác nhận đơn hàng!');
        _loadDetail();
      } else {
        Helpers.showSnackBar(context, res.message ?? 'Thất bại', isError: true);
      }
    } catch (_) {
      Helpers.showSnackBar(context, 'Có lỗi xảy ra', isError: true);
    }
  }

  Future<void> _assignShipper() async {
    // Load danh sách shipper (role=4)
    List<Map<String, dynamic>> shippers = [];
    try {
      final res = await sl.adminService.getUsers(role: 4, isActive: true, pageSize: 50);
      if (res.success && res.data != null) {
        final data = res.data;
        final list = data is List ? data : (data is Map ? data['items'] as List? ?? [] : []);
        shippers = list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}

    if (!mounted) return;
    if (shippers.isEmpty) {
      Helpers.showSnackBar(context, 'Không có shipper nào đang hoạt động', isError: true);
      return;
    }

    int? selectedId;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Chọn Shipper'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: shippers.length,
              itemBuilder: (_, i) {
                final s = shippers[i];
                final id = s['userId'] ?? s['id'] as int;
                final name = s['fullName'] ?? s['name'] ?? 'Shipper $id';
                final phone = s['phone'] ?? s['phoneNumber'] ?? '';
                return RadioListTile<int>(
                  value: id,
                  groupValue: selectedId,
                  onChanged: (v) => setLocal(() => selectedId = v),
                  title: Text(name.toString(), style: const TextStyle(fontSize: 14)),
                  subtitle: phone.toString().isNotEmpty ? Text(phone.toString(), style: const TextStyle(fontSize: 12)) : null,
                  dense: true,
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            TextButton(
              onPressed: selectedId != null ? () => Navigator.pop(ctx, true) : null,
              child: const Text('Giao đơn', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    ).then((confirmed) async {
      if (confirmed == true && selectedId != null) {
        try {
          final res = await sl.adminService.assignShipper(widget.orderId, selectedId!);
          if (!mounted) return;
          if (res.success) {
            Helpers.showSnackBar(context, 'Đã giao đơn cho shipper!');
            _loadDetail();
          } else {
            Helpers.showSnackBar(context, res.message ?? 'Thất bại', isError: true);
          }
        } catch (_) {
          Helpers.showSnackBar(context, 'Có lỗi xảy ra', isError: true);
        }
      }
    });
  }

  Future<void> _cancelOrder() async {
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lý do hủy'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Nhập lý do...'), maxLines: 2),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Xác nhận', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    try {
      final res = await sl.adminService.cancelOrder(widget.orderId, reason);
      if (res.success) {
        Helpers.showSnackBar(context, 'Đã hủy đơn hàng');
        _loadDetail();
      } else {
        Helpers.showSnackBar(context, res.message ?? 'Thất bại', isError: true);
      }
    } catch (_) {
      Helpers.showSnackBar(context, 'Có lỗi xảy ra', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_order != null ? (_order!['orderCode'] ?? 'Chi tiết đơn hàng') : 'Chi tiết đơn hàng'),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _loadDetail, child: const Text('Thử lại')),
                  ],
                ))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final o = _order!;
    final status = (o['status'] ?? '').toString().toUpperCase();
    final total = (o['total'] as num?)?.toDouble() ?? 0.0;
    final items = (o['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final address = o['shippingAddress'] as Map<String, dynamic>?;

    return RefreshIndicator(
      onRefresh: _loadDetail,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status + code
          _card([
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(o['orderCode'] ?? '#${o['orderId']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Helpers.getOrderStatusColor(status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(Helpers.getOrderStatusText(status),
                    style: TextStyle(color: Helpers.getOrderStatusColor(status), fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ]),
            const SizedBox(height: 8),
            if (o['createdAt'] != null)
              _infoRow(Icons.access_time, 'Ngày đặt', _formatDate(o['createdAt'].toString())),
            if (o['customerName'] != null)
              _infoRow(Icons.person_outline, 'Khách hàng', o['customerName'].toString()),
            if (o['customerPhone'] != null)
              _infoRow(Icons.phone_outlined, 'Điện thoại', o['customerPhone'].toString()),
          ]),

          const SizedBox(height: 12),

          // Shipping address
          if (address != null)
            _card([
              _sectionTitle('Địa chỉ giao hàng'),
              _infoRow(Icons.person, 'Người nhận', address['fullName']?.toString() ?? ''),
              _infoRow(Icons.phone, 'SĐT', address['phone']?.toString() ?? ''),
              _infoRow(Icons.location_on_outlined, 'Địa chỉ',
                  [address['addressLine'], address['ward'], address['district'], address['city']]
                      .where((e) => e != null && e.toString().isNotEmpty)
                      .join(', ')),
            ]),

          if (address != null) const SizedBox(height: 12),

          // Order items
          _card([
            _sectionTitle('Sản phẩm (${items.length})'),
            ...items.map((item) => _buildItemRow(item)),
          ]),

          const SizedBox(height: 12),

          // Payment summary
          _card([
            _sectionTitle('Thanh toán'),
            if (o['subtotal'] != null)
              _amountRow('Tạm tính', (o['subtotal'] as num).toDouble()),
            if (o['shippingFee'] != null)
              _amountRow('Phí vận chuyển', (o['shippingFee'] as num).toDouble()),
            if (o['discountAmount'] != null && (o['discountAmount'] as num) > 0)
              _amountRow('Giảm giá', -(o['discountAmount'] as num).toDouble(), color: Colors.green),
            const Divider(),
            _amountRow('Tổng cộng', total, bold: true),
            if (o['paymentMethod'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _infoRow(Icons.payment, 'Thanh toán', o['paymentMethod'].toString()),
              ),
          ]),

          // Action buttons
          if (status != 'DELIVERED' && status != 'CANCELLED') ...[
            const SizedBox(height: 16),
            Column(children: [
              if (status == 'PENDING')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _confirmOrder,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Xác nhận đơn hàng'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              if (status == 'CONFIRMED') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _assignShipper,
                    icon: const Icon(Icons.delivery_dining),
                    label: const Text('Giao cho Shipper'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _cancelOrder,
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                  label: const Text('Hủy đơn', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ]),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item) {
    final img = item['thumbnailUrl'] ?? item['imageUrl'];
    final name = item['productName'] ?? item['name'] ?? '';
    final variant = item['variantName'] ?? item['size'] ?? '';
    final qty = item['quantity'] ?? 1;
    final price = (item['price'] as num?)?.toDouble() ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: img != null
                ? Image.network(img.toString(), width: 50, height: 50, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imgPlaceholder())
                : _imgPlaceholder(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                if (variant.toString().isNotEmpty)
                  Text(variant.toString(), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                Text('SL: $qty', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Text(Helpers.formatCurrency(price * qty), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _card(List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
  );

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: Colors.grey),
        const SizedBox(width: 6),
        SizedBox(width: 90, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
      ],
    ),
  );

  Widget _amountRow(String label, double amount, {bool bold = false, Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      Text(
        (amount < 0 ? '- ' : '') + Helpers.formatCurrency(amount.abs()),
        style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.w500, color: color),
      ),
    ]),
  );

  Widget _imgPlaceholder() => Container(width: 50, height: 50, color: Colors.grey.shade200, child: const Icon(Icons.image_outlined, size: 20, color: Colors.grey));

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
