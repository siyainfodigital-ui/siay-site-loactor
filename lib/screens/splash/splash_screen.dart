import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../app/controllers/auth_controller.dart';
import '../../app/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    final ctrl = Get.find<AuthController>();
    await ctrl.checkSession();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.splashGradient),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Solar panel icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3), width: 2),
                ),
                child: const Icon(
                  Icons.wb_sunny_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              )
                  .animate()
                  .scale(
                      begin: const Offset(0.6, 0.6),
                      end: const Offset(1.0, 1.0),
                      duration: 600.ms,
                      curve: Curves.elasticOut)
                  .fade(begin: 0, end: 1, duration: 400.ms),

              const SizedBox(height: 32),

              Text(
                'Siya Site Locator',
                style: AppTextStyles.heading1.copyWith(
                  color: Colors.white,
                  fontSize: 28,
                  letterSpacing: 0.5,
                ),
              )
                  .animate(delay: 300.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.3, end: 0),

              const SizedBox(height: 8),

              Text(
                'सौर साइट व्यवस्थापन',
                style: AppTextStyles.body1.copyWith(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              )
                  .animate(delay: 500.ms)
                  .fadeIn(duration: 500.ms),

              const Spacer(flex: 2),

              // Animated solar rays
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  )
                      .animate(
                          onPlay: (c) => c.repeat(),
                          delay: Duration(milliseconds: i * 200))
                      .scaleXY(
                          begin: 0.5,
                          end: 1.2,
                          duration: 600.ms,
                          curve: Curves.easeInOut)
                      .then()
                      .scaleXY(
                          begin: 1.2,
                          end: 0.5,
                          duration: 600.ms,
                          curve: Curves.easeInOut),
                ),
              ),

              const SizedBox(height: 48),

              Text(
                'Powered by Solar Energy',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
