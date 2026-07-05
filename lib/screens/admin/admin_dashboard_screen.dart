import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../../app/controllers/admin_dashboard_controller.dart';
import '../../app/routes/app_routes.dart';
import '../../app/models/customer_model.dart';
import '../../app/models/installation_model.dart';
import '../../app/theme/app_theme.dart';
import '../shared/activity_log_timeline.dart';
import '../../app/widgets/global_image_thumbnail.dart';
import '../../app/models/global_image_item.dart';
import '../../app/widgets/global_image_viewer.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AdminDashboardController>();
    const Color primaryGreen = Color(0xFF4CAF50);
    const Color bgLight = Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.solarGradient,
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
            actions: [
              IconButton(icon: const Icon(Icons.notifications_none, color: Colors.white), onPressed: () {}),
              IconButton(icon: const Icon(Icons.person_outline, color: Colors.white), onPressed: () {}),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: ctrl.loadDashboard,
        color: primaryGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSyncStatusBanner(ctrl),
                    const SizedBox(height: 16),
                    _buildNotificationsSection(ctrl),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Dashboard Summary'),
                    _buildSummaryCards(ctrl),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Quick Actions'),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Pending Work (Needs Attention)'),
                    _buildPendingWork(ctrl, primaryGreen),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Recent Installations'),
                    _buildRecentInstallations(ctrl, primaryGreen),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Installer Performance'),
                    _buildInstallerPerformance(ctrl, primaryGreen),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Recent Activity'),
                    _buildRecentActivity(ctrl),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Search & Filter Customers'),
                    _buildSearchBox(ctrl),
                    const SizedBox(height: 12),
                    _buildFilterChips(ctrl),
                    const SizedBox(height: 20),
                    _buildCustomerListPreview(ctrl, primaryGreen),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
    );
  }

  Widget _buildSyncStatusBanner(AdminDashboardController ctrl) {
    return Obx(() {
      final isOnline = ctrl.isOnline.value;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isOnline ? Colors.green.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isOnline ? Colors.green.shade200 : Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(isOnline ? Icons.cloud_done : Icons.cloud_off, color: isOnline ? Colors.green : Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isOnline ? 'System Online' : 'System Offline', style: TextStyle(fontWeight: FontWeight.bold, color: isOnline ? Colors.green.shade800 : Colors.red.shade800)),
                  Text('Pending Sync: ${ctrl.pendingSyncCount.value} | Last Sync: ${ctrl.lastSyncTime.value}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: isOnline ? Colors.green : Colors.red,
                side: BorderSide(color: isOnline ? Colors.green : Colors.red),
              ),
              child: const Text('Sync Now'),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildNotificationsSection(AdminDashboardController ctrl) {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.blue.shade100)),
      child: const ListTile(
        leading: Icon(Icons.info_outline, color: Colors.blue),
        title: Text('New installation submitted by Rajesh Kumar'),
        subtitle: Text('Tap to review application #APP-9932'),
        trailing: Icon(Icons.chevron_right, color: Colors.blue),
      ),
    );
  }

  Widget _buildSummaryCards(AdminDashboardController ctrl) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        double spacing = 12;
        double itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;
        
        return Obx(() => Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(width: itemWidth, child: _buildStatCard('Total Customers', ctrl.totalCustomers.value, Icons.group, AppColors.primarySurface, AppColors.primary, () => ctrl.setFilter('All'))),
            SizedBox(width: itemWidth, child: _buildStatCard('New Customers', ctrl.newCustomersCount.value, Icons.person_add, Colors.teal.shade50, Colors.teal, () => ctrl.setFilter('All'))),
            SizedBox(width: itemWidth, child: _buildStatCard('In Progress', ctrl.inProgressCount.value, Icons.pending_actions, Colors.orange.shade50, Colors.orange, () => ctrl.setFilter('Pending'))),
            SizedBox(width: itemWidth, child: _buildStatCard('Pending Photos', ctrl.pendingPhotosCount.value, Icons.add_a_photo, Colors.purple.shade50, Colors.purple, () => ctrl.setFilter('Pending'))),
            SizedBox(width: itemWidth, child: _buildStatCard('Submitted for Verification', ctrl.readyForVerificationCount.value, Icons.upload_file, Colors.blue.shade50, Colors.blue, () => ctrl.setFilter('Submitted'))),
            SizedBox(width: itemWidth, child: _buildStatCard('Verified', ctrl.verifiedCount.value, Icons.verified, Colors.green.shade50, Colors.green, () => ctrl.setFilter('Verified'))),
            SizedBox(width: itemWidth, child: _buildStatCard('Rejected', ctrl.rejectedCount.value, Icons.cancel, Colors.red.shade50, Colors.red, () => ctrl.setFilter('Rejected'))),
            SizedBox(width: itemWidth, child: _buildStatCard('Active Installers', ctrl.installerStats.length, Icons.engineering, Colors.indigo.shade50, Colors.indigo, null)),
          ],
        ));
      },
    );
  }

  Widget _buildStatCard(String label, int count, IconData icon, Color bgColor, Color iconColor, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                if (onTap != null) const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 16),
            Text(count.toString(), style: AppTextStyles.heading2.copyWith(fontSize: 24)),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.body2, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildActionBtn('Add Customer', Icons.person_add, () => Get.toNamed(AppRoutes.addCustomer)),
        _buildActionBtn('Bulk Upload', Icons.upload_file, () => Get.toNamed(AppRoutes.bulkUpload)),
        _buildActionBtn('Add Installer', Icons.person_add_alt_1, () {}),
        _buildActionBtn('Manage Installers', Icons.engineering, () => Get.toNamed(AppRoutes.installerManage)),
        _buildActionBtn('Verification Queue', Icons.fact_check, () {}),
        _buildActionBtn('Reports', Icons.analytics, () {}),
      ],
    );
  }

  Widget _buildActionBtn(String label, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 110,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5)],
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label, 
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, height: 1.1)),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingWork(AdminDashboardController ctrl, Color primaryGreen) {
    return Obx(() {
      final pendingInstallations = ctrl.recentInstallations.where((i) => i.verificationStatus == 'S').take(3).toList();
      if (pendingInstallations.isEmpty) {
        return const Padding(padding: EdgeInsets.all(16), child: Text('No pending work!'));
      }
      return Column(
        children: pendingInstallations.map((inst) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              title: Text('App No: ${inst.customerId}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Status: Submitted\nSubmitted Date: ${inst.verifiedAt != null ? inst.verifiedAt.toString() : 'Today'}'),
              trailing: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                child: const Text('Review'),
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildRecentInstallations(AdminDashboardController ctrl, Color primaryGreen) {
    return Obx(() {
      final recent = ctrl.recentInstallations.take(3).toList();
      if (recent.isEmpty) {
        return const Padding(padding: EdgeInsets.all(16), child: Text('No recent installations.'));
      }
      return Column(
        children: recent.map((inst) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: const CircleAvatar(backgroundColor: AppColors.primarySurface, child: Icon(Icons.solar_power, color: AppColors.primary)),
              title: Text('Customer ID: ${inst.customerId}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Status: ${inst.verificationStatus}\nSubmission Time: ${inst.verifiedAt != null ? inst.verifiedAt.toString() : 'Unknown'}'),
              trailing: OutlinedButton(
                onPressed: () {},
                child: const Text('Open'),
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildInstallerPerformance(AdminDashboardController ctrl, Color primaryGreen) {
    return Obx(() {
      final installers = ctrl.installerStats.take(3).toList();
      if (installers.isEmpty) {
        return const Padding(padding: EdgeInsets.all(16), child: Text('No installer data.'));
      }
      return Column(
        children: installers.map((inst) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(inst.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      TextButton(onPressed: () {}, child: const Text('View Details')),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPerfStat('Assigned', inst.assignedCount.toString()),
                      _buildPerfStat('Pending', inst.pendingCount.toString()),
                      _buildPerfStat('Completed', inst.doneCount.toString()),
                    ],
                  )
                ],
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildPerfStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildRecentActivity(AdminDashboardController ctrl) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          const ActivityLogTimeline(customerId: 'ALL_RECENT'), // Mocking global timeline
          TextButton(onPressed: () {}, child: const Text('View All Logs')),
        ],
      ),
    );
  }

  Widget _buildSearchBox(AdminDashboardController ctrl) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search Name, Mobile, App No, Village...',
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        onSubmitted: (val) => ctrl.setSearchQuery(val),
      ),
    );
  }

  Widget _buildFilterChips(AdminDashboardController ctrl) {
    final filters = ['All Customers', 'Pending', 'In Progress', 'Submitted', 'Verified', 'Rejected'];
    return Obx(() => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((f) {
          final isSelected = ctrl.activeFilter.value == f || (ctrl.activeFilter.value == 'All' && f == 'All Customers');
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ChoiceChip(
              label: Text(f),
              selected: isSelected,
              onSelected: (_) {
                if (f == 'All Customers') ctrl.setFilter('All');
                else ctrl.setFilter(f);
              },
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isSelected ? AppColors.primary : AppColors.divider),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    ));
  }

  Widget _buildCustomerListPreview(AdminDashboardController ctrl, Color primaryGreen) {
    return Obx(() {
      if (ctrl.isLoading.value) return _buildShimmerLoading();
      if (ctrl.dashboardCustomers.isEmpty) {
        return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('No customers found.')));
      }
      
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: ctrl.dashboardCustomers.length + (ctrl.hasMore.value ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == ctrl.dashboardCustomers.length) {
            return Center(
              child: TextButton(
                onPressed: ctrl.loadMoreCustomers,
                child: ctrl.isLoadingMore.value ? const CircularProgressIndicator() : const Text('Load More'),
              ),
            );
          }
          final customer = ctrl.dashboardCustomers[index];
          final installation = ctrl.getInstallationForCustomer(customer.id);
          return _buildCustomerCard(customer, installation, primaryGreen);
        },
      );
    });
  }

  Widget _buildCustomerCard(CustomerModel customer, InstallationModel? installation, Color primaryGreen) {
    int photosCompleted = 0;
    int pendingItems = 0;
    if (installation != null) {
      if (installation.structurePhotoStatus == 'A' || installation.structurePhotoStatus == 'V') photosCompleted++; else if (installation.structurePhotoStatus == 'P') pendingItems++;
      if (installation.panelPhotoStatus == 'A' || installation.panelPhotoStatus == 'V') photosCompleted++; else if (installation.panelPhotoStatus == 'P') pendingItems++;
      if (installation.inverterPhotoStatus == 'A' || installation.inverterPhotoStatus == 'V') photosCompleted++; else if (installation.inverterPhotoStatus == 'P') pendingItems++;
      if (installation.meterPhotoStatus == 'A' || installation.meterPhotoStatus == 'V') photosCompleted++; else if (installation.meterPhotoStatus == 'P') pendingItems++;
      if (installation.finalPhotoStatus == 'A' || installation.finalPhotoStatus == 'V') photosCompleted++; else if (installation.finalPhotoStatus == 'P') pendingItems++;
      if (installation.inverterBrand == null || installation.inverterBrand!.isEmpty) pendingItems++;
      if (installation.inverterSerial == null || installation.inverterSerial!.isEmpty) pendingItems++;
      if (installation.generationMeterNo == null || installation.generationMeterNo!.isEmpty) pendingItems++;
    } else {
      pendingItems = 8;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name, style: AppTextStyles.heading3),
                    const SizedBox(height: 4),
                    Text('App No: ${customer.consumerNo ?? 'N/A'}', style: AppTextStyles.body2),
                  ],
                ),
              ),
              _buildStatusChip(customer.status, primaryGreen),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 16, color: AppColors.textHint),
              const SizedBox(width: 6),
              Text(customer.mobile, style: AppTextStyles.body2),
              const SizedBox(width: 16),
              const Icon(Icons.engineering_outlined, size: 16, color: AppColors.textHint),
              const SizedBox(width: 6),
              Expanded(child: Text(customer.installer ?? 'Unassigned', style: AppTextStyles.body2, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(8)),
                    child: Text('Progress: $photosCompleted / 5 Photos', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                  if (pendingItems > 0) ...[
                    const SizedBox(height: 6),
                    Text('Pending: $pendingItems Item${pendingItems > 1 ? 's' : ''}', style: AppTextStyles.caption.copyWith(color: AppColors.warning, fontWeight: FontWeight.bold)),
                  ]
                ],
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Get.toNamed(AppRoutes.adminVerification, arguments: customer),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      minimumSize: const Size(80, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('View Details'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Get.toNamed(AppRoutes.adminPhotos, arguments: customer),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(80, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('View Photos'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, Color primaryGreen) {
    String label = 'Pending';
    Color color = AppColors.statusPending;
    Color bgColor = color.withValues(alpha: 0.1);
    
    if (status == 'V') { label = 'Ready'; color = AppColors.info; bgColor = AppColors.secondarySurface; }
    else if (status == 'D') { label = 'Verified'; color = AppColors.success; bgColor = AppColors.primarySurface; }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: List.generate(4, (index) => Container(
          height: 120, width: double.infinity, margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        )),
      ),
    );
  }
}
