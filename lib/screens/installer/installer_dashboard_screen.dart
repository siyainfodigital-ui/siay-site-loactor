import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../../app/controllers/installer_dashboard_controller.dart';
import '../../app/controllers/auth_controller.dart';
import '../../app/models/customer_model.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_theme.dart';
import '../../app/constants/app_strings.dart';
import 'package:share_plus/share_plus.dart';
import '../../app/services/offline_sync_service.dart';
import '../../app/widgets/double_back_exit.dart';
import '../../app/utils/launch_utils.dart';

class InstallerDashboardScreen extends StatelessWidget {
  const InstallerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<InstallerDashboardController>();
    final authCtrl = Get.find<AuthController>();
    final syncService = OfflineSyncService.to;

    return DoubleBackExit(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
        title: Text(AppStrings.installerDashboard,
            style: AppTextStyles.onPrimary.copyWith(fontSize: 16)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: ctrl.loadSites,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: authCtrl.logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Obx(() {
            if (!syncService.isOnline.value) {
              return Container(
                color: AppColors.error,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Offline Mode - Working Offline / ऑफलाइन मोड',
                      style: AppTextStyles.caption.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          _SyncStatusCard(),
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value) {
                return _LoadingState();
              }
              return RefreshIndicator(
                onRefresh: ctrl.loadSites,
                color: AppColors.primary,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Stats header
                    SliverToBoxAdapter(
                      child: _InstallerHeader(ctrl: ctrl)
                          .animate()
                          .fadeIn(duration: 400.ms),
                    ),

                    // Status filter
                    SliverToBoxAdapter(
                      child: _FilterBar(ctrl: ctrl)
                          .animate(delay: 100.ms)
                          .fadeIn(duration: 300.ms),
                    ),

                    // Sites list
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                      sliver: ctrl.filteredSites.isEmpty
                          ? SliverToBoxAdapter(child: _EmptyState())
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (ctx, i) => _SiteCard(
                                  customer: ctrl.filteredSites[i],
                                  ctrl: ctrl,
                                )
                                    .animate(
                                        delay: Duration(milliseconds: 50 * i))
                                    .slideY(begin: 0.1, end: 0)
                                    .fade(),
                                childCount: ctrl.filteredSites.length,
                              ),
                            ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    ));
  }
}

class _SyncStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final syncService = OfflineSyncService.to;
    return Obx(() {
      final pending = syncService.pendingCount.value;
      final syncing = syncService.isSyncing.value;
      final progress = syncService.syncProgress.value;

      if (pending == 0 && !syncing) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      syncing ? Icons.sync_rounded : Icons.cloud_queue_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      syncing
                          ? 'Syncing data... / सिंक होत आहे'
                          : '$pending pending sync items / प्रलंबित डेटा',
                      style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (!syncing && syncService.isOnline.value)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: syncService.syncPendingData,
                    icon: const Icon(Icons.sync_rounded, size: 16),
                    label: const Text('Sync Now', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
            if (syncing) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress * 100).toStringAsFixed(0)}% completed',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _InstallerHeader extends StatelessWidget {
  final InstallerDashboardController ctrl;
  const _InstallerHeader({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.solarGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.engineering_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Sites / माझ्या साइट्स',
                        style: AppTextStyles.heading3
                            .copyWith(color: Colors.white)),
                    Text('${ctrl.totalInstallationsCount} sites assigned',
                        style: AppTextStyles.body2
                            .copyWith(color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniStat('Pending', ctrl.pendingCount, AppColors.warning),
              _MiniStat('Submitted', ctrl.submittedCount, const Color(0xFF64B5F6)),
              _MiniStat('Approved', ctrl.approvedCount, const Color(0xFF81C784)),
              _MiniStat('Rejected', ctrl.rejectedCount, const Color(0xFFE57373)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value.toString(),
              style: AppTextStyles.heading3
                  .copyWith(color: color, fontWeight: FontWeight.w800)),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final InstallerDashboardController ctrl;
  const _FilterBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _Chip('All', '', ctrl),
            const SizedBox(width: 8),
            _Chip('Pending', 'P', ctrl),
            const SizedBox(width: 8),
            _Chip('Visited', 'V', ctrl),
            const SizedBox(width: 8),
            _Chip('Done', 'D', ctrl),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final InstallerDashboardController ctrl;
  const _Chip(this.label, this.value, this.ctrl);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isSelected = ctrl.filterStatus.value == value;
      final color = value == 'P'
          ? AppColors.statusPending
          : value == 'V'
              ? AppColors.statusVisited
              : value == 'D'
                  ? AppColors.statusDone
                  : AppColors.primary;

      return GestureDetector(
        onTap: () => ctrl.filterStatus.value = value,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isSelected ? color : color.withOpacity(0.3)),
          ),
          child: Text(label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w600,
              )),
        ),
      );
    });
  }
}

class _SiteCard extends StatelessWidget {
  final CustomerModel customer;
  final InstallerDashboardController ctrl;

  const _SiteCard({required this.customer, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    Color statusColor = AppColors.statusPending;
    if (customer.status == 'V') statusColor = AppColors.statusVisited;
    if (customer.status == 'D') statusColor = AppColors.statusDone;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Push SiteVisit with customer arg
          Get.toNamed(AppRoutes.siteVisit, arguments: customer);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primarySurface,
                    child: Text(
                      customer.name[0].toUpperCase(),
                      style: AppTextStyles.body1.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customer.name,
                            style: AppTextStyles.body1
                                .copyWith(fontWeight: FontWeight.w600)),
                        GestureDetector(
                          onTap: () => LaunchUtils.makePhoneCall(customer.mobile),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone, size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(customer.mobile,
                                  style: AppTextStyles.caption
                                      .copyWith(color: AppColors.primary, decoration: TextDecoration.underline)),
                            ],
                          ),
                        ),
                        if (customer.consumerNo != null && customer.consumerNo!.isNotEmpty)
                          Text('Consumer: ${customer.consumerNo}',
                              style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                        if (customer.customerId != null && customer.customerId!.isNotEmpty)
                          Text('ID: ${customer.customerId}',
                              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: statusColor.withOpacity(0.5)),
                        ),
                        child: Text(customer.status,
                            style: AppTextStyles.caption.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w700)),
                      ),
                      if (customer.syncStatus != 'synced') ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: customer.syncStatus == 'failed'
                                ? AppColors.error.withOpacity(0.12)
                                : AppColors.warning.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: customer.syncStatus == 'failed'
                                    ? AppColors.error.withOpacity(0.5)
                                    : AppColors.warning.withOpacity(0.5)),
                          ),
                          child: Text(
                            customer.syncStatus == 'failed' ? 'Failed Sync' : 'Pending Sync',
                            style: AppTextStyles.caption.copyWith(
                                fontSize: 10,
                                color: customer.syncStatus == 'failed'
                                    ? AppColors.error
                                    : AppColors.warning,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Address
              Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      customer.address ??
                          '${customer.village ?? '--'}, ${customer.taluka ?? '--'}',
                      style: AppTextStyles.caption,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Distance + actions row
              Row(
                children: [
                  // Distance badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.secondarySurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.near_me_rounded,
                            size: 12, color: AppColors.secondary),
                        const SizedBox(width: 4),
                        Text(ctrl.distanceTo(customer),
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.secondary)),
                      ],
                    ),
                  ),
                             // Share button
                  IconButton(
                    onPressed: () => _shareCustomerDetails(customer),
                    icon: const Icon(Icons.share_rounded, color: AppColors.accent, size: 20),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),

                  // Navigate button
                  if (customer.hasLocation) ...[
                    ElevatedButton.icon(
                      onPressed: () => ctrl.openNavigation(customer),
                      icon: const Icon(Icons.navigation_rounded,
                          size: 16, color: Colors.white),
                      label: Text('Navigate',
                          style: AppTextStyles.caption
                              .copyWith(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Visit button
                  ElevatedButton.icon(
                    onPressed: () =>
                        Get.toNamed(AppRoutes.siteVisit, arguments: customer),
                    icon: const Icon(Icons.camera_alt_rounded,
                        size: 16, color: Colors.white),
                    label: Text('Visit',
                        style: AppTextStyles.caption
                            .copyWith(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(0, 34),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareCustomerDetails(CustomerModel customer) {
    final Map<String, String> statusLabels = {
      'P': 'Pending / प्रलंबित',
      'V': 'Visited / भेट दिली',
      'D': 'Done / पूर्ण',
    };
    final statusStr = statusLabels[customer.status] ?? customer.status;

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('☀️ *Siya Site Locator - Customer Details* ☀️');
    buffer.writeln('---------------------------------------');
    if (customer.customerId != null && customer.customerId!.isNotEmpty) {
      buffer.writeln('🔹 *Customer ID:* ${customer.customerId}');
    }
    buffer.writeln('👤 *Name:* ${customer.name}');
    buffer.writeln('📱 *Mobile:* ${customer.mobile}');
    if (customer.consumerNo != null && customer.consumerNo!.isNotEmpty) {
      buffer.writeln('🔌 *Consumer No:* ${customer.consumerNo}');
    }
    if (customer.village != null && customer.village!.isNotEmpty) {
      buffer.writeln('🏡 *Village:* ${customer.village}');
    }
    if (customer.taluka != null && customer.taluka!.isNotEmpty) {
      buffer.writeln('📍 *Taluka:* ${customer.taluka}');
    }
    if (customer.address != null && customer.address!.isNotEmpty) {
      buffer.writeln('📝 *Address:* ${customer.address}');
    }
    if (customer.solarKw != null) {
      buffer.writeln('⚡ *Capacity:* ${customer.solarKw} kW');
    }
    buffer.writeln('🔄 *Status:* $statusStr');

    if (customer.hasLocation) {
      buffer.writeln('\n🌐 *GPS Location:*');
      buffer.writeln('Latitude: ${customer.lat}');
      buffer.writeln('Longitude: ${customer.lng}');
      buffer.writeln('🗺️ *Google Maps Link:*');
      buffer.writeln('https://www.google.com/maps/search/?api=1&query=${customer.lat},${customer.lng}');
    }

    if (customer.photoUrl != null && customer.photoUrl!.isNotEmpty) {
      buffer.writeln('\n📸 *Site Photo:*');
      buffer.writeln(customer.photoUrl);
    }

    Share.share(buffer.toString());
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            const Icon(Icons.construction_rounded,
                size: 72, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(AppStrings.noSitesAssigned,
                style: AppTextStyles.heading3),
            const SizedBox(height: 8),
            Text('Pull down to refresh', style: AppTextStyles.body2),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
