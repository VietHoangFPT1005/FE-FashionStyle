import 'package:flutter/material.dart';
import '../../services/service_locator.dart';
import '../../utils/helpers.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/empty_widget.dart';

class AdminRefundsScreen extends StatefulWidget {
  const AdminRefundsScreen({super.key});

  @override
  State<AdminRefundsScreen> createState() => _AdminRefundsScreenState();
}

class _AdminRefundsScreenState extends State<AdminRefundsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _refunds = [];
  bool _isLoading = true;
  String? _error;
  String? _currentStatus;

  final _tabs = [
    {'label': 'Tất cả', 'status': null},
    {'label': 'Chờ xử lý', 'status': 'PENDING'},
    {'label': 'Đã duyệt', 'status': 'APPROVED'},
    {'label': 'Từ chối', 'status': 'REJECTED'},
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() {
      if (_tabCtrl.indexIsChanging) {
        _loadRefunds(_tabs[_tabCtrl.index]['status'] as String?);
      }
    });
    _loadRefunds(null);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRefunds(String? status) async {
    setState(() { _isLoading = true; _error = null; _currentStatus = status; });
    try {
      final res = await sl.adminService.getRefunds(status: status, pageSize: 50);
      if (res.success && res.data != null) {
        final data = res.data;
        if (data is List) setState(() => _refunds = data);
        else if (data is Map && data['items'] is List) setState(() => _refunds = data['items'] as List);
        else setState(() => _refunds = []);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _isLoading = false);
  }

  Future<void> _processRefund(int refundId, bool approve) async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve ? 'Duyệt hoàn trả' : 'Từ chối hoàn trả'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(approve ? 'Duyệt yêu cầu này?' : 'Từ chối yêu cầu này?'),
          const SizedBox(height: 12),
          TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Ghi chú (tùy chọn)', hintText: 'Nhập lý do hoặc ghi chú...'), maxLines: 2),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: approve ? Colors.green : Colors.red),
            child: Text(approve ? 'Duyệt' : 'Từ chối'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final res = approve
          ? await sl.adminService.approveRefund(refundId, note: noteCtrl.text.trim())
          : await sl.adminService.rejectRefund(refundId, note: noteCtrl.text.trim());
      if (res.success) {
        Helpers.showSnackBar(context, approve ? 'Đã duyệt hoàn trả!' : 'Đã từ chối hoàn trả');
        _loadRefunds(_currentStatus);
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
        title: const Text('Quản lý hoàn trả'),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabs: _tabs.map((t) => Tab(text: t['label'] as String)).toList(),
        ),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: () => _loadRefunds(_currentStatus))
              : _refunds.isEmpty
                  ? const EmptyWidget(icon: Icons.assignment_return_outlined, message: 'Không có yêu cầu hoàn trả')
                  : RefreshIndicator(
                      onRefresh: () => _loadRefunds(_currentStatus),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _refunds.length,
                        itemBuilder: (_, i) => _buildRefundCard(_refunds[i] as Map<String, dynamic>),
                      ),
                    ),
    );
  }

  Widget _buildRefundCard(Map<String, dynamic> refund) {
    final id = (refund['refundId'] ?? refund['id'] ?? 0) as int;
    final orderCode = refund['orderCode'] ?? '#${refund['orderId'] ?? ''}';
    final reason = refund['reason'] ?? '';
    final status = (refund['status'] ?? 'PENDING').toString().toUpperCase();
    final customerName = refund['customerName'] ?? refund['userName'] ?? '';
    final createdAt = refund['createdAt'] != null ? DateTime.tryParse(refund['createdAt'].toString()) : null;

    Color statusColor = status == 'APPROVED' ? Colors.green : status == 'REJECTED' ? Colors.red : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(orderCode.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(status == 'APPROVED' ? 'Đã duyệt' : status == 'REJECTED' ? 'Từ chối' : 'Chờ xử lý',
                style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 6),
          if (customerName.isNotEmpty) Row(children: [
            const Icon(Icons.person_outline, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(customerName.toString(), style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ]),
          if (createdAt != null) ...[
            const SizedBox(height: 2),
            Text(Helpers.formatDateTime(createdAt), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],
          const SizedBox(height: 8),
          Text('Lý do: $reason', style: const TextStyle(fontSize: 13), maxLines: 3, overflow: TextOverflow.ellipsis),
          if (status == 'PENDING') ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _processRefund(id, true),
                  icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                  label: const Text('Duyệt', style: TextStyle(color: Colors.green)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.green)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _processRefund(id, false),
                  icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
                  label: const Text('Từ chối', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                ),
              ),
            ]),
          ],
        ]),
      ),
    );
  }
}
