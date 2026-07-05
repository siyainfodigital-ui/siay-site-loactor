import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../app/models/customer_model.dart';
import '../../app/controllers/admin_photos_controller.dart';
import '../../app/widgets/global_image_thumbnail.dart';
import '../../app/models/global_image_item.dart';
import '../../app/theme/app_theme.dart';

class AdminPhotosScreen extends StatefulWidget {
  const AdminPhotosScreen({super.key});

  @override
  State<AdminPhotosScreen> createState() => _AdminPhotosScreenState();
}

class _AdminPhotosScreenState extends State<AdminPhotosScreen> {
  CustomerModel? customer;
  late AdminPhotosController controller;

  @override
  void initState() {
    super.initState();
    customer = Get.arguments as CustomerModel?;
    if (customer != null) {
      controller = Get.put(AdminPhotosController(customer: customer!));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (customer == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.back();
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Installation Photos'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final inst = controller.installation.value;
        if (inst == null) {
          return const Center(child: Text('No installation data found.'));
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildPhotoSummary(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSectionTitle('Structure Photo'),
                  _buildSinglePhoto('Structure', inst.structurePhotoUrl, inst.structurePhotoStatus, 'structure_photo'),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Solar Panel Photos (${inst.panelPhotoUrls?.length ?? 0})'),
                  _buildPanelPhotos(inst.panelPhotoUrls, inst.panelPhotoStatus),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Inverter Photo'),
                  _buildSinglePhoto('Inverter', inst.inverterPhotoUrl, inst.inverterPhotoStatus, 'inverter_photo'),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Generation Meter Photo'),
                  _buildSinglePhoto('Generation Meter', inst.meterPhotoUrl, inst.meterPhotoStatus, 'meter_photo'),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Final Geo-tagged Photo'),
                  _buildFinalPhoto(),
                  const SizedBox(height: 100), // padding for bottom
                ]),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildPhotoSummary() {
    final inst = controller.installation.value;
    int completed = 0;
    
    Widget buildRow(String title, bool isPending, String uploadedStr) {
      if (!isPending) completed++;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Expanded(child: Text(title, style: AppTextStyles.body2)),
            if (isPending) 
              const Text('⏳ Pending', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))
            else 
              Text('✅ $uploadedStr', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Photo Summary', style: AppTextStyles.heading3),
          const Divider(),
          buildRow('Structure Photo', !controller.hasStructurePhoto, 'Uploaded'),
          buildRow('Solar Panel Photos', !controller.hasPanelPhotos, '${inst?.panelPhotoUrls?.length ?? 0} Uploaded'),
          buildRow('Inverter Photo', !controller.hasInverterPhoto, 'Uploaded'),
          buildRow('Generation Meter Photo', !controller.hasMeterPhoto, 'Uploaded'),
          buildRow('Final Geo Photo', !controller.hasFinalPhoto, 'Uploaded'),
          const Divider(),
          Text('Overall Progress: $completed / 5 Required Items Completed', style: AppTextStyles.subtitle.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: AppTextStyles.heading3),
    );
  }

  Widget _buildSinglePhoto(String type, String? url, String? status, String statusKey) {
    if (url == null || url.isEmpty) {
      return _buildMissingPhotoPlaceholder();
    }
    
    final item = GlobalImageItem(
      url: url,
      photoType: '$type Photo',
      status: status,
      onApprove: () => controller.approvePhoto(statusKey),
      onReject: () => controller.rejectPhoto(statusKey),
      onAddRemark: (remark) => controller.addRemark(statusKey, remark),
    );

    return SizedBox(
      height: 200,
      width: double.infinity,
      child: GlobalImageThumbnail(
        images: [item],
        currentIndex: 0,
      ),
    );
  }

  Widget _buildPanelPhotos(List<String>? urls, String? status) {
    if (urls == null || urls.isEmpty) {
      return _buildMissingPhotoPlaceholder();
    }

    List<GlobalImageItem> items = urls.asMap().entries.map((e) {
      return GlobalImageItem(
        url: e.value,
        photoType: 'Solar Panel Photo ${e.key + 1}',
        status: status,
        onApprove: () => controller.approvePhoto('panel_photo'),
        onReject: () => controller.rejectPhoto('panel_photo'),
        onAddRemark: (remark) => controller.addRemark('panel_photo', remark),
      );
    }).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return GlobalImageThumbnail(
          images: items,
          currentIndex: index,
          height: double.infinity,
        );
      },
    );
  }

  Widget _buildFinalPhoto() {
    final inst = controller.installation.value;
    if (inst == null || inst.finalPhotoUrl == null) {
      return _buildMissingPhotoPlaceholder();
    }

    String watermark = '';
    if (inst.lat != null && inst.lng != null) {
      watermark += 'Lat: ${inst.lat}, Lng: ${inst.lng}\n';
    }
    if (inst.submittedAt != null) {
      watermark += 'Uploaded: ${DateFormat('dd MMM yyyy, hh:mm a').format(inst.submittedAt!.toLocal())}\n';
    }

    final item = GlobalImageItem(
      url: inst.finalPhotoUrl,
      photoType: 'Final Geo-tagged Photo',
      status: inst.finalPhotoStatus,
      lat: inst.lat,
      lng: inst.lng,
      uploadedAt: inst.submittedAt,
      watermarkInfo: watermark,
      onApprove: () => controller.approvePhoto('final_photo'),
      onReject: () => controller.rejectPhoto('final_photo'),
      onAddRemark: (remark) => controller.addRemark('final_photo', remark),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          width: double.infinity,
          child: GlobalImageThumbnail(
            images: [item],
            currentIndex: 0,
          ),
        ),
        if (inst.lat != null && inst.lng != null) ...[
          const SizedBox(height: 8),
          Text('📍 Lat: ${inst.lat}, Lng: ${inst.lng}', style: AppTextStyles.caption),
        ],
        if (inst.submittedAt != null) ...[
          const SizedBox(height: 4),
          Text('🕒 ${DateFormat('dd MMM yyyy, hh:mm a').format(inst.submittedAt!.toLocal())}', style: AppTextStyles.caption),
        ]
      ],
    );
  }

  Widget _buildMissingPhotoPlaceholder() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
      ),
      child: const Center(
        child: Text('Not Uploaded Yet', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
