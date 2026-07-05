import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/controllers/reports_controller.dart';
import '../../app/theme/app_theme.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(ReportsController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Reports / अहवाल', style: AppTextStyles.onPrimary.copyWith(fontSize: 16)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: ctrl.loadReports,
          ),
        ],
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        
        return RefreshIndicator(
          onRefresh: ctrl.loadReports,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummaryCard(ctrl),
                const SizedBox(height: 24),
                
                // Export Button
                ElevatedButton.icon(
                  onPressed: ctrl.isExporting.value ? null : ctrl.exportCsv,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 56), // Ensure it spans full width
                  ),
                  icon: ctrl.isExporting.value 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.download_rounded, color: Colors.white),
                  label: Text(
                    ctrl.isExporting.value ? 'Exporting...' : 'Export All Data to CSV',
                    style: AppTextStyles.buttonText,
                  ),
                ),
                
                const SizedBox(height: 24),
                _buildInfoSection(),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSummaryCard(ReportsController ctrl) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Overall Summary', style: AppTextStyles.heading3),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildMetricTile('Total\nCustomers', ctrl.totalCustomers.value, Colors.blueGrey)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricTile('Pending', ctrl.pendingCount.value, AppColors.statusPending)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetricTile('Submitted', ctrl.submittedCount.value, Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricTile('Verified', ctrl.verifiedCount.value, AppColors.statusVisited)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetricTile('Rejected', ctrl.rejectedCount.value, AppColors.error)),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()), // Empty slot for balance
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value.toString(),
            style: AppTextStyles.heading2.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: color.withOpacity(0.8), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'The CSV export includes all customer data along with their current verification status. You can open the exported file in Excel or Google Sheets.',
              style: AppTextStyles.body2.copyWith(color: Colors.blue.shade900),
            ),
          ),
        ],
      ),
    );
  }
}
