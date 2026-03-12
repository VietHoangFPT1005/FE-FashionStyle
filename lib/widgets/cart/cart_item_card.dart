import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/cart/cart.dart';
import '../../utils/extensions.dart';

class CartItemCard extends StatelessWidget {
  final CartItem item;
  final void Function(int quantity)? onQuantityChanged;
  final VoidCallback? onRemove;

  const CartItemCard({
    super.key,
    required this.item,
    this.onQuantityChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 80,
                height: 80,
                child: item.thumbnailUrl != null
                    ? CachedNetworkImage(imageUrl: item.thumbnailUrl!, fit: BoxFit.cover)
                    : Container(color: Colors.grey.shade200, child: const Icon(Icons.image)),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  if (item.color != null || item.size != null)
                    Text(
                      [if (item.color != null) item.color, if (item.size != null) item.size]
                          .join(' / '),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.unitPrice.toCurrency,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      // Quantity controls
                      Row(
                        children: [
                          _QtyButton(
                            icon: Icons.remove,
                            onTap: item.quantity > 1
                                ? () => onQuantityChanged?.call(item.quantity - 1)
                                : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('${item.quantity}',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          _QtyButton(
                            icon: Icons.add,
                            onTap: () => onQuantityChanged?.call(item.quantity + 1),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Remove button
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 18),
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16, color: onTap != null ? Colors.black87 : Colors.grey.shade300),
      ),
    );
  }
}
