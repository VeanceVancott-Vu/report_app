import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '/utils/logger.dart';

class CloudinaryUploader {
  static const String cloudName = 'drxb00t5h';
  static const String apiKey = '272947454727268';
  static const String apiSecret = '7sqBRXddc7hWBQa8IvlTFySuovs';

  static Future<String?> uploadImage(File imageFile) async {
    final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round().toString();
    final signatureString = 'timestamp=$timestamp$apiSecret';
    final signature = sha1.convert(utf8.encode(signatureString)).toString();

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['api_key'] = apiKey
      ..fields['timestamp'] = timestamp
      ..fields['signature'] = signature
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final resBody = await response.stream.bytesToString();
      final jsonData = json.decode(resBody);
      logger.d('Uploaded image to ${jsonData['secure_url']}');
      return jsonData['secure_url'] as String;
    } else {
      logger.d('Upload failed: ${response.statusCode}');
      return null;
    }
  }

  static Future<List<String>> uploadImages(List<File> images) async {
    final List<String> urls = [];

    for (final image in images) {
      final url = await uploadImage(image);
      if (url != null) {
        urls.add(url);
      } else {
        logger.d('Skipped an image due to upload failure');
      }
    }

    return urls;
  }

  static Future<String?> uploadVideo(File videoFile) async {
    final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round().toString();
    final signatureString = 'timestamp=$timestamp$apiSecret';
    final signature = sha1.convert(utf8.encode(signatureString)).toString();

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/video/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['api_key'] = apiKey
      ..fields['timestamp'] = timestamp
      ..fields['signature'] = signature
      ..files.add(await http.MultipartFile.fromPath('file', videoFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final resBody = await response.stream.bytesToString();
      final jsonData = json.decode(resBody);
      logger.d('Uploaded video to ${jsonData['secure_url']}');
      return jsonData['secure_url'] as String;
    } else {
      logger.e('Video upload failed: ${response.statusCode}');
      return null;
    }
  }

  static Future<List<String>> uploadVideos(List<File> videos) async {
    final List<String> urls = [];

    for (final video in videos) {
      final url = await uploadVideo(video);
      if (url != null) {
        urls.add(url);
      } else {
        logger.d('Skipped a video due to upload failure');
      }
    }

    return urls;
  }
}