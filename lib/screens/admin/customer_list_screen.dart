import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../../app/controllers/customer_controller.dart';
import '../../app/models/customer_model.dart';
import '../../app/utils/launch_utils.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_theme.dart';
import '../../app/constants/app_strings.dart';
import '../../app/services/location_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/widgets/global_image_viewer.dart';
import '../../app/models/global_image_item.dart';

class CustomerListScreen extends StatelessWidget {
  final bool isVerificationMode;
  const CustomerListScreen({super.key, this.isVerificationMode = false});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CustomerController>();
    // Pre-set filter if navigated from a stat card (e.g., 'P', 'V', 'D', '')
    final String? filterArg = Get.arguments as String?;
    if (filterArg != null) {
      ctrl.filterStatus.value = filterArg;
    }

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
              'Customers (${ctrl.filteredCustomers.length})',
              style: AppTextStyles.onPrimary.copyWith(fontSize: 16),
            )),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: (ModalRoute.of(context)?.canPop ?? false)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              onChanged: (v) => ctrl.searchQuery.value = v,
              decoration: InputDecoration(
                hintText: AppStrings.searchHint,
                prefixIcon:
                    const Icon(Icons.search_rounded, color: AppColors.textHint),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                hintStyle: AppTextStyles.body2,
              ),
              style: AppTextStyles.body1,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (!isVerificationMode) _CustomerListSummary(ctrl: ctrl),
          // Status filter tabs
          if (!isVerificationMode) _StatusFilterBar(ctrl: ctrl),

          // Customer list
          Expanded(
            child: Obx(() {
              if (ctrl.loadingList.value) {
                return _LoadingList();
              }
              
              List<CustomerModel> customers;
              if (isVerificationMode) {
                customers = ctrl.customers.where((c) {
                  final matchesSearch = c.name.toLowerCase().contains(ctrl.searchQuery.value.toLowerCase()) ||
                      c.mobile.contains(ctrl.searchQuery.value) ||
                      (c.consumerNo?.contains(ctrl.searchQuery.value) ?? false);
                  return matchesSearch && c.status == 'P' && ctrl.getCompletedItemsCount(c.id) == 5;
                }).toList();
              } else {
                customers = ctrl.filteredCustomers;
              }

              if (customers.isEmpty) {
                return _EmptyState();
              }
              return RefreshIndicator(
                onRefresh: ctrl.loadCustomers,
                color: AppColors.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: customers.length,
                  itemBuilder: (ctx, i) {
                    final customer = customers[i];
                    return _CustomerCard(
                      customer: customer,
                      ctrl: ctrl,
                      isVerificationMode: isVerificationMode,
                    )
                      .animate(delay: Duration(milliseconds: 30 * i))
                      .slideX(begin: 0.05, end: 0)
                      .fade();
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: isVerificationMode ? null : FloatingActionButton(
        heroTag: 'customer_add_fab',
        onPressed: () {
          ctrl.clearForm();
          Get.toNamed(AppRoutes.addCustomer);
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
    );
  }
}

class _CustomerListSummary extends StatelessWidget {
  final CustomerController ctrl;
  const _CustomerListSummary({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final total = ctrl.customers.length;
      final pending = ctrl.customers.where((c) => c.status != 'V' && c.status != 'D' && ctrl.getCompletedItemsCount(c.id) < 5).length;
      final ready = ctrl.customers.where((c) => c.status == 'P' && ctrl.getCompletedItemsCount(c.id) == 5).length;
      final verified = ctrl.customers.where((c) => c.status == 'V' || c.status == 'D').length;

      return Container(
        padding: const EdgeInsets.all(16),
        color: AppColors.primarySurface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _SummaryStat(label: 'Total', count: total, color: AppColors.primary),
            _SummaryStat(label: 'Pending\nItems', count: pending, color: Colors.orange),
            _SummaryStat(label: 'Ready for\nVerify', count: ready, color: Colors.blue),
            _SummaryStat(label: 'Verified', count: verified, color: AppColors.statusDone),
          ],
        ),
      );
    });
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryStat({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(count.toString(), style: AppTextStyles.heading2.copyWith(color: color)),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  final CustomerController ctrl;
  const _StatusFilterBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
                label: 'All Customers', value: '', ctrl: ctrl),
            const SizedBox(width: 8),
            _FilterChip(
                label: 'Pending Photos',
                value: 'PendingPhotos',
                color: Colors.orange,
                ctrl: ctrl),
            const SizedBox(width: 8),
            _FilterChip(
                label: 'Submitted',
                value: 'S',
                color: Colors.blue,
                ctrl: ctrl),
            const SizedBox(width: 8),
            _FilterChip(
                label: 'Verified',
                value: 'V',
                color: AppColors.statusVisited,
                ctrl: ctrl),
            const SizedBox(width: 8),
            _FilterChip(
                label: 'Completed',
                value: 'Completed',
                color: AppColors.statusDone,
                ctrl: ctrl),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final CustomerController ctrl;

  const _FilterChip({
    required this.label,
    required this.value,
    this.color = AppColors.primary,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isSelected = ctrl.filterStatus.value == value;
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
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    });
  }
}

class _CustomerCard extends StatelessWidget {
  final CustomerModel customer;
  final CustomerController ctrl;
  final bool isVerificationMode;

  const _CustomerCard({required this.customer, required this.ctrl, this.isVerificationMode = false});

  @override
  Widget build(BuildContext context) {
    Color statusColor = AppColors.statusPending;
    String statusLabel = 'P';
    if (customer.status == 'V') {
      statusColor = AppColors.statusVisited;
      statusLabel = 'V';
    }
    if (customer.status == 'D') {
      statusColor = AppColors.statusDone;
      statusLabel = 'D';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          ctrl.prepareEdit(customer);
          Get.toNamed(AppRoutes.addCustomer);
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
                      (customer.name.isNotEmpty)
                          ? customer.name[0].toUpperCase()
                          : 'C',
                      style: AppTextStyles.body1.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Info
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
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primary, decoration: TextDecoration.underline)),
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

                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Text(statusLabel,
                        style: AppTextStyles.caption.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Installation Progress
              _InstallationProgressIndicator(customer: customer, ctrl: ctrl),
              const SizedBox(height: 10),

              // Address row
              Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      (customer.address != null && customer.address!.trim().isNotEmpty)
                          ? customer.address!
                          : '${customer.village ?? '--'}, ${customer.taluka ?? '--'}',
                      style: AppTextStyles.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (customer.solarKw != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.solar_power_rounded,
                        size: 14, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text('${customer.solarKw} kW',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.accent)),
                  ],
                ],
              ),

              if (customer.installer != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.engineering_rounded,
                        size: 14, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text('Installer: ${customer.installer}',
                        style: AppTextStyles.caption),
                  ],
                ),
              ],

              const SizedBox(height: 10),

              // Action buttons
              if (isVerificationMode) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.toNamed(AppRoutes.adminVerification, arguments: customer),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('View Details'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Get.toNamed(AppRoutes.adminPhotos, arguments: customer),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('View Photos'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: _SmallBtn(
                        icon: Icons.person_rounded,
                        label: 'Assign',
                        onTap: () => _showAssignDialog(context, ctrl, customer),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SmallBtn(
                        icon: Icons.swap_horiz_rounded,
                        label: 'Status',
                        onTap: () =>
                            _showStatusDialog(context, ctrl, customer),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (customer.hasLocation) ...[
                      _SmallIconBtn(
                        icon: Icons.navigation_rounded,
                        color: AppColors.secondary,
                        onTap: () => LocationService.openNavigation(customer.lat!, customer.lng!),
                      ),
                      const SizedBox(width: 8),
                    ],
                    _SmallIconBtn(
                      icon: Icons.share_rounded,
                      color: AppColors.accent,
                      onTap: () => _shareCustomerDetails(customer),
                    ),
                    const SizedBox(width: 8),
                    _SmallIconBtn(
                      icon: Icons.delete_outline_rounded,
                      color: AppColors.error,
                      onTap: () => _showDeleteConfirmation(context, ctrl, customer),
                    ),
                  ],
                ),
              ],
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



  void _showDeleteConfirmation(
      BuildContext ctx, CustomerController ctrl, CustomerModel c) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Customer? / ग्राहक हटवा?'),
        content: Text('Are you sure you want to delete "${c.name}"?\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel / रद्द करा'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              ctrl.deleteCustomer(c.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete / हटवा', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(
      BuildContext ctx, CustomerController ctrl, CustomerModel c) {
    String? selectedInstallerEmail;
    
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.assignInstaller,
                    style: AppTextStyles.heading3),
                const SizedBox(height: 16),
                Obx(() {
                  if (ctrl.installersList.isEmpty) {
                    return const Text('No installers available. Please add an installer first.');
                  }
                  
                  return DropdownButtonFormField<String>(
                    value: selectedInstallerEmail,
                    decoration: const InputDecoration(
                      labelText: 'Select Installer / इन्स्टॉलर निवडा',
                      prefixIcon: Icon(Icons.engineering_rounded),
                    ),
                    items: ctrl.installersList.map((u) {
                      final email = u['email'] as String? ?? '';
                      final meta = u['raw_user_meta_data'] as Map? ?? {};
                      final name = meta['name'] as String? ?? email;
                      return DropdownMenuItem<String>(
                        value: email,
                        child: Text(name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedInstallerEmail = val;
                      });
                    },
                  );
                }),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (selectedInstallerEmail != null && selectedInstallerEmail!.isNotEmpty) {
                      Get.back();
                      ctrl.assignInstaller(c.id, selectedInstallerEmail!);
                    } else {
                      Get.snackbar('Error', 'Please select an installer', snackPosition: SnackPosition.BOTTOM);
                    }
                  },
                  child: Text(AppStrings.assignInstaller,
                      style: AppTextStyles.buttonText),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showStatusDialog(
      BuildContext ctx, CustomerController ctrl, CustomerModel c) {
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Update Status / स्थिती बदला',
                style: AppTextStyles.heading3),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatusBtn(
                    label: 'Pending (P)',
                    color: AppColors.statusPending,
                    onTap: () {
                      Get.back();
                      ctrl.updateStatus(c.id, 'P');
                    }),
                const SizedBox(width: 8),
                _StatusBtn(
                    label: 'Visited (V)',
                    color: AppColors.statusVisited,
                    onTap: () {
                      Get.back();
                      ctrl.updateStatus(c.id, 'V');
                    }),
                const SizedBox(width: 8),
                _StatusBtn(
                    label: 'Done (D)',
                    color: AppColors.statusDone,
                    onTap: () {
                      Get.back();
                      ctrl.updateStatus(c.id, 'D');
                    }),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SmallBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _SmallIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SmallIconBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

class _StatusBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _StatusBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size(0, 44),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label,
            style: AppTextStyles.caption
                .copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline_rounded,
              size: 72, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('No customers found', style: AppTextStyles.heading3),
          Text('ग्राहक सापडले नाहीत', style: AppTextStyles.body2),
        ],
      ),
    );
  }
}

class _InstallationProgressIndicator extends StatelessWidget {
  final CustomerModel customer;
  final CustomerController ctrl;

  const _InstallationProgressIndicator({required this.customer, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final completedCount = ctrl.getCompletedItemsCount(customer.id);
      final isComplete = completedCount == 5;
      final isVerified = customer.status == 'V' || customer.status == 'D';
      final pendingItems = ctrl.getPendingItemsList(customer.id);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progress', style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isVerified ? AppColors.statusDone.withOpacity(0.1) : (isComplete ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isVerified ? AppColors.statusDone : (isComplete ? Colors.blue : Colors.orange).withOpacity(0.5)),
                ),
                child: Text(
                  isVerified ? 'Verified' : (isComplete ? 'Ready for Verify' : 'In Progress'),
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isVerified ? AppColors.statusDone : (isComplete ? Colors.blue : Colors.orange),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${isComplete ? "5 / 5 Completed" : "$completedCount / 5 Completed"}', 
            style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.bold, color: isComplete ? AppColors.statusDone : AppColors.textPrimary)),
          
          if (!isComplete && pendingItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Pending:', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.error)),
            const SizedBox(height: 4),
            ...pendingItems.take(3).map((item) => Row(
              children: [
                const Icon(Icons.circle, size: 6, color: AppColors.error),
                const SizedBox(width: 6),
                Expanded(child: Text(item, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            )),
            if (pendingItems.length > 3)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 2),
                child: Text('+ ${pendingItems.length - 3} more items', style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic)),
              ),
          ],
        ],
      );
    });
  }
}
