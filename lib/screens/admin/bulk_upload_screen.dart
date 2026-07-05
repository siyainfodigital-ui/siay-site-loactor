import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../app/controllers/bulk_upload_controller.dart';
import '../../app/theme/app_theme.dart';
import '../../app/constants/app_strings.dart';

class BulkUploadScreen extends StatelessWidget {
  const BulkUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(BulkUploadController());

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.bulkUpload,
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
        child: Obx(() {
          if (ctrl.uploadDone.value) {
            return _SuccessState(ctrl: ctrl);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instructions card
              _InstructionCard().animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 16),

              // File picker
              _FilePickerCard(ctrl: ctrl)
                  .animate(delay: 100.ms)
                  .fadeIn(duration: 300.ms),

              // Parsed preview
              if (ctrl.parsedRows.isNotEmpty || ctrl.parseErrors.isNotEmpty) ...[
                const SizedBox(height: 16),
                _ParseSummaryCard(ctrl: ctrl)
                    .animate()
                    .slideY(begin: 0.1, end: 0)
                    .fade(),
                const SizedBox(height: 16),
                _PreviewTable(ctrl: ctrl)
                    .animate(delay: 100.ms)
                    .slideY(begin: 0.1, end: 0)
                    .fade(),
                const SizedBox(height: 16),

                // Errors
                if (ctrl.parseErrors.isNotEmpty)
                  _ErrorsCard(ctrl: ctrl)
                      .animate()
                      .fadeIn(duration: 300.ms),
                const SizedBox(height: 20),

                 // Upload button
                if (ctrl.parsedRows.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed:
                            ctrl.isUploading.value ? null : ctrl.uploadCustomers,
                        icon: ctrl.isUploading.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.cloud_upload_rounded,
                                color: Colors.white),
                        label: Text(
                          ctrl.isUploading.value
                              ? 'Uploading / अपलोड होत आहे...'
                              : AppStrings.uploadCustomers,
                          style: AppTextStyles.buttonText,
                        ),
                      ),
                      if (ctrl.isUploading.value) ...[
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
                      ],
                    ],
                  ),
              ],
              const SizedBox(height: 32),
            ],
          );
        }),
      ),
    );
  }
}

class _InstructionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppColors.secondary, size: 18),
              const SizedBox(width: 8),
              Text('File Format / फाईल स्वरूप',
                  style: AppTextStyles.label
                      .copyWith(color: AppColors.secondary)),
            ],
          ),
          const SizedBox(height: 10),
          // Column guide
          _InfoRow(icon: Icons.check_circle_rounded, color: AppColors.error,
              text: 'Name — Customer full name (Required)'),
          _InfoRow(icon: Icons.check_circle_rounded, color: AppColors.error,
              text: 'Mobile — 10-digit mobile number (Required)'),
          _InfoRow(icon: Icons.radio_button_unchecked_rounded, color: AppColors.textHint,
              text: 'Consumer_No — Electricity board consumer number (Optional)'),
          _InfoRow(icon: Icons.radio_button_unchecked_rounded, color: AppColors.textHint,
              text: 'Village, Taluka, Address, Solar_kw — (Optional)'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warning.withOpacity(0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Do NOT add "Customer_Id" column — it is AUTO-GENERATED as SIYA-0001, SIYA-0002... by the system.',
                    style: AppTextStyles.caption.copyWith(color: AppColors.warning),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _InfoRow({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: AppTextStyles.caption.copyWith(height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _FilePickerCard extends StatelessWidget {
  final BulkUploadController ctrl;
  const _FilePickerCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ctrl.isParsing.value ? null : ctrl.pickAndParseFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              ctrl.fileName.value.isNotEmpty
                  ? Icons.description_rounded
                  : Icons.upload_file_rounded,
              size: 52,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              ctrl.isParsing.value
                  ? 'Parsing file... / फाईल वाचत आहे...'
                  : ctrl.fileName.value.isNotEmpty
                      ? ctrl.fileName.value
                      : AppStrings.selectFile,
              style: ctrl.fileName.value.isNotEmpty
                  ? AppTextStyles.body1
                      .copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)
                  : AppTextStyles.body2,
              textAlign: TextAlign.center,
            ),
            if (ctrl.isParsing.value) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(color: AppColors.primary),
            ],
            if (ctrl.fileName.value.isEmpty) ...[
              const SizedBox(height: 8),
              Text('Tap to select CSV or Excel file',
                  style: AppTextStyles.caption),
            ],
          ],
        ),
      ),
    );
  }
}

class _ParseSummaryCard extends StatelessWidget {
  final BulkUploadController ctrl;
  const _ParseSummaryCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          _SummaryItem(
              label: 'Total', value: ctrl.totalParsed.value, color: AppColors.secondary),
          _Divider(),
          _SummaryItem(
              label: 'Valid', value: ctrl.parsedRows.length, color: AppColors.success),
          _Divider(),
          _SummaryItem(
              label: 'Duplicates',
              value: ctrl.duplicatesRemoved.value,
              color: AppColors.warning),
          _Divider(),
          _SummaryItem(
              label: 'Errors',
              value: ctrl.parseErrors.length,
              color: AppColors.error),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _SummaryItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value.toString(),
              style: AppTextStyles.heading3.copyWith(color: color)),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: AppColors.divider);
  }
}

class _PreviewTable extends StatelessWidget {
  final BulkUploadController ctrl;
  const _PreviewTable({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final rows = ctrl.parsedRows.take(10).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview (first ${rows.length} rows) / पूर्वावलोकन',
          style: AppTextStyles.label,
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStatePropertyAll(AppColors.primarySurface),
                columnSpacing: 20,
                dataRowMinHeight: 44,
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Mobile')),
                  DataColumn(label: Text('Consumer No')),
                  DataColumn(label: Text('Village')),
                  DataColumn(label: Text('Taluka')),
                ],
                rows: rows.map((row) {
                  return DataRow(cells: [
                    DataCell(Text(row['name'] ?? '--',
                        style: AppTextStyles.body2)),
                    DataCell(Text(row['mobile'] ?? '--',
                        style: AppTextStyles.body2)),
                    DataCell(Text(row['consumer_no'] ?? '--',
                        style: AppTextStyles.body2)),
                    DataCell(Text(row['village'] ?? '--',
                        style: AppTextStyles.body2)),
                    DataCell(Text(row['taluka'] ?? '--',
                        style: AppTextStyles.body2)),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorsCard extends StatelessWidget {
  final BulkUploadController ctrl;
  const _ErrorsCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.error, size: 18),
              const SizedBox(width: 8),
              Text('Errors / त्रुटी (${ctrl.parseErrors.length})',
                  style: AppTextStyles.label
                      .copyWith(color: AppColors.error)),
            ],
          ),
          const SizedBox(height: 8),
          ...ctrl.parseErrors.take(5).map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $e',
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.error)),
              )),
          if (ctrl.parseErrors.length > 5)
            Text('... and ${ctrl.parseErrors.length - 5} more errors',
                style: AppTextStyles.caption.copyWith(color: AppColors.error)),
        ],
      ),
    );
  }
}

class _SuccessState extends StatelessWidget {
  final BulkUploadController ctrl;
  const _SuccessState({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                size: 60, color: AppColors.success),
          )
              .animate()
              .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.0, 1.0),
                  curve: Curves.elasticOut,
                  duration: 600.ms)
              .fade(),
          const SizedBox(height: 24),
          Text(
            '${ctrl.uploadedCount.value} customers uploaded!',
            style: AppTextStyles.heading3.copyWith(color: AppColors.success),
            textAlign: TextAlign.center,
          ).animate(delay: 300.ms).fadeIn(),
          Text(AppStrings.uploadSuccess,
              style: AppTextStyles.body2).animate(delay: 400.ms).fadeIn(),
          const SizedBox(height: 36),
          ElevatedButton(
            onPressed: () {
              ctrl.reset();
              Get.back();
            },
            child: Text('Done / पूर्ण', style: AppTextStyles.buttonText),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: ctrl.reset,
            child: Text('Upload More / अधिक अपलोड करा',
                style: AppTextStyles.buttonText
                    .copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
