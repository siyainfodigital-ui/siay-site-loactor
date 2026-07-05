import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/models/log_model.dart';
import '../../app/services/cache_service.dart';
import '../../app/services/supabase_service.dart';
import '../../app/services/offline_sync_service.dart';

class ActivityLogTimeline extends StatelessWidget {
  final String customerId;

  const ActivityLogTimeline({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Activity Logs',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        StreamBuilder(
          // For real-time updates when logs are added locally, we can use an Rx trigger 
          // or just periodically poll. To keep it simple, we use a future builder and 
          // a refresh mechanism. Using Obx with pendingCount to trigger rebuilds is a quick hack.
          stream: Stream.periodic(const Duration(seconds: 2)).asyncMap((_) => _getLogs()),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            
            final logs = snapshot.data as List<LogModel>;
            if (logs.isEmpty) {
              return const Text('No activity logs yet.', style: TextStyle(color: Colors.grey));
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                final isLast = index == logs.length - 1;
                return _buildLogItem(log, isLast);
              },
            );
          },
        ),
      ],
    );
  }

  Future<List<LogModel>> _getLogs() async {
    // Merge local logs and online logs
    final localLogMaps = CacheService.getLogs(customerId);
    final localLogs = localLogMaps.map((e) => LogModel.fromJson(e)).toList();

    if (OfflineSyncService.to.isOnline.value) {
      try {
        final onlineLogs = await SupabaseService.getLogs(customerId);
        // Deduplicate using id or action/timestamp
        final merged = <LogModel>[];
        merged.addAll(onlineLogs);
        for (var local in localLogs) {
          if (!merged.any((online) => online.offlineId == local.offlineId)) {
            merged.add(local);
          }
        }
        merged.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
        return merged;
      } catch (e) {
        // Fallback to local
      }
    }
    
    localLogs.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
    return localLogs;
  }

  Widget _buildLogItem(LogModel log, bool isLast) {
    final timeStr = log.createdAt != null 
        ? DateFormat('hh:mm a').format(log.createdAt!) 
        : 'Pending';
        
    final dateStr = log.createdAt != null 
        ? DateFormat('dd MMM').format(log.createdAt!) 
        : '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Colors.blue.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                log.action,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                '$dateStr - $timeStr • ${log.userName}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
