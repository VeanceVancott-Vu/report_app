import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:logger/logger.dart';

class ImageViewerScreen extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const ImageViewerScreen({
    Key? key,
    required this.imageUrls,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  _ImageViewerScreenState createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  final logger = Logger();
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    logger.d('ImageViewerScreen initialized with initialIndex: $_currentIndex, imageUrls: ${widget.imageUrls}');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Image ${_currentIndex + 1} of ${widget.imageUrls.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
            logger.d('Swiped to image index: $_currentIndex');
          });
        },
        itemBuilder: (context, index) {
          return PhotoView(
            imageProvider: CachedNetworkImageProvider(widget.imageUrls[index]),
            loadingBuilder: (context, event) => const Center(child: CircularProgressIndicator()),
            errorBuilder: (context, error, stackTrace) {
              logger.d('PhotoView error for ${widget.imageUrls[index]}: $error');
              return const Center(
                child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
              );
            },
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          );
        },
      ),
    );
  }
}