import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_constants.dart';
import '../../providers/order_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_widget.dart';
import '../../widgets/order/order_card.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabs = [
    {'label': 'Tất cả', 'status': null},
    {'label': 'Chờ xác nhận', 'status': AppConstants.orderPending},
    {'label': 'Đang giao', 'status': AppConstants.orderShipping},
    {'label': 'Đã giao', 'status': AppConstants.orderDelivered},
    {'label': 'Đã hủy', 'status': AppConstants.orderCancelled},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context.read<OrderProvider>().loadOrders(
            status: _tabs[_tabController.index]['status'] as String?);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          'Đơn hàng của tôi',
          style: GoogleFonts.cormorantGaramond(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          indicatorWeight: 2,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          tabs: _tabs.map((t) => Tab(text: t['label'] as String)).toList(),
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading) return const LoadingWidget();
          if (provider.orders.isEmpty) {
            return EmptyWidget(
              message: 'Chưa có đơn hàng nào',
              icon: Icons.receipt_long_outlined,
              actionText: 'Mua sắm ngay',
              onAction: () => Navigator.pop(context),
            );
          }
          return RefreshIndicator(
            color: Colors.black,
            onRefresh: () => provider.loadOrders(
                status:
                    _tabs[_tabController.index]['status'] as String?),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: provider.orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => OrderCard(order: provider.orders[i]),
            ),
          );
        },
      ),
    );
  }
}
