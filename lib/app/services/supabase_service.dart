import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import '../models/customer_model.dart';
import '../models/installation_model.dart';
import '../models/log_model.dart';
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // ─── AUTH ────────────────────────────────────────────────
  static Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static User? get currentUser => client.auth.currentUser;

  static bool get isLoggedIn => currentUser != null;

  static String? get userRole =>
      currentUser?.userMetadata?['role'] as String?;

  static Future<List<CustomerModel>> getCustomers({
    String? installerPhone,
    String? status,
    int? limit,
    int? offset,
    String? searchQuery,
  }) async {
    var query = client
        .from(AppConstants.customersTable)
        .select();

    if (installerPhone != null) {
      query = query.eq('installer', installerPhone);
    }
    if (status != null) {
      query = query.eq('status', status);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.or('name.ilike.%$searchQuery%,mobile.ilike.%$searchQuery%,consumer_no.ilike.%$searchQuery%');
    }

    var finalQuery = query.order('created_at', ascending: false);

    if (limit != null) {
      if (offset != null) {
        finalQuery = finalQuery.range(offset, offset + limit - 1);
      } else {
        finalQuery = finalQuery.limit(limit);
      }
    }

    final response = await finalQuery;
    List<CustomerModel> customers = (response as List)
        .map((e) => CustomerModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return customers;
  }

  static Future<CustomerModel?> addCustomer(
      Map<String, dynamic> data) async {
    final response = await client
        .from(AppConstants.customersTable)
        .insert(data)
        .select()
        .single();
    return CustomerModel.fromJson(response);
  }

  static Future<void> updateCustomer(
      String id, Map<String, dynamic> data) async {
    await client
        .from(AppConstants.customersTable)
        .update(data)
        .eq('id', id);
  }

  static Future<void> deleteCustomer(String id) async {
    await client
        .from(AppConstants.customersTable)
        .delete()
        .eq('id', id);
  }

  static Future<void> updateStatus(String id, String status) async {
    await updateCustomer(id, {'status': status});
  }

  static Future<void> assignInstaller(String id, String installerPhone) async {
    await updateCustomer(id, {'installer': installerPhone});
  }

  static Future<Set<String>> getExistingMobiles() async {
    final response = await client
        .from(AppConstants.customersTable)
        .select('mobile');
    return (response as List).map((e) => e['mobile'] as String).toSet();
  }

  static Future<void> insertBatch(List<Map<String, dynamic>> batch) async {
    await client.from(AppConstants.customersTable).insert(batch);
  }

  static Future<void> bulkInsertCustomers(
      List<Map<String, dynamic>> customers) async {
    final existingMobiles = await getExistingMobiles();

    final newCustomers = customers
        .where((c) => !existingMobiles.contains(c['mobile']))
        .toList();

    if (newCustomers.isEmpty) return;

    // Insert in batches of 100
    const batchSize = 100;
    for (int i = 0; i < newCustomers.length; i += batchSize) {
      final batch = newCustomers.sublist(
        i,
        (i + batchSize) > newCustomers.length
            ? newCustomers.length
            : (i + batchSize),
      );
      await insertBatch(batch);
    }
  }

  // ─── INSTALLATIONS ───────────────────────────────────────
  static Future<InstallationModel?> getInstallation(String customerId) async {
    final response = await client
        .from(AppConstants.installationsTable)
        .select()
        .eq('customer_id', customerId)
        .maybeSingle();
    if (response == null) return null;
    return InstallationModel.fromJson(response);
  }

  static Future<List<InstallationModel>> getInstallationsForCustomers(List<String> customerIds) async {
    if (customerIds.isEmpty) return [];
    final response = await client
        .from(AppConstants.installationsTable)
        .select()
        .inFilter('customer_id', customerIds);
    return (response as List).map((e) => InstallationModel.fromJson(e)).toList();
  }
  
  static Future<List<InstallationModel>> getAllInstallations() async {
    final response = await client
        .from(AppConstants.installationsTable)
        .select();
    return (response as List).map((e) => InstallationModel.fromJson(e)).toList();
  }

  static Future<InstallationModel> upsertInstallation(Map<String, dynamic> data) async {
    final response = await client
        .from(AppConstants.installationsTable)
        .upsert(data)
        .select()
        .single();
    return InstallationModel.fromJson(response);
  }

  // ─── LOGS ────────────────────────────────────────────────
  static Future<List<LogModel>> getLogs(String customerId) async {
    final response = await client
        .from(AppConstants.logsTable)
        .select()
        .eq('customer_id', customerId)
        .order('created_at', ascending: true);
    
    return (response as List)
        .map((e) => LogModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<LogModel> addLog(Map<String, dynamic> data) async {
    final response = await client
        .from(AppConstants.logsTable)
        .insert(data)
        .select()
        .single();
    return LogModel.fromJson(response);
  }

  // ─── STORAGE ─────────────────────────────────────────────
  /// Upload photo from File (mobile only)
  static Future<String?> uploadPhoto(String customerId, dynamic photo) async {
    try {
      final bytes = await photo.readAsBytes();
      final fileName = '$customerId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await client.storage
          .from(AppConstants.photoBucket)
          .uploadBinary(fileName, bytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true));
      return client.storage.from(AppConstants.photoBucket).getPublicUrl(fileName);
    } catch (e) {
      debugPrint('Photo upload error: $e');
      return null;
    }
  }

  /// Upload photo from bytes (works on web + mobile)
  static Future<String?> uploadPhotoBytes(
      String customerId, Uint8List bytes, String filename, {String bucket = AppConstants.photoBucket}) async {
    try {
      final ext = filename.split('.').last.toLowerCase();
      final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';
      final fileName = '$customerId/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await client.storage
          .from(bucket)
          .uploadBinary(fileName, bytes,
              fileOptions: FileOptions(contentType: contentType, upsert: true));
      return client.storage.from(bucket).getPublicUrl(fileName);
    } catch (e) {
      debugPrint('Photo bytes upload error: $e');
      return null;
    }
  }

  // ─── STATS ───────────────────────────────────────────────
  static Future<Map<String, int>> getDashboardStats() async {
    final response = await client
        .from(AppConstants.customersTable)
        .select('status');

    final list = response as List;
    final total = list.length;
    final pending = list.where((e) => e['status'] == 'P').length;
    final visited = list.where((e) => e['status'] == 'V').length;
    final done = list.where((e) => e['status'] == 'D').length;

    return {
      'total': total,
      'pending': pending,
      'visited': visited,
      'done': done,
    };
  }

  static Future<List<Map<String, dynamic>>> getInstallerStats() async {
    final response = await client
        .from(AppConstants.customersTable)
        .select('installer, status')
        .not('installer', 'is', null);

    final list = response as List;
    final Map<String, Map<String, int>> stats = {};

    for (final item in list) {
      final installer = item['installer'] as String? ?? '';
      final status = item['status'] as String? ?? 'P';
      if (installer.isEmpty) continue;

      stats.putIfAbsent(
          installer, () => {'total': 0, 'P': 0, 'V': 0, 'D': 0});
      stats[installer]!['total'] = (stats[installer]!['total'] ?? 0) + 1;
      stats[installer]![status] = (stats[installer]![status] ?? 0) + 1;
    }

    return stats.entries
        .map((e) => {'installer': e.key, ...e.value})
        .toList();
  }

  // ─── REALTIME ────────────────────────────────────────────
  static RealtimeChannel subscribeToCustomers(
      void Function(dynamic payload) callback) {
    return client
        .channel('customers_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: AppConstants.customersTable,
          callback: (payload) => callback(payload),
        )
        .subscribe();
  }

  // ─── INSTALLER USER MANAGEMENT ───────────────────────────

  /// Fetch all users with role=installer from auth.users via RPC
  static Future<List<Map<String, dynamic>>> getInstallerUsers() async {
    final response = await client
        .from('auth_installer_view')
        .select()
        .order('created_at', ascending: false);
    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Create a new installer user (uses Supabase Admin API via RPC)
  static Future<void> createInstallerUser({
    required String email,
    required String password,
    required String name,
  }) async {
    await client.rpc('create_installer_user', params: {
      'p_email': email,
      'p_password': password,
      'p_name': name,
    });
  }

  /// Update installer display name
  static Future<void> updateInstallerName({
    required String userId,
    required String name,
  }) async {
    await client.rpc('update_installer_name', params: {
      'p_user_id': userId,
      'p_name': name,
    });
  }

  /// Delete an installer user
  static Future<void> deleteInstallerUser(String userId) async {
    await client.rpc('delete_installer_user', params: {
      'p_user_id': userId,
    });
  }
}
