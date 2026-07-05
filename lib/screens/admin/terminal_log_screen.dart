import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../app/services/log_service.dart';

class TerminalLogScreen extends StatelessWidget {
  const TerminalLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logService = Get.find<LogService>();

    return Scaffold(
      backgroundColor: Colors.black, // Terminal black
      appBar: AppBar(
        title: const Text('Terminal Logs', style: TextStyle(fontFamily: 'monospace')),
        backgroundColor: Colors.black,
        foregroundColor: Colors.green, // Terminal green
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.red),
            tooltip: 'Throw Test Error',
            onPressed: () {
              // Simulate an unhandled exception to test the log capture
              throw Exception('Test Unhandled Exception from TerminalLogScreen');
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.green),
            tooltip: 'Copy Logs',
            onPressed: () {
              final allLogs = logService.logs.join('\n');
              Clipboard.setData(ClipboardData(text: allLogs));
              Get.snackbar('Copied', 'Logs copied to clipboard',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green.withValues(alpha: 0.2),
                  colorText: Colors.green);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.green),
            tooltip: 'Clear Logs',
            onPressed: () {
              logService.clearLogs();
            },
          ),
        ],
      ),
      body: Obx(() {
        if (logService.logs.isEmpty) {
          return const Center(
            child: Text(
              'No logs yet. Waiting...',
              style: TextStyle(color: Colors.green, fontFamily: 'monospace'),
            ),
          );
        }
        return ListView.builder(
          reverse: false,
          padding: const EdgeInsets.all(8.0),
          itemCount: logService.logs.length,
          itemBuilder: (context, index) {
            final log = logService.logs[index];
            final isError = log.contains('[ERROR]');
            return Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: SelectableText(
                log,
                style: TextStyle(
                  color: isError ? Colors.redAccent : Colors.greenAccent,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
