import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../../app/widgets/global_image_thumbnail.dart';
import '../../app/models/global_image_item.dart';
import '../../app/controllers/customer_controller.dart';
import '../../app/theme/app_theme.dart';
import '../../app/constants/app_strings.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AddCustomerScreen extends StatelessWidget {
  const AddCustomerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CustomerController>();
    final isEdit = ctrl.editingCustomer != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Customer / संपादन' : AppStrings.addCustomer,
          style: AppTextStyles.onPrimary.copyWith(fontSize: 16),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: ctrl.formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Customer Info
            _SectionCard(
              title: 'Customer Info / ग्राहक माहिती',
              icon: Icons.person_rounded,
              children: [
                _Field(
                  controller: ctrl.nameCtrl,
                  label: AppStrings.customerName,
                  icon: Icons.person_outline_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? AppStrings.requiredField
                      : null,
                ),
                const SizedBox(height: 14),
                _Field(
                  controller: ctrl.mobileCtrl,
                  label: AppStrings.mobileNo,
                  icon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return AppStrings.requiredField;
                    if (v.trim().length != 10) return AppStrings.invalidMobile;
                    return null;
                  },
                ),
                _Field(
                  controller: ctrl.consumerNoCtrl,
                  label: 'Consumer Number / ग्राहक क्रमांक',
                  icon: Icons.electric_meter_rounded,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 14),
                _Field(
                  controller: ctrl.solarCtrl,
                  label: AppStrings.solarCapacity,
                  icon: Icons.solar_power_rounded,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 14),

            // Address
            _SectionCard(
              title: 'Address / पत्ता',
              icon: Icons.location_city_rounded,
              children: [
                Row(children: [
                  Expanded(
                    child: _Field(
                      controller: ctrl.villageCtrl,
                      label: AppStrings.village,
                      icon: Icons.home_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Field(
                      controller: ctrl.talukaCtrl,
                      label: AppStrings.taluka,
                      icon: Icons.map_rounded,
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                _Field(
                  controller: ctrl.addressCtrl,
                  label: AppStrings.fullAddress,
                  icon: Icons.home_work_rounded,
                  maxLines: 3,
                ),
              ],
            ).animate(delay: 100.ms).fadeIn(duration: 300.ms),

            const SizedBox(height: 14),

            // Location — manual lat/lng, no map
            _SectionCard(
              title: 'GPS Location / GPS ठिकाण',
              icon: Icons.gps_fixed_rounded,
              children: [
                // GPS badge
                Obx(() => ctrl.hasLocation.value
                    ? _LocationBadge(
                        lat: ctrl.latCtrl.text,
                        lng: ctrl.lngCtrl.text,
                      )
                    : const SizedBox.shrink()),

                const SizedBox(height: 10),

                // Auto-capture GPS button
                Obx(() => _LocationBtn(
                      icon: Icons.my_location_rounded,
                      label: AppStrings.useCurrentLocation,
                      color: AppColors.primary,
                      isLoading: ctrl.isLoading.value,
                      onTap: ctrl.captureCurrentLocation,
                    )),

                const SizedBox(height: 14),

                // Paste lat,lng or Google Maps link
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: ctrl.latLngPasteCtrl,
                      decoration: InputDecoration(
                        labelText: 'Paste lat,lng or Maps link',
                        hintText: '21.12345, 74.56789',
                        prefixIcon: const Icon(Icons.link_rounded,
                            color: AppColors.textHint, size: 20),
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppColors.secondary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                      ),
                      style: AppTextStyles.body2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: ctrl.parsePastedLatLng,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ]),

                const SizedBox(height: 14),

                // Manual lat/lng fields
                Row(children: [
                  Expanded(
                    child: _Field(
                      controller: ctrl.latCtrl,
                      label: 'Latitude / अक्षांश',
                      icon: Icons.north_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Field(
                      controller: ctrl.lngCtrl,
                      label: 'Longitude / रेखांश',
                      icon: Icons.east_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                    ),
                  ),
                ]),

                // Error
                Obx(() => ctrl.error.value.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(ctrl.error.value,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.error)),
                      )
                    : const SizedBox.shrink()),
              ],
            ).animate(delay: 200.ms).fadeIn(duration: 300.ms),

            const SizedBox(height: 14),

            // Site Photo
            _SectionCard(
              title: 'Site Photo / साइट फोटो',
              icon: Icons.camera_alt_rounded,
              children: [
                // Photo preview
                Obx(() {
                  final hasLocalPhoto = ctrl.hasPhoto.value && ctrl.photoBytes != null;
                  final hasRemotePhoto = ctrl.editingCustomer != null &&
                      ctrl.editingCustomer!.photoUrl != null &&
                      ctrl.editingCustomer!.photoUrl!.isNotEmpty;

                  if (hasLocalPhoto) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          GlobalImageThumbnail(
                            images: [
                              GlobalImageItem(
                                memoryBytes: ctrl.photoBytes!,
                                photoType: 'Site Photo',
                              )
                            ],
                            currentIndex: 0,
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                ctrl.photoXFile = null;
                                ctrl.photoBytes = null;
                                ctrl.hasPhoto.value = false;
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (hasRemotePhoto) {
                    return GlobalImageThumbnail(
                      images: [
                        GlobalImageItem(
                          url: ctrl.editingCustomer!.photoUrl!,
                          photoType: 'Site Photo',
                          status: ctrl.editingCustomer!.status,
                        )
                      ],
                      currentIndex: 0,
                    );
                  } else {
                    return Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_outlined, size: 40, color: AppColors.textHint),
                            SizedBox(height: 8),
                            Text('No photo selected', style: TextStyle(color: AppColors.textHint)),
                          ],
                        ),
                      ),
                    );
                  }
                }),

                const SizedBox(height: 12),

                // Camera + Gallery row
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: ctrl.pickPhotoFromCamera,
                      icon: const Icon(Icons.camera_alt_rounded, size: 18),
                      label: const Text('Camera'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: ctrl.pickPhotoFromGallery,
                      icon: const Icon(Icons.photo_library_rounded, size: 18),
                      label: const Text('Gallery'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: const BorderSide(color: AppColors.accent),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ]),
              ],
            ).animate(delay: 250.ms).fadeIn(duration: 300.ms),

            const SizedBox(height: 28),

            Obx(() => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: ctrl.isLoading.value ? null : ctrl.saveCustomer,
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
                            : AppStrings.saveCustomer,
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
                )),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
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
          Row(children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(title,
                style: AppTextStyles.label.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int? maxLength;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLength,
    this.maxLines,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      maxLines: maxLines ?? 1,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textHint, size: 20),
        counterText: '',
      ),
      style: AppTextStyles.body1,
    );
  }
}

class _LocationBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  const _LocationBtn({
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
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: color))
              : Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Flexible(
            child: Text(label,
                style: AppTextStyles.body2.copyWith(
                    color: color, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      ),
    );
  }
}

class _LocationBadge extends StatelessWidget {
  final String lat;
  final String lng;
  const _LocationBadge({required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.check_circle_rounded,
            color: AppColors.success, size: 16),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'Lat: $lat  |  Lng: $lng',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }
}
