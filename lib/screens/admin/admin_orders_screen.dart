import 'package:flutter/material.dart';
import '../../config/app_routes.dart';
import '../../services/service_locator.dart';
import '../../utils/helpers.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/empty_widget.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _error;
  String? _currentStatus;

  final _tabs = [
    {'label': 'Tất cả', 'status': null},
    {'label': 'Chờ xác nhận', 'status': 'PENDING'},
    {'label': 'Đã xác nhận', 'status': 'CONFIRMED'},
    {'label': 'Đang giao', 'status': 'SHIPPING'},
    {'label': 'Đã giao', 'status': 'DELIVERED'},
    {'label': 'Đã hủy', 'status': 'CANCELLED'},
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
    setState(() { _isLoading = true; _error = null; _currentStatus = status; });
    try {
      final res = await sl.adminService.getOrders(status: status, pageSize: 50);
      if (res.success && res.data != null) {
        final data = res.data;
        if (data is List) {
          setState(() => _orders = data);
        } else if (data is Map && data['items'] is List) {
          setState(() => _orders = data['items'] as List);
        } else {
          setState(() => _orders = []);
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _isLoading = false);
  }

  Future<void> _confirmOrder(int orderId) async {
    try {
      final res = await sl.adminService.confirmOrder(orderId);
      if (res.success) {
        Helpers.showSnackBar(context, 'Đã xác nhận đơn hàng!');
        _loadOrders(_currentStatus);
      } else {
        Helpers.showSnackBar(context, res.message ?? 'Thất bại', isError: true);
      }
    } catch (_) {
      Helpers.showSnackBar(context, 'Có lỗi xảy ra', isError: true);
    }
  }

  Future<void> _cancelOrder(int orderId) async {
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lý do hủy'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Nhập lý do...'), maxLines: 2),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Xác nhận', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    try {
      final res = await sl.adminService.cancelOrder(orderId, reason);
      if (res.success) {
        Helpers.showSnackBar(context, 'Đã hủy đơn hàng');
        _loadOrders(_currentStatus);
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
        title: const Text('Quản lý đơn hàng'),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabs: _tabs.map((t) => Tab(text: t['label'] as String)).toList(),
        ),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: () => _loadOrders(_currentStatus))
              : _orders.isEmpty
                  ? const EmptyWidget(icon: Icons.receipt_long_outlined, message: 'Không có đơn hàng')
                  : RefreshIndicator(
                      onRefresh: () => _loadOrders(_currentStatus),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _orders.length,
                        itemBuilder: (_, i) => _buildOrderCard(_orders[i] as Map<String, dynamic>),
                      ),
                    ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = order['orderId'] ?? order['id'] ?? 0;
    final code = order['orderCode'] ?? '#$orderId';
    final status = (order['status'] ?? '').toString().toUpperCase();
    final customer = order['customerName'] ?? order['userName'] ?? '';
    final total = (order['total'] as num?)?.toDouble() ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => Navigator.pushNamed(context, AppRoutes.adminOrderDetail, arguments: orderId),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Helpers.getOrderStatusColor(status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(Helpers.getOrderStatusText(status),
                    style: TextStyle(color: Helpers.getOrderStatusColor(status), fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 6),
              if (customer.isNotEmpty) Row(children: [
                const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(customer, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ]),
              const SizedBox(height: 4),
              Text(Helpers.formatCurrency(total), style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
              const SizedBox(height: 10),
              Row(children: [
                if (status == 'PENDING')
                  _actionBtn('Xác nhận', Colors.green, Icons.check_circle_outline, () => _confirmOrder(orderId)),
                const Spacer(),
                if (status != 'DELIVERED' && status != 'CANCELLED')
                  _actionBtn('Hủy đơn', Colors.red, Icons.cancel_outlined, () => _cancelOrder(orderId)),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(String label, Color color, IconData icon, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 13)),
      style: OutlinedButton.styleFrom(side: BorderSide(color: color.withValues(alpha: 0.5)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
    );
  }
}
