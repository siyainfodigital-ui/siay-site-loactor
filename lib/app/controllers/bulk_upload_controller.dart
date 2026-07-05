import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import '../services/csv_excel_service.dart';
import '../services/supabase_service.dart';

class BulkUploadController extends GetxController {
  final RxList<Map<String, dynamic>> parsedRows = <Map<String, dynamic>>[].obs;
  final RxList<String> parseErrors = <String>[].obs;
  final RxInt duplicatesRemoved = 0.obs;
  final RxInt totalParsed = 0.obs;
  final RxBool isParsing = false.obs;
  final RxBool isUploading = false.obs;
  final RxBool uploadDone = false.obs;
  final RxString fileName = ''.obs;
  final RxInt uploadedCount = 0.obs;
  final RxDouble uploadProgress = 0.0.obs; // 0.0 to 1.0

  Future<void> pickAndParseFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls'],
      withData: true, // Crucial for Web to read bytes directly
    );

    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) {
      Get.snackbar('Error', 'Could not read file data', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    fileName.value = result.files.first.name;
    isParsing.value = true;
    parsedRows.clear();
    parseErrors.clear();

    try {
      final parseResult = await CsvExcelService.parseFile(bytes, fileName.value);
      parsedRows.value = parseResult.validRows;
      parseErrors.value = parseResult.errors;
      duplicatesRemoved.value = parseResult.duplicatesRemoved;
      totalParsed.value = parseResult.totalParsed;
    } finally {
      isParsing.value = false;
    }
  }

  Future<void> uploadCustomers() async {
    if (parsedRows.isEmpty) return;
    isUploading.value = true;
    uploadProgress.value = 0.0;
    try {
      final list = parsedRows.toList();
      final total = list.length;
      int processed = 0;

      // Filter duplicates first
      final existingMobiles = await SupabaseService.getExistingMobiles();
      final newCustomers = list.where((c) => !existingMobiles.contains(c['mobile'])).toList();

      if (newCustomers.isNotEmpty) {
        // Upload in small batches to report progress
        const batchSize = 10;
        for (int i = 0; i < newCustomers.length; i += batchSize) {
          final batch = newCustomers.sublist(
            i,
            (i + batchSize) > newCustomers.length
                ? newCustomers.length
                : (i + batchSize),
          );
          await SupabaseService.insertBatch(batch);
          processed += batch.length;
          uploadProgress.value = processed / newCustomers.length;
        }
      }

      uploadedCount.value = list.length;
      uploadProgress.value = 1.0;
      uploadDone.value = true;
      Get.snackbar(
        'Upload Complete',
        '${list.length} customers added successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      parsedRows.clear();
    } catch (e) {
      Get.snackbar('Upload Failed', e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isUploading.value = false;
    }
  }

  void reset() {
    parsedRows.clear();
    parseErrors.clear();
    duplicatesRemoved.value = 0;
    totalParsed.value = 0;
    uploadDone.value = false;
    fileName.value = '';
    uploadedCount.value = 0;
    uploadProgress.value = 0.0;
  }
}
