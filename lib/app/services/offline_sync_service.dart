import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../models/customer_model.dart';
import '../constants/app_constants.dart';
import 'cache_service.dart';
import 'supabase_service.dart';

class OfflineSyncService extends GetxService {
  static OfflineSyncService get to => Get.find();

  final RxBool isOnline = true.obs;
  final RxBool isSyncing = false.obs;
  final RxDouble syncProgress = 0.0.obs;
  final RxInt pendingCount = 0.obs;

  Timer? _connectivityTimer;

  @override
  void onInit() {
    super.onInit();
    updatePendingCount();
    // Periodically check connectivity and attempt auto sync
    _checkStatusAndAutoSync();
    _connectivityTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _checkStatusAndAutoSync();
    });
  }

  @override
  void onClose() {
    _connectivityTimer?.cancel();
    super.onClose();
  }

  void updatePendingCount() {
    pendingCount.value = CacheService.getAllSyncTasks().length;
  }

  Future<void> _checkStatusAndAutoSync() async {
    final online = await checkInternetConnection();
    isOnline.value = online;
    if (online && !isSyncing.value && pendingCount.value > 0) {
      syncPendingData();
    }
  }

  static Future<bool> checkInternetConnection() async {
    if (kIsWeb) return true; // Web assumes online or relies on browser
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ─── LOCAL PHOTO SAVING ──────────────────────────────────
  Future<String?> savePhotoLocally(String customerId, Uint8List bytes, String filename) async {
    if (kIsWeb) return null; // Web doesn't support dart:io File
    
    final directory = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${directory.path}/offline_photos');
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    final ext = filename.split('.').last.toLowerCase();
    final uniqueName = '${customerId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final file = File('${photosDir.path}/$uniqueName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  // ─── ADD TO SYNC QUEUE ────────────────────────────────────
  Future<void> enqueueCreateTask(CustomerModel customer, Uint8List? photoBytes, String? photoName) async {
    String? localPath;
    if (photoBytes != null && photoName != null) {
      localPath = await savePhotoLocally(customer.id, photoBytes, photoName);
    }

    final taskCustomer = customer.copyWith(
      syncStatus: 'pending',
      localPhotoPath: localPath,
    );

    final task = {
      'id': customer.id,
      'action': 'create',
      'customer': taskCustomer.toJson(),
      'photo_name': photoName,
      'error': null,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await CacheService.saveSyncTask(customer.id, task);
    
    // Also save in local customer list cache
    final localList = CacheService.getCustomers();
    localList.removeWhere((c) => c.id == customer.id || c.mobile == customer.mobile);
    localList.insert(0, taskCustomer);
    await CacheService.saveCustomers(localList);

    updatePendingCount();
    _checkStatusAndAutoSync();
  }

  Future<void> enqueueUpdateTask(String customerId, Map<String, dynamic> updateData, Uint8List? photoBytes, String? photoName) async {
    String? localPath;
    if (photoBytes != null && photoName != null) {
      localPath = await savePhotoLocally(customerId, photoBytes, photoName);
    }

    final task = {
      'id': customerId,
      'action': 'update',
      'update_data': updateData,
      'local_photo_path': localPath,
      'photo_name': photoName,
      'error': null,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Store sync task in queue
    await CacheService.saveSyncTask(customerId, task);

    // Update customer in local cache immediately
    final localList = CacheService.getCustomers();
    final idx = localList.indexWhere((c) => c.id == customerId);
    if (idx != -1) {
      var updated = localList[idx].copyWith(
        status: updateData['status'] ?? localList[idx].status,
        lat: updateData['lat'] ?? localList[idx].lat,
        lng: updateData['lng'] ?? localList[idx].lng,
        syncStatus: 'pending',
        localPhotoPath: localPath ?? localList[idx].localPhotoPath,
      );
      localList[idx] = updated;
      await CacheService.saveCustomers(localList);
    }

    updatePendingCount();
    _checkStatusAndAutoSync();
  }

  // ─── INSTALLATIONS & LOGS ────────────────────────────────
  Future<void> enqueueInstallationTask(
    String customerId, 
    Map<String, dynamic> installationData, 
    {
      Uint8List? structurePhotoBytes, String? structurePhotoName,
      Uint8List? panelPhotoBytes, String? panelPhotoName,
      Uint8List? inverterPhotoBytes, String? inverterPhotoName,
      Uint8List? meterPhotoBytes, String? meterPhotoName,
      Uint8List? finalPhotoBytes, String? finalPhotoName,
      bool isUpdate = false,
    }
  ) async {
    
    Future<Map<String, String?>> processPhoto(Uint8List? bytes, String? name) async {
      if (bytes == null || name == null) return {'local': null, 'web': null};
      if (kIsWeb) return {'local': null, 'web': base64Encode(bytes)};
      return {'local': await savePhotoLocally(customerId, bytes, name), 'web': null};
    }

    final structure = await processPhoto(structurePhotoBytes, structurePhotoName);
    final panel = await processPhoto(panelPhotoBytes, panelPhotoName);
    final inverter = await processPhoto(inverterPhotoBytes, inverterPhotoName);
    final meter = await processPhoto(meterPhotoBytes, meterPhotoName);
    final finalP = await processPhoto(finalPhotoBytes, finalPhotoName);

    final taskId = 'inst_${customerId}_${DateTime.now().millisecondsSinceEpoch}';
    final task = {
      'id': taskId,
      'customer_id': customerId,
      'action': isUpdate ? 'update_installation' : 'create_installation',
      'installation_data': installationData,
      'photos': {
        'structure': {'local': structure['local'], 'web': structure['web'], 'name': structurePhotoName},
        'panel': {'local': panel['local'], 'web': panel['web'], 'name': panelPhotoName},
        'inverter': {'local': inverter['local'], 'web': inverter['web'], 'name': inverterPhotoName},
        'meter': {'local': meter['local'], 'web': meter['web'], 'name': meterPhotoName},
        'final': {'local': finalP['local'], 'web': finalP['web'], 'name': finalPhotoName},
      },
      'error': null,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await CacheService.saveSyncTask(taskId, task);
    
    // Save locally
    if (structure['local'] != null) installationData['local_structure_photo_path'] = structure['local'];
    if (panel['local'] != null) installationData['local_panel_photo_path'] = panel['local'];
    if (inverter['local'] != null) installationData['local_inverter_photo_path'] = inverter['local'];
    if (meter['local'] != null) installationData['local_meter_photo_path'] = meter['local'];
    if (finalP['local'] != null) installationData['local_final_photo_path'] = finalP['local'];
    
    installationData['sync_status'] = 'pending';
    await CacheService.saveInstallation(customerId, installationData);

    updatePendingCount();
    _checkStatusAndAutoSync();
  }

  Future<void> enqueueLogTask(Map<String, dynamic> logData) async {
    final taskId = 'log_${DateTime.now().millisecondsSinceEpoch}';
    final task = {
      'id': taskId,
      'action': 'add_log',
      'log_data': logData,
      'error': null,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await CacheService.saveSyncTask(taskId, task);

    // Save locally
    logData['sync_status'] = 'pending';
    logData['offline_id'] = taskId;
    await CacheService.addLog(logData['customer_id'], logData);

    updatePendingCount();
    _checkStatusAndAutoSync();
  }

  // ─── SYNC PROCESSING ─────────────────────────────────────
  Future<void> syncPendingData() async {
    if (isSyncing.value) return;
    isSyncing.value = true;
    syncProgress.value = 0.0;

    final tasks = CacheService.getAllSyncTasks();
    if (tasks.isEmpty) {
      isSyncing.value = false;
      return;
    }

    double progressStep = 1.0 / tasks.length;

    for (final task in tasks) {
      final String taskId = task['id'];
      final String action = task['action'];
      
      try {
        if (action == 'create') {
          var customer = CustomerModel.fromJson(task['customer'] as Map<String, dynamic>);
          String? photoUrl = customer.photoUrl;

          // 1. Upload photo if present locally
          if (customer.localPhotoPath != null) {
            final file = File(customer.localPhotoPath!);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              final url = await SupabaseService.uploadPhotoBytes(
                customer.id,
                bytes,
                task['photo_name'] ?? 'photo.jpg',
              );
              if (url != null) {
                photoUrl = url;
              }
            }
          }

          // Prepare final customer object
          final finalCustomer = customer.copyWith(photoUrl: photoUrl);
          final insertData = finalCustomer.toInsertJson();

          // 2. Conflict Handling: check by mobile
          final existing = await SupabaseService.client
              .from(AppConstants.customersTable)
              .select()
              .eq('mobile', finalCustomer.mobile);

          if ((existing as List).isNotEmpty) {
            // Update existing
            final existingId = existing[0]['id'] as String;
            await SupabaseService.updateCustomer(existingId, insertData);
          } else {
            // Insert new
            await SupabaseService.addCustomer(insertData);
          }

        } else if (action == 'update') {
          final updateData = Map<String, dynamic>.from(task['update_data']);
          final String? localPhotoPath = task['local_photo_path'];

          // 1. Upload photo if present locally
          if (localPhotoPath != null) {
            final file = File(localPhotoPath);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              final url = await SupabaseService.uploadPhotoBytes(
                taskId,
                bytes,
                task['photo_name'] ?? 'photo.jpg',
              );
              if (url != null) {
                updateData['photo_url'] = url;
              }
            }
          }

          // 2. Perform DB update
          await SupabaseService.updateCustomer(taskId, updateData);
        } else if (action == 'create_installation' || action == 'update_installation') {
          final installationData = Map<String, dynamic>.from(task['installation_data']);
          final String customerId = task['customer_id'];
          final photos = task['photos'] as Map<String, dynamic>? ?? {};

          Future<String?> uploadPhoto(String key, String fallbackName, String bucket) async {
            final p = photos[key] as Map<String, dynamic>?;
            if (p == null) return null;

            Uint8List? bytes;
            if (p['web'] != null) {
              bytes = base64Decode(p['web']);
            } else if (p['local'] != null) {
              final file = File(p['local']);
              if (await file.exists()) bytes = await file.readAsBytes();
            }

            if (bytes != null) {
              return await SupabaseService.uploadPhotoBytes(
                customerId,
                bytes,
                p['name'] ?? fallbackName,
                bucket: bucket,
              );
            }
            return null;
          }

          final structureUrl = await uploadPhoto('structure', 'structure.jpg', AppConstants.installationPhotosBucket);
          if (structureUrl != null) installationData['structure_photo_url'] = structureUrl;

          final panelUrl = await uploadPhoto('panel', 'panel.jpg', AppConstants.installationPhotosBucket);
          if (panelUrl != null) installationData['panel_photo_url'] = panelUrl;

          final inverterUrl = await uploadPhoto('inverter', 'inverter.jpg', AppConstants.installationPhotosBucket);
          if (inverterUrl != null) installationData['inverter_photo_url'] = inverterUrl;

          final meterUrl = await uploadPhoto('meter', 'meter.jpg', AppConstants.installationPhotosBucket);
          if (meterUrl != null) installationData['meter_photo_url'] = meterUrl;

          final finalUrl = await uploadPhoto('final', 'final.jpg', AppConstants.installationPhotosBucket);
          if (finalUrl != null) installationData['final_photo_url'] = finalUrl;

          installationData.remove('local_structure_photo_path');
          installationData.remove('local_panel_photo_path');
          installationData.remove('local_inverter_photo_path');
          installationData.remove('local_meter_photo_path');
          installationData.remove('local_final_photo_path');
          installationData.remove('sync_status');

          await SupabaseService.upsertInstallation(installationData);
          
          final localInst = CacheService.getInstallation(customerId);
          if (localInst != null) {
             localInst['sync_status'] = 'synced';
             await CacheService.saveInstallation(customerId, localInst);
          }
        } else if (action == 'add_log') {
          final logData = Map<String, dynamic>.from(task['log_data']);
          logData.remove('sync_status');
          logData.remove('offline_id');
          await SupabaseService.addLog(logData);
          
          // Local update
          final customerId = logData['customer_id'];
          final logs = CacheService.getLogs(customerId);
          final offlineId = task['id'];
          final idx = logs.indexWhere((l) => l['offline_id'] == offlineId);
          if (idx != -1) {
             logs[idx]['sync_status'] = 'synced';
             await CacheService.saveLogs(customerId, logs);
          }
        }

        // Success - remove from sync queue
        await CacheService.deleteSyncTask(taskId);
      } catch (e) {
        debugPrint('Sync task error for taskId $taskId: $e');
        // Update task error details in DB for UI display
        task['error'] = e.toString();
        await CacheService.saveSyncTask(taskId, task);

        // Update syncStatus of cached customer to 'failed'
        final localList = CacheService.getCustomers();
        final idx = localList.indexWhere((c) => c.id == taskId);
        if (idx != -1) {
          localList[idx] = localList[idx].copyWith(syncStatus: 'failed');
          await CacheService.saveCustomers(localList);
        }
      }

      syncProgress.value += progressStep;
    }

    // Refresh final customer list from Supabase
    try {
      final updatedList = await SupabaseService.getCustomers();
      await CacheService.saveCustomers(updatedList);
    } catch (_) {}

    updatePendingCount();
    isSyncing.value = false;
    syncProgress.value = 1.0;
  }
}
