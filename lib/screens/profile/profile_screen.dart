import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_routes.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('MY ACCOUNT', style: TextStyle(letterSpacing: 2.0)),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // Elegant User info header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                  child: user?.avatarUrl == null ? const Icon(Icons.person, size: 40, color: Colors.grey) : null,
                ),
                const SizedBox(height: 20),
                Text(
                  user?.fullName?.toUpperCase() ?? 'GUEST',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user?.email ?? 'Please log in to continue',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          
          _buildSectionTitle('ACCOUNT'),
          _menuItem(context, Icons.person_outline, 'Personal Information', AppRoutes.editProfile),
          _menuItem(context, Icons.location_on_outlined, 'My Addresses', AppRoutes.addresses),
          _menuItem(context, Icons.receipt_long_outlined, 'Order History', AppRoutes.orders),
          _menuItem(context, Icons.lock_outline, 'Change Password', AppRoutes.changePassword),
          
          const Divider(height: 32, color: Color(0xFFEEEEEE), thickness: 8),
          
          _buildSectionTitle('SETTINGS & MORE'),
          _menuItem(context, Icons.favorite_outline, 'Wishlist', AppRoutes.wishlist),
          _menuItem(context, Icons.local_offer_outlined, 'Vouchers & Offers', AppRoutes.vouchers),
          _menuItem(context, Icons.smart_toy_outlined, 'Fashion AI Assistant', AppRoutes.aiChat),
          
          const Divider(height: 32, color: Color(0xFFEEEEEE), thickness: 8),
          
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.black87),
                title: const Text('Sign Out', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                onTap: () async {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
                  }
                },
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.login, color: Colors.black87),
                title: const Text('Sign In', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                onTap: () => Navigator.pushNamed(context, AppRoutes.login),
              ),
            ),
            
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: () => Navigator.pushNamed(context, route),
    );
  }
}
