import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

class WatermarkService {
  static Future<Uint8List?> addWatermark({
    required Uint8List imageBytes,
    required String customerName,
    required double? lat,
    required double? lng,
  }) async {
    try {
      // Run image processing in isolate to avoid blocking UI
      return await compute(_processWatermark, {
        'bytes': imageBytes,
        'customerName': customerName,
        'lat': lat,
        'lng': lng,
      });
    } catch (e) {
      debugPrint('Error adding watermark: $e');
      return null;
    }
  }

  static Uint8List? _processWatermark(Map<String, dynamic> data) {
    try {
      final Uint8List bytes = data['bytes'];
      final String customerName = data['customerName'];
      final double? lat = data['lat'];
      final double? lng = data['lng'];

      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(now);
      final timeStr = DateFormat('hh:mm a').format(now);
      
      final latStr = lat != null ? lat.toStringAsFixed(6) : 'N/A';
      final lngStr = lng != null ? lng.toStringAsFixed(6) : 'N/A';

      final watermarkText = '''
Customer: $customerName
Date: $dateStr
Time: $timeStr
Lat: $latStr
Lng: $lngStr
''';

      // Load arial font from package
      final font = img.arial48;

      // Draw background rect for text readability
      final textWidth = 600;
      final textHeight = 300;
      final x = 20;
      final y = image.height - textHeight - 20;

      img.fillRect(image,
          x1: x,
          y1: y,
          x2: x + textWidth,
          y2: image.height - 20,
          color: img.ColorRgba8(0, 0, 0, 150));

      img.drawString(image, watermarkText, font: font, x: x + 10, y: y + 10, color: img.ColorRgba8(255, 255, 255, 255));

      return img.encodeJpg(image, quality: 80);
    } catch (e) {
      debugPrint('Compute watermark error: $e');
      return null;
    }
  }
}
