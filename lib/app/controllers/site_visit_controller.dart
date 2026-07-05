import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../models/customer_model.dart';
import '../services/supabase_service.dart';
import '../services/location_service.dart';
import '../services/offline_sync_service.dart';

class SiteVisitController extends GetxController {
  CustomerModel? customer;
  final RxBool isLoading = false.obs;
  final RxString selectedStatus = 'P'.obs;
  final RxDouble capturedLat = 0.0.obs;
  final RxDouble capturedLng = 0.0.obs;
  final RxBool hasGps = false.obs;
  final RxString capturedAddress = ''.obs;
  XFile? photoXFile;
  Uint8List? photoBytes;
  final RxBool hasPhoto = false.obs;
  final RxBool photoUploaded = false.obs;
  final RxString error = ''.obs;
  final RxDouble uploadProgress = 0.0.obs; // 0.0 to 1.0
  final RxString loadingStatus = ''.obs; // Status message

  void init(CustomerModel c) {
    customer = c;
    selectedStatus.value = c.status;
    if (c.hasLocation) {
      capturedLat.value = c.lat!;
      capturedLng.value = c.lng!;
      hasGps.value = true;
    }
  }

  // ─── GPS CAPTURE ─────────────────────────────────────────
  Future<void> captureGps() async {
    isLoading.value = true;
    final pos = await LocationService.getCurrentPosition();
    isLoading.value = false;

    if (pos != null) {
      capturedLat.value = pos.latitude;
      capturedLng.value = pos.longitude;
      hasGps.value = true;
      capturedAddress.value = '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      Get.snackbar('GPS Captured', 'Location captured successfully',
          snackPosition: SnackPosition.BOTTOM);
    } else {
      error.value = 'Location unavailable. Check GPS & permissions.';
    }
  }

  // ─── PHOTO ───────────────────────────────────────────────
  Future<void> takePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked != null) {
      photoXFile = picked;
      photoBytes = await picked.readAsBytes();
      hasPhoto.value = true;
    }
  }

  Future<void> pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked != null) {
      photoXFile = picked;
      photoBytes = await picked.readAsBytes();
      hasPhoto.value = true;
    }
  }

  // ─── SAVE VISIT ──────────────────────────────────────────
  Future<void> saveVisit() async {
    if (customer == null) return;
    isLoading.value = true;
    error.value = '';
    uploadProgress.value = 0.0;
    loadingStatus.value = 'Preparing...';

    // Start a timer to simulate upload progress smoothly
    final timer = Stream.periodic(const Duration(milliseconds: 100))
        .take(90) // Simulate up to 90%
        .listen((tick) {
      if (uploadProgress.value < 0.9) {
        uploadProgress.value += 0.01;
      }
    });

    try {
      final online = await OfflineSyncService.checkInternetConnection();
      final updateData = <String, dynamic>{
        'status': selectedStatus.value,
        if (hasGps.value) 'lat': capturedLat.value,
        if (hasGps.value) 'lng': capturedLng.value,
      };

      if (online) {
        String? uploadedUrl;
        if (photoXFile != null && photoBytes != null) {
          loadingStatus.value = 'Uploading photo...';
          uploadedUrl = await SupabaseService.uploadPhotoBytes(
              customer!.id, photoBytes!, photoXFile!.name);
          if (uploadedUrl != null) photoUploaded.value = true;
        }

        if (uploadedUrl != null) {
          updateData['photo_url'] = uploadedUrl;
        }

        loadingStatus.value = 'Saving visit info & GPS...';
        await SupabaseService.updateCustomer(customer!.id, updateData);
      } else {
        loadingStatus.value = 'Saving visit locally...';
        await OfflineSyncService.to.enqueueUpdateTask(
          customer!.id,
          updateData,
          photoBytes,
          photoXFile?.name,
        );
      }

      timer.cancel();
      uploadProgress.value = 1.0;
      loadingStatus.value = 'Complete!';

      Get.back(result: true);
      Get.snackbar(
        'Saved!',
        online ? 'Site visit saved successfully' : 'Site visit saved locally (offline)',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      timer.cancel();
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
