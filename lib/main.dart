import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'app.dart';
import 'services/service_locator.dart';
import 'services/local_notification_service.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/wishlist_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register Vietnamese locale for timeago
  timeago.setLocaleMessages('vi', timeago.ViMessages());

  // Init all services via ServiceLocator
  await sl.init();

  // Init local notifications
  await LocalNotificationService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(sl.storage)),
        ChangeNotifierProvider(create: (_) => AuthProvider(sl.authService, sl.storage)),
        ChangeNotifierProvider(create: (_) => ProductProvider(sl.productService)),
        ChangeNotifierProvider(create: (_) => CartProvider(sl.cartService)),
        ChangeNotifierProvider(create: (_) => OrderProvider(sl.orderService)),
        ChangeNotifierProvider(create: (_) => NotificationProvider(sl.notificationService)),
        ChangeNotifierProvider(create: (_) => WishlistProvider(sl.wishlistService)),
      ],
      child: const FashionStyleApp(),
    ),
  );
}
