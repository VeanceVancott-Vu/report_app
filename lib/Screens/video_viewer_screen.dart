import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:video_player/video_player.dart';

class VideoViewerScreen extends StatefulWidget {
  final List<String> videoUrls;
  final int initialIndex;

  const VideoViewerScreen({
    Key? key,
    required this.videoUrls,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  _VideoViewerScreenState createState() => _VideoViewerScreenState();
}

class _VideoViewerScreenState extends State<VideoViewerScreen> {
  final logger = Logger();
  late PageController _pageController;
  late int _currentIndex;
  late List<VideoPlayerController> _videoControllers;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _videoControllers = widget.videoUrls.map((url) {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      controller.initialize().then((_) => setState(() {})).catchError((e) {
        logger.e('Error initializing video $url: $e');
      });
      return controller;
    }).toList();
    _videoControllers[_currentIndex].play();
    logger.d('VideoViewerScreen initialized with initialIndex: $_currentIndex, videoUrls: ${widget.videoUrls}');
  }

  @override
  void dispose() {
    for (var controller in _videoControllers) {
      controller.dispose();
    }
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
          onPressed: () {
            logger.d('Close button pressed on VideoViewerScreen');
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Video ${_currentIndex + 1} of ${widget.videoUrls.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.videoUrls.length,
        onPageChanged: (index) {
          setState(() {
            _videoControllers[_currentIndex].pause();
            _currentIndex = index;
            _videoControllers[_currentIndex].play();
            logger.d('Swiped to video index: $_currentIndex');
          });
        },
        itemBuilder: (context, index) {
          final controller = _videoControllers[index];
          return Center(
            child: controller.value.isInitialized
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: VideoPlayer(controller),
                      ),
                      if (!controller.value.isPlaying)
                        IconButton(
                          icon: const Icon(Icons.play_circle_filled, size: 60, color: Colors.white70),
                          onPressed: () {
                            setState(() {
                              controller.play();
                              logger.d('Play button pressed for video at index $index');
                            });
                          },
                        ),
                      if (controller.value.isPlaying)
                        IconButton(
                          icon: const Icon(Icons.pause_circle_filled, size: 60, color: Colors.white70),
                          onPressed: () {
                            setState(() {
                              controller.pause();
                              logger.d('Pause button pressed for video at index $index');
                            });
                          },
                        ),
                    ],
                  )
                : const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}