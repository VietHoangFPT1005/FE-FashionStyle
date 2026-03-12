import 'api_client.dart';
import 'storage_service.dart';
import 'auth_service.dart';
import 'product_service.dart';
import 'category_service.dart';
import 'cart_service.dart';
import 'order_service.dart';
import 'address_service.dart';
import 'user_service.dart';
import 'review_service.dart';
import 'notification_service.dart';
import 'voucher_service.dart';
import 'wishlist_service.dart';
import 'shipper_service.dart';
import 'refund_service.dart';
import 'chat_service.dart';
import 'payment_service.dart';
import 'location_service.dart';
import 'admin_service.dart';
import 'support_chat_service.dart'; // [CHAT SUPPORT - MỚI THÊM]

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._();
  factory ServiceLocator() => _instance;
  ServiceLocator._();

  late final StorageService storage;
  late final ApiClient apiClient;
  late final AuthService authService;
  late final ProductService productService;
  late final CategoryService categoryService;
  late final CartService cartService;
  late final OrderService orderService;
  late final AddressService addressService;
  late final UserService userService;
  late final ReviewService reviewService;
  late final NotificationService notificationService;
  late final VoucherService voucherService;
  late final WishlistService wishlistService;
  late final ShipperService shipperService;
  late final RefundService refundService;
  late final ChatService chatService;
  late final PaymentService paymentService;
  late final LocationService locationService;
  late final AdminService adminService;
  late final SupportChatService supportChatService; // [CHAT SUPPORT - MỚI THÊM]

  Future<void> init() async {
    storage = StorageService();
    await storage.init();

    apiClient = ApiClient(storage);

    authService = AuthService(apiClient);
    productService = ProductService(apiClient);
    categoryService = CategoryService(apiClient);
    cartService = CartService(apiClient);
    orderService = OrderService(apiClient);
    addressService = AddressService(apiClient);
    userService = UserService(apiClient);
    reviewService = ReviewService(apiClient);
    notificationService = NotificationService(apiClient);
    voucherService = VoucherService(apiClient);
    wishlistService = WishlistService(apiClient);
    shipperService = ShipperService(apiClient);
    refundService = RefundService(apiClient);
    chatService = ChatService(apiClient);
    paymentService = PaymentService(apiClient);
    locationService = LocationService(shipperService);
    adminService = AdminService(apiClient);
    supportChatService = SupportChatService(apiClient); // [CHAT SUPPORT - MỚI THÊM]
  }
}

// Global access
final sl = ServiceLocator();
