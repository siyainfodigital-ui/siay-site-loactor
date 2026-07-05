import 'package:get/get.dart';
import '../controllers/installer_dashboard_controller.dart';
import '../controllers/auth_controller.dart';

class InstallerBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(AuthController(), permanent: true);
    }
    Get.lazyPut<InstallerDashboardController>(
        () => InstallerDashboardController());
  }
}
