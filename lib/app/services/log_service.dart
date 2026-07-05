import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class LogService extends GetxService {
  final RxList<String> logs = <String>[].obs;
  final int maxLogs = 500;

  void addLog(String message, {bool isError = false}) {
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now());
    final type = isError ? '[ERROR]' : '[INFO]';
    final logEntry = '$timestamp $type: $message';
    
    logs.add(logEntry);
    
    if (logs.length > maxLogs) {
      logs.removeAt(0);
    }
    
    if (kDebugMode) {
      if (isError) {
        debugPrint('\x1B[31m$logEntry\x1B[0m');
      } else {
        debugPrint(logEntry);
      }
    }
  }

  void addError(Object error, StackTrace stackTrace) {
    addLog('Exception: $error\n$stackTrace', isError: true);
  }

  void clearLogs() {
    logs.clear();
  }
}
