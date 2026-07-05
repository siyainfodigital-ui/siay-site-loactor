import 'package:get/get.dart';
import '../controllers/customer_controller.dart';
import '../controllers/bulk_upload_controller.dart';

class CustomerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CustomerController>(() => CustomerController());
    Get.lazyPut<BulkUploadController>(() => BulkUploadController());
  }
}
