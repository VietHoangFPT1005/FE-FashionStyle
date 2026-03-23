class ApiConfig {
  // === Chọn môi trường ===
  // true  → chạy LOCAL (tạo tài khoản, test nhanh, không tốn quota)
  // false → chạy PRODUCTION trên Render
  // static const bool useLocalServer = false;
  static const bool useLocalServer = true;

  // === URL theo môi trường ===
  // Local - điện thoại thật cần cùng WiFi với máy tính
  static const String _localUrl = 'http://192.168.102.20:5118/api';
  // Production - Render deploy
  static const String _productionUrl = 'https://be-fashionstyle.onrender.com/api';

  static const String baseUrl = useLocalServer ? _localUrl : _productionUrl;

  // === Timeout (ms) ===
  // Local: 15s | Production Render cold start có thể mất 30-50s
  static const int connectTimeout = useLocalServer ? 15000 : 60000;
  static const int receiveTimeout = useLocalServer ? 15000 : 60000;

  // === OpenStreetMap / Nominatim ===
  static const String osmBaseUrl = 'https://nominatim.openstreetmap.org';
  static const String osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String osmUserAgent = 'FashionStyleApp/1.0';

  // ==================== AUTH ====================
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verifyEmail = '/auth/verify-email';
  static const String resendOtp = '/auth/resend-otp';
  static const String refreshToken = '/auth/refresh-token';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';
  static const String googleLogin = '/auth/google-login';
  static const String logout = '/auth/logout';

  // ==================== USER ====================
  static const String userProfile = '/users/profile';
  static const String bodyProfile = '/users/body-profile';
  static const String addresses = '/users/addresses';
  static String addressById(int id) => '/users/addresses/$id';
  static String setDefaultAddress(int id) => '/users/addresses/$id/set-default';

  // ==================== PRODUCTS ====================
  static const String products = '/products';
  static const String productSearch = '/products/search';
  static String productDetail(int id) => '/products/$id';
  static String productVariants(int id) => '/products/$id/variants';
  static String productImages(int id) => '/products/$id/images';
  static String productSizeGuide(int id) => '/products/$id/size-guide';
  static String productRecommendSize(int id) => '/products/$id/recommend-size';
  static String productReviews(int id) => '/products/$id/reviews';

  // ==================== CATEGORIES ====================
  static const String categories = '/categories';
  static String categoryProducts(int id) => '/categories/$id/products';

  // ==================== CART ====================
  static const String cart = '/cart';
  static const String cartItems = '/cart/items';
  static String cartItemById(int id) => '/cart/items/$id';

  // ==================== ORDERS ====================
  // Backend controller: [Route("api/Order")]
  static const String createOrder = '/Order/checkout';     // POST
  static const String myOrders   = '/Order/my-orders';    // GET list
  static String orderDetail(int id) => '/Order/$id';
  static String cancelOrder(int id) => '/Order/$id/cancel';
  static String orderTracking(int id) => '/Order/$id/tracking';

  // ==================== REVIEWS ====================
  static String createReview(int productId) => '/products/$productId/reviews';
  static String updateReview(int productId, int reviewId) =>
      '/products/$productId/reviews/$reviewId';
  static String deleteReview(int productId, int reviewId) =>
      '/products/$productId/reviews/$reviewId';

  // ==================== WISHLIST ====================
  static const String wishlists = '/wishlists';
  static String removeWishlist(int productId) => '/wishlists/$productId';

  // ==================== NOTIFICATIONS ====================
  static const String notifications = '/notifications';
  static String readNotification(int id) => '/notifications/$id/read';
  static const String readAllNotifications = '/notifications/read-all';
  static const String unreadCount = '/notifications/unread-count';
  static String deleteNotification(int id) => '/notifications/$id';

  // ==================== VOUCHERS ====================
  static const String vouchers = '/vouchers';
  static const String validateVoucher = '/vouchers/validate';

  // ==================== PAYMENT ====================
  // Backend controller: [Route("api/Payment")]
  static const String createPayment = '/Payment/sepay/create';            // POST { orderId }
  static String paymentPollStatus(int orderId) => '/Payment/$orderId/poll-status'; // GET polling

  // ==================== CHAT AI ====================
  static const String chatAi = '/chat/ai';
  static const String chatSessions = '/chat/ai/sessions';
  static String chatSessionById(String id) => '/chat/ai/sessions/$id';

  // ==================== CHAT SUPPORT (MỚI THÊM) ====================
  // SignalR Hub URL (không có /api prefix)
  static String get chatHubUrl => baseUrl.replaceFirst('/api', '') + '/hubs/chat';
  // REST: lấy lịch sử chat
  static const String supportChatHistory = '/SupportChat/history';
  static String supportChatCustomerHistory(int customerId) => '/SupportChat/history/$customerId';
  static const String supportChatConversations = '/SupportChat/conversations';
  static String supportChatMarkRead(int customerId) => '/SupportChat/read/$customerId';
  static const String supportChatUploadImage = '/SupportChat/upload-image';

  // ==================== SHIPPER ====================
  static const String shipperOrders = '/shipper/orders';
  static String shipperPickup(int id) => '/shipper/orders/$id/pickup';
  static String shipperDeliver(int id) => '/shipper/orders/$id/deliver';
  static String shipperFail(int id) => '/shipper/orders/$id/fail';
  static const String shipperLocation = '/shipper/location';

  // ==================== REFUND ====================
  static String createRefund(int orderId) => '/orders/$orderId/refund';
  static String getRefund(int orderId) => '/orders/$orderId/refund';

  // ==================== ADMIN ====================
  static const String adminUsers = '/admin/users';
  static String adminUserRole(int userId) => '/admin/users/$userId/role';
  static String adminUserStatus(int userId) => '/admin/users/$userId/status';
  static const String adminOrders = '/admin/orders';
  static String adminOrderDetail(int id) => '/admin/orders/$id';
  static String adminConfirmOrder(int id) => '/admin/orders/$id/confirm';
  static String adminAssignShipper(int id) => '/admin/orders/$id/assign-shipper';
  static String adminCancelOrder(int id) => '/admin/orders/$id/cancel';
  static const String adminBroadcast = '/admin/notifications/broadcast';
  static String adminDeleteReview(int id) => '/admin/reviews/$id';

  // Admin Products
  static const String adminProducts = '/admin/products';
  static const String adminProductUploadImage = '/admin/products/upload-image';
  static String adminProductDetail(int id) => '/admin/products/$id';
  static String adminProductVariants(int id) => '/admin/products/$id/variants';
  static String adminVariant(int id) => '/admin/products/variants/$id';
  static String adminProductImages(int id) => '/admin/products/$id/images';
  static String adminImage(int id) => '/admin/products/images/$id';
  static String adminProductSizeGuide(int id) => '/admin/products/$id/size-guide';

  // Admin Categories
  static const String adminCategories = '/admin/categories';
  static String adminCategoryById(int id) => '/admin/categories/$id';

  // Admin Vouchers
  static const String adminVouchers = '/admin/vouchers';
  static String adminVoucherById(int id) => '/admin/vouchers/$id';

  // Admin Refunds
  static const String adminRefunds = '/admin/refunds';
  static String adminApproveRefund(int id) => '/admin/refunds/$id/approve';
  static String adminRejectRefund(int id) => '/admin/refunds/$id/reject';
}
