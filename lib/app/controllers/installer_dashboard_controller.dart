import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/customer_model.dart';
import '../services/supabase_service.dart';
import '../services/location_service.dart';
import '../services/cache_service.dart';
import '../constants/app_constants.dart';

import '../services/offline_sync_service.dart';

import '../models/installation_model.dart';

class InstallerDashboardController extends GetxController {
  final RxList<CustomerModel> sites = <CustomerModel>[].obs;
  final RxList<InstallationModel> installations = <InstallationModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString filterStatus = ''.obs;
  final RxDouble myLat = 0.0.obs;
  final RxDouble myLng = 0.0.obs;
  final RxBool hasMyLocation = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadSites();
    _getMyLocation();
  }

  Future<void> loadSites() async {
    isLoading.value = true;
    try {
      final online = await OfflineSyncService.checkInternetConnection();
      final myEmail = SupabaseService.currentUser?.email ?? '';

      if (online) {
        final remoteSites = await SupabaseService.getCustomers(
            installerPhone: myEmail.toLowerCase());
        
        final pendingTasks = CacheService.getAllSyncTasks()
            .where((task) => task['action'] == 'create')
            .map((task) => CustomerModel.fromJson(task['customer'] as Map<String, dynamic>))
            .where((c) => c.installer?.toLowerCase() == myEmail.toLowerCase() || c.installer == null || c.installer!.isEmpty);
            
        final merged = [...pendingTasks, ...remoteSites];
        sites.value = merged;
        await CacheService.saveCustomers(merged);
        
        // Fetch installations for these customers
        final customerIds = merged.map((c) => c.id).toList();
        final remoteInstallations = await SupabaseService.getInstallationsForCustomers(customerIds);
        installations.value = remoteInstallations;
        
        final instMaps = remoteInstallations.map((i) => {
          'id': i.id,
          'customer_id': i.customerId,
          'structure_photo_url': i.structurePhotoUrl,
          'panel_photo_url': i.panelPhotoUrls,
          'inverter_photo_url': i.inverterPhotoUrl,
          'meter_photo_url': i.meterPhotoUrl,
          'final_photo_url': i.finalPhotoUrl,
          'lat': i.lat,
          'lng': i.lng,
          'inverter_brand': i.inverterBrand,
          'inverter_serial': i.inverterSerial,
          'panel_brand': i.panelBrand,
          'panel_count': i.panelCount,
          'panel_serials': i.panelSerials,
          'generation_meter_no': i.generationMeterNo,
          'structure_photo_status': i.structurePhotoStatus,
          'panel_photo_status': i.panelPhotoStatus,
          'inverter_photo_status': i.inverterPhotoStatus,
          'meter_photo_status': i.meterPhotoStatus,
          'final_photo_status': i.finalPhotoStatus,
          'verification_status': i.verificationStatus,
          'admin_verified_photo_url': i.adminVerifiedPhotoUrl,
          'admin_remark': i.adminRemark,
          'submitted_at': i.submittedAt?.toIso8601String(),
          'verified_at': i.verifiedAt?.toIso8601String(),
        }).toList();
        await CacheService.saveInstallations(instMaps);
        
      } else {
        final cached = CacheService.getCustomers();
        sites.value =
            cached.where((c) => c.installer?.toLowerCase() == myEmail.toLowerCase()).toList();
        
        final cachedInstMaps = CacheService.getAllInstallations();
        installations.value = cachedInstMaps.map((map) => InstallationModel.fromJson(map)).toList();
      }
    } catch (e) {
      final cached = CacheService.getCustomers();
      final myEmail = SupabaseService.currentUser?.email ?? '';
      sites.value =
          cached.where((c) => c.installer?.toLowerCase() == myEmail.toLowerCase()).toList();
          
      final cachedInstMaps = CacheService.getAllInstallations();
      installations.value = cachedInstMaps.map((map) => InstallationModel.fromJson(map)).toList();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _getMyLocation() async {
    final pos = await LocationService.getCurrentPosition();
    if (pos != null) {
      myLat.value = pos.latitude;
      myLng.value = pos.longitude;
      hasMyLocation.value = true;
    }
  }

  List<CustomerModel> get filteredSites {
    if (filterStatus.value.isEmpty) return sites.toList();
    return sites.where((c) => c.status == filterStatus.value).toList();
  }

  String distanceTo(CustomerModel customer) {
    if (!hasMyLocation.value ||
        customer.lat == null ||
        customer.lng == null) {
      return '--';
    }
    final km = LocationService.distanceKm(
      myLat.value,
      myLng.value,
      customer.lat!,
      customer.lng!,
    );
    return km < 1
        ? '${(km * 1000).toStringAsFixed(0)} m'
        : '${km.toStringAsFixed(1)} km';
  }

  /// Open navigation — tries OSM first (free), with Google Maps as fallback
  Future<void> openNavigation(CustomerModel customer) async {
    await LocationService.openNavigation(customer.lat!, customer.lng!);
  }

  int get totalInstallationsCount => sites.length;
  
  int get pendingCount => totalInstallationsCount - submittedCount - approvedCount - rejectedCount;

  int get submittedCount => installations.where((i) => i.verificationStatus == 'S').length;
      
  int get approvedCount => installations.where((i) => i.verificationStatus == 'A' || i.verificationStatus == 'V').length;
      
  int get rejectedCount => installations.where((i) => i.verificationStatus == 'R').length;
}
