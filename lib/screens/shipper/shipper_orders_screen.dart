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
      if (!_tabCtrl.indexIsChanging) {
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

    return Container(
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
    );
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
