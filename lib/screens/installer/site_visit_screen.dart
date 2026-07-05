import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../app/controllers/site_visit_controller.dart';
import '../../app/models/customer_model.dart';
import '../../app/theme/app_theme.dart';
import '../../app/constants/app_strings.dart';
import '../../app/routes/app_routes.dart';
import '../../app/utils/launch_utils.dart';
import '../../app/widgets/global_image_thumbnail.dart';
import '../../app/models/global_image_item.dart';

class SiteVisitScreen extends StatelessWidget {
  const SiteVisitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (Get.arguments == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed('/installer_dashboard');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    final ctrl = Get.find<SiteVisitController>();
    final CustomerModel customer = Get.arguments as CustomerModel;
    ctrl.init(customer);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.siteVisit,
            style: AppTextStyles.onPrimary.copyWith(fontSize: 16)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer info card
            _CustomerInfoCard(customer: customer)
                .animate()
                .fadeIn(duration: 300.ms),

            const SizedBox(height: 16),

            // GPS Section
            _GpsCard(ctrl: ctrl)
                .animate(delay: 100.ms)
                .slideY(begin: 0.1, end: 0)
                .fade(),

            const SizedBox(height: 16),

            // Photo Section
            _PhotoCard(ctrl: ctrl)
                .animate(delay: 200.ms)
                .slideY(begin: 0.1, end: 0)
                .fade(),

            const SizedBox(height: 16),

            // Status Section
            _StatusCard(ctrl: ctrl)
                .animate(delay: 300.ms)
                .slideY(begin: 0.1, end: 0)
                .fade(),

            const SizedBox(height: 28),

            // Save button
            Obx(() => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: ctrl.isLoading.value ? null : ctrl.saveVisit,
                      icon: ctrl.isLoading.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save_rounded, color: Colors.white),
                      label: Text(
                        ctrl.isLoading.value
                            ? 'Saving... / जतन होत आहे...'
                            : 'Save Visit / भेट सेव करा',
                        style: AppTextStyles.buttonText,
                      ),
                    ),
                    if (ctrl.isLoading.value) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ctrl.uploadProgress.value,
                                backgroundColor: AppColors.divider,
                                color: AppColors.primary,
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${(ctrl.uploadProgress.value * 100).toInt()}%',
                            style: AppTextStyles.body2.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          ctrl.loadingStatus.value,
                          style: AppTextStyles.caption.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                )).animate(delay: 400.ms).fadeIn(),

            const SizedBox(height: 16),
            
            // PM Surya Ghar Installation Button
            ElevatedButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.installationSubmission, arguments: customer),
              icon: const Icon(Icons.solar_power_rounded, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size.fromHeight(50),
              ),
              label: const Text(
                'Submit Installation Details',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ).animate(delay: 500.ms).fadeIn(),

            // Error
            Obx(() => ctrl.error.value.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(ctrl.error.value,
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.error)),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink()),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _CustomerInfoCard extends StatelessWidget {
  final CustomerModel customer;
  const _CustomerInfoCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.solarGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withOpacity(0.25),
                child: Text(
                  customer.name[0].toUpperCase(),
                  style: AppTextStyles.heading3.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name,
                        style: AppTextStyles.body1.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
                    GestureDetector(
                      onTap: () => LaunchUtils.makePhoneCall(customer.mobile),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phone, size: 14, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(customer.mobile,
                              style: AppTextStyles.body2
                                  .copyWith(color: Colors.white70, decoration: TextDecoration.underline, decorationColor: Colors.white70)),
                        ],
                      ),
                    ),
                    if (customer.consumerNo != null && customer.consumerNo!.isNotEmpty)
                      Text('Consumer: ${customer.consumerNo}',
                          style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                    if (customer.customerId != null && customer.customerId!.isNotEmpty)
                      Text('ID: ${customer.customerId}',
                          style: AppTextStyles.caption.copyWith(color: Colors.white70, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              // Current status badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.4)),
                ),
                child: Text(
                  customer.status,
                  style: AppTextStyles.caption.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          // Address
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 14, color: Colors.white70),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  customer.address ??
                      '${customer.village ?? '--'}, ${customer.taluka ?? '--'}',
                  style: AppTextStyles.caption
                      .copyWith(color: Colors.white70),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (customer.solarKw != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.solar_power_rounded,
                    size: 14, color: Colors.white70),
                const SizedBox(width: 6),
                Text('${customer.solarKw} kW Solar',
                    style: AppTextStyles.caption
                        .copyWith(color: Colors.white70)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GpsCard extends StatelessWidget {
  final SiteVisitController ctrl;
  const _GpsCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Live GPS / लाइव GPS',
      icon: Icons.gps_fixed_rounded,
      iconColor: AppColors.secondary,
      child: Column(
        children: [
          // GPS status
          Obx(() => ctrl.hasGps.value
              ? _GpsBadge(
                  lat: ctrl.capturedLat.value,
                  lng: ctrl.capturedLng.value,
                  address: ctrl.capturedAddress.value,
                )
              : _InfoBanner(
                  icon: Icons.gps_off_rounded,
                  message: 'GPS not captured yet / GPS अजून कॅप्चर नाही',
                )),

          const SizedBox(height: 12),

          // Capture button
          Obx(() => _ActionButton(
                icon: Icons.my_location_rounded,
                label: ctrl.hasGps.value
                    ? 'Re-capture GPS / GPS पुन्हा घ्या'
                    : AppStrings.captureGps,
                color: AppColors.secondary,
                isLoading: ctrl.isLoading.value,
                onTap: ctrl.captureGps,
              )),
        ],
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final SiteVisitController ctrl;
  const _PhotoCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Site Photo / साइट फोटो',
      icon: Icons.camera_alt_rounded,
      iconColor: AppColors.accent,
      child: Column(
        children: [
          // Photo preview
          Obx(() {
            if (ctrl.hasPhoto.value && ctrl.photoBytes != null) {
              return GlobalImageThumbnail(
                images: [
                  GlobalImageItem(
                    memoryBytes: ctrl.photoBytes!,
                    photoType: 'Site Photo',
                    status: 'P',
                  )
                ],
                currentIndex: 0,
              ).animate().scale(
                  begin: const Offset(0.95, 0.95),
                  duration: 300.ms);
            } else if (ctrl.customer?.hasPhoto == true) {
              return GlobalImageThumbnail(
                images: [
                  GlobalImageItem(
                    url: ctrl.customer!.photoUrl!,
                    photoType: 'Site Photo',
                    status: 'S',
                  )
                ],
                currentIndex: 0,
              );
            } else {
              return const _InfoBanner(
                icon: Icons.image_outlined,
                message: 'No photo taken yet / फोटो नाही',
              );
            }
          }),

          const SizedBox(height: 12),

          // Camera + Gallery buttons
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera / कॅमेरा',
                  color: AppColors.primary,
                  isLoading: false,
                  onTap: ctrl.takePhoto,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery / गॅलरी',
                  color: AppColors.accent,
                  isLoading: false,
                  onTap: ctrl.pickFromGallery,
                ),
              ),
            ],
          ),

          // WhatsApp hint
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'To ensure offline reliability, share large media via WhatsApp.',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final SiteVisitController ctrl;
  const _StatusCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Update Status / स्थिती',
      icon: Icons.swap_horiz_rounded,
      iconColor: AppColors.primary,
      child: Obx(() => Row(
            children: [
              _StatusOption(
                code: 'P',
                label: 'Pending',
                labelMr: 'प्रलंबित',
                color: AppColors.statusPending,
                isSelected: ctrl.selectedStatus.value == 'P',
                onTap: () => ctrl.selectedStatus.value = 'P',
              ),
              const SizedBox(width: 8),
              _StatusOption(
                code: 'V',
                label: 'Visited',
                labelMr: 'भेट दिली',
                color: AppColors.statusVisited,
                isSelected: ctrl.selectedStatus.value == 'V',
                onTap: () => ctrl.selectedStatus.value = 'V',
              ),
              const SizedBox(width: 8),
              _StatusOption(
                code: 'D',
                label: 'Done',
                labelMr: 'पूर्ण',
                color: AppColors.statusDone,
                isSelected: ctrl.selectedStatus.value == 'D',
                onTap: () => ctrl.selectedStatus.value = 'D',
              ),
            ],
          )),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: AppTextStyles.label
                      .copyWith(color: iconColor, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _GpsBadge extends StatelessWidget {
  final double lat;
  final double lng;
  final String address;

  const _GpsBadge(
      {required this.lat, required this.lng, required this.address});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 16),
              const SizedBox(width: 8),
              Text('GPS Captured / GPS कॅप्चर झाला',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
            style: AppTextStyles.caption.copyWith(
                color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
          if (address.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              address,
              style: AppTextStyles.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String message;

  const _InfoBanner({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textHint, size: 32),
          const SizedBox(height: 8),
          Text(message,
              style: AppTextStyles.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: color.withOpacity(0.09),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: color))
                : Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(label,
                  style: AppTextStyles.body2.copyWith(
                      color: color, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  final String code;
  final String label;
  final String labelMr;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusOption({
    required this.code,
    required this.label,
    required this.labelMr,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Column(
            children: [
              Text(
                code,
                style: AppTextStyles.heading3.copyWith(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: isSelected ? Colors.white.withOpacity(0.9) : color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                labelMr,
                style: AppTextStyles.caption.copyWith(
                  color: isSelected
                      ? Colors.white.withOpacity(0.7)
                      : AppColors.textHint,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
