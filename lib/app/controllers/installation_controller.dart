import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../models/customer_model.dart';
import '../services/watermark_service.dart';
import '../services/offline_sync_service.dart';
import '../services/supabase_service.dart';
import '../services/cache_service.dart';

class InstallationController extends GetxController {
  final CustomerModel customer;

  InstallationController({required this.customer});

  @override
  void onInit() {
    super.onInit();
    _loadDraft();
  }
  final Rx<Map<String, dynamic>?> draftData = Rx<Map<String, dynamic>?>(null);

  void _loadDraft() {
    final draft = CacheService.getInstallation(customer.id);
    if (draft != null) {
      draftData.value = draft;
      inverterBrandController.value = draft['inverter_brand'] ?? '';
      inverterSerialController.value = draft['inverter_serial'] ?? '';
      panelBrandController.value = draft['panel_brand'] ?? '';
      if (draft['panel_count'] != null) {
        panelCountController.value = draft['panel_count'].toString();
      }
      if (draft['panel_serials'] != null) {
        panelSerials.value = List<String>.from(draft['panel_serials']);
      }
      meterNumberController.value = draft['generation_meter_no'] ?? '';
      
      // Photos from draft are URL only. Local drafts might need bytes caching which is complex, 
      // so for now we just load text fields.
    }
  }

  final Rx<Uint8List?> structurePhotoBytes = Rx<Uint8List?>(null);
  final RxString structurePhotoName = ''.obs;

  final Rx<Uint8List?> panelPhotoBytes = Rx<Uint8List?>(null);
  final RxString panelPhotoName = ''.obs;

  final Rx<Uint8List?> inverterPhotoBytes = Rx<Uint8List?>(null);
  final RxString inverterPhotoName = ''.obs;

  final Rx<Uint8List?> meterPhotoBytes = Rx<Uint8List?>(null);
  final RxString meterPhotoName = ''.obs;

  final Rx<Uint8List?> finalPhotoBytes = Rx<Uint8List?>(null);
  final RxString finalPhotoName = ''.obs;

  final inverterBrandController = ''.obs;
  final inverterSerialController = ''.obs;
  final panelBrandController = ''.obs;
  final panelCountController = ''.obs;
  final meterNumberController = ''.obs;
  
  final panelSerials = <String>[].obs;
  
  final RxBool isSubmitting = false.obs;
  
  void setInverterBrand(String value) => inverterBrandController.value = value;
  void setInverterSerial(String value) => inverterSerialController.value = value;
  void setPanelBrand(String value) => panelBrandController.value = value;
  void setPanelCount(String value) {
    panelCountController.value = value;
    final count = int.tryParse(value) ?? 0;
    
    // Adjust panelSerials list to match count
    if (panelSerials.length < count) {
      panelSerials.addAll(List.generate(count - panelSerials.length, (_) => ''));
    } else if (panelSerials.length > count) {
      panelSerials.removeRange(count, panelSerials.length);
    }
  }
  
  void updatePanelSerial(int index, String serial) {
    if (index >= 0 && index < panelSerials.length) {
      panelSerials[index] = serial;
    }
  }
  
  void setMeterNumber(String value) => meterNumberController.value = value;
  
  // Manual add/remove logic is no longer needed since it's dynamic
  int get completedItemsCount {
    int count = 0;
    if (structurePhotoBytes.value != null || draftData.value?['structure_photo_url'] != null || draftData.value?['structure_photo_status'] == 'S') count++;
    if (panelPhotoBytes.value != null || draftData.value?['panel_photo_url'] != null || draftData.value?['panel_photo_status'] == 'S') count++;
    if (inverterPhotoBytes.value != null || draftData.value?['inverter_photo_url'] != null || draftData.value?['inverter_photo_status'] == 'S') count++;
    if (meterPhotoBytes.value != null || draftData.value?['meter_photo_url'] != null || draftData.value?['meter_photo_status'] == 'S') count++;
    if (finalPhotoBytes.value != null || draftData.value?['final_photo_url'] != null || draftData.value?['final_photo_status'] == 'S') count++;
    return count;
  }

  List<String> get pendingItemsList {
    final list = <String>[];
    if (structurePhotoBytes.value == null && draftData.value?['structure_photo_url'] == null && draftData.value?['structure_photo_status'] != 'S') list.add('Structure Photo');
    if (panelPhotoBytes.value == null && draftData.value?['panel_photo_url'] == null && draftData.value?['panel_photo_status'] != 'S') list.add('Solar Panel Photos');
    if (inverterPhotoBytes.value == null && draftData.value?['inverter_photo_url'] == null && draftData.value?['inverter_photo_status'] != 'S') list.add('Inverter Photo');
    if (meterPhotoBytes.value == null && draftData.value?['meter_photo_url'] == null && draftData.value?['meter_photo_status'] != 'S') list.add('Generation Meter Photo');
    if (finalPhotoBytes.value == null && draftData.value?['final_photo_url'] == null && draftData.value?['final_photo_status'] != 'S') list.add('Final Geo-tagged Photo');
    return list;
  }


  Future<void> capturePhoto(String type) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        
        if (type == 'final') {
          // Final photo needs GPS and watermark
          final watermarkedBytes = await WatermarkService.addWatermark(
            imageBytes: bytes,
            customerName: customer.name,
            lat: customer.lat,
            lng: customer.lng,
          );
          
          if (watermarkedBytes != null) {
            finalPhotoBytes.value = watermarkedBytes;
            finalPhotoName.value = image.name;
            _addLog('Final geo-tagged photo uploaded');
          }
        } else {
          // Other photos do not get watermarks or GPS checks
          switch (type) {
            case 'structure':
              structurePhotoBytes.value = bytes;
              structurePhotoName.value = image.name;
              _addLog('Structure photo uploaded');
              break;
            case 'panel':
              panelPhotoBytes.value = bytes;
              panelPhotoName.value = image.name;
              _addLog('Panel photo uploaded');
              break;
            case 'inverter':
              inverterPhotoBytes.value = bytes;
              inverterPhotoName.value = image.name;
              _addLog('Inverter photo uploaded');
              break;
            case 'meter':
              meterPhotoBytes.value = bytes;
              meterPhotoName.value = image.name;
              _addLog('Meter photo uploaded');
              break;
          }
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to capture photo: $e');
    }
  }

  void _addLog(String action) {
    final logData = {
      'customer_id': customer.id,
      'user_name': SupabaseService.currentUser?.userMetadata?['name'] ?? 'Installer',
      'user_role': 'installer',
      'action': action,
    };
    OfflineSyncService.to.enqueueLogTask(logData);
  }

  void logSiteOpened() {
    _addLog('Installer opened site');
  }

  void logSerialsAdded() {
    if (inverterSerialController.value.isNotEmpty || inverterBrandController.value.isNotEmpty) _addLog('Inverter details saved');
    if (panelSerials.isNotEmpty || panelBrandController.value.isNotEmpty) _addLog('Solar panel details saved');
    if (meterNumberController.value.isNotEmpty) _addLog('Generation meter number saved');
  }

  Future<void> saveProgress() async {
    isSubmitting.value = true;
    
    try {
      logSerialsAdded();

      final int? parsedPanelCount = int.tryParse(panelCountController.value);

      final installationData = {
        'customer_id': customer.id,
        'lat': customer.lat,
        'lng': customer.lng,
        'inverter_brand': inverterBrandController.value,
        'inverter_serial': inverterSerialController.value,
        'panel_brand': panelBrandController.value,
        'panel_count': parsedPanelCount,
        'panel_serials': panelSerials.toList(),
        'generation_meter_no': meterNumberController.value,
        'verification_status': 'IP', // In Progress
        'structure_photo_status': structurePhotoBytes.value != null ? 'S' : (draftData.value?['structure_photo_status'] ?? 'P'),
        'panel_photo_status': panelPhotoBytes.value != null ? 'S' : (draftData.value?['panel_photo_status'] ?? 'P'),
        'inverter_photo_status': inverterPhotoBytes.value != null ? 'S' : (draftData.value?['inverter_photo_status'] ?? 'P'),
        'meter_photo_status': meterPhotoBytes.value != null ? 'S' : (draftData.value?['meter_photo_status'] ?? 'P'),
        'final_photo_status': finalPhotoBytes.value != null ? 'S' : (draftData.value?['final_photo_status'] ?? 'P'),
        'submitted_at': DateTime.now().toIso8601String(),
      };

      await OfflineSyncService.to.enqueueInstallationTask(
        customer.id, 
        installationData, 
        structurePhotoBytes: structurePhotoBytes.value,
        structurePhotoName: structurePhotoName.value.isNotEmpty ? structurePhotoName.value : null,
        panelPhotoBytes: panelPhotoBytes.value,
        panelPhotoName: panelPhotoName.value.isNotEmpty ? panelPhotoName.value : null,
        inverterPhotoBytes: inverterPhotoBytes.value,
        inverterPhotoName: inverterPhotoName.value.isNotEmpty ? inverterPhotoName.value : null,
        meterPhotoBytes: meterPhotoBytes.value,
        meterPhotoName: meterPhotoName.value.isNotEmpty ? meterPhotoName.value : null,
        finalPhotoBytes: finalPhotoBytes.value,
        finalPhotoName: finalPhotoName.value.isNotEmpty ? finalPhotoName.value : null,
      );
      
      // Update customer status to In Progress (if not already completed)
      await OfflineSyncService.to.enqueueUpdateTask(
         customer.id,
         {'status': 'IP'}, 
         null, null
      );

      _addLog('Installation progress saved locally');
      
      Get.back();
      Get.snackbar('Success', 'Progress saved successfully');
    } catch (e) {
      debugPrint('Save Error: $e');
      Get.snackbar('Error', 'Failed to save progress: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> submitInstallation() async {
    if (completedItemsCount < 5) {
      Get.snackbar('Validation', 'Please complete all 5 required items before submitting.');
      return;
    }
    
    isSubmitting.value = true;
    
    try {
      logSerialsAdded();

      final int? parsedPanelCount = int.tryParse(panelCountController.value);

      final installationData = {
        'customer_id': customer.id,
        'lat': customer.lat,
        'lng': customer.lng,
        'inverter_brand': inverterBrandController.value,
        'inverter_serial': inverterSerialController.value,
        'panel_brand': panelBrandController.value,
        'panel_count': parsedPanelCount,
        'panel_serials': panelSerials.toList(),
        'generation_meter_no': meterNumberController.value,
        'verification_status': 'S', // Submitted
        'structure_photo_status': 'S',
        'panel_photo_status': 'S',
        'inverter_photo_status': 'S',
        'meter_photo_status': 'S',
        'final_photo_status': 'S',
        'submitted_at': DateTime.now().toIso8601String(),
      };

      await OfflineSyncService.to.enqueueInstallationTask(
        customer.id, 
        installationData, 
        structurePhotoBytes: structurePhotoBytes.value,
        structurePhotoName: structurePhotoName.value.isNotEmpty ? structurePhotoName.value : null,
        panelPhotoBytes: panelPhotoBytes.value,
        panelPhotoName: panelPhotoName.value.isNotEmpty ? panelPhotoName.value : null,
        inverterPhotoBytes: inverterPhotoBytes.value,
        inverterPhotoName: inverterPhotoName.value.isNotEmpty ? inverterPhotoName.value : null,
        meterPhotoBytes: meterPhotoBytes.value,
        meterPhotoName: meterPhotoName.value.isNotEmpty ? meterPhotoName.value : null,
        finalPhotoBytes: finalPhotoBytes.value,
        finalPhotoName: finalPhotoName.value.isNotEmpty ? finalPhotoName.value : null,
      );
      
      // Update customer status to Ready for Verification (P)
      await OfflineSyncService.to.enqueueUpdateTask(
         customer.id,
         {'status': 'P'}, 
         null, null
      );

      _addLog('Installation submitted for verification');
      
      Get.back();
      Get.snackbar('Success', 'Installation submitted successfully');
    } catch (e) {
      debugPrint('Submission Error: $e');
      Get.snackbar('Error', 'Failed to submit: $e');
    } finally {
      isSubmitting.value = false;
    }
}
}
