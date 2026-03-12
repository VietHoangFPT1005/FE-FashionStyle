import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../services/service_locator.dart';
import '../../utils/helpers.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  Map<String, dynamic>? _dashboard;
  bool _loadingDash = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _loadingDash = true);
    try {
      final res = await sl.adminService.getDashboard();
      if (res.success && res.data is Map<String, dynamic>) {
        setState(() => _dashboard = res.data as Map<String, dynamic>);
      }
    } catch (_) {}
    setState(() => _loadingDash = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final isAdmin = user?.role == 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          isAdmin ? 'ADMIN PANEL' : 'STAFF PANEL',
          style: GoogleFonts.cormorantGaramond(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          children: [
            _buildHeader(user),

            // ── Dashboard (Admin only) ──
            if (isAdmin) ...[
              const SizedBox(height: 16),
              _buildSectionTitle('Dashboard', Icons.dashboard_outlined),
              const SizedBox(height: 8),
              if (_loadingDash)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_dashboard != null) ...[
                _buildStatsRow(_dashboard!),
                const SizedBox(height: 12),
                _buildOrderStatusChart(_dashboard!),
                const SizedBox(height: 12),
                _buildTopProducts(_dashboard!),
                const SizedBox(height: 12),
                _buildRecentOrders(_dashboard!),
              ],
            ],

            const SizedBox(height: 16),
            _buildSectionTitle('Quản lý', Icons.manage_accounts_outlined),
            const SizedBox(height: 8),
            _buildMenuSection(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─── Header ───
  Widget _buildHeader(dynamic user) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white24,
            child: Text(
              ((user?.fullName ?? '').isNotEmpty ? user!.fullName![0].toUpperCase() : 'A'),
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Xin chào, ${user?.fullName ?? 'Admin'}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
              Text(user?.email ?? '', style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(title.toUpperCase(),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  // ─── Stats row (4 cards) ───
  Widget _buildStatsRow(Map<String, dynamic> dash) {
    final ov = dash['overview'] as Map<String, dynamic>? ?? {};
    final stats = [
      {'label': 'Đơn hàng', 'value': '${ov['totalOrders'] ?? 0}', 'icon': Icons.receipt_long, 'color': Colors.blue},
      {'label': 'Doanh thu', 'value': Helpers.formatCurrency(((ov['totalRevenue'] ?? 0) as num).toDouble()), 'icon': Icons.attach_money, 'color': Colors.green},
      {'label': 'Khách hàng', 'value': '${ov['totalCustomers'] ?? 0}', 'icon': Icons.people, 'color': Colors.purple},
      {'label': 'Sản phẩm', 'value': '${ov['totalProducts'] ?? 0}', 'icon': Icons.inventory_2, 'color': Colors.orange},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.9,
        children: stats.map((s) {
          final color = s['color'] as Color;
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(s['icon'] as IconData, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(s['value'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(s['label'] as String,
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Order status bar chart ───
  Widget _buildOrderStatusChart(Map<String, dynamic> dash) {
    final raw = dash['ordersByStatus'] as Map<String, dynamic>? ?? {};
    if (raw.isEmpty) return const SizedBox.shrink();

    const statusLabels = {
      'PENDING': 'Chờ', 'CONFIRMED': 'XN', 'SHIPPING': 'Giao',
      'DELIVERED': 'Xong', 'CANCELLED': 'Hủy',
    };
    const statusColors = {
      'PENDING': Colors.orange, 'CONFIRMED': Colors.blue, 'SHIPPING': Colors.teal,
      'DELIVERED': Colors.green, 'CANCELLED': Colors.red,
    };

    final entries = raw.entries.toList();
    final maxVal = entries.map((e) => (e.value as num).toDouble()).fold(0.0, (a, b) => a > b ? a : b);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Đơn hàng theo trạng thái', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: (maxVal * 1.3 + 1).clamp(1.0, double.infinity),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: ((maxVal / 4).clamp(1.0, double.infinity)),
                  getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) => Text('${v.toInt()}',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= entries.length) return const SizedBox.shrink();
                        final key = entries[idx].key;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(statusLabels[key] ?? key,
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: entries.asMap().entries.map((e) {
                  final key = e.value.key;
                  final count = (e.value.value as num).toDouble();
                  final color = statusColors[key] ?? Colors.grey;
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [BarChartRodData(toY: count, color: color, width: 22, borderRadius: BorderRadius.circular(4))],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Top products ───
  Widget _buildTopProducts(Map<String, dynamic> dash) {
    final top = (dash['topProducts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (top.isEmpty) return const SizedBox.shrink();

    final maxRevenue = top.map((p) => (p['revenue'] as num? ?? 0).toDouble()).fold(0.0, (a, b) => a > b ? a : b);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top sản phẩm bán chạy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          ...top.take(5).map((p) {
            final revenue = (p['revenue'] as num? ?? 0).toDouble();
            final ratio = maxRevenue > 0 ? revenue / maxRevenue : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(p['name'] ?? '',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Text('${p['soldCount'] ?? 0} đã bán',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade100,
                            valueColor: const AlwaysStoppedAnimation(Colors.black87),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(Helpers.formatCurrency(revenue),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Recent orders ───
  Widget _buildRecentOrders(Map<String, dynamic> dash) {
    final recent = (dash['recentOrders'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (recent.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Đơn hàng gần đây', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.adminOrders),
                  child: const Text('Xem tất cả', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...recent.take(5).map((o) {
            final status = (o['status'] ?? '').toString().toUpperCase();
            final total = (o['total'] as num?)?.toDouble() ?? 0.0;
            return ListTile(
              dense: true,
              title: Text(o['orderCode'] ?? '#${o['orderId']}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              subtitle: Text(o['customerName'] ?? '',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(Helpers.formatCurrency(total),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Helpers.getOrderStatusColor(status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(Helpers.getOrderStatusText(status),
                        style: TextStyle(color: Helpers.getOrderStatusColor(status), fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Menu ───
  Widget _buildMenuSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMenuItem(context, icon: Icons.receipt_long, title: 'Đơn hàng', subtitle: 'Xem và cập nhật trạng thái', route: AppRoutes.adminOrders, color: Colors.blue),
          _buildMenuItem(context, icon: Icons.people, title: 'Người dùng', subtitle: 'Danh sách và quản lý tài khoản', route: AppRoutes.adminUsers, color: Colors.purple),
          _buildMenuItem(context, icon: Icons.inventory_2, title: 'Sản phẩm', subtitle: 'Thêm, sửa, xóa sản phẩm', route: AppRoutes.adminProducts, color: Colors.orange),
          const SizedBox(height: 12),
          _sectionLabel('Khuyến mãi & Hoàn trả'),
          const SizedBox(height: 8),
          _buildMenuItem(context, icon: Icons.local_offer, title: 'Voucher', subtitle: 'Quản lý mã giảm giá', route: AppRoutes.adminVouchers, color: Colors.green),
          _buildMenuItem(context, icon: Icons.assignment_return, title: 'Hoàn trả', subtitle: 'Xét duyệt yêu cầu hoàn hàng', route: AppRoutes.adminRefunds, color: Colors.red),
          const SizedBox(height: 12),
          _sectionLabel('Hỗ trợ'),
          const SizedBox(height: 8),
          _buildMenuItem(context, icon: Icons.headset_mic, title: 'Chat hỗ trợ', subtitle: 'Trả lời tin nhắn từ khách hàng', route: AppRoutes.staffChatList, color: Colors.teal),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text.toUpperCase(),
    style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
  );

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, required String subtitle, required String route, required Color color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }
}
