import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_strings.dart';
import '../models/customer_model.dart';
import '../models/installation_model.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import '../services/location_service.dart';
import '../services/offline_sync_service.dart';
import '../services/cache_service.dart';

class CustomerController extends GetxController {
  // Form field controllers
  final nameCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();
  final villageCtrl = TextEditingController();
  final talukaCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final solarCtrl = TextEditingController();
  final latCtrl = TextEditingController();
  final lngCtrl = TextEditingController();
  final latLngPasteCtrl = TextEditingController(); // "21.123, 74.456" paste
  final consumerNoCtrl = TextEditingController();

  // State
  final RxBool hasLocation = false.obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<CustomerModel> customers = <CustomerModel>[].obs;
  final RxMap<String, InstallationModel> installations = <String, InstallationModel>{}.obs;
  final RxList<Map<String, dynamic>> installersList = <Map<String, dynamic>>[].obs;
  final RxBool loadingList = true.obs;
  final RxString searchQuery = ''.obs;
  final RxString filterStatus = ''.obs;
  final formKey = GlobalKey<FormState>();

  // Photo
  XFile? photoXFile;
  Uint8List? photoBytes;
  final RxBool hasPhoto = false.obs;
  final RxDouble uploadProgress = 0.0.obs; // 0.0 to 1.0
  final RxString loadingStatus = ''.obs; // Status message

  CustomerModel? editingCustomer;
  XFile? importedPhoto;

  @override
  void onInit() {
    super.onInit();
    loadCustomers();
    loadInstallers();
  }

  Future<void> loadInstallers() async {
    try {
      installersList.value = await SupabaseService.getInstallerUsers();
    } catch (e) {
      debugPrint('Error loading installers: $e');
    }
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    mobileCtrl.dispose();
    villageCtrl.dispose();
    talukaCtrl.dispose();
    addressCtrl.dispose();
    solarCtrl.dispose();
    latCtrl.dispose();
    lngCtrl.dispose();
    latLngPasteCtrl.dispose();
    consumerNoCtrl.dispose();
    super.onClose();
  }

  // ─── CUSTOMERS ───────────────────────────────────────────
  Future<void> loadCustomers() async {
    loadingList.value = true;
    try {
      final online = await OfflineSyncService.checkInternetConnection();
      if (online) {
        customers.value = await SupabaseService.getCustomers();
        await CacheService.saveCustomers(customers);
        
        final customerIds = customers.map((c) => c.id).toList();
        final insts = await SupabaseService.getInstallationsForCustomers(customerIds);
        installations.clear();
        for (var inst in insts) {
          installations[inst.customerId] = inst;
        }
        await CacheService.saveInstallations(insts.map((e) => e.toJson()).toList());
      } else {
        customers.value = CacheService.getCustomers();
        final localInsts = CacheService.getAllInstallations();
        installations.clear();
        for (var item in localInsts) {
          final inst = InstallationModel.fromJson(item);
          installations[inst.customerId] = inst;
        }
      }
    } catch (e) {
      error.value = e.toString();
      customers.value = CacheService.getCustomers();
    } finally {
      loadingList.value = false;
    }
  }

  int getCompletedItemsCount(String customerId) {
    final inst = installations[customerId];
    if (inst == null) return 0;
    int count = 0;
    if (inst.structurePhotoUrl != null || inst.structurePhotoStatus == 'S') count++;
    if ((inst.panelPhotoUrls != null && inst.panelPhotoUrls!.isNotEmpty) || inst.panelPhotoStatus == 'S') count++;
    if (inst.inverterPhotoUrl != null || inst.inverterPhotoStatus == 'S') count++;
    if (inst.meterPhotoUrl != null || inst.meterPhotoStatus == 'S') count++;
    if (inst.finalPhotoUrl != null || inst.finalPhotoStatus == 'S') count++;
    return count;
  }

  List<String> getPendingItemsList(String customerId) {
    final inst = installations[customerId];
    final list = <String>[];
    if (inst == null) {
      return ['Structure Photo', 'Solar Panel Photos', 'Inverter Photo', 'Generation Meter Photo', 'Final Geo-tagged Photo'];
    }
    if (inst.structurePhotoUrl == null && inst.structurePhotoStatus != 'S') list.add('Structure Photo');
    if ((inst.panelPhotoUrls == null || inst.panelPhotoUrls!.isEmpty) && inst.panelPhotoStatus != 'S') list.add('Solar Panel Photos');
    if (inst.inverterPhotoUrl == null && inst.inverterPhotoStatus != 'S') list.add('Inverter Photo');
    if (inst.meterPhotoUrl == null && inst.meterPhotoStatus != 'S') list.add('Generation Meter Photo');
    if (inst.finalPhotoUrl == null && inst.finalPhotoStatus != 'S') list.add('Final Geo-tagged Photo');
    return list;
  }

  List<CustomerModel> get filteredCustomers {
    var list = customers.toList();
    final q = searchQuery.value.toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((c) =>
          c.name.toLowerCase().contains(q) ||
          c.mobile.contains(q) ||
          (c.village?.toLowerCase().contains(q) ?? false) ||
          (c.installer?.contains(q) ?? false)).toList();
    }
    if (filterStatus.value.isNotEmpty) {
      if (filterStatus.value == 'PendingPhotos') {
        list = list.where((c) => c.status != 'V' && c.status != 'D' && getCompletedItemsCount(c.id) < 5).toList();
      } else if (filterStatus.value == 'Completed') {
        list = list.where((c) => c.status == 'D').toList();
      } else if (filterStatus.value == 'S') {
        // Submitted means status is P but all 5 items are completed (ready for verification)
        list = list.where((c) => c.status == 'P' && getCompletedItemsCount(c.id) == 5).toList();
      } else {
        list = list.where((c) => c.status == filterStatus.value).toList();
      }
    }
    return list;
  }

  Future<void> saveCustomer() async {
    if (!formKey.currentState!.validate()) return;
    isLoading.value = true;
    error.value = '';
    uploadProgress.value = 0.0;
    loadingStatus.value = 'Saving customer details...';

    // Start a timer to simulate upload progress smoothly
    final timer = Stream.periodic(const Duration(milliseconds: 100))
        .take(90) // Simulate up to 90%
        .listen((tick) {
      if (uploadProgress.value < 0.9) {
        uploadProgress.value += 0.01;
      }
    });

    try {
      final lat = double.tryParse(latCtrl.text.trim());
      final lng = double.tryParse(lngCtrl.text.trim());

      final data = {
        'name': nameCtrl.text.trim(),
        'mobile': mobileCtrl.text.trim(),
        'village': villageCtrl.text.trim().isEmpty ? null : villageCtrl.text.trim(),
        'taluka': talukaCtrl.text.trim().isEmpty ? null : talukaCtrl.text.trim(),
        'address': addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
        'solar_kw': double.tryParse(solarCtrl.text.trim()),
        'consumer_no': consumerNoCtrl.text.trim().isEmpty ? null : consumerNoCtrl.text.trim(),
        'lat': lat,
        'lng': lng,
        'status': editingCustomer?.status ?? 'P',
      };

      final online = await OfflineSyncService.checkInternetConnection();

      if (online) {
        String? customerId;
        if (editingCustomer != null) {
          await SupabaseService.updateCustomer(editingCustomer!.id, data);
          customerId = editingCustomer!.id;
        } else {
          final added = await SupabaseService.addCustomer(data);
          customerId = added?.id;
        }

        // Upload photo if selected
        if (customerId != null && photoBytes != null && photoXFile != null) {
          loadingStatus.value = 'Uploading site photo...';
          final url = await SupabaseService.uploadPhotoBytes(
              customerId, photoBytes!, photoXFile!.name);
          if (url != null) {
            await SupabaseService.updateCustomer(customerId, {'photo_url': url});
          }
        }
      } else {
        // Offline flow
        final String customerId = editingCustomer?.id ?? const Uuid().v4();
        
        final localCustomer = CustomerModel(
          id: customerId,
          name: data['name'] as String,
          mobile: data['mobile'] as String,
          village: data['village'] as String?,
          taluka: data['taluka'] as String?,
          address: data['address'] as String?,
          solarKw: data['solar_kw'] as double?,
          consumerNo: data['consumer_no'] as String?,
          lat: data['lat'] as double?,
          lng: data['lng'] as double?,
          status: data['status'] as String,
          syncStatus: 'pending',
        );

        if (editingCustomer != null) {
          await OfflineSyncService.to.enqueueUpdateTask(customerId, data, photoBytes, photoXFile?.name);
        } else {
          await OfflineSyncService.to.enqueueCreateTask(localCustomer, photoBytes, photoXFile?.name);
        }
      }

      timer.cancel();
      uploadProgress.value = 1.0;
      loadingStatus.value = 'Complete!';

      Get.back();
      Get.snackbar(
        editingCustomer != null ? 'Updated' : 'Added',
        editingCustomer != null ? 'Customer updated' : 'Customer added successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      clearForm();
      await loadCustomers();
    } catch (e) {
      timer.cancel();
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // ─── PHOTO PICK ──────────────────────────────────────────
  Future<void> pickPhotoFromCamera() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.camera, imageQuality: 80, maxWidth: 1200);
    if (picked != null) {
      photoXFile = picked;
      photoBytes = await picked.readAsBytes();
      hasPhoto.value = true;
    }
  }

  Future<void> pickPhotoFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 1200);
    if (picked != null) {
      photoXFile = picked;
      photoBytes = await picked.readAsBytes();
      hasPhoto.value = true;
    }
  }

  // ─── LOCATION HELPERS ────────────────────────────────────
  void setLocation(double lat, double lng) {
    latCtrl.text = lat.toStringAsFixed(6);
    lngCtrl.text = lng.toStringAsFixed(6);
    hasLocation.value = true;
  }

  /// Parse "21.123, 74.456" from paste field
  void parsePastedLatLng() {
    final input = latLngPasteCtrl.text.trim();
    if (input.isEmpty) return;

    // Try lat,lng format
    final coords = LocationService.parseLatLng(input);
    if (coords != null) {
      setLocation(coords['lat']!, coords['lng']!);
      latLngPasteCtrl.clear();
      error.value = '';
      Get.snackbar('Location Set', '${AppStrings.locationSaved}',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // Try Google Maps link
    final gmCoords = LocationService.parseGoogleMapsLink(input);
    if (gmCoords != null) {
      setLocation(gmCoords['lat']!, gmCoords['lng']!);
      latLngPasteCtrl.clear();
      error.value = '';
      Get.snackbar('Location Set', AppStrings.locationSaved,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    error.value = 'Invalid format. Use: 21.12345, 74.56789';
  }

  Future<void> captureCurrentLocation() async {
    isLoading.value = true;
    final pos = await LocationService.getCurrentPosition();
    isLoading.value = false;
    if (pos != null) {
      setLocation(pos.latitude, pos.longitude);
    } else {
      error.value = 'Could not get GPS. Check permissions.';
    }
  }

  // ─── ASSIGN / STATUS ─────────────────────────────────────
  Future<void> assignInstaller(String customerId, String installerPhone) async {
    try {
      await SupabaseService.assignInstaller(customerId, installerPhone);
      await loadCustomers();
      Get.snackbar('Assigned', AppStrings.assigned, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> updateStatus(String customerId, String status) async {
    try {
      await SupabaseService.updateStatus(customerId, status);
      await loadCustomers();
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    try {
      isLoading.value = true;
      await SupabaseService.deleteCustomer(customerId);
      await loadCustomers();
      Get.snackbar('Deleted', 'Customer deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withOpacity(0.1));
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  // ─── EDIT ─────────────────────────────────────────────────
  void prepareEdit(CustomerModel customer) {
    editingCustomer = customer;
    nameCtrl.text = customer.name;
    mobileCtrl.text = customer.mobile;
    villageCtrl.text = customer.village ?? '';
    talukaCtrl.text = customer.taluka ?? '';
    addressCtrl.text = customer.address ?? '';
    solarCtrl.text = customer.solarKw?.toString() ?? '';
    consumerNoCtrl.text = customer.consumerNo ?? '';
    if (customer.hasLocation) {
      setLocation(customer.lat!, customer.lng!);
    }
  }

  void clearForm() {
    editingCustomer = null;
    nameCtrl.clear();
    mobileCtrl.clear();
    villageCtrl.clear();
    talukaCtrl.clear();
    addressCtrl.clear();
    solarCtrl.clear();
    consumerNoCtrl.clear();
    latCtrl.clear();
    lngCtrl.clear();
    latLngPasteCtrl.clear();
    hasLocation.value = false;
    importedPhoto = null;
    photoXFile = null;
    photoBytes = null;
    hasPhoto.value = false;
    uploadProgress.value = 0.0;
    loadingStatus.value = '';
    error.value = '';
  }

  // ─── WHATSAPP IMPORT ──────────────────────────────────────────
  Future<void> importFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) importedPhoto = picked;
  }
}
