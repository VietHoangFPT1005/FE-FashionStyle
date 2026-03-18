import 'package:flutter/material.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/verify_email_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/change_password_screen.dart';
import '../screens/home/main_navigation.dart';
import '../screens/product/product_list_screen.dart';
import '../screens/product/product_detail_screen.dart';
import '../screens/product/product_search_screen.dart';
import '../screens/category/category_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/checkout/checkout_screen.dart';
import '../screens/checkout/payment_screen.dart';
import '../screens/order/order_list_screen.dart';
import '../screens/order/order_detail_screen.dart';
import '../screens/order/order_tracking_screen.dart';
import '../screens/order/order_success_screen.dart';
import '../screens/address/address_list_screen.dart';
import '../screens/address/address_form_screen.dart';
import '../screens/address/address_picker_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/wishlist/wishlist_screen.dart';
import '../screens/notification/notification_screen.dart';
import '../screens/voucher/voucher_screen.dart';
import '../screens/review/review_screen.dart';
import '../screens/refund/refund_screen.dart';
import '../screens/chat/ai_chat_screen.dart';
import '../screens/chat/support_chat_screen.dart';         // [CHAT SUPPORT - MỚI THÊM]
import '../screens/chat/staff_chat_list_screen.dart';      // [CHAT SUPPORT - MỚI THÊM]
import '../screens/chat/staff_chat_detail_screen.dart';    // [CHAT SUPPORT - MỚI THÊM]
import '../screens/shipper/shipper_orders_screen.dart';
import '../screens/shipper/shipper_delivery_screen.dart';
import '../screens/admin/admin_screen.dart';
import '../screens/admin/admin_orders_screen.dart';
import '../screens/admin/admin_order_detail_screen.dart';
import '../screens/admin/admin_users_screen.dart';
import '../screens/admin/admin_products_screen.dart';
import '../screens/admin/admin_product_form_screen.dart';
import '../screens/admin/admin_vouchers_screen.dart';
import '../screens/admin/admin_refunds_screen.dart';

class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyEmail = '/verify-email';
  static const String forgotPassword = '/forgot-password';
  static const String changePassword = '/change-password';
  static const String main = '/main';
  static const String productList = '/products';
  static const String productDetail = '/product-detail';
  static const String productSearch = '/product-search';
  static const String categories = '/categories';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String payment = '/payment';
  static const String orders = '/orders';
  static const String orderDetail = '/order-detail';
  static const String orderTracking = '/order-tracking';
  static const String orderSuccess = '/order-success';
  static const String addresses = '/addresses';
  static const String addressForm = '/address-form';
  static const String addressPicker = '/address-picker';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String wishlist = '/wishlist';
  static const String notifications = '/notifications';
  static const String vouchers = '/vouchers';
  static const String reviews = '/reviews';
  static const String refund = '/refund';
  static const String aiChat = '/ai-chat';
  // TODO: [CHAT SUPPORT] Uncomment 3 hằng số route sau sau khi scaffold BE xong
  static const String supportChat = '/support-chat';
  static const String staffChatList = '/staff-chat';
  static const String staffChatDetail = '/staff-chat-detail';
  static const String shipperOrders = '/shipper-orders';
  static const String shipperDelivery = '/shipper-delivery';
  static const String admin = '/admin';
  static const String adminOrders = '/admin/orders';
  static const String adminOrderDetail = '/admin/order-detail';
  static const String adminUsers = '/admin/users';
  static const String adminProducts = '/admin/products';
  static const String adminProductForm = '/admin/product-form';
  static const String adminVouchers = '/admin/vouchers';
  static const String adminRefunds = '/admin/refunds';

  // Route generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen(), settings);
      case login:
        return _buildRoute(const LoginScreen(), settings);
      case register:
        return _buildRoute(const RegisterScreen(), settings);
      case verifyEmail:
        final email = settings.arguments as String;
        return _buildRoute(VerifyEmailScreen(email: email), settings);
      case forgotPassword:
        return _buildRoute(const ForgotPasswordScreen(), settings);
      case changePassword:
        return _buildRoute(const ChangePasswordScreen(), settings);
      case main:
        return _buildRoute(const MainNavigation(), settings);
      case productList:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          ProductListScreen(
            categoryId: args?['categoryId'],
            categoryName: args?['categoryName'],
          ),
          settings,
        );
      case productDetail:
        final productId = settings.arguments as int;
        return _buildRoute(ProductDetailScreen(productId: productId), settings);
      case productSearch:
        return _buildRoute(const ProductSearchScreen(), settings);
      case categories:
        return _buildRoute(const CategoryScreen(), settings);
      case cart:
        return _buildRoute(const CartScreen(), settings);
      case checkout:
        return _buildRoute(const CheckoutScreen(), settings);
      case payment:
        final args = settings.arguments as Map<String, dynamic>;
        return _buildRoute(PaymentScreen(paymentData: args), settings);
      case orders:
        return _buildRoute(const OrderListScreen(), settings);
      case orderDetail:
        final orderId = settings.arguments as int;
        return _buildRoute(OrderDetailScreen(orderId: orderId), settings);
      case orderTracking:
        final orderId = settings.arguments as int;
        return _buildRoute(OrderTrackingScreen(orderId: orderId), settings);
      case orderSuccess:
        final args = settings.arguments as Map<String, dynamic>;
        return _buildRoute(
          OrderSuccessScreen(
            orderId: args['orderId'] as int,
            total: (args['total'] as num).toDouble(),
            paymentMethod: args['paymentMethod'] as String,
          ),
          settings,
        );
      case addresses:
        return _buildRoute(const AddressListScreen(), settings);
      case addressForm:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(AddressFormScreen(addressData: args), settings);
      case addressPicker:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          AddressPickerScreen(
            initialLat: args?['latitude'],
            initialLng: args?['longitude'],
          ),
          settings,
        );
      case profile:
        return _buildRoute(const ProfileScreen(), settings);
      case editProfile:
        return _buildRoute(const EditProfileScreen(), settings);
      case wishlist:
        return _buildRoute(const WishlistScreen(), settings);
      case notifications:
        return _buildRoute(const NotificationScreen(), settings);
      case vouchers:
        return _buildRoute(const VoucherScreen(), settings);
      case reviews:
        final productId = settings.arguments as int;
        return _buildRoute(ReviewScreen(productId: productId), settings);
      case refund:
        final orderId = settings.arguments as int;
        return _buildRoute(RefundScreen(orderId: orderId), settings);
      case aiChat:
        return _buildRoute(const AiChatScreen(), settings);
      // [CHAT SUPPORT - MỚI THÊM]
      case supportChat:
        return _buildRoute(const SupportChatScreen(), settings);
      case staffChatList:
        return _buildRoute(const StaffChatListScreen(), settings);
      case staffChatDetail:
        return _buildRoute(const StaffChatDetailScreen(), settings);
      case shipperOrders:
        return _buildRoute(const ShipperOrdersScreen(), settings);
      case shipperDelivery:
        final args = settings.arguments as Map<String, dynamic>;
        return _buildRoute(ShipperDeliveryScreen(orderData: args), settings);
      case admin:
        return _buildRoute(const AdminScreen(), settings);
      case adminOrders:
        return _buildRoute(const AdminOrdersScreen(), settings);
      case adminOrderDetail:
        final orderId = settings.arguments as int;
        return _buildRoute(AdminOrderDetailScreen(orderId: orderId), settings);
      case adminUsers:
        return _buildRoute(const AdminUsersScreen(), settings);
      case adminProducts:
        return _buildRoute(const AdminProductsScreen(), settings);
      case adminProductForm:
        final product = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(AdminProductFormScreen(product: product), settings);
      case adminVouchers:
        return _buildRoute(const AdminVouchersScreen(), settings);
      case adminRefunds:
        return _buildRoute(const AdminRefundsScreen(), settings);
      default:
        return _buildRoute(
          Scaffold(body: Center(child: Text('Route not found: ${settings.name}'))),
          settings,
        );
    }
  }

  static MaterialPageRoute _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
