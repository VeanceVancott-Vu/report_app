import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:report_app/models/user_model.dart';
import 'package:report_app/models/report_model.dart';
import 'package:report_app/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:report_app/viewmodels/report_viewmodel.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import '/utils/map_picker.dart';
import '/utils/image_picker.dart';

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

class NewReportScreen extends StatefulWidget {
  const NewReportScreen({Key? key}) : super(key: key);

  @override
  State<NewReportScreen> createState() => _NewReportScreenState();
}

class _NewReportScreenState extends State<NewReportScreen> {
  final TextEditingController _reportTitleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _manualAddressController = TextEditingController();
  LatLng? _pickedLocation;
  String? _locationString;
  List<File> _selectedImages = [];
  List<File> _selectedVideos = [];
  int _descriptionCharCount = 0;
  String? _selectedReportType;

  final List<String> _reportTypes = [
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

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(_updateDescriptionCharCount);
  }

  @override
  void dispose() {
    _reportTitleController.dispose();
    _descriptionController.removeListener(_updateDescriptionCharCount);
    _descriptionController.dispose();
    _manualAddressController.dispose();
    super.dispose();
  }

  void _updateDescriptionCharCount() {
    setState(() {
      _descriptionCharCount = _descriptionController.text.length;
    });
  }

  Future<void> _sendReport(AppUser user) async {
    final reportVM = context.read<ReportViewModel>();
    final title = _reportTitleController.text.trim();
    final description = _descriptionController.text.trim();
    final reportType = _selectedReportType ?? "Unknown";
    final createdAt = Timestamp.now();
    final manualAddress = _manualAddressController.text.trim().isNotEmpty
        ? _manualAddressController.text.trim()
        : null;

    // Validate input
    if (title.isEmpty || description.isEmpty || reportType == "Unknown") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    final reportLocation = ReportLocation(
      latitude: _pickedLocation?.latitude ?? user.latitude ?? 0.0,
      longitude: _pickedLocation?.longitude ?? user.longitude ?? 0.0,
      address: manualAddress,
    );

    final report = Report(
      reportId: null,
      userId: user.uid,
      title: title,
      type: reportType,
      description: description,
      imageUrls: [],
      videoUrls: [],
      location: reportLocation,
      status: ReportStatus.Submitted,
      createdAt: createdAt,
    );

    logger.i("\uD83D\uDCCB Report Created:\n$report\nImages: $_selectedImages\nVideos: $_selectedVideos");

    try {
      await reportVM.addReport(report, images: _selectedImages, videos: _selectedVideos);
      if (!context.mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report "$title" sent successfully'),
          duration: const Duration(seconds: 2),
        ),
      );

      // Clear form fields
      setState(() {
        _reportTitleController.clear();
        _descriptionController.clear();
        _manualAddressController.clear();
        _selectedImages = [];
        _selectedVideos = [];
        _selectedReportType = null;
        _pickedLocation = null;
        _locationString = null;
        _descriptionCharCount = 0;
      });

      // Navigate to home screen after SnackBar
      await Future.delayed(const Duration(seconds: 2));
      if (context.mounted) {
        context.go('/');
      }
    } catch (e) {
      logger.e('Failed to send report: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send report: $e')),
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
      logger.d("Picked location to address: $address");
      setState(() {
        _pickedLocation = result;
        _locationString = address ?? "${result.latitude}, ${result.longitude}";
      });
    }
  }

  Future<void> _addMedia() async {
    if (_selectedImages.length + _selectedVideos.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can only upload up to 10 media files.")),
      );
      return;
    }

    final file = await ImagePickerUtil.showMediaSourceDialog(context);
    if (file != null) {
      setState(() {
        if (file.path.endsWith('.mp4') || file.path.endsWith('.mov')) {
          _selectedVideos.add(file);
        } else {
          _selectedImages.add(file);
        }
      });
    }
  }

  Future<String?> _getAddressFromLatLng(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final place = placemarks.first;
      return '${place.street}, ${place.locality}, ${place.country}';
    } catch (e) {
      logger.e("Geocoding error: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentAppUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            logger.d('Back button pressed on NewReportScreen');
            context.pop();
          },
        ),
        title: const Text(
          "New Report",
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
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
              _sectionTitle("Report Title"),
              _buildTextInputField(
                controller: _reportTitleController,
                hintText: "e.g., Overflowing Trash Bin",
                keyboardType: TextInputType.text,
                maxLines: 1,
              ),
              const SizedBox(height: 20),
              _sectionTitle("Description"),
              _buildTextInputField(
                controller: _descriptionController,
                hintText: "Provide detailed description of the issue...",
                keyboardType: TextInputType.multiline,
                maxLines: 5,
                showCharCounter: true,
                currentChars: _descriptionCharCount,
                maxChars: 500,
              ),
              const SizedBox(height: 20),
              _sectionTitle("Report Type"),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _reportTypes.map((type) {
                  final isSelected = _selectedReportType == type;
                  return ChoiceChip(
                    label: Text(type),
                    selected: isSelected,
                    selectedColor: Colors.blueAccent,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    backgroundColor: Colors.grey[100],
                    side: BorderSide(color: isSelected ? Colors.blueAccent : Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedReportType = selected ? type : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _sectionTitle("Location"),
              _buildTextInputField(
                controller: _manualAddressController,
                hintText: "e.g., 3rd floor of apartment 1",
                keyboardType: TextInputType.text,
                maxLines: 1,
              ),
              const SizedBox(height: 10),
              _locationRow(_locationString ?? user.address ?? "Unknown"),
              const SizedBox(height: 20),
              _sectionTitle("Attach Photos/Videos"),
              _mediaPickerRow(),
              const SizedBox(height: 40),
              Center(
                child: ElevatedButton(
                  onPressed: () => _sendReport(user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    "Send Report",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      );

  Widget _locationRow(String location) => Row(
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
                      location,
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
            onPressed: _changeLocation,
            icon: const Icon(Icons.map, size: 20),
            label: const Text("Choose location"),
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
      );

  Widget _mediaPickerRow() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length + _selectedVideos.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index < _selectedImages.length) {
            final file = _selectedImages[index];
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
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedImages.removeAt(index);
                      });
                    },
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
          } else if (index < _selectedImages.length + _selectedVideos.length) {
            final videoIndex = index - _selectedImages.length;
            final file = _selectedVideos[videoIndex];
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
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedVideos.removeAt(videoIndex);
                      });
                    },
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
                const Positioned.fill(
                  child: Center(
                    child: Icon(Icons.play_circle_outline, size: 40, color: Colors.white70),
                  ),
                ),
              ],
            );
          } else {
            return GestureDetector(
              onTap: _addMedia,
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
    );
  }

  Widget _buildTextInputField({
    required TextEditingController controller,
    required String hintText,
    required TextInputType keyboardType,
    int? maxLines,
    bool showCharCounter = false,
    int? currentChars,
    int? maxChars,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
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
        if (showCharCounter)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              '$currentChars/$maxChars',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
      ],
    );
  }
}