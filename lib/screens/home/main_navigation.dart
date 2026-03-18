import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import '../../config/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/wishlist_provider.dart';
import 'home_screen.dart';
import '../category/category_screen.dart';
import '../cart/cart_screen.dart';
import '../notification/notification_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late final AnimationController _fabAnim;

  final _screens = const [
    HomeScreen(),
    CategoryScreen(),
    CartScreen(),
    NotificationScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().loadCart();
      context.read<NotificationProvider>().loadUnreadCount();
      context.read<WishlistProvider>().loadWishlist();
    });
  }

  @override
  void dispose() {
    _fabAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    // Chỉ Customer (role=3) mới thấy nút chat với Staff
    final isCustomer = user?.role == 3;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),

      // Floating Chat Button — chỉ hiện với Customer
      floatingActionButton: isCustomer
          ? ScaleTransition(
              scale: CurvedAnimation(parent: _fabAnim, curve: Curves.elasticOut),
              child: _SupportChatFab(
                onTap: () => Navigator.pushNamed(context, AppRoutes.supportChat),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade200, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey.shade500,
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 26),
              activeIcon: Icon(Icons.home, size: 26),
              label: 'HOME',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined, size: 24),
              activeIcon: Icon(Icons.grid_view, size: 24),
              label: 'SHOP',
            ),
            BottomNavigationBarItem(
              icon: Consumer<CartProvider>(
                builder: (_, cart, child) => badges.Badge(
                  showBadge: cart.itemCount > 0,
                  badgeStyle: const badges.BadgeStyle(
                    badgeColor: Colors.black,
                    padding: EdgeInsets.all(4),
                  ),
                  badgeContent: Text('${cart.itemCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  child: child!,
                ),
                child: const Icon(Icons.shopping_bag_outlined, size: 25),
              ),
              activeIcon: const Icon(Icons.shopping_bag, size: 25),
              label: 'CART',
            ),
            BottomNavigationBarItem(
              icon: Consumer<NotificationProvider>(
                builder: (_, notif, child) => badges.Badge(
                  showBadge: notif.unreadCount > 0,
                  badgeStyle: const badges.BadgeStyle(
                    badgeColor: Colors.redAccent,
                    padding: EdgeInsets.all(4),
                  ),
                  badgeContent: Text('${notif.unreadCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  child: child!,
                ),
                child: const Icon(Icons.notifications_none, size: 26),
              ),
              activeIcon: const Icon(Icons.notifications, size: 26),
              label: 'INBOX',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 26),
              activeIcon: Icon(Icons.person, size: 26),
              label: 'ACCOUNT',
            ),
          ],
        ),
      ),
    );
  }
}

/// Nút chat nổi dành cho Customer — thiết kế pill expandable
class _SupportChatFab extends StatefulWidget {
  final VoidCallback onTap;
  const _SupportChatFab({required this.onTap});

  @override
  State<_SupportChatFab> createState() => _SupportChatFabState();
}

class _SupportChatFabState extends State<_SupportChatFab>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _ctrl;
  late final Animation<double> _widthAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _widthAnim = Tween<double>(begin: 54, end: 140).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    // Tự expand rồi collapse để hint user
    Future.delayed(const Duration(milliseconds: 800), _hintExpand);
  }

  Future<void> _hintExpand() async {
    if (!mounted) return;
    setState(() => _expanded = true);
    _ctrl.forward();
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _expanded = false);
    _ctrl.reverse();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() => _expanded = true);
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 120), widget.onTap);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _widthAnim,
      builder: (_, __) => GestureDetector(
        onTap: _handleTap,
        child: Container(
          height: 52,
          width: _expanded ? _widthAnim.value : 54,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.28),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.support_agent_rounded, color: Colors.white, size: 22),
              if (_expanded) ...[
                const SizedBox(width: 7),
                const Text(
                  'Chat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
