import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/customer_model.dart';
import '../models/installation_model.dart';
import '../services/supabase_service.dart';

class AdminPhotosController extends GetxController {
  final CustomerModel customer;
  final Rx<InstallationModel?> installation = Rx<InstallationModel?>(null);
  final RxBool isLoading = true.obs;

  AdminPhotosController({required this.customer});

  @override
  void onInit() {
    super.onInit();
    _loadInstallation();
  }

  Future<void> _loadInstallation() async {
    isLoading.value = true;
    try {
      final data = await SupabaseService.getInstallation(customer.id);
      installation.value = data;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load photos: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updatePhotoStatus(String photoTypeKey, String newStatus, {String? remark}) async {
    if (installation.value == null) return;
    
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      Map<String, dynamic> updates = {
        'id': installation.value!.id,
        'customer_id': customer.id,
        '${photoTypeKey}_status': newStatus,
      };

      if (remark != null && remark.isNotEmpty) {
        final currentRemark = installation.value!.adminRemark ?? '';
        final newRemark = '${currentRemark.isNotEmpty ? '$currentRemark\n' : ''}[$photoTypeKey]: $remark';
        updates['admin_remark'] = newRemark;
      }

      final updated = await SupabaseService.upsertInstallation(updates);
      installation.value = updated;
      Get.back(); // close dialog
      
      Get.snackbar('Success', 'Photo status updated to ${newStatus == 'A' ? 'Approved' : 'Rejected'}');
    } catch (e) {
      Get.back();
      Get.snackbar('Error', 'Failed to update photo status: $e');
    }
  }

  void approvePhoto(String photoTypeKey) => updatePhotoStatus(photoTypeKey, 'A');
  void rejectPhoto(String photoTypeKey) => updatePhotoStatus(photoTypeKey, 'R');
  void addRemark(String photoTypeKey, String remark) => updatePhotoStatus(photoTypeKey, installation.value?.toJson()['${photoTypeKey}_status'] ?? 'P', remark: remark);

  bool get isStructurePending => (installation.value?.structurePhotoStatus ?? 'P') == 'P';
  bool get isPanelPending => (installation.value?.panelPhotoStatus ?? 'P') == 'P';
  bool get isInverterPending => (installation.value?.inverterPhotoStatus ?? 'P') == 'P';
  bool get isMeterPending => (installation.value?.meterPhotoStatus ?? 'P') == 'P';
  bool get isFinalPending => (installation.value?.finalPhotoStatus ?? 'P') == 'P';

  bool get hasStructurePhoto => installation.value?.structurePhotoUrl != null;
  bool get hasPanelPhotos => installation.value?.panelPhotoUrls != null && installation.value!.panelPhotoUrls!.isNotEmpty;
  bool get hasInverterPhoto => installation.value?.inverterPhotoUrl != null;
  bool get hasMeterPhoto => installation.value?.meterPhotoUrl != null;
  bool get hasFinalPhoto => installation.value?.finalPhotoUrl != null;
}
