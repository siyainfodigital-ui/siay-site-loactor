import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/global_image_item.dart';
import '../theme/app_theme.dart';
import 'global_image_viewer.dart';

class GlobalImageThumbnail extends StatelessWidget {
  final List<GlobalImageItem> images;
  final int currentIndex;
  final double height;
  final double width;
  final BoxFit fit;
  final double borderRadius;

  const GlobalImageThumbnail({
    super.key,
    required this.images,
    required this.currentIndex,
    this.height = 180,
    this.width = double.infinity,
    this.fit = BoxFit.cover,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty || currentIndex < 0 || currentIndex >= images.length) {
      return _buildErrorPlaceholder();
    }

    final item = images[currentIndex];

    return GestureDetector(
      onTap: () {
        Get.to(
          () => GlobalImageViewer(images: images, initialIndex: currentIndex),
          transition: Transition.fadeIn,
          fullscreenDialog: true,
          opaque: false,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            // Base Image
            SizedBox(
              height: height,
              width: width,
              child: _buildImage(item),
            ),
            
            // Gradient Overlay for text readability
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
            ),

            // Eye Icon Center
            Positioned.fill(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.remove_red_eye_rounded, color: Colors.white, size: 28),
                ),
              ),
            ),

            // Bottom Meta Info
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      item.photoType,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (item.status != null) ...[
                    const SizedBox(width: 8),
                    _buildStatusBadge(item.status!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(GlobalImageItem item) {
    if (item.memoryBytes != null) {
      return Image.memory(
        item.memoryBytes!,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
      );
    } else if (item.url != null) {
      return CachedNetworkImage(
        imageUrl: item.url!,
        fit: fit,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(color: Colors.white),
        ),
        errorWidget: (context, url, error) => _buildErrorPlaceholder(),
      );
    }
    return _buildErrorPlaceholder();
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      height: height,
      width: width,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    String label = 'Pending';
    Color color = AppColors.statusPending;

    if (status == 'S') {
      label = 'Submitted';
      color = AppColors.info;
    } else if (status == 'V') {
      label = 'Ready';
      color = AppColors.info;
    } else if (status == 'D' || status == 'A') {
      label = 'Approved';
      color = AppColors.statusDone;
    } else if (status == 'R') {
      label = 'Rejected';
      color = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
