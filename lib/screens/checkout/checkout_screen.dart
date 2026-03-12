import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_routes.dart';
import '../../models/address/address.dart';
import '../../models/order/order_detail.dart';
import '../../models/voucher/voucher.dart';
import '../../providers/cart_provider.dart';
import '../../services/service_locator.dart';
import '../../widgets/common/custom_button.dart';
import '../../utils/helpers.dart';
import '../../utils/extensions.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _noteCtrl = TextEditingController();
  List<Address> _addresses = [];
  Address? _selectedAddress;
  String _paymentMethod = 'COD';
  String? _voucherCode;
  double _discount = 0;
  bool _isLoading = true;
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    try {
      final res = await sl.addressService.getAddresses();
      if (res.success && res.data != null) {
        setState(() {
          _addresses = res.data!;
          if (_addresses.isNotEmpty) {
            _selectedAddress = _addresses.firstWhere(
              (a) => a.isDefault,
              orElse: () => _addresses.first,
            );
          }
        });
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _applyVoucher() async {
    final ctrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(),
        title: Text('Mã giảm giá',
            style: GoogleFonts.cormorantGaramond(
                fontSize: 20, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'Nhập mã giảm giá...',
            prefixIcon: const Icon(Icons.confirmation_number_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.zero),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Hủy',
                  style: TextStyle(color: Colors.grey.shade600))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Áp dụng',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (code == null || code.isEmpty) return;
    try {
      final cart = context.read<CartProvider>();
      final res = await sl.voucherService.validateVoucher(
        ValidateVoucherRequest(code: code, orderTotal: cart.totalAmount),
      );
      if (res.success) {
        setState(() {
          _voucherCode = code;
          _discount = (res.data as num?)?.toDouble() ?? 0;
        });
        if (mounted) Helpers.showSnackBar(context, 'Áp dụng mã giảm giá thành công!');
      } else {
        if (mounted)
          Helpers.showSnackBar(context, res.message ?? 'Mã không hợp lệ', isError: true);
      }
    } catch (_) {
      if (mounted) Helpers.showSnackBar(context, 'Mã không hợp lệ', isError: true);
    }
  }

  Future<void> _placeOrder() async {
    if (_selectedAddress == null) {
      Helpers.showSnackBar(context, 'Vui lòng chọn địa chỉ giao hàng', isError: true);
      return;
    }
    setState(() => _isPlacingOrder = true);
    try {
      // Step 1: Create the order
      final request = CreateOrderRequest(
        addressId: _selectedAddress!.addressId,
        paymentMethod: _paymentMethod,
        voucherCode: _voucherCode,
        note: _noteCtrl.text.trim().isNotEmpty ? _noteCtrl.text.trim() : null,
      );
      final res = await sl.orderService.createOrder(request);

      if (!res.success || res.data == null) {
        if (mounted)
          Helpers.showSnackBar(context, res.message ?? 'Đặt hàng thất bại', isError: true);
        setState(() => _isPlacingOrder = false);
        return;
      }

      final orderResp = res.data!; // CreateOrderResponse
      if (!mounted) return;
      context.read<CartProvider>().loadCart();

      if (_paymentMethod == 'SEPAY') {
        // Step 2 (SEPAY only): Create SePay QR payment and get bank/QR info
        final payRes = await sl.paymentService.createSepayPayment(orderResp.orderId);
        if (!mounted) return;

        if (payRes.success && payRes.data != null) {
          final d = payRes.data!;
          // Map SePayPaymentResponse JSON fields → PaymentScreen expected keys
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.payment,
            arguments: {
              'orderId': orderResp.orderId,
              'qrUrl': d['qrCodeUrl'] ?? '',
              'bankAccount': d['accountNumber'] ?? '',
              'bankName': d['bankName'] ?? 'Ngân hàng',
              'transferContent': d['description'] ?? d['orderCode'] ?? '',
              'amount': (d['amount'] as num?)?.toDouble() ?? orderResp.total,
            },
          );
        } else {
          // Order created but payment QR failed — still go to orders
          Helpers.showSnackBar(
              context, 'Đặt hàng thành công nhưng không lấy được QR thanh toán.');
          Navigator.pushNamedAndRemoveUntil(
              context, AppRoutes.orders, (r) => r.settings.name == AppRoutes.main);
        }
      } else {
        // COD: done
        Helpers.showSnackBar(context, 'Đặt hàng thành công! Đơn hàng đang được xử lý.');
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.orders, (r) => r.settings.name == AppRoutes.main);
      }
    } catch (e) {
      if (mounted) Helpers.showSnackBar(context, 'Đặt hàng thất bại. Vui lòng thử lại.', isError: true);
    }
    if (mounted) setState(() => _isPlacingOrder = false);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final subtotal = cart.totalAmount;
    const shippingFee = 30000.0;
    final total = subtotal + shippingFee - _discount;

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
          'Thanh toán',
          style: GoogleFonts.cormorantGaramond(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Delivery address
                  _buildSectionCard(
                    title: 'Địa chỉ giao hàng',
                    icon: Icons.location_on_outlined,
                    trailing: TextButton(
                      onPressed: () => _showAddressPicker(),
                      child: const Text('Thay đổi',
                          style: TextStyle(color: Colors.black, fontSize: 12)),
                    ),
                    child: _selectedAddress != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _selectedAddress!.receiverName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _selectedAddress!.phone,
                                    style: TextStyle(
                                        color: Colors.grey.shade600, fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedAddress!.fullAddress,
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_selectedAddress!.isDefault)
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  color: Colors.black,
                                  child: const Text(
                                    'Mặc định',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 11),
                                  ),
                                ),
                            ],
                          )
                        : GestureDetector(
                            onTap: () async {
                              await Navigator.pushNamed(
                                  context, AppRoutes.addressForm);
                              _loadAddresses();
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.add_location_alt,
                                    size: 18, color: Colors.black),
                                const SizedBox(width: 8),
                                const Text('Thêm địa chỉ giao hàng',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),

                  // Order items
                  _buildSectionCard(
                    title: 'Sản phẩm (${cart.itemCount})',
                    icon: Icons.shopping_bag_outlined,
                    child: Column(
                      children: cart.cart?.items
                              .map((item) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.zero,
                                          child: item.thumbnailUrl != null
                                              ? Image.network(
                                                  item.thumbnailUrl!,
                                                  width: 56,
                                                  height: 56,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      Container(
                                                          width: 56,
                                                          height: 56,
                                                          color: Colors
                                                              .grey.shade100),
                                                )
                                              : Container(
                                                  width: 56,
                                                  height: 56,
                                                  color: Colors.grey.shade100,
                                                  child: const Icon(Icons.image,
                                                      color: Colors.grey)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(item.productName,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500)),
                                              Text(
                                                  '${item.color ?? ''} · ${item.size ?? ''} · x${item.quantity}',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors
                                                          .grey.shade500)),
                                            ],
                                          ),
                                        ),
                                        Text(item.subtotal.toCurrency,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13)),
                                      ],
                                    ),
                                  ))
                              .toList() ??
                          [],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Voucher
                  _buildSectionCard(
                    title: 'Mã giảm giá',
                    icon: Icons.local_offer_outlined,
                    trailing: TextButton(
                      onPressed: _applyVoucher,
                      child: Text(
                        _voucherCode != null ? 'Đổi mã' : 'Chọn mã',
                        style:
                            const TextStyle(color: Colors.black, fontSize: 12),
                      ),
                    ),
                    child: _voucherCode != null
                        ? Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black),
                                ),
                                child: Text(_voucherCode!,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '-${_discount.toCurrency}',
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => setState(() {
                                  _voucherCode = null;
                                  _discount = 0;
                                }),
                                child: const Icon(Icons.close,
                                    size: 18, color: Colors.grey),
                              ),
                            ],
                          )
                        : Text('Chưa áp dụng mã giảm giá',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 13)),
                  ),
                  const SizedBox(height: 12),

                  // Payment method
                  _buildSectionCard(
                    title: 'Phương thức thanh toán',
                    icon: Icons.payment_outlined,
                    child: Column(
                      children: [
                        _paymentOption(
                          'COD',
                          'Thanh toán khi nhận hàng',
                          'Trả tiền mặt khi nhận hàng',
                          Icons.money,
                        ),
                        const SizedBox(height: 8),
                        _paymentOption(
                          'SEPAY',
                          'Chuyển khoản ngân hàng',
                          'Thanh toán qua SePay (quét QR)',
                          Icons.qr_code,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Note
                  _buildSectionCard(
                    title: 'Ghi chú',
                    icon: Icons.note_outlined,
                    child: TextField(
                      controller: _noteCtrl,
                      decoration: InputDecoration(
                        hintText: 'Ghi chú cho người giao hàng...',
                        hintStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 13),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide:
                                BorderSide(color: Colors.grey.shade200)),
                        focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(color: Colors.black)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      maxLines: 2,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Order summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tóm tắt đơn hàng',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 12),
                        _summaryRow('Tạm tính', subtotal.toCurrency),
                        const SizedBox(height: 6),
                        _summaryRow(
                            'Phí vận chuyển', shippingFee.toCurrency),
                        if (_discount > 0) ...[
                          const SizedBox(height: 6),
                          _summaryRow('Giảm giá', '-${_discount.toCurrency}',
                              valueColor: Colors.green),
                        ],
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tổng cộng',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                            Text(
                              total.toCurrency,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: SafeArea(
          child: CustomButton(
            text: 'ĐẶT HÀNG  •  ${total.toCurrency}',
            isLoading: _isPlacingOrder,
            onPressed: _placeOrder,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              children: [
                Icon(icon, size: 18, color: Colors.black87),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const Spacer(),
                if (trailing != null) trailing,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _paymentOption(
      String value, String title, String subtitle, IconData icon) {
    final isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
              color: isSelected ? Colors.black : Colors.grey.shade200,
              width: isSelected ? 2 : 1),
          color: isSelected ? Colors.black.withOpacity(0.02) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: isSelected ? Colors.black : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isSelected ? Colors.black : Colors.black87)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.black, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: valueColor ?? Colors.black87)),
      ],
    );
  }

  void _showAddressPicker() {
    if (_addresses.isEmpty) {
      Navigator.pushNamed(context, AppRoutes.addressForm)
          .then((_) => _loadAddresses());
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Chọn địa chỉ',
                    style: GoogleFonts.cormorantGaramond(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
          ..._addresses.map((addr) => ListTile(
                leading: Radio<int>(
                  value: addr.addressId,
                  groupValue: _selectedAddress?.addressId,
                  activeColor: Colors.black,
                  onChanged: (v) {
                    setState(() => _selectedAddress = addr);
                    Navigator.pop(ctx);
                  },
                ),
                title: Text(addr.receiverName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '${addr.phone}\n${addr.fullAddress}',
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 12),
                ),
                isThreeLine: true,
              )),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.addressForm)
                      .then((_) => _loadAddresses());
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Thêm địa chỉ mới'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black),
                  shape: const RoundedRectangleBorder(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
