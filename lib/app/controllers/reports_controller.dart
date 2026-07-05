import 'dart:io';
import 'package:csv/csv.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../services/supabase_service.dart';
import '../models/customer_model.dart';

class ReportsController extends GetxController {
  final RxBool isLoading = true.obs;
  final RxBool isExporting = false.obs;
  
  final RxInt totalCustomers = 0.obs;
  final RxInt pendingCount = 0.obs;
  final RxInt submittedCount = 0.obs;
  final RxInt verifiedCount = 0.obs;
  final RxInt rejectedCount = 0.obs;
  
  final RxList<CustomerModel> allCustomers = <CustomerModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadReports();
  }

  Future<void> loadReports() async {
    isLoading.value = true;
    try {
      final customers = await SupabaseService.getCustomers(); // Fetch all
      allCustomers.value = customers;
      
      totalCustomers.value = customers.length;
      
      int pend = 0, sub = 0, ver = 0, rej = 0;
      for (var c in customers) {
        if (c.status == 'P') pend++;
        else if (c.status == 'S') sub++;
        else if (c.status == 'V') ver++;
        else if (c.status == 'R') rej++;
      }
      
      pendingCount.value = pend;
      submittedCount.value = sub;
      verifiedCount.value = ver;
      rejectedCount.value = rej;
      
    } catch (e) {
      Get.snackbar('Error', 'Failed to load report data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> exportCsv() async {
    if (allCustomers.isEmpty) {
      Get.snackbar('Empty', 'No data to export');
      return;
    }
    
    isExporting.value = true;
    try {
      List<List<dynamic>> rows = [];
      // Headers
      rows.add([
        'ID',
        'Name',
        'Mobile',
        'Consumer No',
        'Village',
        'Taluka',
        'Address',
        'Installer',
        'Status',
        'Created At'
      ]);
      
      // Data
      for (var c in allCustomers) {
        rows.add([
          c.id,
          c.name,
          c.mobile,
          c.consumerNo ?? '',
          c.village ?? '',
          c.taluka ?? '',
          c.address ?? '',
          c.installer ?? '',
          _getFullStatus(c.status),
          c.createdAt != null ? DateFormat('yyyy-MM-dd HH:mm').format(c.createdAt!) : '',
        ]);
      }
      
      String csv = const ListToCsvConverter().convert(rows);
      
      final dir = await getApplicationDocumentsDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final path = '${dir.path}/siyasitelocator_report_$dateStr.csv';
      final file = File(path);
      await file.writeAsString(csv);
      
      // Share file
      await Share.shareXFiles([XFile(path)], text: 'Installation Report - $dateStr');
      
    } catch (e) {
      Get.snackbar('Error', 'Failed to export CSV: $e');
    } finally {
      isExporting.value = false;
    }
  }
  
  String _getFullStatus(String status) {
    switch (status) {
      case 'P': return 'Pending';
      case 'S': return 'Submitted';
      case 'V': return 'Verified';
      case 'R': return 'Rejected';
      default: return status;
    }
  }
}
