import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:report_app/models/report_model.dart';
import 'package:report_app/services/auth_service.dart';
import 'package:report_app/utils/image_picker.dart';
import 'package:report_app/viewmodels/report_viewmodel.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:report_app/utils/map_picker.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:report_app/utils/cloudinary_upload.dart';

final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    printTime: true,
  ),
);

class EditReportScreen extends StatefulWidget {
  final Report report;

  const EditReportScreen({Key? key, required this.report}) : super(key: key);

  @override
  _EditReportScreenState createState() => _EditReportScreenState();
}

class _EditReportScreenState extends State<EditReportScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  LatLng? _pickedLocation;
  List<String> _reportTypes = [
    "Broken equipment",
    "Infrastructure",
    "Traffic Signal Issue",
    "Power Outage",
    "Water Leakage",
    "Sewage Issue",
    "Waste Management",
    "Environment",
    "Graffiti / Vandalism",
    "Noise Disturbance",
    "Public Safety",
    "Illegal Parking",
    "Animal Control",
    "Pest Infestation",
    "Public Transportation",
    "Other",
  ];
  String? _selectedReportType;
  List<File> _newImages = [];
  List<File> _newVideos = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.report.title);
    _descriptionController = TextEditingController(text: widget.report.description);
    _locationController = TextEditingController(
        text: widget.report.location.address ??
            '${widget.report.location.latitude}, ${widget.report.location.longitude}');
    _selectedReportType = widget.report.type;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveReport(BuildContext context) async {
    final viewModel = context.read<ReportViewModel>();
    try {
      final updatedLocation = _pickedLocation ??
          LatLng(widget.report.location.latitude, widget.report.location.longitude);
      final updatedReport = widget.report.copyWithFromMap({
        'title': _titleController.text,
        'type': _selectedReportType,
        'description': _descriptionController.text,
        'location': {
          'latitude': updatedLocation.latitude,
          'longitude': updatedLocation.longitude,
          'address': _locationController.text.isNotEmpty ? _locationController.text : null,
        },
        'imageUrls': widget.report.imageUrls ?? [],
        'videoUrls': widget.report.videoUrls ?? [],
      });
      await viewModel.updateReport(
        widget.report.reportId!,
        updatedReport.toJson(),
        images: _newImages,
        videos: _newVideos,
      );
      logger.d('Updated report: ${widget.report.reportId} via ReportViewModel');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report updated successfully')),
      );
      // Return updated report to ReportDetailScreen
     context.go('/report/${updatedReport.reportId}', extra: updatedReport);

    } catch (e) {
      logger.e('Error updating report ${widget.report.reportId}: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating report: $e')),
      );
    }
  }

  Future<void> _deleteReport(BuildContext context) async {
    final viewModel = context.read<ReportViewModel>();
    try {
      await viewModel.deleteReport(widget.report.reportId!);
      logger.d('Deleted report: ${widget.report.reportId} via ReportViewModel');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report deleted successfully')),
      );
      context.go('/');
    } catch (e) {
      logger.e('Error deleting report ${widget.report.reportId}: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting report: $e')),
      );
    }
  }

  Future<void> _changeLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FreeMapPicker()),
    );
    if (result is LatLng) {
      logger.d("Picked location: ${result.latitude}, ${result.longitude}");
      final address = await _getAddressFromLatLng(result);
      setState(() {
        _pickedLocation = result;
        _locationController.text = address ?? '${result.latitude}, ${result.longitude}';
      });
    }
  }

  Future<String?> _getAddressFromLatLng(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      final place = placemarks.first;
      return '${place.street}, ${place.locality}, ${place.country}';
    } catch (e) {
      logger.e("Geocoding error: $e");
      return null;
    }
  }

  Future<void> _addMedia() async {
    try {
      final file = await ImagePickerUtil.showMediaSourceDialog(context);
      if (file != null) {
        if (!file.existsSync()) {
          logger.e('File does not exist: ${file.path}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected file is inaccessible')),
          );
          return;
        }
        final extension = file.path.split('.').last.toLowerCase();
        const validImageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp'];
        const validVideoExtensions = ['mp4', 'mov', 'avi'];

        if (validImageExtensions.contains(extension)) {
          setState(() {
            _newImages.add(file);
          });
          logger.d('Added image: ${file.path}');
        } else if (validVideoExtensions.contains(extension)) {
          setState(() {
            _newVideos.add(file);
          });
          logger.d('Added video: ${file.path}');
        } else {
          logger.w('Unsupported file format: $extension');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unsupported file format')),
          );
        }
      } else {
        logger.d('No media selected');
      }
    } catch (e) {
      logger.e('Error picking media: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking media: $e')),
      );
    }
  }

  void _removeMedia(int index, bool isImage) {
    setState(() {
      if (isImage) {
        _newImages.removeAt(index);
      } else {
        _newVideos.removeAt(index);
      }
    });
  }

  void _removeExistingMedia(int index, bool isImage) async {
    final viewModel = context.read<ReportViewModel>();
    try {
      final mediaUrls = isImage ? widget.report.imageUrls : widget.report.videoUrls;
      if (mediaUrls == null || index >= mediaUrls.length) return;
      final urlToRemove = mediaUrls[index];
      final publicId = urlToRemove.split('/').last.split('.').first;

      // Delete from Cloudinary
      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round().toString();
      final signature = sha1.convert(
          utf8.encode('public_id=reports/${widget.report.reportId}/$publicId&timestamp=$timestamp${CloudinaryUploader.apiSecret}')).toString();
      final response = await http.post(
        Uri.parse(
            'https://api.cloudinary.com/v1_1/${CloudinaryUploader.cloudName}/${isImage ? 'image' : 'video'}/destroy'),
        body: {
          'public_id': 'reports/${widget.report.reportId}/$publicId',
          'api_key': CloudinaryUploader.apiKey,
          'timestamp': timestamp,
          'signature': signature,
        },
      );

      if (response.statusCode == 200) {
        // Update Firestore
        final updatedUrls = List<String>.from(mediaUrls)..removeAt(index);
        await viewModel.updateReport(
          widget.report.reportId!,
          {
            isImage ? 'imageUrls' : 'videoUrls': updatedUrls,
          },
        );

        setState(() {
          if (isImage) {
            widget.report.imageUrls = updatedUrls;
          } else {
            widget.report.videoUrls = updatedUrls;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Media deleted successfully')),
        );
      } else {
        throw Exception('Failed to delete media: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Error deleting media: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting media: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentAppUser;

    if (user == null) {
      logger.w('No user logged in');
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isOwner = user.uid == widget.report.userId;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            logger.d('Back button pressed on EditReportScreen');
            context.pop();
          },
        ),
        title: const Text(
          'Edit Report',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Report Title
              const Text(
                'Report Title',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  labelText: 'Title',
                  hintText: 'e.g., Overflowing Trash Bin',
                ),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              // Report Type
              const Text(
                'Report Type',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedReportType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  labelText: 'Type',
                  hintText: 'Select report type',
                ),
                style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey),
                items: _reportTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: isOwner
                    ? (String? newValue) {
                        setState(() {
                          _selectedReportType = newValue;
                        });
                      }
                    : null,
              ),
              const SizedBox(height: 20),
              // Description
              const Text(
                'Description',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Provide detailed description of the issue...',
                  ),
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 20),
              // Location
              const Text(
                'Location',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: 'Address derived from coordinates',
                  prefixIcon: const Icon(Icons.location_on, size: 20, color: Colors.grey),
                ),
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                enabled: false, // Read-only to show derived address
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
                              _pickedLocation != null
                                  ? _locationController.text
                                  : '${widget.report.location.latitude}, ${widget.report.location.longitude}',
                              style: const TextStyle(fontSize: 16, color: Colors.black87),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: isOwner ? _changeLocation : null,
                    icon: const Icon(Icons.map, size: 20),
                    label: const Text("Choose on map"),
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
              const SizedBox(height: 20),
              // Images
              const Text(
                'Attached Images',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: (widget.report.imageUrls ?? []).length + _newImages.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    if (index < (widget.report.imageUrls ?? []).length) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: (widget.report.imageUrls ?? [])[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
                            ),
                          ),
                          if (isOwner)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeExistingMedia(index, true),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black54,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      );
                    } else if (index < (widget.report.imageUrls ?? []).length + _newImages.length) {
                      final newIndex = index - (widget.report.imageUrls ?? []).length;
                      final file = _newImages[newIndex];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              file,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (isOwner)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeMedia(newIndex, true),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black54,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      );
                    } else {
                      return GestureDetector(
                        onTap: isOwner ? _addMedia : null,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blueAccent),
                          ),
                          child: const Center(
                            child: Icon(Icons.add_a_photo, size: 30, color: Colors.blueAccent),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Videos
              const Text(
                'Attached Videos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: (widget.report.videoUrls ?? []).length + _newVideos.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    if (index < (widget.report.videoUrls ?? []).length) {
                      final videoUrls = widget.report.videoUrls ?? [];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: videoUrls[index].replaceAll(RegExp(r'\.\w+$'), '.jpg'),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.videocam,
                                size: 50,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          const Positioned.fill(
                            child: Center(
                              child: Icon(
                                Icons.play_circle_outline,
                                size: 40,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          if (isOwner)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeExistingMedia(index, false),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black54,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      );
                    } else if (index < (widget.report.videoUrls ?? []).length + _newVideos.length) {
                      final newIndex = index - (widget.report.videoUrls ?? []).length;
                      final file = _newVideos[newIndex];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              file,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.videocam,
                                size: 50,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                          const Positioned.fill(
                            child: Center(
                              child: Icon(
                                Icons.play_circle_outline,
                                size: 40,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          if (isOwner)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeMedia(newIndex, false),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black54,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      );
                    } else {
                      return GestureDetector(
                        onTap: isOwner ? _addMedia : null,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blueAccent),
                          ),
                          child: const Center(
                            child: Icon(Icons.add_a_photo, size: 30, color: Colors.blueAccent),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),
              if (isOwner) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _saveReport(context),
                      icon: const Icon(Icons.save, size: 20),
                      label: const Text('Save Changes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _deleteReport(context),
                      icon: const Icon(Icons.delete, size: 20),
                      label: const Text('Delete Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}