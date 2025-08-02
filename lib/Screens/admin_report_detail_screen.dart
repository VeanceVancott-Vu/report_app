import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:logger/logger.dart';
import '../models/report_model.dart';
import '../viewmodels/report_viewmodel.dart';
import 'image_viewer_screen.dart';

class AdminReportDetailScreen extends StatefulWidget {
  final Report report;

  const AdminReportDetailScreen({Key? key, required this.report})
      : super(key: key);

  @override
  _AdminReportDetailScreenState createState() => _AdminReportDetailScreenState();
}

class _AdminReportDetailScreenState extends State<AdminReportDetailScreen> {
  final logger = Logger();
  late ReportStatus _selectedStatus;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.report.title;
    _descriptionController.text = widget.report.description;
    logger.d('AdminReportDetailScreen - Report Details:');
    logger.d('  report: ${widget.report}');

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

  Future<void> _updateStatus(BuildContext context, ReportStatus newStatus) async {
    final viewModel = context.read<ReportViewModel>();
    try {
      if (widget.report.reportId != null) {
        await viewModel.updateReportStatus(widget.report.reportId!, newStatus);
        logger.d(
            'Updated report ${widget.report.reportId} status to $newStatus');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Status updated to ${_getDisplayStatus(newStatus)}')),
        );
        setState(() {
          _selectedStatus = newStatus;
        });
      } else {
        logger.w('Cannot update status: reportId is null');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Report ID is missing')),
        );
      }
    } catch (e) {
      logger.e('Error updating status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  Future<void> _updateReport(BuildContext context) async {
    final viewModel = context.read<ReportViewModel>();
    try {
      if (widget.report.reportId != null) {
        await viewModel.updateReport(widget.report.reportId!, {
          'title': _titleController.text,
          'description': _descriptionController.text,
        });
        logger.d('Updated report ${widget.report.reportId}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report updated successfully')),
        );
        setState(() {
          _isEditing = false;
        });
      } else {
        logger.w('Cannot update report: reportId is null');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Report ID is missing')),
        );
      }
    } catch (e) {
      logger.e('Error updating report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating report: $e')),
      );
    }
  }

  Future<void> _deleteReport(BuildContext context) async {
    final viewModel = context.read<ReportViewModel>();
    try {
      if (widget.report.reportId != null) {
        await viewModel.deleteReport(widget.report.reportId!);
        logger.d('Deleted report ${widget.report.reportId}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report deleted successfully')),
        );
        context.go('/admin');
      } else {
        logger.w('Cannot delete report: reportId is null');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Report ID is missing')),
        );
      }
    } catch (e) {
      logger.e('Error deleting report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting report: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportViewModel = context.watch<ReportViewModel>();
    final imageUrls =
        reportViewModel.getImageUrlsForReport(widget.report.reportId ?? '');
    logger.d('Image URLs for reportId ${widget.report.reportId}: $imageUrls');

    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade700,
        elevation: 2,
        title: const Text(
          'Report Management',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            logger.d('Navigating back to AdminHomeScreen');
            context.go('/admin');
          },
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit, color: Colors.white),
            onPressed: () {
              if (_isEditing) {
                _updateReport(context);
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _isEditing
                          ? TextField(
                              controller: _titleController,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Title',
                                border: OutlineInputBorder(),
                              ),
                            )
                          : Text(
                              widget.report.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                      const SizedBox(height: 8),
                      Text(
                        'Type: ${widget.report.type}',
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.indigo.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description Card
              Card(
                elevation: 4,
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
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _isEditing
                          ? TextField(
                              controller: _descriptionController,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              maxLines: 5,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                border: OutlineInputBorder(),
                              ),
                            )
                          : Text(
                              widget.report.description.isEmpty
                                  ? 'No description provided.'
                                  : widget.report.description,
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.black87),
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Status Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status Management',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: ReportStatus.values.map((status) {
                          return ElevatedButton(
                            onPressed: () => _updateStatus(context, status),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedStatus == status
                                  ? _getStatusColor(status)
                                  : Colors.grey.shade300,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              _getDisplayStatus(status),
                              style: TextStyle(
                                color: _selectedStatus == status
                                    ? Colors.white
                                    : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Created: ${_getTimeAgo(widget.report.createdAt)}',
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Location Card
              Card(
                elevation: 4,
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
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.report.location.address?.isNotEmpty == true
                            ? widget.report.location.address!
                            : 'Address not available',
                        style: const TextStyle(
                            fontSize: 16, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Latitude: ${widget.report.location.latitude.toStringAsFixed(4)}',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black87),
                      ),
                      Text(
                        'Longitude: ${widget.report.location.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Images Card
              if (imageUrls.isNotEmpty)
                Card(
                  elevation: 4,
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
                            color: Colors.indigo,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: imageUrls.length,
                            itemBuilder: (context, index) {
                              logger.d('Rendering image URL: ${imageUrls[index]}');
                              return GestureDetector(
                                onTap: () {
                                  logger.d(
                                      'Tapped image at index $index: ${imageUrls[index]}');
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
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Center(
                                          child: CircularProgressIndicator()),
                                      errorWidget: (context, url, error) {
                                        logger.e(
                                            'CachedNetworkImage error for $url: $error');
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
                  elevation: 4,
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

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      logger.d('Delete Report button pressed');
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Report'),
                          content: const Text(
                              'Are you sure you want to delete this report?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _deleteReport(context);
                              },
                              child: const Text(
                                  'Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete, size: 20),
                    label: const Text('Delete Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}