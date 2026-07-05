import 'package:get/get.dart';
import '../controllers/site_visit_controller.dart';

class SiteVisitBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SiteVisitController>(() => SiteVisitController());
  }
}
