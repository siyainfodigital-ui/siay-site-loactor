import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/models/customer_model.dart';
import '../../app/controllers/admin_verification_controller.dart';
import '../shared/activity_log_timeline.dart';
import '../../app/routes/app_routes.dart';
import '../../app/utils/launch_utils.dart';
import '../../app/widgets/double_back_exit.dart';
import '../../app/widgets/global_image_thumbnail.dart';
import '../../app/models/global_image_item.dart';

class AdminVerificationScreen extends StatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  State<AdminVerificationScreen> createState() => _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen> {
  CustomerModel? customer;
  late AdminVerificationController controller;

  // Theme Colors
  final Color primaryGreen = const Color(0xFF4CAF50);
  final Color accentBlue = const Color(0xFF2196F3);
  final Color bgWhite = const Color(0xFFF8F9FA);
  final Color surfaceWhite = Colors.white;

  @override
  void initState() {
    super.initState();
    customer = Get.arguments as CustomerModel?;
    if (customer != null) {
      controller = Get.put(AdminVerificationController(customer: customer!));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (customer == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed(AppRoutes.adminDashboard);
      });
      return Scaffold(
        backgroundColor: bgWhite,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: bgWhite,
      appBar: _buildAppBar(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final installation = controller.installation.value;
        if (installation == null) {
          return const Center(child: Text('No installation data found for this customer.'));
        }

        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCustomerInfoCard(),
                  const SizedBox(height: 16),
                  _buildProgressCard(),
                  const SizedBox(height: 16),
                  _buildPendingItemsCard(),
                  const SizedBox(height: 16),
                  _buildVerificationChecklist(),
                  const SizedBox(height: 16),
                  _buildPhotoGallery(),
                  const SizedBox(height: 16),
                  _buildRemarksCard(),
                  const SizedBox(height: 16),
                  _buildActivityTimeline(),
                ],
              ),
            ),
            if (installation.verificationStatus != 'V')
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomActionBar(),
              ),
          ],
        );
      }),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: surfaceWhite,
      surfaceTintColor: surfaceWhite,
      elevation: 0,
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Installation Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text('Application No. ${customer!.consumerNo ?? 'N/A'}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
      ],
    );
  }

  Widget _buildCustomerInfoCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: primaryGreen.withOpacity(0.1),
                child: Icon(Icons.person, color: primaryGreen, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer!.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => LaunchUtils.makePhoneCall(customer!.mobile),
                      child: Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: accentBlue),
                          const SizedBox(width: 4),
                          Text(customer!.mobile, style: TextStyle(color: accentBlue, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(customer!.status),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow(Icons.location_on, 'Address', customer!.address ?? 'N/A'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.home, 'Village', customer!.village ?? 'N/A'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.engineering, 'Assigned Installer', 'Installer Details'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.calendar_today, 'Installation Date', controller.installation.value?.verifiedAt?.toLocal().toString().split(' ')[0] ?? 'Pending'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    switch (status) {
      case 'D':
        color = Colors.green;
        text = 'Verified';
        break;
      case 'V':
        color = Colors.blue;
        text = 'Ready for Verification';
        break;
      case 'P':
      default:
        color = Colors.orange;
        text = 'In Progress';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildProgressCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('${controller.approvedCount} / ${controller.totalChecklistItems} Completed', 
                style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: controller.approvedCount / controller.totalChecklistItems,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProgressStat('✅ Submitted', controller.submittedCount, Colors.blue),
              _buildProgressStat('⏳ Pending', controller.pendingCount, Colors.orange),
              _buildProgressStat('✔ Approved', controller.approvedCount, Colors.green),
              _buildProgressStat('❌ Rejected', controller.rejectedCount, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(value.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _buildPendingItemsCard() {
    final pending = controller.pendingItemNames;
    if (pending.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
              const SizedBox(width: 8),
              Text('Remaining Items (${pending.length})', style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          ...pending.map((item) => Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 8.0),
            child: Text('• $item', style: TextStyle(color: Colors.orange.shade900)),
          )),
        ],
      ),
    );
  }

  Widget _buildVerificationChecklist() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Verification Checklist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildChecklistPhotoItem('Structure Photo', Icons.foundation, controller.installation.value?.structurePhotoUrl, 'structure', controller.structurePhotoStatus),
        _buildChecklistPhotoItem('Solar Panel Photos', Icons.solar_power, controller.installation.value?.panelPhotoUrls?.firstOrNull, 'panel', controller.panelPhotoStatus),
        _buildChecklistPhotoItem('Inverter Photo', Icons.power, controller.installation.value?.inverterPhotoUrl, 'inverter', controller.inverterPhotoStatus),
        _buildChecklistPhotoItem('Generation Meter Photo', Icons.electric_meter, controller.installation.value?.meterPhotoUrl, 'meter', controller.meterPhotoStatus),
        _buildChecklistPhotoItem('Final Geo-tagged Photo', Icons.pin_drop, controller.installation.value?.finalPhotoUrl, 'final', controller.finalPhotoStatus),
        
        // Equipment Info in Checklist
        _buildChecklistTextItem('Inverter Brand', Icons.branding_watermark, controller.installation.value?.inverterBrand),
        _buildChecklistTextItem('Inverter Serial Number', Icons.numbers, controller.installation.value?.inverterSerial),
        _buildChecklistTextItem('Generation Meter Number', Icons.numbers, controller.installation.value?.generationMeterNo),
      ],
    );
  }

  Widget _buildChecklistPhotoItem(String title, IconData icon, String? url, String type, RxString statusRx) {
    return _buildCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: accentBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: accentBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    _buildItemStatusBadge(statusRx.value),
                  ],
                ),
              ),
              if (url != null)
                IconButton(
                  icon: const Icon(Icons.remove_red_eye),
                  color: primaryGreen,
                  onPressed: () => _showPhotoPreview(title, url),
                )
              else
                Icon(Icons.image_not_supported, color: Colors.grey.shade400),
            ],
          ),
          if (controller.installation.value?.verificationStatus != 'V' && url != null) ...[
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => controller.setPhotoStatus(type, 'R'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: statusRx.value == 'R' ? Colors.red : Colors.grey.shade300, width: statusRx.value == 'R' ? 2 : 1),
                      backgroundColor: statusRx.value == 'R' ? Colors.red.withOpacity(0.1) : null,
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => controller.setPhotoStatus(type, 'A'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: statusRx.value == 'A' ? primaryGreen : Colors.white,
                      foregroundColor: statusRx.value == 'A' ? Colors.white : primaryGreen,
                      side: BorderSide(color: primaryGreen, width: statusRx.value == 'A' ? 2 : 1),
                      elevation: 0,
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildChecklistTextItem(String title, IconData icon, String? value) {
    bool hasValue = value != null && value.isNotEmpty;
    return _buildCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: accentBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: accentBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(hasValue ? value : 'Not provided', style: TextStyle(color: hasValue ? Colors.black87 : Colors.grey)),
              ],
            ),
          ),
          _buildItemStatusBadge(hasValue ? 'A' : 'P'),
        ],
      ),
    );
  }

  Widget _buildItemStatusBadge(String status) {
    Color color;
    String text;
    switch (status) {
      case 'A': color = Colors.green; text = 'Approved'; break;
      case 'R': color = Colors.red; text = 'Rejected'; break;
      case 'S': color = Colors.blue; text = 'Submitted'; break;
      case 'P':
      default: color = Colors.orange; text = 'Pending'; break;
    }
    return Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12));
  }

  Widget _buildPhotoGallery() {
    final inst = controller.installation.value!;
    final List<Map<String, dynamic>> photoData = [
      {'title': 'Structure', 'url': inst.structurePhotoUrl, 'status': inst.structurePhotoStatus},
      {'title': 'Panel', 'url': inst.panelPhotoUrls?.firstOrNull, 'status': inst.panelPhotoStatus},
      {'title': 'Inverter', 'url': inst.inverterPhotoUrl, 'status': inst.inverterPhotoStatus},
      {'title': 'Meter', 'url': inst.meterPhotoUrl, 'status': inst.meterPhotoStatus},
      {'title': 'Final Geo', 'url': inst.finalPhotoUrl, 'status': inst.finalPhotoStatus},
    ].where((p) => p['url'] != null).toList();

    if (photoData.isEmpty) return const SizedBox.shrink();

    final List<GlobalImageItem> globalImages = photoData.map((p) {
      final isFinal = p['title'] == 'Final Geo';
      return GlobalImageItem(
        url: p['url'],
        photoType: p['title'],
        status: p['status'],
        uploadedAt: inst.submittedAt,
        lat: isFinal ? inst.lat : null,
        lng: isFinal ? inst.lng : null,
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Photo Gallery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: globalImages.length,
          itemBuilder: (context, index) {
            return GlobalImageThumbnail(
              images: globalImages,
              currentIndex: index,
            );
          },
        ),
      ],
    );
  }

  Widget _buildRemarksCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Verification Remarks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'Enter verification remarks...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            maxLines: 3,
            onChanged: controller.setRemark,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () {}, // Save functionality could be added to controller if needed independently
              style: OutlinedButton.styleFrom(foregroundColor: accentBlue),
              child: const Text('Save Remark'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTimeline() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Activity Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ActivityLogTimeline(customerId: customer!.id),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceWhite,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => controller.verifyInstallation(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Reject Installation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: controller.isAllApproved ? () => controller.verifyInstallation(true) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  controller.isAllApproved ? 'Approve Installation' : 'Pending Items: ${controller.pendingCount}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child, EdgeInsetsGeometry? margin}) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  void _showPhotoPreview(String title, String url) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Get.back(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
