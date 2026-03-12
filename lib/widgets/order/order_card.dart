import 'package:flutter/material.dart';
import '../../models/order/order.dart';
import '../../config/app_routes.dart';
import '../../utils/helpers.dart';
import '../../utils/extensions.dart';

class OrderCard extends StatelessWidget {
  final OrderSummary order;

  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final statusColor = Helpers.getOrderStatusColor(order.status);

    return Card(
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.orderDetail,
          arguments: order.orderId,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(order.orderCode,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      Helpers.getOrderStatusText(order.status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${order.totalItems} san pham',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  Text(order.total.toCurrency,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),

              if (order.createdAt != null) ...[
                const SizedBox(height: 6),
                Text(
                  order.createdAt!.toFormattedDateTime,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
