import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_routes.dart';
import '../../config/app_constants.dart';
import '../../providers/order_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/custom_button.dart';
import '../../utils/extensions.dart';
import '../../utils/helpers.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrderDetail(widget.orderId);
    });
  }

  Future<void> _cancelOrder(OrderProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(),
        title: Text('Hủy đơn hàng',
            style: GoogleFonts.cormorantGaramond(
                fontSize: 20, fontWeight: FontWeight.w700)),
        content: const Text(
            'Bạn có chắc muốn hủy đơn hàng này không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Không', style: TextStyle(color: Colors.grey.shade600))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hủy đơn',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirm == true) {
      final success = await provider.cancelOrder(widget.orderId);
      if (mounted) {
        if (success) {
          Helpers.showSnackBar(context, 'Đã hủy đơn hàng thành công');
          Navigator.pop(context); // Quay về danh sách đơn hàng
        } else {
          Helpers.showSnackBar(context, 'Hủy đơn hàng thất bại. Vui lòng thử lại.', isError: true);
        }
      }
    }
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
          'Chi tiết đơn hàng',
          style: GoogleFonts.cormorantGaramond(
              color: Colors.black, fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading) return const LoadingWidget();
          final order = provider.currentOrder;
          if (order == null) {
            return const Center(child: Text('Không tìm thấy đơn hàng'));
          }

          final statusColor = Helpers.getOrderStatusColor(order.status);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status banner
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        color: statusColor.withOpacity(0.1),
                        child: Text(
                          Helpers.getOrderStatusText(order.status),
                          style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        order.orderCode,
                        style: GoogleFonts.cormorantGaramond(
                            fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      if (order.timeline.createdAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Đặt lúc ${Helpers.formatDateTime(order.timeline.createdAt!)}',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Shipping info
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Địa chỉ giao hàng', Icons.location_on_outlined),
                      const SizedBox(height: 10),
                      Text(
                        '${order.shippingInfo.name}  ·  ${order.shippingInfo.phone}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.shippingInfo.address,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Products
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Sản phẩm', Icons.shopping_bag_outlined),
                      const SizedBox(height: 10),
                      ...order.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                if (item.thumbnailUrl != null)
                                  Image.network(
                                    item.thumbnailUrl!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey.shade100),
                                  )
                                else
                                  Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey.shade100,
                                    child: const Icon(Icons.image,
                                        color: Colors.grey),
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item.productName,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 2),
                                      Text(
                                          '${item.color ?? ''} · ${item.size ?? ''} · x${item.quantity}',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500)),
                                    ],
                                  ),
                                ),
                                Text(item.subtotal.toCurrency,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Payment info
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Thanh toán', Icons.payment_outlined),
                      const SizedBox(height: 12),
                      _infoRow('Phương thức',
                          order.paymentMethod == 'COD'
                              ? 'Tiền mặt khi nhận hàng'
                              : 'Chuyển khoản (SePay)'),
                      const SizedBox(height: 4),
                      _infoRow('Tạm tính', order.subtotal.toCurrency),
                      const SizedBox(height: 4),
                      _infoRow('Phí vận chuyển', order.shippingFee.toCurrency),
                      if (order.discount > 0) ...[
                        const SizedBox(height: 4),
                        _infoRow('Giảm giá', '-${order.discount.toCurrency}',
                            valueColor: Colors.green),
                      ],
                      Divider(height: 16, color: Colors.grey.shade200),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng cộng',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(order.total.toCurrency,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      if (order.status == AppConstants.orderShipping)
                        CustomButton(
                          text: 'THEO DÕI ĐƠN HÀNG',
                          icon: Icons.map_outlined,
                          onPressed: () => Navigator.pushNamed(
                              context, AppRoutes.orderTracking,
                              arguments: widget.orderId),
                        ),
                      if (order.status == AppConstants.orderDelivered) ...[
                        CustomButton(
                          text: 'ĐÁNH GIÁ SẢN PHẨM',
                          icon: Icons.star_outline,
                          onPressed: () {
                            if (order.items.isEmpty) return;
                            if (order.items.length == 1) {
                              Navigator.pushNamed(context, AppRoutes.reviews,
                                  arguments: order.items.first.productId);
                            } else {
                              // Multiple products - show picker
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.white,
                                shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                                builder: (_) => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 12),
                                    Container(width: 40, height: 4,
                                        decoration: BoxDecoration(color: Colors.grey.shade300,
                                            borderRadius: BorderRadius.circular(2))),
                                    const SizedBox(height: 16),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 16),
                                      child: Text('Chọn sản phẩm để đánh giá',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ),
                                    const SizedBox(height: 8),
                                    ...order.items.map((item) => ListTile(
                                          leading: item.thumbnailUrl != null
                                              ? Image.network(item.thumbnailUrl!, width: 48, height: 48, fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => const Icon(Icons.image))
                                              : const Icon(Icons.shopping_bag_outlined),
                                          title: Text(item.productName, maxLines: 1, overflow: TextOverflow.ellipsis),
                                          subtitle: Text('${item.color ?? ''} · ${item.size ?? ''}',
                                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                          onTap: () {
                                            Navigator.pop(context);
                                            Navigator.pushNamed(context, AppRoutes.reviews,
                                                arguments: item.productId);
                                          },
                                        )),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        CustomButton(
                          text: 'YÊU CẦU HOÀN TRẢ',
                          isOutlined: true,
                          onPressed: () => Navigator.pushNamed(
                              context, AppRoutes.refund,
                              arguments: widget.orderId),
                        ),
                      ],
                      if (order.status == AppConstants.orderPending) ...[
                        const SizedBox(height: 8),
                        CustomButton(
                          text: 'HỦY ĐƠN HÀNG',
                          isOutlined: true,
                          onPressed: () => _cancelOrder(provider),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black87),
        const SizedBox(width: 8),
        Text(title,
            style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: valueColor ?? Colors.black87)),
      ],
    );
  }
}
