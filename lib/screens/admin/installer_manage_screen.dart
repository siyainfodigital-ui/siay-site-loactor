import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../app/services/supabase_service.dart';
import '../../app/theme/app_theme.dart';
import '../../app/constants/app_strings.dart';

class InstallerManageScreen extends StatelessWidget {
  final bool isTab;
  const InstallerManageScreen({super.key, this.isTab = false});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(_InstallerManageController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Installers / इन्स्टॉलर',
            style: AppTextStyles.onPrimary.copyWith(fontSize: 16)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: isTab ? null : IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: ctrl.load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'installer_add_fab',
        onPressed: () => _showAddDialog(context, ctrl),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: Text('Add Installer', style: AppTextStyles.buttonText.copyWith(fontSize: 13)),
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (ctrl.installers.isEmpty) {
          return _EmptyState(onAdd: () => _showAddDialog(context, ctrl));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: ctrl.installers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final item = ctrl.installers[i];
            return _InstallerTile(
              item: item,
              onDelete: () => _confirmDelete(context, ctrl, item),
              onEdit: () => _showEditDialog(context, ctrl, item),
            ).animate(delay: Duration(milliseconds: 60 * i)).slideY(begin: 0.15).fade();
          },
        );
      }),
    );
  }

  // ─── ADD DIALOG ───────────────────────────────────────────
  void _showAddDialog(BuildContext context, _InstallerManageController ctrl) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final obscure = true.obs;

    Get.dialog(
      AlertDialog(
        title: const Text('Add Installer / इन्स्टॉलर जोडा'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogField(controller: nameCtrl, label: 'Full Name / नाव', icon: Icons.person_outline_rounded),
              const SizedBox(height: 12),
              _DialogField(controller: emailCtrl, label: 'Email / ईमेल', icon: Icons.email_outlined,
                  keyboard: TextInputType.emailAddress),
              const SizedBox(height: 12),
              Obx(() => _DialogField(
                    controller: passCtrl,
                    label: 'Password / पासवर्ड',
                    icon: Icons.lock_outline_rounded,
                    obscure: obscure.value,
                    suffix: IconButton(
                      icon: Icon(
                        obscure.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 18,
                        color: AppColors.textHint,
                      ),
                      onPressed: () => obscure.value = !obscure.value,
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          Obx(() => ElevatedButton(
                onPressed: ctrl.isCreating.value
                    ? null
                    : () async {
                        final ok = await ctrl.addInstaller(
                          name: nameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          password: passCtrl.text,
                        );
                        if (ok) Get.back();
                      },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: ctrl.isCreating.value
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Add', style: AppTextStyles.buttonText),
              )),
        ],
      ),
    );
  }

  // ─── EDIT DIALOG ─────────────────────────────────────────
  void _showEditDialog(BuildContext context, _InstallerManageController ctrl, _InstallerItem item) {
    final nameCtrl = TextEditingController(text: item.name);
    Get.dialog(
      AlertDialog(
        title: const Text('Edit Name / नाव बदला'),
        content: _DialogField(controller: nameCtrl, label: 'Full Name / नाव', icon: Icons.person_outline_rounded),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final ok = await ctrl.updateName(item.id, nameCtrl.text.trim());
              if (ok) Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('Save', style: AppTextStyles.buttonText),
          ),
        ],
      ),
    );
  }

  // ─── CONFIRM DELETE ───────────────────────────────────────
  void _confirmDelete(BuildContext context, _InstallerManageController ctrl, _InstallerItem item) {
    Get.dialog(
      AlertDialog(
        title: const Text('Remove Installer?'),
        content: Text(
          'Are you sure you want to remove "${item.displayName}"?\n'
          'Their assigned customers will remain but no longer have an installer.',
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await ctrl.deleteInstaller(item.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── TILE ─────────────────────────────────────────────────
class _InstallerTile extends StatelessWidget {
  final _InstallerItem item;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  const _InstallerTile({required this.item, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.solarGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                item.displayName.isNotEmpty ? item.displayName[0].toUpperCase() : 'I',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.displayName,
                    style: AppTextStyles.heading3.copyWith(fontSize: 15)),
                Text(item.email,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _StatChip(label: '${item.total}', icon: Icons.people_rounded, color: AppColors.primary),
                    const SizedBox(width: 6),
                    _StatChip(label: '${item.pending}P', icon: Icons.pending_actions_rounded, color: const Color(0xFFE67E22)),
                    const SizedBox(width: 6),
                    _StatChip(label: '${item.done}D', icon: Icons.check_circle_rounded, color: AppColors.success),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Column(
            children: [
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: const Icon(Icons.edit_rounded, color: AppColors.secondary, size: 20),
                ),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _StatChip({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.engineering_rounded, size: 56, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text('No Installers Yet', style: AppTextStyles.heading3),
          const SizedBox(height: 6),
          Text('Add an installer to assign customers to them',
              style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.person_add_rounded, color: Colors.white),
            label: Text('Add First Installer', style: AppTextStyles.buttonText),
          ),
        ],
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboard;
  final bool obscure;
  final Widget? suffix;

  const _DialogField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboard,
    this.obscure = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textHint),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

// ─── DATA MODEL ──────────────────────────────────────────
class _InstallerItem {
  final String id;
  final String email;
  final String name;
  final int total;
  final int pending;
  final int done;

  _InstallerItem({
    required this.id,
    required this.email,
    required this.name,
    required this.total,
    required this.pending,
    required this.done,
  });

  String get displayName => name.isNotEmpty ? name : email;
}

// ─── CONTROLLER ──────────────────────────────────────────
class _InstallerManageController extends GetxController {
  final RxList<_InstallerItem> installers = <_InstallerItem>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isCreating = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      // Load all users with role=installer from user_meta + customer stats
      final users = await SupabaseService.getInstallerUsers();
      final stats = await SupabaseService.getInstallerStats();

      // Build stats map keyed by installer email
      final statsMap = <String, Map<String, int>>{};
      for (final s in stats) {
        final key = s['installer'] as String? ?? '';
        statsMap[key] = {
          'total': (s['total'] as int? ?? 0),
          'P': (s['P'] as int? ?? 0),
          'D': (s['D'] as int? ?? 0),
        };
      }

      installers.value = users.map((u) {
        final email = u['email'] as String? ?? '';
        final meta = u['raw_user_meta_data'] as Map? ?? {};
        final st = statsMap[email] ?? {};
        return _InstallerItem(
          id: u['id'] as String? ?? '',
          email: email,
          name: meta['name'] as String? ?? '',
          total: st['total'] ?? 0,
          pending: st['P'] ?? 0,
          done: st['D'] ?? 0,
        );
      }).toList();
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addInstaller({
    required String name,
    required String email,
    required String password,
  }) async {
    if (name.isEmpty) {
      Get.snackbar('Error', 'Please enter a name', snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    if (!GetUtils.isEmail(email)) {
      Get.snackbar('Error', 'Please enter a valid email', snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    if (password.length < 8) {
      Get.snackbar('Error', 'Password must be at least 8 characters', snackPosition: SnackPosition.BOTTOM);
      return false;
    }

    isCreating.value = true;
    try {
      await SupabaseService.createInstallerUser(
          email: email, password: password, name: name);
      await load();
      Get.snackbar('Success', 'Installer "$name" added successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success.withOpacity(0.1));
      return true;
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isCreating.value = false;
    }
  }

  Future<bool> updateName(String userId, String name) async {
    try {
      await SupabaseService.updateInstallerName(userId: userId, name: name);
      await load();
      return true;
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }

  Future<void> deleteInstaller(String userId) async {
    try {
      await SupabaseService.deleteInstallerUser(userId);
      await load();
      Get.snackbar('Removed', 'Installer removed',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }
}
