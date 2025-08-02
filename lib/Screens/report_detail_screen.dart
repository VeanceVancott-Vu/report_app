import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:report_app/utils/logger.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart';
import 'package:report_app/utils/map_picker.dart';
import 'dart:io';
import '../models/report_model.dart';
import '../viewmodels/report_viewmodel.dart';
import 'image_viewer_screen.dart';
import '../utils/reverse_geocoding.dart';

class ReportDetailScreen extends StatefulWidget {
  final Report report;

  const ReportDetailScreen({Key? key, required this.report}) : super(key: key);

  @override
  _ReportDetailScreenState createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _manualAddressController = TextEditingController(); // New controller for manual address
  bool _isEditing = false;
  bool _isGeocoding = false;
  List<String> _imageUrls = [];
  List<File> _newImages = [];
  double? _latitude;
  double? _longitude;
  String? _locationString;
  LatLng? _pickedLocation; // User-selected location from map

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.report.title;
    _descriptionController.text = widget.report.description;
    _manualAddressController.text = widget.report.location.address ?? '';
    _imageUrls = List.from(widget.report.imageUrls);
    _latitude = widget.report.location.latitude;
    _longitude = widget.report.location.longitude;
    _locationString = widget.report.location.address?.isNotEmpty == true
        ? widget.report.location.address
        : '${widget.report.location.latitude.toStringAsFixed(4)}, ${widget.report.location.longitude.toStringAsFixed(4)}';
    logger.d('ReportDetailScreen - Report Details:');
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _manualAddressController.dispose();
    super.dispose();
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

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final pickedFile = await picker.pickImage(source: ImageSource.camera);
                if (pickedFile != null) {
                  setState(() {
                    _newImages.add(File(pickedFile.path));
                  });
                  logger.d('Added new image from camera: ${pickedFile.path}');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  setState(() {
                    _newImages.add(File(pickedFile.path));
                  });
                  logger.d('Added new image from gallery: ${pickedFile.path}');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeImage(int index, bool isExisting) {
    setState(() {
      if (isExisting) {
        _imageUrls.removeAt(index);
      } else {
        _newImages.removeAt(index);
      }
    });
    logger.d('Removed image at index $index (isExisting: $isExisting)');
  }

  Future<void> _changeLocation() async {
    setState(() {
      _isGeocoding = true;
    });
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FreeMapPicker(
  
        ),
      ),
    );

    if (result is LatLng) {
      logger.d("Picked location: ${result.latitude}, ${result.longitude}");
      final address = await _getAddressFromLatLng(result);
      logger.d("Picked location to address: $address");
      setState(() {
        _pickedLocation = result;
        _latitude = result.latitude;
        _longitude = result.longitude;
        _locationString = address ?? "${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}";
        _isGeocoding = false;
      });
    } else {
      setState(() {
        _isGeocoding = false;
      });
    }
  }

  Future<String?> _getAddressFromLatLng(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
        localeIdentifier: 'en_US',
      );
      final place = placemarks.first;
      return '${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}'.trim();
    } catch (e) {
      logger.e("Geocoding error: $e");
      return null;
    }
  }

  Future<void> _updateReport(BuildContext context) async {
    final viewModel = context.read<ReportViewModel>();
    try {
      if (widget.report.reportId != null) {
        final manualAddress = _manualAddressController.text.trim().isNotEmpty
            ? _manualAddressController.text.trim()
            : null;
        String? address = manualAddress ?? _locationString;
        if (address == '${_latitude?.toStringAsFixed(4)}, ${_longitude?.toStringAsFixed(4)}') {
          address = await _getAddressFromLatLng(LatLng(_latitude!, _longitude!));
          if (address == null || address.isEmpty) {
            try {
              final placemarks = await placemarkFromCoordinates(_latitude!, _longitude!, localeIdentifier: 'en_US');
              final place = placemarks.first;
              address = '${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}'
                  .trim();
              if (address.isEmpty) address = '';
            } catch (e) {
              logger.w('Failed to fetch address: $e');
              address = '';
            }
          }
          setState(() {
            _locationString = address;
          });
        }
        final updates = {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'location': ReportLocation(
            latitude: _latitude ?? widget.report.location.latitude,
            longitude: _longitude ?? widget.report.location.longitude,
            address: address,
          ).toJson(),
          'imageUrls': _imageUrls,
        };
        if (_newImages.isNotEmpty) {
          final newImageUrls = await viewModel.addReportImages(_newImages);
          updates['imageUrls'] = [..._imageUrls, ...newImageUrls];
        }
        await viewModel.updateReport(widget.report.reportId!, updates);
        logger.d('Updated report ${widget.report.reportId}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report updated successfully')),
        );
        setState(() {
          _isEditing = false;
          _newImages.clear();
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
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report deleted successfully')),
      );
      if (!context.mounted) return;
      context.go('/home');
    } else {
      logger.w('Cannot delete report: reportId is null');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Report ID is missing')),
      );
    }
  } catch (e) {
    logger.e('Error deleting report: $e');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error deleting report: $e')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final reportViewModel = context.watch<ReportViewModel>();
    final allImages = [..._imageUrls, ..._newImages.map((x) => x.path)];

    logger.d('Rendering images: $allImages');

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
          onPressed: () {
            logger.d('Navigating back to HomeScreen');
            context.go('/home');
          },
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit, color: Colors.black),
            onPressed: () {
              if (_isEditing) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Save Changes'),
                    content: const Text('Are you sure you want to save changes to this report?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          logger.d('Update cancelled for report: ${widget.report.reportId}');
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _updateReport(context);
                        },
                        child: const Text('Save', style: TextStyle(color: Colors.blueAccent)),
                      ),
                    ],
                  ),
                );
              } else {
                setState(() {
                  _isEditing = true;
                });
                logger.d('Entered edit mode for report: ${widget.report.reportId}');
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
                elevation: 2,
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
                                color: Colors.black87,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Title',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            )
                          : Text(
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
                      _isEditing
                          ? TextField(
                              controller: _descriptionController,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              maxLines: 5,
                              decoration: InputDecoration(
                                labelText: 'Description',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            )
                          : Text(
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
                      if (_isEditing) ...[
                        TextField(
                          controller: _manualAddressController,
                          keyboardType: TextInputType.text,
                          maxLines: 1,
                          decoration: InputDecoration(
                            hintText: 'e.g., 3rd floor of apartment 1',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 20, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _locationString ?? 'Unknown',
                                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (_isGeocoding)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 8.0),
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: _isGeocoding ? null : _changeLocation,
                              icon: const Icon(Icons.map, size: 20),
                              label: const Text('Choose location'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.blueAccent,
                                side: const BorderSide(color: Colors.blueAccent),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Images Card
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
                            'Images',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          if (_isEditing)
                            IconButton(
                              icon: const Icon(Icons.add_a_photo, color: Colors.blueAccent),
                              onPressed: _pickImage,
                              tooltip: 'Add Image',
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (allImages.isNotEmpty)
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: allImages.length,
                            itemBuilder: (context, index) {
                              final isExisting = index < _imageUrls.length;
                              final imagePath = allImages[index];
                              logger.d('Rendering image: $imagePath');
                              return Stack(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      logger.d('Tapped image at index $index: $imagePath');
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ImageViewerScreen(
                                            imageUrls: allImages,
                                            initialIndex: index,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: isExisting
                                            ? CachedNetworkImage(
                                                imageUrl: imagePath,
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
                                              )
                                            : Image.file(
                                                File(imagePath),
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                    ),
                                  ),
                                  if (_isEditing)
                                    Positioned(
                                      top: 0,
                                      right: 8,
                                      child: IconButton(
                                        icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                                        onPressed: () => _removeImage(index, isExisting),
                                        tooltip: 'Remove Image',
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      if (allImages.isEmpty)
                        const Text(
                          'No images available for this report.',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                    ],
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
                          content: const Text('Are you sure you want to delete this report?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                logger.d('Delete cancelled for report: ${widget.report.reportId}');
                              },
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _deleteReport(context);
                              },
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.redAccent),
                              ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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