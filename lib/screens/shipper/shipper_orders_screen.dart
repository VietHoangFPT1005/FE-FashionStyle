import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../services/service_locator.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/empty_widget.dart';
import '../../utils/helpers.dart';

class ShipperOrdersScreen extends StatefulWidget {
  const ShipperOrdersScreen({super.key});

  @override
  State<ShipperOrdersScreen> createState() => _ShipperOrdersScreenState();
}

class _ShipperOrdersScreenState extends State<ShipperOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _error;
  String? _currentFilter;

  final _tabs = [
    {'label': 'Tất cả', 'status': null},
    {'label': 'Chờ lấy', 'status': 'PROCESSING'},
    {'label': 'Đang giao', 'status': 'SHIPPING'},
    {'label': 'Hoàn thành', 'status': 'DELIVERED'},
    {'label': 'Đã huỷ', 'status': 'CANCELLED'},
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() {
      if (_tabCtrl.indexIsChanging) {
        _loadOrders(_tabs[_tabCtrl.index]['status'] as String?);
      }
    });
    _loadOrders(null);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOrders(String? status) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentFilter = status;
    });
    try {
      final res = await sl.shipperService.getShipperOrders(status: status);
      if (res.success && res.data != null) {
        setState(() =>
            _orders = res.data is List ? res.data as List : []);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickupOrder(int orderId) async {
    final ctrl = TextEditingController();
    final trackingNumber = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(),
        title: Text('Nhập mã vận đơn',
            style: GoogleFonts.cormorantGaramond(
                fontSize: 18, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'VD: GHN123456789'),
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Hủy',
                  style: TextStyle(color: Colors.grey.shade600))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Xác nhận',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (trackingNumber == null || trackingNumber.isEmpty) return;
    try {
      final res = await sl.shipperService
          .pickupOrder(orderId, trackingNumber: trackingNumber);
      if (res.success) {
        Helpers.showSnackBar(context, 'Đã nhận đơn hàng! Bắt đầu giao.');
        _loadOrders(_currentFilter);
      } else {
        Helpers.showSnackBar(context, res.message ?? 'Thất bại',
            isError: true);
      }
    } catch (_) {
      Helpers.showSnackBar(context, 'Thao tác thất bại', isError: true);
    }
  }

  Future<void> _deliverOrder(int orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(),
        title: Text('Xác nhận giao hàng',
            style: GoogleFonts.cormorantGaramond(
                fontSize: 18, fontWeight: FontWeight.w700)),
        content: const Text(
            'Bạn đã giao hàng thành công cho khách hàng?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Hủy',
                  style: TextStyle(color: Colors.grey.shade600))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Đã giao',
                  style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final res = await sl.shipperService.deliverOrder(orderId);
      if (res.success) {
        Helpers.showSnackBar(context, 'Đã giao hàng thành công!');
        _loadOrders(_currentFilter);
      }
    } catch (_) {
      Helpers.showSnackBar(context, 'Thao tác thất bại', isError: true);
    }
  }

  Future<void> _failDelivery(int orderId) async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape: const RoundedRectangleBorder(),
          title: Text('Giao hàng thất bại',
              style: GoogleFonts.cormorantGaramond(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '* Lý do thất bại (bắt buộc)',
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: reasonCtrl,
                onChanged: (_) => setStateDialog(() {}),
                decoration: InputDecoration(
                  hintText: 'VD: Khách không nghe máy, sai địa chỉ...',
                  border: const OutlineInputBorder(),
                  errorText: reasonCtrl.text.trim().isEmpty ? null : null,
                ),
                maxLines: 2,
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Hủy',
                    style: TextStyle(color: Colors.grey.shade600))),
            TextButton(
                onPressed: reasonCtrl.text.trim().isEmpty
                    ? null // disabled khi chưa nhập
                    : () => Navigator.pop(ctx, reasonCtrl.text.trim()),
                child: Text(
                  'Báo cáo',
                  style: TextStyle(
                    color: reasonCtrl.text.trim().isEmpty
                        ? Colors.grey
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                )),
          ],
        ),
      ),
    );
    if (reason == null || reason.isEmpty) return;
    try {
      final res = await sl.shipperService.deliveryFailed(orderId,
          reason: reason.isNotEmpty ? reason : null);
      if (res.success) {
        // Kiểm tra BE trả về data.status == CANCELLED (hết 3 lần)
        final data = res.data as Map<String, dynamic>?;
        final isAutoCancelled = data?['status'] == 'CANCELLED';

        if (isAutoCancelled) {
          Helpers.showSnackBar(
            context,
            '❌ Đã thất bại 3 lần — đơn hàng bị huỷ tự động',
            isError: true,
          );
        } else {
          final attempts = data?['deliveryAttempts'] ?? 0;
          final maxAttempts = data?['maxAttempts'] ?? 3;
          final remaining = maxAttempts - attempts;
          Helpers.showSnackBar(
            context,
            '⚠️ Giao thất bại lần $attempts/$maxAttempts — còn $remaining lần thử',
          );
        }
        _loadOrders(_currentFilter);
      } else {
        Helpers.showSnackBar(
          context,
          res.message ?? 'Thao tác thất bại',
          isError: true,
        );
      }
    } catch (_) {
      Helpers.showSnackBar(context, 'Thao tác thất bại', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'ĐƠN HÀNG GIAO',
          style: GoogleFonts.cormorantGaramond(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.login, (_) => false);
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          indicatorWeight: 2,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: _tabs.map((t) => Tab(text: t['label'] as String)).toList(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const LoadingWidget();
    if (_error != null)
      return AppErrorWidget(
          message: _error!, onRetry: () => _loadOrders(_currentFilter));
    if (_orders.isEmpty) {
      return const EmptyWidget(
        icon: Icons.local_shipping_outlined,
        message: 'Không có đơn hàng nào',
      );
    }
    return RefreshIndicator(
      color: Colors.black,
      onRefresh: () => _loadOrders(_currentFilter),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) =>
            _buildOrderCard(_orders[i] as Map<String, dynamic>),
      ),
    );
  }

  void _showOrderDetail(Map<String, dynamic> order) {
    final orderCode = order['orderCode'] ?? '#${order['orderId'] ?? order['id']}';
    final status = (order['status'] ?? '').toString().toUpperCase();
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final shippingInfo = order['shippingInfo'] as Map<String, dynamic>?;
    final address = shippingInfo?['address'] ?? order['shippingAddress'] ?? '';
    final customerName = shippingInfo?['name'] ?? order['customerName'] ?? '';
    final customerPhone = shippingInfo?['phone'] ?? order['customerPhone'] ?? '';
    final totalItems = order['totalItems'] ?? 0;
    final paymentMethod = order['paymentMethod'] ?? '';
    final trackingNumber = order['trackingNumber'] ?? order['shippingCode'];
    final deliveryAttempts = (order['deliveryAttempts'] as num?)?.toInt() ?? 0;
    final cancelReason = order['cancelReason'] as String?;
    final createdAt = order['createdAt'] != null
        ? DateTime.tryParse(order['createdAt'].toString())
        : null;
    final items = (order['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    Color statusColor;
    String statusText;
    switch (status) {
      case 'PROCESSING': statusColor = Colors.blue; statusText = 'Chờ lấy hàng'; break;
      case 'SHIPPING': statusColor = Colors.orange; statusText = 'Đang giao'; break;
      case 'DELIVERED': statusColor = Colors.green; statusText = 'Đã giao'; break;
      case 'CANCELLED': statusColor = Colors.red; statusText = 'Đã huỷ'; break;
      default: statusColor = Colors.grey; statusText = status;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(orderCode,
                      style: GoogleFonts.cormorantGaramond(
                          fontSize: 20, fontWeight: FontWeight.w700)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(statusText,
                      style: TextStyle(
                          color: statusColor, fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            if (createdAt != null) ...[
              const SizedBox(height: 4),
              Text(Helpers.formatDateTime(createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
            const Divider(height: 24),

            // Thông tin khách hàng
            _detailSection('Thông tin giao hàng', Icons.local_shipping_outlined, [
              if (customerName.isNotEmpty) _detailRow(Icons.person_outline, customerName),
              if (customerPhone.isNotEmpty) _detailRow(Icons.phone_outlined, customerPhone),
              if (address.isNotEmpty) _detailRow(Icons.location_on_outlined, address, maxLines: 3),
            ]),

            // Thông tin đơn hàng
            _detailSection('Thông tin đơn hàng', Icons.receipt_long_outlined, [
              _detailRow(Icons.shopping_bag_outlined, '$totalItems sản phẩm'),
              _detailRow(Icons.payments_outlined,
                  Helpers.formatCurrency(total) +
                      (paymentMethod.isNotEmpty ? ' · $paymentMethod' : '')),
              if (trackingNumber != null && trackingNumber.toString().isNotEmpty)
                _detailRow(Icons.qr_code_outlined, 'Mã vận đơn: $trackingNumber'),
            ]),

            // Danh sách sản phẩm (nếu có)
            if (items.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Sản phẩm',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              ...items.map((item) {
                final name = item['productName'] ?? item['name'] ?? 'Sản phẩm';
                final qty = item['quantity'] ?? 1;
                final price = (item['price'] as num?)?.toDouble() ?? 0;
                final variant = [item['size'], item['color']]
                    .where((v) => v != null && v.toString().isNotEmpty)
                    .join(' / ');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name.toString(),
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w500),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            if (variant.isNotEmpty)
                              Text(variant,
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('x$qty  ${Helpers.formatCurrency(price)}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                );
              }),
            ],

            // Cảnh báo nếu có
            if (deliveryAttempts > 0 && status != 'DELIVERED') ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200)),
                child: Row(children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange.shade700, size: 18),
                  const SizedBox(width: 8),
                  Text('Đã thất bại $deliveryAttempts/3 lần',
                      style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ),
            ],
            if (status == 'CANCELLED' &&
                cancelReason != null &&
                cancelReason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.cancel_outlined,
                        color: Colors.red.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Lý do huỷ: $cancelReason',
                          style: TextStyle(
                              color: Colors.red.shade700, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailSection(String title, IconData icon, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 15, color: Colors.black54),
          const SizedBox(width: 6),
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ]),
        const SizedBox(height: 8),
        ...rows,
        const Divider(height: 24),
      ],
    );
  }

  Widget _detailRow(IconData icon, String text, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style:
                    TextStyle(fontSize: 13, color: Colors.grey.shade700),
                maxLines: maxLines, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = order['orderId'] ?? order['id'] ?? 0;
    final orderCode = order['orderCode'] ?? '#$orderId';
    final status = (order['status'] ?? '').toString().toUpperCase();
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final shippingInfo = order['shippingInfo'] as Map<String, dynamic>?;
    final address = shippingInfo?['address'] ??
        order['shippingAddress'] ??
        'Không có địa chỉ';
    final customerName =
        shippingInfo?['name'] ?? order['customerName'] ?? '';
    final customerPhone =
        shippingInfo?['phone'] ?? order['customerPhone'] ?? '';
    final totalItems = order['totalItems'] ?? 0;
    final deliveryAttempts = (order['deliveryAttempts'] as num?)?.toInt() ?? 0;
    final cancelReason = order['cancelReason'] as String?;

    Color statusColor;
    String statusText;
    switch (status) {
      case 'PROCESSING':
        statusColor = Colors.blue;
        statusText = 'Chờ lấy hàng';
        break;
      case 'SHIPPING':
        statusColor = Colors.orange;
        statusText = 'Đang giao';
        break;
      case 'DELIVERED':
        statusColor = Colors.green;
        statusText = 'Đã giao';
        break;
      case 'CANCELLED':
        statusColor = Colors.red;
        statusText = 'Đã huỷ';
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
    }

    return GestureDetector(
      onTap: () => _showOrderDetail(order),
      child: Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Text(orderCode,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  color: statusColor.withOpacity(0.1),
                  child: Text(statusText,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(
              children: [
                _infoRow(Icons.person_outline, '$customerName · $customerPhone'),
                const SizedBox(height: 4),
                _infoRow(Icons.location_on_outlined, address.toString()),
                const SizedBox(height: 4),
                _infoRow(Icons.shopping_bag_outlined,
                    '$totalItems sản phẩm · ${Helpers.formatCurrency(total)}'),
                if (deliveryAttempts > 0 && status != 'CANCELLED') ...[
                  const SizedBox(height: 4),
                  _infoRow(
                    Icons.warning_amber_rounded,
                    'Đã thất bại $deliveryAttempts/3 lần',
                    iconColor: Colors.orange,
                    textColor: Colors.orange,
                  ),
                ],
                if (status == 'CANCELLED' && cancelReason != null && cancelReason.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _infoRow(
                    Icons.cancel_outlined,
                    'Lý do: $cancelReason',
                    iconColor: Colors.red,
                    textColor: Colors.red.shade700,
                  ),
                ],
                if (status == 'CANCELLED' || status == 'DELIVERED')
                  const SizedBox(height: 14),
              ],
            ),
          ),

          // Actions — ẩn nếu đã huỷ hoặc đã giao
          if (status != 'CANCELLED' && status != 'DELIVERED')
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                if (status == 'PROCESSING')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickupOrder(orderId),
                      icon: const Icon(Icons.inventory, size: 16),
                      label: const Text('NHẬN ĐƠN'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const RoundedRectangleBorder(),
                      ),
                    ),
                  ),
                if (status == 'SHIPPING') ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                          context, AppRoutes.shipperDelivery,
                          arguments: order),
                      icon: const Icon(Icons.map, size: 16),
                      label: const Text('BẢN ĐỒ'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black),
                        shape: const RoundedRectangleBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _deliverOrder(orderId),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('ĐÃ GIAO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const RoundedRectangleBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: () => _failDelivery(orderId),
                    icon: const Icon(Icons.report_problem, color: Colors.red),
                    tooltip: 'Giao thất bại',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    )); // GestureDetector
  }

  Widget _infoRow(IconData icon, String text, {Color? iconColor, Color? textColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: iconColor ?? Colors.grey.shade500),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: textColor ?? Colors.grey.shade700,
              fontWeight: textColor != null ? FontWeight.w600 : FontWeight.normal,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
