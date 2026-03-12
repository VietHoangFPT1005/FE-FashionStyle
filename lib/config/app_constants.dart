class AppConstants {
  // App info
  static const String appName = 'FashionStyle';
  static const String appVersion = '1.0.0';

  // Storage keys
  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String firstLaunchKey = 'first_launch';

  // User roles (match BE enum)
  static const int roleAdmin = 1;
  static const int roleStaff = 2;
  static const int roleCustomer = 3;
  static const int roleShipper = 4;

  // Order statuses
  static const String orderPending = 'PENDING';
  static const String orderConfirmed = 'CONFIRMED';
  static const String orderProcessing = 'PROCESSING';
  static const String orderShipping = 'SHIPPING';
  static const String orderDelivered = 'DELIVERED';
  static const String orderCancelled = 'CANCELLED';
  static const String orderRefunded = 'REFUNDED';

  // Payment methods
  static const String paymentCod = 'COD';
  static const String paymentBanking = 'BANKING';

  // Pagination
  static const int defaultPageSize = 10;
  static const int productsPageSize = 20;

  // Location
  static const double defaultLat = 10.762622; // HCM center
  static const double defaultLng = 106.660172;
  static const int locationUpdateInterval = 5; // seconds
  static const int trackingPollInterval = 5; // seconds

  // Refund
  static const int refundWindowDays = 7;

  // Google Sign-In — Web Client ID (GCP project: hoangnv10052004)
  // Used as serverClientId to get idToken for backend verification
  static const String googleWebClientId =
      '571495207196-1ggrpkpdbpflu58qnbi8b00iqvusg312.apps.googleusercontent.com';
}
