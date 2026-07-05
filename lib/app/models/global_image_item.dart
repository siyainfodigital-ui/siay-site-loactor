import 'dart:typed_data';
import 'dart:ui';

class GlobalImageItem {
  final String? url;
  final Uint8List? memoryBytes;
  final String photoType;
  final String? status; // 'P', 'S', 'V', 'D', 'A', 'R'
  final DateTime? uploadedAt;
  final String? uploadedBy;
  final double? lat;
  final double? lng;
  final String? watermarkInfo;
  
  // Admin Actions
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final Function(String)? onAddRemark;

  GlobalImageItem({
    this.url,
    this.memoryBytes,
    required this.photoType,
    this.status,
    this.uploadedAt,
    this.uploadedBy,
    this.lat,
    this.lng,
    this.watermarkInfo,
    this.onApprove,
    this.onReject,
    this.onAddRemark,
  }) : assert(url != null || memoryBytes != null, 'Either url or memoryBytes must be provided');
}
