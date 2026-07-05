import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../models/customer_model.dart';
import '../models/installation_model.dart';
import '../services/supabase_service.dart';
import '../services/offline_sync_service.dart';

class AdminVerificationController extends GetxController {
  final CustomerModel customer;
  final Rx<InstallationModel?> installation = Rx<InstallationModel?>(null);
  final RxBool isLoading = true.obs;
  
  final Rx<Uint8List?> verifiedPhotoBytes = Rx<Uint8List?>(null);
  final RxString photoName = ''.obs;
  final remarkController = ''.obs;

  // Photo Statuses (P = Pending, S = Submitted, A = Approved, R = Rejected)
  final RxString structurePhotoStatus = 'P'.obs;
  final RxString panelPhotoStatus = 'P'.obs;
  final RxString inverterPhotoStatus = 'P'.obs;
  final RxString meterPhotoStatus = 'P'.obs;
  final RxString finalPhotoStatus = 'P'.obs;

  // New Progress Getters
  int get totalChecklistItems => 8;

  int get submittedCount {
    int count = 0;
    if (structurePhotoStatus.value == 'S') count++;
    if (panelPhotoStatus.value == 'S') count++;
    if (inverterPhotoStatus.value == 'S') count++;
    if (meterPhotoStatus.value == 'S') count++;
    if (finalPhotoStatus.value == 'S') count++;
    
    final inst = installation.value;
    if (inst != null) {
      if (inst.inverterBrand != null && inst.inverterBrand!.isNotEmpty) count++;
      if (inst.inverterSerial != null && inst.inverterSerial!.isNotEmpty) count++;
      if (inst.generationMeterNo != null && inst.generationMeterNo!.isNotEmpty) count++;
    }
    return count;
  }

  int get approvedCount {
    int count = 0;
    if (structurePhotoStatus.value == 'A') count++;
    if (panelPhotoStatus.value == 'A') count++;
    if (inverterPhotoStatus.value == 'A') count++;
    if (meterPhotoStatus.value == 'A') count++;
    if (finalPhotoStatus.value == 'A') count++;
    
    // For text fields, we consider them approved if they are present and the admin hasn't rejected the installation.
    final inst = installation.value;
    if (inst != null) {
      if (inst.inverterBrand != null && inst.inverterBrand!.isNotEmpty) count++;
      if (inst.inverterSerial != null && inst.inverterSerial!.isNotEmpty) count++;
      if (inst.generationMeterNo != null && inst.generationMeterNo!.isNotEmpty) count++;
    }
    return count;
  }

  int get pendingCount {
    int count = 0;
    if (structurePhotoStatus.value == 'P') count++;
    if (panelPhotoStatus.value == 'P') count++;
    if (inverterPhotoStatus.value == 'P') count++;
    if (meterPhotoStatus.value == 'P') count++;
    if (finalPhotoStatus.value == 'P') count++;
    
    final inst = installation.value;
    if (inst == null) return count + 3;
    if (inst.inverterBrand == null || inst.inverterBrand!.isEmpty) count++;
    if (inst.inverterSerial == null || inst.inverterSerial!.isEmpty) count++;
    if (inst.generationMeterNo == null || inst.generationMeterNo!.isEmpty) count++;
    return count;
  }

  int get rejectedCount {
    int count = 0;
    if (structurePhotoStatus.value == 'R') count++;
    if (panelPhotoStatus.value == 'R') count++;
    if (inverterPhotoStatus.value == 'R') count++;
    if (meterPhotoStatus.value == 'R') count++;
    if (finalPhotoStatus.value == 'R') count++;
    return count;
  }

  List<String> get pendingItemNames {
    List<String> items = [];
    if (structurePhotoStatus.value == 'P') items.add('Structure Photo');
    if (panelPhotoStatus.value == 'P') items.add('Solar Panel Photos');
    if (inverterPhotoStatus.value == 'P') items.add('Inverter Photo');
    if (meterPhotoStatus.value == 'P') items.add('Generation Meter Photo');
    if (finalPhotoStatus.value == 'P') items.add('Final Geo-tagged Photo');
    
    final inst = installation.value;
    if (inst == null || inst.inverterBrand == null || inst.inverterBrand!.isEmpty) items.add('Inverter Brand');
    if (inst == null || inst.inverterSerial == null || inst.inverterSerial!.isEmpty) items.add('Inverter Serial Number');
    if (inst == null || inst.generationMeterNo == null || inst.generationMeterNo!.isEmpty) items.add('Generation Meter Number');
    
    return items;
  }

  bool get isAllApproved => approvedCount == totalChecklistItems;

  AdminVerificationController({required this.customer});

  @override
  void onInit() {
    super.onInit();
    _loadInstallation();
  }

  Future<void> _loadInstallation() async {
    isLoading.value = true;
    try {
      installation.value = await SupabaseService.getInstallation(customer.id);
      if (installation.value != null) {
        structurePhotoStatus.value = installation.value!.structurePhotoStatus ?? 'P';
        panelPhotoStatus.value = installation.value!.panelPhotoStatus ?? 'P';
        inverterPhotoStatus.value = installation.value!.inverterPhotoStatus ?? 'P';
        meterPhotoStatus.value = installation.value!.meterPhotoStatus ?? 'P';
        finalPhotoStatus.value = installation.value!.finalPhotoStatus ?? 'P';
        
        _addLog('Admin viewed installation details');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load installation: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void setRemark(String value) => remarkController.value = value;

  void setPhotoStatus(String type, String status) {
    switch (type) {
      case 'structure':
        structurePhotoStatus.value = status;
        _addLog(status == 'A' ? 'Admin approved Structure Photo' : 'Admin rejected Structure Photo');
        break;
      case 'panel':
        panelPhotoStatus.value = status;
        _addLog(status == 'A' ? 'Admin approved Panel Photo' : 'Admin rejected Panel Photo');
        break;
      case 'inverter':
        inverterPhotoStatus.value = status;
        _addLog(status == 'A' ? 'Admin approved Inverter Photo' : 'Admin rejected Inverter Photo');
        break;
      case 'meter':
        meterPhotoStatus.value = status;
        _addLog(status == 'A' ? 'Admin approved Meter Photo' : 'Admin rejected Meter Photo');
        break;
      case 'final':
        finalPhotoStatus.value = status;
        _addLog(status == 'A' ? 'Admin approved Final Photo' : 'Admin rejected Final Photo');
        break;
    }
  }

  Future<void> uploadVerifiedPhoto() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        verifiedPhotoBytes.value = await image.readAsBytes();
        photoName.value = image.name;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick photo: $e');
    }
  }

  void _addLog(String action) {
    final logData = {
      'customer_id': customer.id,
      'user_name': SupabaseService.currentUser?.userMetadata?['name'] ?? 'Admin',
      'user_role': 'admin',
      'action': action,
    };
    OfflineSyncService.to.enqueueLogTask(logData);
  }

  Future<void> verifyInstallation(bool isApproved) async {
    if (installation.value == null) return;
    
    isLoading.value = true;
    
    String? verifiedUrl = installation.value?.adminVerifiedPhotoUrl;
    if (verifiedPhotoBytes.value != null) {
       final url = await SupabaseService.uploadPhotoBytes(
         customer.id, 
         verifiedPhotoBytes.value!, 
         photoName.value,
         bucket: 'verified_photos'
       );
       if (url != null) verifiedUrl = url;
    }

    final updateData = {
      'id': installation.value!.id,
      'customer_id': customer.id,
      'verification_status': isApproved ? 'V' : 'R', // Verified / Rejected
      'structure_photo_status': structurePhotoStatus.value,
      'panel_photo_status': panelPhotoStatus.value,
      'inverter_photo_status': inverterPhotoStatus.value,
      'meter_photo_status': meterPhotoStatus.value,
      'final_photo_status': finalPhotoStatus.value,
      'admin_remark': remarkController.value,
      'admin_verified_photo_url': verifiedUrl,
      'verified_at': DateTime.now().toIso8601String(),
    };

    await OfflineSyncService.to.enqueueInstallationTask(
      customer.id, 
      updateData, 
      isUpdate: true,
    );

    _addLog(isApproved ? 'Admin verified installation' : 'Admin rejected installation');
    
    isLoading.value = false;
    Get.back();
    Get.snackbar('Success', isApproved ? 'Installation Approved' : 'Installation Rejected');
  }
}
