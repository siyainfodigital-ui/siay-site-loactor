import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../app/controllers/auth_controller.dart';
import '../../app/theme/app_theme.dart';
import '../../app/constants/app_strings.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AuthController>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.splashGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Top branding
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4), width: 2),
                      ),
                      child: const Icon(Icons.wb_sunny_rounded,
                          size: 48, color: Colors.white),
                    ).animate().scale(
                        begin: const Offset(0.7, 0.7),
                        duration: 500.ms,
                        curve: Curves.elasticOut),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.appName,
                      style: AppTextStyles.heading2.copyWith(
                          color: Colors.white, letterSpacing: 0.5),
                    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 6),
                    Text(
                      'Solar Field Management',
                      style: AppTextStyles.body2
                          .copyWith(color: Colors.white.withValues(alpha: 0.7)),
                    ).animate(delay: 350.ms).fadeIn(),
                  ],
                ),
              ),

              // Login card
              Expanded(
                flex: 3,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  padding: const EdgeInsets.all(28),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(AppStrings.login, style: AppTextStyles.heading3),
                        const SizedBox(height: 6),
                        Text(
                          'Enter credentials to sign in / लॉगिन करा',
                          style: AppTextStyles.body2,
                        ),
                        const SizedBox(height: 28),

                        // Email field
                        TextFormField(
                          initialValue: ctrl.email.value,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (v) => ctrl.email.value = v,
                          decoration: const InputDecoration(
                            labelText: 'Email Address / ईमेल पत्ता',
                            hintText: 'Enter your email address',
                            prefixIcon: Icon(Icons.email_rounded, color: AppColors.textHint),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Password field with visibility toggle
                        Obx(() => TextFormField(
                              initialValue: ctrl.password.value,
                              obscureText: ctrl.obscurePassword.value,
                              onChanged: (v) => ctrl.password.value = v,
                              decoration: InputDecoration(
                                labelText: 'Password / पासवर्ड',
                                hintText: 'Enter your password',
                                prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.textHint),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    ctrl.obscurePassword.value
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: AppColors.textHint,
                                  ),
                                  onPressed: () => ctrl.obscurePassword.toggle(),
                                ),
                              ),
                            )),

                        const SizedBox(height: 12),

                        // Remember Me Checkbox
                        Row(
                          children: [
                            Obx(() => Checkbox(
                                  value: ctrl.rememberMe.value,
                                  activeColor: AppColors.primary,
                                  onChanged: (v) => ctrl.rememberMe.value = v ?? false,
                                )),
                            GestureDetector(
                              onTap: () => ctrl.rememberMe.toggle(),
                              child: Text(
                                'Remember Me / लक्षात ठेवा',
                                style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Error
                        Obx(() => ctrl.error.value.isNotEmpty
                            ? Text(ctrl.error.value,
                                style: AppTextStyles.caption.copyWith(color: AppColors.error))
                            : const SizedBox.shrink()),

                        const SizedBox(height: 20),

                        // Login button
                        Obx(() => ElevatedButton(
                              onPressed: ctrl.isLoading.value ? null : ctrl.loginWithPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                              ),
                              child: ctrl.isLoading.value
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2.5))
                                  : const Text('Login / लॉगिन',
                                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 16)),
                            )),

                        const SizedBox(height: 32),

                        const Center(
                          child: Column(
                            children: [
                              Icon(Icons.lock_outline_rounded,
                                  color: AppColors.textHint, size: 20),
                              SizedBox(height: 6),
                              Text('Protected by Supabase Encryption / सुरक्षित लॉगिन',
                                  style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: 200.ms).slideY(begin: 0.3, end: 0, duration: 400.ms),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
