import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/global_image_item.dart';
import '../theme/app_theme.dart';

class GlobalImageViewer extends StatefulWidget {
  final List<GlobalImageItem> images;
  final int initialIndex;

  const GlobalImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<GlobalImageViewer> createState() => _GlobalImageViewerState();
}

class _GlobalImageViewerState extends State<GlobalImageViewer> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return const SizedBox();

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Get.back(),
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final item = widget.images[index];
              return _ZoomablePage(item: item);
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildMetadataOverlay(widget.images[_currentIndex]),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataOverlay(GlobalImageItem item) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.8),
            Colors.black,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.photoType,
                    style: AppTextStyles.heading3.copyWith(color: Colors.white),
                  ),
                ),
                if (item.status != null) _buildStatusBadge(item.status!),
              ],
            ),
            const SizedBox(height: 8),
            if (item.uploadedBy != null) ...[
              Text(
                'Uploaded by: ${item.uploadedBy}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
            ],
            if (item.uploadedAt != null) ...[
              Text(
                'Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(item.uploadedAt!.toLocal())}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
            ],
            if (item.lat != null && item.lng != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.accent, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${item.lat}, ${item.lng}',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
            if (item.watermarkInfo != null) ...[
              const SizedBox(height: 4),
              Text(
                item.watermarkInfo!,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
            if (item.onApprove != null || item.onReject != null || item.onAddRemark != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (item.onReject != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Reject'),
                        onPressed: item.onReject,
                      ),
                    ),
                  if (item.onReject != null) const SizedBox(width: 8),
                  if (item.onAddRemark != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                        ),
                        icon: const Icon(Icons.comment, size: 16),
                        label: const Text('Remark'),
                        onPressed: () {
                          _showRemarkDialog(context, item);
                        },
                      ),
                    ),
                  if (item.onAddRemark != null) const SizedBox(width: 8),
                  if (item.onApprove != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Approve'),
                        onPressed: item.onApprove,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRemarkDialog(BuildContext context, GlobalImageItem item) {
    final tc = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Remark'),
          content: TextField(
            controller: tc,
            decoration: const InputDecoration(
              hintText: 'Enter your remark here...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (tc.text.trim().isNotEmpty && item.onAddRemark != null) {
                  item.onAddRemark!(tc.text.trim());
                }
                Navigator.pop(context);
              },
              child: const Text('Save Remark'),
            ),
          ],
        );
      }
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ZoomablePage extends StatefulWidget {
  final GlobalImageItem item;

  const _ZoomablePage({required this.item});

  @override
  State<_ZoomablePage> createState() => _ZoomablePageState();
}

class _ZoomablePageState extends State<_ZoomablePage> with SingleTickerProviderStateMixin {
  final TransformationController _transformationController = TransformationController();
  TapDownDetails? _doubleTapDetails;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
        if (_animation != null) {
          _transformationController.value = _animation!.value;
        }
      });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_doubleTapDetails == null) return;
    final position = _doubleTapDetails!.localPosition;

    if (_transformationController.value != Matrix4.identity()) {
      // Zoom out
      _animateScale(Matrix4.identity());
    } else {
      // Zoom in
      final matrix = Matrix4.identity()
        ..translate(-position.dx * 1.5, -position.dy * 1.5)
        ..scale(2.5);
      _animateScale(matrix);
    }
  }

  void _animateScale(Matrix4 endMatrix) {
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: endMatrix,
    ).animate(CurveTween(curve: Curves.easeOut).animate(_animationController));
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: _handleDoubleTapDown,
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformationController,
        panEnabled: true,
        minScale: 1.0,
        maxScale: 4.0,
        child: Center(
          child: _buildImage(),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.item.memoryBytes != null) {
      return Image.memory(
        widget.item.memoryBytes!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _errorPlaceholder(),
      );
    } else if (widget.item.url != null) {
      return CachedNetworkImage(
        imageUrl: widget.item.url!,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        errorWidget: (context, url, error) => _errorPlaceholder(),
      );
    }
    return _errorPlaceholder();
  }

  Widget _errorPlaceholder() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.broken_image, color: Colors.white54, size: 64),
        SizedBox(height: 16),
        Text('Failed to load image', style: TextStyle(color: Colors.white54)),
      ],
    );
  }
}
