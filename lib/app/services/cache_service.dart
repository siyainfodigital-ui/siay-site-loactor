import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';
import '../models/customer_model.dart';

class CacheService {
  static late Box _customerBox;
  static late Box _installationBox;
  static late Box _logsBox;
  static late Box _settingsBox;
  static late Box _syncQueueBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    _customerBox = await Hive.openBox(AppConstants.customerBox);
    _installationBox = await Hive.openBox(AppConstants.installationBox);
    _logsBox = await Hive.openBox(AppConstants.logsBox);
    _settingsBox = await Hive.openBox(AppConstants.settingsBox);
    _syncQueueBox = await Hive.openBox(AppConstants.syncQueueBox);
  }

  // ─── CUSTOMERS ───────────────────────────────────────────
  static Future<void> saveCustomers(List<CustomerModel> customers) async {
    final encoded = customers.map((c) => jsonEncode(c.toJson())).toList();
    await _customerBox.put(AppConstants.cachedCustomers, encoded);
  }

  static List<CustomerModel> getCustomers() {
    final encoded = _customerBox.get(AppConstants.cachedCustomers);
    if (encoded == null) return [];
    return (encoded as List)
        .map((e) => CustomerModel.fromJson(
            jsonDecode(e as String) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> clearCustomers() async {
    await _customerBox.delete(AppConstants.cachedCustomers);
  }

  // ─── SYNC QUEUE ──────────────────────────────────────────
  static Future<void> saveSyncTask(String id, Map<String, dynamic> task) async {
    await _syncQueueBox.put(id, jsonEncode(task));
  }

  static Map<String, dynamic>? getSyncTask(String id) {
    final data = _syncQueueBox.get(id);
    if (data == null) return null;
    return jsonDecode(data as String) as Map<String, dynamic>;
  }

  static List<Map<String, dynamic>> getAllSyncTasks() {
    return _syncQueueBox.values
        .map((e) => jsonDecode(e as String) as Map<String, dynamic>)
        .toList();
  }

  static Future<void> deleteSyncTask(String id) async {
    await _syncQueueBox.delete(id);
  }

  static Future<void> clearSyncTasks() async {
    await _syncQueueBox.clear();
  }

  // ─── INSTALLATIONS ───────────────────────────────────────
  static Future<void> saveInstallation(String customerId, Map<String, dynamic> data) async {
    await _installationBox.put(customerId, jsonEncode(data));
  }

  static Future<void> saveInstallations(List<Map<String, dynamic>> installations) async {
    for (var inst in installations) {
      if (inst['customer_id'] != null) {
        await _installationBox.put(inst['customer_id'], jsonEncode(inst));
      }
    }
  }

  static Map<String, dynamic>? getInstallation(String customerId) {
    final data = _installationBox.get(customerId);
    if (data == null) return null;
    return jsonDecode(data as String) as Map<String, dynamic>;
  }

  static List<Map<String, dynamic>> getAllInstallations() {
    return _installationBox.values
        .map((e) => jsonDecode(e as String) as Map<String, dynamic>)
        .toList();
  }

  // ─── LOGS ────────────────────────────────────────────────
  static Future<void> addLog(String customerId, Map<String, dynamic> log) async {
    final existingLogs = getLogs(customerId);
    existingLogs.add(log);
    await _logsBox.put(customerId, jsonEncode(existingLogs));
  }

  static List<Map<String, dynamic>> getLogs(String customerId) {
    final data = _logsBox.get(customerId);
    if (data == null) return [];
    final List decoded = jsonDecode(data as String);
    return decoded.cast<Map<String, dynamic>>();
  }

  static Future<void> saveLogs(String customerId, List<Map<String, dynamic>> logs) async {
    await _logsBox.put(customerId, jsonEncode(logs));
  }

  // ─── SETTINGS ────────────────────────────────────────────
  static Future<void> saveString(String key, String value) async {
    await _settingsBox.put(key, value);
  }

  static String? getString(String key) {
    return _settingsBox.get(key) as String?;
  }

  static Future<void> remove(String key) async {
    await _settingsBox.delete(key);
  }

  static Future<void> clear() async {
    await _settingsBox.clear();
    await _customerBox.clear();
    await _installationBox.clear();
    await _logsBox.clear();
    await _syncQueueBox.clear();
  }
}
