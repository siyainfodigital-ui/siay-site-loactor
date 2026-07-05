import 'package:get/get.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/admin/admin_main_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/add_customer_screen.dart';
import '../../screens/admin/bulk_upload_screen.dart';
import '../../screens/admin/customer_list_screen.dart';
import '../../screens/admin/installer_manage_screen.dart';
import '../../screens/installer/installer_dashboard_screen.dart';
import '../../screens/installer/site_visit_screen.dart';
import '../../screens/installer/installation_details_screen.dart';
import '../../screens/admin/admin_verification_screen.dart';
import '../../screens/admin/admin_photos_screen.dart';
import '../../screens/admin/terminal_log_screen.dart';
import '../bindings/auth_binding.dart';
import '../bindings/admin_binding.dart';
import '../bindings/customer_binding.dart';
import '../bindings/installer_binding.dart';
import '../bindings/site_visit_binding.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String adminDashboard = '/admin';
  static const String addCustomer = '/admin/add-customer';
  static const String customerList = '/admin/customers';
  static const String bulkUpload = '/admin/bulk-upload';
  static const String adminVerification = '/admin/verification';
  static const String adminPhotos = '/admin/photos';
  static const String installerDashboard = '/installer';
  static const String siteVisit = '/installer/site-visit';
  static const String installationSubmission = '/installer/installation';
  static const String installerManage = '/admin/installers';
  static const String terminalLogs = '/admin/terminal-logs';

  static final List<GetPage> pages = [
    GetPage(
      name: splash,
      page: () => const SplashScreen(),
      binding: AuthBinding(),
      transition: Transition.fade,
    ),
    GetPage(
      name: login,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: adminDashboard,
      page: () => const AdminMainScreen(),
      binding: AdminBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: addCustomer,
      page: () => const AddCustomerScreen(),
      binding: CustomerBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: customerList,
      page: () => const CustomerListScreen(),
      binding: CustomerBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: bulkUpload,
      page: () => const BulkUploadScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: installerManage,
      page: () => const InstallerManageScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: installerDashboard,
      page: () => const InstallerDashboardScreen(),
      binding: InstallerBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: siteVisit,
      page: () => const SiteVisitScreen(),
      binding: SiteVisitBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: installationSubmission,
      page: () => const InstallationDetailsScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: adminVerification,
      page: () => const AdminVerificationScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: adminPhotos,
      page: () => const AdminPhotosScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: terminalLogs,
      page: () => const TerminalLogScreen(),
      transition: Transition.cupertino,
    ),
  ];
}
