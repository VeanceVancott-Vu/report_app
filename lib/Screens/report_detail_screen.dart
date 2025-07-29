import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:report_app/Screens/new_report_screen.dart';
import 'package:report_app/Screens/image_viewer_screen.dart'; // Import the new screen
import '../models/report_model.dart';
import '../viewmodels/report_viewmodel.dart';
import 'package:logger/logger.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ReportDetailScreen extends StatefulWidget {
  final Report report;

  const ReportDetailScreen({Key? key, required this.report}) : super(key: key);

  @override
  _ReportDetailScreenState createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final logger = Logger();

  @override
  void initState() {
    super.initState();
    // Debug: Log report details
    logger.d('Report Details:');
    logger.d('  reportId: ${widget.report.reportId}');
    logger.d('  title: ${widget.report.title}');
    logger.d('  type: ${widget.report.type}');
    logger.d('  description: ${widget.report.description}');
    logger.d('  imageUrls: ${widget.report.imageUrls}');
    logger.d('  location: ${widget.report.location.address}, '
        'lat: ${widget.report.location.latitude}, '
        'lon: ${widget.report.location.longitude}');
    logger.d('  status: ${widget.report.status}');
    logger.d('  createdAt: ${widget.report.createdAt}');
    logger.d('  userId: ${widget.report.userId}');
  }

  String _getTimeAgo(Timestamp createdAt) {
    final now = DateTime.now();
    final reportTime = createdAt.toDate();
    final difference = now.difference(reportTime);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  String _getDisplayStatus(ReportStatus status) {
    switch (status) {
      case ReportStatus.Submitted:
        return 'Not yet resolved';
      case ReportStatus.Processing:
        return 'Resolving';
      case ReportStatus.Done:
        return 'Resolved';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.Submitted:
        return Colors.redAccent;
      case ReportStatus.Processing:
        return Colors.orangeAccent;
      case ReportStatus.Done:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportViewModel = context.watch<ReportViewModel>();
    // Use imageUrls directly from widget.report
    final imageUrls = widget.report.imageUrls;

    // Debug: Log image URLs
    logger.d('Image URLs for reportId ${widget.report.reportId}: $imageUrls');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Report Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.report.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Type: ${widget.report.type}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.report.description.isEmpty
                            ? 'No description provided.'
                            : widget.report.description,
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Status and Time Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(widget.report.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getDisplayStatus(widget.report.status),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Created: ${_getTimeAgo(widget.report.createdAt)}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Location Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.report.location.address?.isNotEmpty == true
                            ? widget.report.location.address!
                            : 'Address not available',
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Latitude: ${widget.report.location.latitude.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      Text(
                        'Longitude: ${widget.report.location.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Images Card (using CachedNetworkImage with click functionality)
              if (imageUrls.isNotEmpty)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Images',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: imageUrls.length,
                            itemBuilder: (context, index) {
                              logger.d('Rendering image URL: ${imageUrls[index]}');
                              return GestureDetector(
                                onTap: () {
                                  logger.d('Tapped image at index $index: ${imageUrls[index]}');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ImageViewerScreen(
                                        imageUrls: imageUrls,
                                        initialIndex: index,
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: imageUrls[index],
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                      errorWidget: (context, url, error) {
                                        logger.d('CachedNetworkImage error for $url: $error');
                                        return const Icon(
                                          Icons.broken_image,
                                          size: 50,
                                          color: Colors.grey,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Fallback if no images
              if (imageUrls.isEmpty)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No images available for this report.',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Action Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Action not implemented yet')),
                    );
                  },
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('Refresh Status'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}