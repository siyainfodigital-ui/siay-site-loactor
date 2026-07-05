import 'package:get/get.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/customer_controller.dart';

class AdminBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure AuthController is always available (may already exist as permanent)
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(AuthController(), permanent: true);
    }
    Get.lazyPut<AdminDashboardController>(() => AdminDashboardController());
    Get.lazyPut<CustomerController>(() => CustomerController());
  }
}
