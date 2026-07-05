import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/models/customer_model.dart';
import '../../app/controllers/installation_controller.dart';
import '../../app/theme/app_theme.dart';
import '../shared/activity_log_timeline.dart';

class InstallationDetailsScreen extends StatefulWidget {
  const InstallationDetailsScreen({super.key});

  @override
  State<InstallationDetailsScreen> createState() => _InstallationDetailsScreenState();
}

class _InstallationDetailsScreenState extends State<InstallationDetailsScreen> {
  CustomerModel? customer;
  late InstallationController controller;

  // Local text controllers for bottom sheet dialogs
  final TextEditingController _inverterBrandController = TextEditingController();
  final TextEditingController _inverterSerialController = TextEditingController();
  final TextEditingController _meterController = TextEditingController();
  final TextEditingController _panelBrandController = TextEditingController();
  final TextEditingController _panelCountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    customer = Get.arguments as CustomerModel?;
    if (customer != null) {
      controller = Get.put(InstallationController(customer: customer!));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.logSiteOpened();
      });
    }
  }

  @override
  void dispose() {
    _inverterBrandController.dispose();
    _inverterSerialController.dispose();
    _meterController.dispose();
    _panelBrandController.dispose();
    _panelCountController.dispose();
    super.dispose();
  }

  void _showInputDialog(String title, TextEditingController textController, Function(String) onSave, {bool isNumeric = false}) {
    textController.text = ""; // clear previous
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter $title', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
              decoration: InputDecoration(
                labelText: title,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  onSave(textController.text);
                  Get.back();
                },
                child: const Text('Save', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (customer == null) return const Scaffold(body: Center(child: Text('Error: Customer not found')));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Installation Details', style: TextStyle(color: Colors.white, fontSize: 18)),
            Text('App No. ${customer!.consumerNo ?? customer!.id.substring(0,8)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Get.snackbar('Activity Log', 'Scroll down to view the activity timeline');
            },
          )
        ],
      ),
      body: Obx(() {
        if (controller.isSubmitting.value) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCustomerInfoCard(),
                    const SizedBox(height: 16),
                    _buildProgressCard(),
                    const SizedBox(height: 24),
                    const Text('Required Installation Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    
                    // Photos
                    _buildItemCard(
                      icon: Icons.foundation, 
                      title: 'Structure Photo', 
                      status: _getPhotoStatus(controller.structurePhotoBytes.value, controller.draftData.value?['structure_photo_url'], controller.draftData.value?['structure_photo_status']), 
                      onAction: () => controller.capturePhoto('structure'),
                      actionLabel: _getPhotoStatus(controller.structurePhotoBytes.value, controller.draftData.value?['structure_photo_url'], controller.draftData.value?['structure_photo_status']) == 'Pending' ? 'Capture Photo' : 'Retake Photo'
                    ),
                    _buildItemCard(
                      icon: Icons.solar_power, 
                      title: 'Solar Panel Photos', 
                      status: _getPhotoStatus(controller.panelPhotoBytes.value, controller.draftData.value?['panel_photo_url'], controller.draftData.value?['panel_photo_status']), 
                      onAction: () => controller.capturePhoto('panel'),
                      actionLabel: _getPhotoStatus(controller.panelPhotoBytes.value, controller.draftData.value?['panel_photo_url'], controller.draftData.value?['panel_photo_status']) == 'Pending' ? 'Capture Photo' : 'Retake Photo'
                    ),
                    _buildItemCard(
                      icon: Icons.electric_bolt, 
                      title: 'Inverter Photo', 
                      status: _getPhotoStatus(controller.inverterPhotoBytes.value, controller.draftData.value?['inverter_photo_url'], controller.draftData.value?['inverter_photo_status']), 
                      onAction: () => controller.capturePhoto('inverter'),
                      actionLabel: _getPhotoStatus(controller.inverterPhotoBytes.value, controller.draftData.value?['inverter_photo_url'], controller.draftData.value?['inverter_photo_status']) == 'Pending' ? 'Capture Photo' : 'Retake Photo'
                    ),
                    _buildItemCard(
                      icon: Icons.speed, 
                      title: 'Generation Meter Photo', 
                      status: _getPhotoStatus(controller.meterPhotoBytes.value, controller.draftData.value?['meter_photo_url'], controller.draftData.value?['meter_photo_status']), 
                      onAction: () => controller.capturePhoto('meter'),
                      actionLabel: _getPhotoStatus(controller.meterPhotoBytes.value, controller.draftData.value?['meter_photo_url'], controller.draftData.value?['meter_photo_status']) == 'Pending' ? 'Capture Photo' : 'Retake Photo'
                    ),
                    _buildItemCard(
                      icon: Icons.pin_drop, 
                      title: 'Final Geo-tagged Photo', 
                      status: _getPhotoStatus(controller.finalPhotoBytes.value, controller.draftData.value?['final_photo_url'], controller.draftData.value?['final_photo_status']), 
                      onAction: () => controller.capturePhoto('final'),
                      actionLabel: _getPhotoStatus(controller.finalPhotoBytes.value, controller.draftData.value?['final_photo_url'], controller.draftData.value?['final_photo_status']) == 'Pending' ? 'Capture Photo' : 'Retake Photo'
                    ),


                    const SizedBox(height: 24),
                    _buildPendingItemsCard(),
                    const SizedBox(height: 24),
                    ActivityLogTimeline(customerId: customer!.id),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            _buildBottomButtons(),
          ],
        );
      }),
    );
  }

  String _getPhotoStatus(dynamic localBytes, dynamic remoteUrl, dynamic remoteStatus) {
    if (localBytes != null) return 'Submitted';
    if (remoteUrl != null) return 'Submitted';
    if (remoteStatus == 'S' || remoteStatus == 'A') return 'Submitted';
    return 'Pending';
  }

  Widget _buildCustomerInfoCard() {
    return Container(
      width: double.infinity,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(customer!.name, style: AppTextStyles.heading2),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Text('In Progress', style: AppTextStyles.caption.copyWith(color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.phone, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(customer!.mobile, style: AppTextStyles.body2),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(child: Text('${customer!.address ?? ""}, ${customer!.village ?? ""}', style: AppTextStyles.body2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final int completed = controller.completedItemsCount;
    final double progress = completed / 5.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(completed == 5 ? AppColors.statusDone : Colors.blue),
                ),
                Center(
                  child: Text('${(progress * 100).toInt()}%', style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Progress', style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
                Text('$completed / 5 Completed', style: AppTextStyles.heading3.copyWith(color: completed == 5 ? AppColors.statusDone : Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard({required IconData icon, required String title, String? subtitle, required String status, required VoidCallback onAction, required String actionLabel}) {
    final bool isCompleted = status != 'Pending';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.statusDone.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: isCompleted ? AppColors.statusDone : Colors.orange, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                    ]
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.statusDone.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? AppColors.statusDone : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: isCompleted ? Colors.blue : AppColors.primary,
                side: BorderSide(color: isCompleted ? Colors.blue.withOpacity(0.5) : AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingItemsCard() {
    final pending = controller.pendingItemsList;
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
              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              const SizedBox(width: 8),
              Text('Remaining Items', style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
            ],
          ),
          const SizedBox(height: 12),
          ...pending.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 6, color: Colors.orange),
                const SizedBox(width: 8),
                Text(item, style: AppTextStyles.body2.copyWith(color: Colors.orange.shade900)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: Colors.grey),
              ),
              onPressed: () => controller.saveProgress(),
              child: const Text('Save Progress', style: TextStyle(color: Colors.black87, fontSize: 16)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => controller.submitInstallation(),
              child: const Text('Submit Available', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
