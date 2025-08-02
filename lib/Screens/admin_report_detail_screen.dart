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

<<<<<<< HEAD
  const AdminReportDetailScreen({Key? key, required this.report})
      : super(key: key);
=======
  const AdminReportDetailScreen({Key? key, required this.report}) : super(key: key);
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb

  @override
  _AdminReportDetailScreenState createState() => _AdminReportDetailScreenState();
}

class _AdminReportDetailScreenState extends State<AdminReportDetailScreen> {
  final logger = Logger();
  late ReportStatus _selectedStatus;
<<<<<<< HEAD
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isEditing = false;
=======
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.report.status;
<<<<<<< HEAD
    _titleController.text = widget.report.title;
    _descriptionController.text = widget.report.description;
=======
    // Debug: Log report details
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
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

<<<<<<< HEAD
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
=======
  Future<void> _updateStatus(BuildContext context) async {
    final viewModel = context.read<ReportViewModel>();
    try {
      if (widget.report.reportId != null) {
        await viewModel.updateReportStatus(widget.report.reportId!, _selectedStatus);
        logger.d('Updated report ${widget.report.reportId} status to $_selectedStatus');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to ${_getDisplayStatus(_selectedStatus)}')),
        );
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
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

<<<<<<< HEAD
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

=======
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
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
<<<<<<< HEAD
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
=======
    final imageUrls = reportViewModel.getImageUrlsForReport(widget.report.reportId ?? '');
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
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
          onPressed: () {
            logger.d('Navigating back to AdminHomeScreen');
            context.go('/admin');
          },
        ),
<<<<<<< HEAD
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
=======
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Card
              Card(
<<<<<<< HEAD
                elevation: 4,
=======
                elevation: 2,
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
<<<<<<< HEAD
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
=======
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
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description Card
              Card(
<<<<<<< HEAD
                elevation: 4,
=======
                elevation: 2,
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
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
<<<<<<< HEAD
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
=======
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
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

<<<<<<< HEAD
              // Status Card
              Card(
                elevation: 4,
=======
              // Status and Time Card
              Card(
                elevation: 2,
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
<<<<<<< HEAD
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
=======
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
                      const SizedBox(height: 12),
                      DropdownButton<ReportStatus>(
                        value: _selectedStatus,
                        isExpanded: true,
                        items: ReportStatus.values.map((ReportStatus status) {
                          return DropdownMenuItem<ReportStatus>(
                            value: status,
                            child: Text(_getDisplayStatus(status)),
                          );
                        }).toList(),
                        onChanged: (ReportStatus? newStatus) {
                          if (newStatus != null) {
                            setState(() {
                              _selectedStatus = newStatus;
                            });
                            logger.d('Selected new status: $newStatus');
                            _updateStatus(context);
                          }
                        },
                        hint: const Text('Update Status'),
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                        underline: Container(
                          height: 2,
                          color: Colors.blueAccent,
                        ),
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Location Card
              Card(
<<<<<<< HEAD
                elevation: 4,
=======
                elevation: 2,
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
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
<<<<<<< HEAD
                          color: Colors.indigo,
=======
                          color: Colors.black87,
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.report.location.address?.isNotEmpty == true
                            ? widget.report.location.address!
                            : 'Address not available',
<<<<<<< HEAD
                        style: const TextStyle(
                            fontSize: 16, color: Colors.black87),
=======
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Latitude: ${widget.report.location.latitude.toStringAsFixed(4)}',
<<<<<<< HEAD
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black87),
                      ),
                      Text(
                        'Longitude: ${widget.report.location.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black87),
=======
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      Text(
                        'Longitude: ${widget.report.location.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Images Card
              if (imageUrls.isNotEmpty)
                Card(
<<<<<<< HEAD
                  elevation: 4,
=======
                  elevation: 2,
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
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
<<<<<<< HEAD
                            color: Colors.indigo,
=======
                            color: Colors.black87,
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
<<<<<<< HEAD
                          height: 120,
=======
                          height: 100,
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: imageUrls.length,
                            itemBuilder: (context, index) {
                              logger.d('Rendering image URL: ${imageUrls[index]}');
                              return GestureDetector(
                                onTap: () {
<<<<<<< HEAD
                                  logger.d(
                                      'Tapped image at index $index: ${imageUrls[index]}');
=======
                                  logger.d('Tapped image at index $index: ${imageUrls[index]}');
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
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
<<<<<<< HEAD
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Center(
                                          child: CircularProgressIndicator()),
                                      errorWidget: (context, url, error) {
                                        logger.e(
                                            'CachedNetworkImage error for $url: $error');
=======
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                      errorWidget: (context, url, error) {
                                        logger.e('CachedNetworkImage error for $url: $error');
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
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
<<<<<<< HEAD
                  elevation: 4,
=======
                  elevation: 2,
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
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
<<<<<<< HEAD
=======
                      logger.d('Refresh Status button pressed');
                      setState(() {
                        // Refresh UI if needed
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Status refreshed')),
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
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
                      logger.d('Delete Report button pressed');
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Report'),
<<<<<<< HEAD
                          content: const Text(
                              'Are you sure you want to delete this report?'),
=======
                          content: const Text('Are you sure you want to delete this report?'),
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
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
<<<<<<< HEAD
                              child: const Text(
                                  'Delete', style: TextStyle(color: Colors.red)),
=======
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
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
<<<<<<< HEAD
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
=======
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
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