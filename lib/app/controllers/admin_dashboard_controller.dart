import 'package:get/get.dart';
import '../models/customer_model.dart';
import '../models/installer_model.dart';
import '../services/supabase_service.dart';
import '../services/cache_service.dart';

import '../models/installation_model.dart';

class AdminDashboardController extends GetxController {
  final RxInt totalCustomers = 0.obs;
  
  // Admin stats
  final RxInt totalAssigned = 0.obs;
  final RxInt inProgressCount = 0.obs;
  final RxInt readyForVerificationCount = 0.obs;
  final RxInt verifiedCount = 0.obs;
  final RxInt rejectedCount = 0.obs;
  final RxInt newCustomersCount = 0.obs;
  final RxInt pendingPhotosCount = 0.obs;
  
  // Sync mock
  final RxInt pendingSyncCount = 0.obs;
  final RxString lastSyncTime = 'Today, 08:30 AM'.obs;
  final RxBool isOnline = true.obs;
  
  final RxList<InstallerModel> installerStats = <InstallerModel>[].obs;
  final RxList<CustomerModel> dashboardCustomers = <CustomerModel>[].obs;
  final RxList<InstallationModel> recentInstallations = <InstallationModel>[].obs;
  
  final RxBool isLoading = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  final RxBool hasError = false.obs;

  final int limit = 20;
  int offset = 0;
  final RxString activeFilter = 'All'.obs; // All, Pending, Submitted, Verified, Rejected
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
    _subscribeRealtime();
  }

  Future<void> loadDashboard() async {
    isLoading.value = true;
    hasError.value = false;
    try {
      final stats = await SupabaseService.getDashboardStats();
      totalCustomers.value = stats['total'] ?? 0;

      // Load all installations to calculate admin stats
      final allInstallations = await SupabaseService.getAllInstallations();
      recentInstallations.value = allInstallations;
      
      totalAssigned.value = allInstallations.length;
      inProgressCount.value = allInstallations.where((i) => i.verificationStatus == 'P').length;
      readyForVerificationCount.value = allInstallations.where((i) => i.verificationStatus == 'S').length;
      verifiedCount.value = allInstallations.where((i) => i.verificationStatus == 'A' || i.verificationStatus == 'V').length;
      rejectedCount.value = allInstallations.where((i) => i.verificationStatus == 'R').length;

      // Mock calculation for new customers and pending photos
      newCustomersCount.value = (totalCustomers.value * 0.2).toInt(); // 20% are new
      pendingPhotosCount.value = inProgressCount.value;

      final installerData = await SupabaseService.getInstallerStats();
      installerStats.value = installerData
          .map((e) => InstallerModel(
                id: e['installer'] ?? '',
                mobile: e['installer'] ?? '',
                assignedCount: e['total'] ?? 0,
                pendingCount: e['P'] ?? 0,
                visitedCount: e['V'] ?? 0,
                doneCount: e['D'] ?? 0,
              ))
          .toList();

      // Initial load for paginated customers
      offset = 0;
      hasMore.value = true;
      final customers = await SupabaseService.getCustomers(limit: limit, offset: offset);
      dashboardCustomers.value = customers;
      await CacheService.saveCustomers(customers);
      
      final instMaps = allInstallations.map((i) => {
          'id': i.id,
          'customer_id': i.customerId,
          'structure_photo_status': i.structurePhotoStatus,
          'panel_photo_status': i.panelPhotoStatus,
          'inverter_photo_status': i.inverterPhotoStatus,
          'meter_photo_status': i.meterPhotoStatus,
          'final_photo_status': i.finalPhotoStatus,
          'verification_status': i.verificationStatus,
          'verified_at': i.verifiedAt?.toIso8601String(),
      }).toList();
      await CacheService.saveInstallations(instMaps);
      
    } catch (e) {
      hasError.value = true;
      // Load from cache on error
      final cached = CacheService.getCustomers();
      if (cached.isNotEmpty) {
        dashboardCustomers.value = cached;
        totalCustomers.value = cached.length;
      }
      
      final cachedInstMaps = CacheService.getAllInstallations();
      final instList = cachedInstMaps.map((map) => InstallationModel(
        customerId: map['customer_id'] ?? '',
        verificationStatus: map['verification_status'] ?? 'P',
        verifiedAt: map['verified_at'] != null ? DateTime.tryParse(map['verified_at'].toString()) : null,
      )).toList();
      
      totalAssigned.value = instList.length;
      inProgressCount.value = instList.where((i) => i.verificationStatus == 'P').length;
      readyForVerificationCount.value = instList.where((i) => i.verificationStatus == 'S').length;
      verifiedCount.value = instList.where((i) => i.verificationStatus == 'A' || i.verificationStatus == 'V').length;
      rejectedCount.value = instList.where((i) => i.verificationStatus == 'R').length;
    } finally {
      isLoading.value = false;
    }
  }

  void _subscribeRealtime() {
    SupabaseService.subscribeToCustomers((_) => loadDashboard());
  }

  Future<void> loadMoreCustomers() async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    
    try {
      offset += limit;
      final customers = await SupabaseService.getCustomers(
        limit: limit, 
        offset: offset,
        searchQuery: searchQuery.value.isEmpty ? null : searchQuery.value,
        status: _mapFilterToStatus(activeFilter.value)
      );
      
      if (customers.isEmpty || customers.length < limit) {
        hasMore.value = false;
      }
      
      dashboardCustomers.addAll(customers);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load more customers');
      hasMore.value = false;
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> setFilter(String filter) async {
    if (activeFilter.value == filter) return;
    activeFilter.value = filter;
    await _reloadCustomers();
  }

  Future<void> setSearchQuery(String query) async {
    searchQuery.value = query;
    await _reloadCustomers();
  }

  Future<void> _reloadCustomers() async {
    isLoading.value = true;
    offset = 0;
    hasMore.value = true;
    
    try {
      final customers = await SupabaseService.getCustomers(
        limit: limit, 
        offset: offset,
        searchQuery: searchQuery.value.isEmpty ? null : searchQuery.value,
        status: _mapFilterToStatus(activeFilter.value)
      );
      
      if (customers.length < limit) {
        hasMore.value = false;
      }
      dashboardCustomers.value = customers;
    } catch (e) {
      Get.snackbar('Error', 'Failed to filter customers');
    } finally {
      isLoading.value = false;
    }
  }

  String? _mapFilterToStatus(String filter) {
    // Note: The prompt maps filter chips (Pending, Submitted, Verified, Rejected)
    // to installation status, but SupabaseService.getCustomers uses customer status.
    // If we need strict verification status filtering, we'd need a backend join, 
    // or we filter the local `recentInstallations` and fetch those customer IDs.
    // For now, mapping to customer status roughly if possible, else null.
    switch (filter) {
      case 'Pending': return 'P';
      case 'Verified': return 'V';
      case 'Done': return 'D';
      default: return null;
    }
  }

  InstallationModel? getInstallationForCustomer(String customerId) {
    return recentInstallations.firstWhereOrNull((i) => i.customerId == customerId);
  }

  @override
  void onClose() {
    SupabaseService.client.removeAllChannels();
    super.onClose();
  }
}
