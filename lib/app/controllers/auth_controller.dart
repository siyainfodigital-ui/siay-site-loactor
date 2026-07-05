import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';
import '../routes/app_routes.dart';
import '../services/cache_service.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends GetxController {
  final RxString email = ''.obs;
  final RxString password = ''.obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  // Show/Hide password toggle
  final RxBool obscurePassword = true.obs;

  // Remember me toggle
  final RxBool rememberMe = false.obs;

  static const String keySavedEmail = 'saved_email';
  static const String keySavedPassword = 'saved_password';
  static const String keyRememberMe = 'remember_me';

  @override
  void onInit() {
    super.onInit();
    _loadSavedCredentials();
  }

  void _loadSavedCredentials() {
    final rememberSaved = CacheService.getString(keyRememberMe) == 'true';
    rememberMe.value = rememberSaved;
    if (rememberSaved) {
      email.value = CacheService.getString(keySavedEmail) ?? '';
      password.value = CacheService.getString(keySavedPassword) ?? '';
    }
  }

  // ─── LOGIN WITH PASSWORD ─────────────────────────────────
  Future<void> loginWithPassword() async {
    if (!GetUtils.isEmail(email.value.trim())) {
      error.value = 'Enter a valid email / वैध ईमेल टाका';
      return;
    }
    if (password.value.isEmpty) {
      error.value = 'Password is required / पासवर्ड आवश्यक आहे';
      return;
    }
    error.value = '';
    isLoading.value = true;
    try {
      final response = await SupabaseService.signInWithPassword(
        email: email.value.trim(),
        password: password.value,
      );

      if (response.user != null) {
        final role = SupabaseService.userRole ?? AppConstants.installerRole;
        
        // Save/Clear cached credentials based on Remember Me value
        if (rememberMe.value) {
          await CacheService.saveString(keyRememberMe, 'true');
          await CacheService.saveString(keySavedEmail, email.value.trim());
          await CacheService.saveString(keySavedPassword, password.value);
        } else {
          await CacheService.remove(keyRememberMe);
          await CacheService.remove(keySavedEmail);
          await CacheService.remove(keySavedPassword);
        }

        await CacheService.saveString(AppConstants.userRoleKey, role);
        await CacheService.saveString(
            AppConstants.userIdKey, response.user!.id);
        _navigateByRole(role);
      } else {
        error.value = AppStrings.somethingWrong;
      }
    } on AuthException catch (e) {
      error.value = e.message;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // ─── SESSION CHECK ───────────────────────────────────────
  Future<void> checkSession() async {
    if (SupabaseService.isLoggedIn) {
      final role = SupabaseService.userRole ??
          CacheService.getString(AppConstants.userRoleKey) ??
          AppConstants.installerRole;
      _navigateByRole(role);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  void _navigateByRole(String role) {
    if (role == AppConstants.adminRole) {
      Get.offAllNamed(AppRoutes.adminDashboard);
    } else {
      Get.offAllNamed(AppRoutes.installerDashboard);
    }
  }

  Future<void> logout() async {
    await SupabaseService.signOut();
    await CacheService.clear();
    Get.offAllNamed(AppRoutes.login);
  }
}
