import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';
import 'package:report_app/utils/cloudinary_upload.dart';
import 'package:report_app/utils/image_picker.dart';
import 'package:report_app/utils/map_picker.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final logger = Logger();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _dobController;
  late TextEditingController _addressController;
  DateTime? _selectedDob;
  File? _selectedImage;
  LatLng? _selectedLocation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppUser?>();
    _emailController = TextEditingController(text: user?.email ?? '');
    _dobController = TextEditingController(
      text: user?.dob != null ? user!.dob! : '',
    );
    _addressController = TextEditingController(text: user?.address ?? '');
    _selectedDob = user?.dob != null ? DateTime.tryParse(user!.dob!) : null;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePickerUtil.showImageSourceDialog(context);
    if (file != null) {
      setState(() {
        _selectedImage = file;
      });
      logger.d('Selected image: ${file.path}');
    }
  }

  Future<void> _pickLocation() async {
    final location = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (context) =>  FreeMapPicker()),
    );
    if (location != null) {
      setState(() {
        _selectedLocation = location;
      });
      // Update address based on selected location
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );
        final place = placemarks.first;
        _addressController.text = '${place.locality}, ${place.administrativeArea}, ${place.country}';
        logger.d('Selected location: ${location.latitude}, ${location.longitude}, address: ${_addressController.text}');
      } catch (e) {
        logger.e('Reverse geocoding failed: $e');
        _addressController.text = 'Unknown address';
      }
    }
  }

  Future<void> _pickDob() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && pickedDate != _selectedDob) {
      setState(() {
        _selectedDob = pickedDate;
        _dobController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
      logger.d('Selected DOB: ${_dobController.text}');
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final user = context.read<AppUser?>();
        if (user == null) {
          throw Exception('No user logged in');
        }

        String? profilePictureUrl;
        if (_selectedImage != null) {
          profilePictureUrl = await CloudinaryUploader.uploadImage(_selectedImage!);
          if (profilePictureUrl == null) {
            throw Exception('Failed to upload profile picture');
          }
        }

        final authService = context.read<AuthService>();
        await authService.updateUserProfile(
          uid: user.userId,
          email: _emailController.text.trim(),
          dob: _dobController.text.trim().isEmpty ? null : _dobController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          latitude: _selectedLocation?.latitude,
          longitude: _selectedLocation?.longitude,
          profilePictureUrl: profilePictureUrl,
        );

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        context.pop(); // Navigate back to ProfileScreen
        logger.d('Profile updated for user: ${user.userId}');
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppUser?>();
    if (user == null) {
      logger.w('No user logged in');
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        elevation: 2,
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture Section
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue.shade100,
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : (user.profilePictureUrl != null
                                ? NetworkImage(user.profilePictureUrl!)
                                : null),
                        child: _selectedImage == null && user.profilePictureUrl == null
                            ? const Icon(Icons.person, size: 50, color: Colors.blue)
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _pickImage,
                    child: const Text(
                      'Change Profile Picture',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Form Fields
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email, color: Colors.blue),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickDob,
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _dobController,
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.cake, color: Colors.blue),
                        hintText: 'Select date of birth',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on, color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _pickLocation,
                  icon: const Icon(Icons.map, color: Colors.white),
                  label: const Text('Pick Location on Map'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Save Changes',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}