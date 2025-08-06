import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerUtil {
  static final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  static Future<File?> pickFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    return image != null ? File(image.path) : null;
  }

  /// Pick image from camera
  static Future<File?> pickFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    return image != null ? File(image.path) : null;
  }

  /// Pick video from gallery
  static Future<File?> pickVideoFromGallery() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    return video != null ? File(video.path) : null;
  }

  /// Pick video from camera
  static Future<File?> pickVideoFromCamera() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
    return video != null ? File(video.path) : null;
  }

  /// Show a dialog to choose image source
  static Future<File?> showImageSourceDialog(BuildContext context) async {
    return showModalBottomSheet<File?>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                final file = await pickFromGallery();
                Navigator.of(context).pop(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () async {
                final file = await pickFromCamera();
                Navigator.of(context).pop(file);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Show a dialog to choose image or video source
  static Future<File?> showMediaSourceDialog(BuildContext context) async {
    return showModalBottomSheet<File?>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blueAccent),
              title: const Text('Choose Image from Gallery'),
              onTap: () async {
                final file = await pickFromGallery();
                Navigator.of(context).pop(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blueAccent),
              title: const Text('Take a Photo'),
              onTap: () async {
                final file = await pickFromCamera();
                Navigator.of(context).pop(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.blueAccent),
              title: const Text('Choose Video from Gallery'),
              onTap: () async {
                final file = await pickVideoFromGallery();
                Navigator.of(context).pop(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_camera_back, color: Colors.blueAccent),
              title: const Text('Record a Video'),
              onTap: () async {
                final file = await pickVideoFromCamera();
                Navigator.of(context).pop(file);
              },
            ),
          ],
        ),
      ),
    );
  }
}