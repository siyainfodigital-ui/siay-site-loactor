class AppConstants {
  // Supabase
  static const String customersTable = 'customers';
  static const String installationsTable = 'installations';
  static const String logsTable = 'logs';
  static const String photoBucket = 'site_photos';
  static const String installationPhotosBucket = 'installation_photos';
  static const String verifiedPhotosBucket = 'verified_photos';
  static const String installerRole = 'installer';
  static const String adminRole = 'admin';

  // Status codes
  static const String statusPending = 'P';
  static const String statusSubmitted = 'S';
  static const String statusVerified = 'V';
  static const String statusRejected = 'R';
  static const String statusVisited = 'V'; // This might conflict with statusVerified, but for customers it means Visited. For installations, V is Verified.
  static const String statusDone = 'D';

  // Hive boxes
  static const String customerBox = 'customer_cache';
  static const String installationBox = 'installation_cache';
  static const String logsBox = 'logs_cache';
  static const String settingsBox = 'settings';
  static const String syncQueueBox = 'sync_queue';

  // Cache keys
  static const String cachedCustomers = 'cached_customers';
  static const String userRoleKey = 'user_role';
  static const String userIdKey = 'user_id';

  // Validation
  static const int mobileLength = 10;
  static const int otpLength = 6;
  static const double maxFileSizeMb = 10;

  // Map defaults (Maharashtra center)
  static const double defaultLat = 19.7515;
  static const double defaultLng = 75.7139;
  static const double defaultZoom = 8.0;
  static const double siteZoom = 16.0;

  // CSV / Excel columns (0-indexed)
  static const List<String> csvColumns = [
    'name',
    'mobile',
    'village',
    'taluka',
    'address',
    'solar_kw',
  ];

  // Pagination
  static const int pageSize = 50;

  // Photo
  static const int photoMaxDimension = 1200;
  static const int photoQuality = 80;
}
