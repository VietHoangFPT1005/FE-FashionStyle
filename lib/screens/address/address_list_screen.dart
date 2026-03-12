import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_routes.dart';
import '../../models/address/address.dart';
import '../../services/service_locator.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/empty_widget.dart';
import '../../utils/helpers.dart';

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({super.key});

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  List<Address> _addresses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await sl.addressService.getAddresses();
      if (res.success && res.data != null) {
        setState(() => _addresses = res.data!);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _isLoading = false);
  }

  Future<void> _deleteAddress(Address addr) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(),
        title: Text('Xóa địa chỉ',
            style: GoogleFonts.cormorantGaramond(
                fontSize: 20, fontWeight: FontWeight.w700)),
        content: Text(
            'Bạn có chắc muốn xóa địa chỉ của "${addr.receiverName}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  Text('Hủy', style: TextStyle(color: Colors.grey.shade600))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Xóa',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final res = await sl.addressService.deleteAddress(addr.addressId);
      if (res.success) {
        Helpers.showSnackBar(context, 'Đã xóa địa chỉ');
        _loadAddresses();
      }
    } catch (_) {
      Helpers.showSnackBar(context, 'Không thể xóa địa chỉ này', isError: true);
    }
  }

  Future<void> _setDefault(Address addr) async {
    try {
      final res = await sl.addressService.setDefaultAddress(addr.addressId);
      if (res.success) {
        Helpers.showSnackBar(context, 'Đã đặt làm địa chỉ mặc định');
        _loadAddresses();
      }
    } catch (_) {}
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
          'Địa chỉ của tôi',
          style: GoogleFonts.cormorantGaramond(
              color: Colors.black, fontSize: 22, fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Navigator.pushNamed(context, AppRoutes.addressForm);
              _loadAddresses();
            },
            icon: const Icon(Icons.add, color: Colors.black, size: 18),
            label: const Text('Thêm',
                style: TextStyle(color: Colors.black, fontSize: 13)),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const LoadingWidget();
    if (_error != null)
      return AppErrorWidget(message: _error!, onRetry: _loadAddresses);
    if (_addresses.isEmpty) {
      return EmptyWidget(
        icon: Icons.location_off,
        message: 'Chưa có địa chỉ nào',
        actionText: 'Thêm địa chỉ mới',
        onAction: () async {
          await Navigator.pushNamed(context, AppRoutes.addressForm);
          _loadAddresses();
        },
      );
    }
    return RefreshIndicator(
      color: Colors.black,
      onRefresh: _loadAddresses,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _addresses.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _buildAddressCard(_addresses[i]),
      ),
    );
  }

  Widget _buildAddressCard(Address addr) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  color: Colors.black,
                  child: const Icon(Icons.location_on,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            addr.receiverName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          if (addr.isDefault) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              color: Colors.black,
                              child: const Text(
                                'Mặc định',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        addr.phone,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        addr.fullAddress,
                        style: TextStyle(
                            color: Colors.grey.shade700, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              children: [
                if (!addr.isDefault)
                  OutlinedButton(
                    onPressed: () => _setDefault(addr),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black),
                      shape: const RoundedRectangleBorder(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    child: const Text('Đặt mặc định', style: TextStyle(fontSize: 12)),
                  ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () async {
                    await Navigator.pushNamed(
                      context,
                      AppRoutes.addressForm,
                      arguments: {
                        'addressId': addr.addressId,
                        'receiverName': addr.receiverName,
                        'phone': addr.phone,
                        'addressLine': addr.addressLine,
                        'ward': addr.ward,
                        'district': addr.district,
                        'city': addr.city,
                        'latitude': addr.latitude,
                        'longitude': addr.longitude,
                        'isDefault': addr.isDefault,
                      },
                    );
                    _loadAddresses();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: Colors.red),
                  onPressed: () => _deleteAddress(addr),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
