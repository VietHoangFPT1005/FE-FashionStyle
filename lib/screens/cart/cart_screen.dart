import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_routes.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_widget.dart';
import '../../widgets/cart/cart_item_card.dart';
import '../../utils/extensions.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('YOUR BAG', style: TextStyle(letterSpacing: 2.0)),
        centerTitle: true,
        actions: [
          Consumer<CartProvider>(
            builder: (_, cart, __) => cart.itemCount > 0
                ? TextButton(
                    onPressed: () => cart.clearCart(),
                    child: const Text('CLEAR', style: TextStyle(color: Colors.grey, letterSpacing: 1.0, fontSize: 12)),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (_, cart, __) {
          if (cart.isLoading) return const LoadingWidget();
          if (cart.cart == null || cart.cart!.items.isEmpty) {
            return EmptyWidget(
              message: 'Your bag is empty',
              icon: Icons.shopping_bag_outlined,
              actionText: 'DISCOVER FASHION',
              onAction: () => Navigator.pushNamed(context, AppRoutes.main),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: cart.cart!.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 32, color: Color(0xFFEEEEEE)),
                  itemBuilder: (_, i) {
                    final item = cart.cart!.items[i];
                    return CartItemCard(
                      item: item,
                      onQuantityChanged: (qty) => cart.updateQuantity(item.cartItemId, qty),
                      onRemove: () => cart.removeItem(item.cartItemId),
                    );
                  },
                ),
              ),
              // Bottom checkout bar
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('SUBTOTAL', style: TextStyle(color: Colors.black54, letterSpacing: 1.5, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text(cart.totalAmount.toCurrency,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            elevation: 0,
                          ),
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.checkout),
                          child: const Text('CHECKOUT', style: TextStyle(letterSpacing: 2.0, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
