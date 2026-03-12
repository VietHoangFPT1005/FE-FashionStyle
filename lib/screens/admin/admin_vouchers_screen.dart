import 'package:flutter/material.dart';
import '../../services/service_locator.dart';
import '../../utils/helpers.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/empty_widget.dart';

class AdminVouchersScreen extends StatefulWidget {
  const AdminVouchersScreen({super.key});

  @override
  State<AdminVouchersScreen> createState() => _AdminVouchersScreenState();
}

class _AdminVouchersScreenState extends State<AdminVouchersScreen> {
  List<dynamic> _vouchers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await sl.adminService.getVouchers(pageSize: 50);
      if (res.success && res.data != null) {
        final data = res.data;
        if (data is List) {
          setState(() => _vouchers = data);
        } else if (data is Map && data['items'] is List) {
          setState(() => _vouchers = data['items'] as List);
        } else {
          setState(() => _vouchers = []);
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _isLoading = false);
  }

  Future<void> _showCreateVoucherDialog() async {
    final codeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final discountCtrl = TextEditingController();
    final minOrderCtrl = TextEditingController();
    final maxUsageCtrl = TextEditingController();
    bool isPercentage = true;
    DateTime? endDate;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Tạo Voucher mới'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(labelText: 'Mã Voucher *', hintText: 'VD: SALE10'),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Mô tả *', hintText: 'VD: Giảm 10% cho đơn từ 200k'),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(
                  controller: discountCtrl,
                  decoration: InputDecoration(labelText: isPercentage ? 'Giảm (%)' : 'Giảm (VNĐ)'),
                  keyboardType: TextInputType.number,
                )),
                const SizedBox(width: 8),
                DropdownButton<bool>(
                  value: isPercentage,
                  items: const [
                    DropdownMenuItem(value: true, child: Text('%')),
                    DropdownMenuItem(value: false, child: Text('VNĐ')),
                  ],
                  onChanged: (v) => setDialogState(() => isPercentage = v!),
                ),
              ]),
              const SizedBox(height: 8),
              TextField(
                controller: minOrderCtrl,
                decoration: const InputDecoration(labelText: 'Đơn tối thiểu (VNĐ)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: maxUsageCtrl,
                decoration: const InputDecoration(labelText: 'Số lần dùng tối đa'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setDialogState(() => endDate = d);
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(endDate != null ? 'HSD: ${Helpers.formatDate(endDate!)}' : 'Chọn ngày hết hạn *'),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Tạo'),
            ),
          ],
        ),
      ),
    );

    if (result != true || codeCtrl.text.trim().isEmpty) return;
    try {
      final now = DateTime.now();
      // BE CreateVoucherRequest field names (camelCase):
      // discountType: 'PERCENTAGE' | 'FIXED_AMOUNT'
      // minOrderAmount (không phải minimumOrderAmount)
      // usageLimit (không phải maxUsage)
      // startDate + endDate đều Required
      final data = <String, dynamic>{
        'code': codeCtrl.text.trim().toUpperCase(),
        'description': descCtrl.text.trim().isNotEmpty
            ? descCtrl.text.trim()
            : '${codeCtrl.text.trim().toUpperCase()} voucher',
        'discountType': isPercentage ? 'PERCENTAGE' : 'FIXED_AMOUNT',
        'discountValue': double.tryParse(discountCtrl.text) ?? 0,
        // startDate bắt buộc - nếu null, BE query StartDate<=now sẽ loại voucher!
        'startDate': now.toIso8601String(),
        'endDate': endDate != null
            ? endDate!.toIso8601String()
            : now.add(const Duration(days: 30)).toIso8601String(),
        if (minOrderCtrl.text.isNotEmpty) 'minOrderAmount': double.tryParse(minOrderCtrl.text),
        if (maxUsageCtrl.text.isNotEmpty) 'usageLimit': int.tryParse(maxUsageCtrl.text),
      };
      final res = await sl.adminService.createVoucher(data);
      if (res.success) {
        Helpers.showSnackBar(context, 'Tạo voucher thành công!');
        _loadVouchers();
      } else {
        Helpers.showSnackBar(context, res.message ?? 'Thất bại', isError: true);
      }
    } catch (_) {
      Helpers.showSnackBar(context, 'Có lỗi xảy ra', isError: true);
    }
  }

  Future<void> _deleteVoucher(int id, String code) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Xóa voucher "$code"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final res = await sl.adminService.deleteVoucher(id);
      if (res.success) {
        Helpers.showSnackBar(context, 'Đã xóa voucher $code');
        _loadVouchers();
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
      appBar: AppBar(title: const Text('Quản lý Voucher')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateVoucherDialog,
        icon: const Icon(Icons.add),
        label: const Text('Tạo Voucher'),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _loadVouchers)
              : _vouchers.isEmpty
                  ? const EmptyWidget(icon: Icons.confirmation_number_outlined, message: 'Chưa có voucher')
                  : RefreshIndicator(
                      onRefresh: _loadVouchers,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                        itemCount: _vouchers.length,
                        itemBuilder: (_, i) => _buildVoucherCard(_vouchers[i] as Map<String, dynamic>),
                      ),
                    ),
    );
  }

  Widget _buildVoucherCard(Map<String, dynamic> v) {
    final id = (v['voucherId'] ?? v['id'] ?? 0) as int;
    final code = v['code'] ?? '';
    final discountType = v['discountType'] ?? 'PERCENTAGE';
    final discountValue = (v['discountValue'] ?? v['discount'] ?? 0 as num).toDouble();
    final isPercentage = discountType == 'PERCENTAGE';
    final endDate = v['endDate'] != null ? DateTime.tryParse(v['endDate'].toString()) : null;
    final isActive = v['isActive'] ?? true;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          width: 80,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isActive as bool) ? Theme.of(context).colorScheme.primary : Colors.grey,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(isPercentage ? '${discountValue.toInt()}%' : Helpers.formatCurrency(discountValue),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('GIẢM', style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ]),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(code.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1)),
              if (endDate != null)
                Text('HSD: ${Helpers.formatDate(endDate)}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ]),
          ),
        ),
        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteVoucher(id, code.toString())),
      ]),
    );
  }
}
