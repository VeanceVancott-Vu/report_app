import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:report_app/utils/cloudinary_upload.dart';
import 'package:report_app/utils/logger.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';
import 'package:geocoding/geocoding.dart';
import '../utils/reverse_geocoding.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:io';


class ReportViewModel extends ChangeNotifier {
  final ReportService _reportService;

  ReportViewModel(this._reportService);

  List<Report> _reports = [];
  List<Report> get reports => _reports;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// Load all reports
  Future<void> fetchAllReports() async {
    _setLoading(true);
    try {
      _reports = await _reportService.getAllReports();
      _error = null;
    } catch (e) {
      _error = 'Failed to fetch reports: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Load reports for a specific user
  Future<void> fetchReportsByUserId(String userId) async {
    _setLoading(true);
    try {
      _reports = await _reportService.getReportsByUserId(userId);
      _error = null;
    } catch (e) {
      _error = 'Failed to fetch reports for user: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Upload a new report
  Future<void> addReport(Report report, {required List<File> images}) async {
    _setLoading(true);


      final address = await fetchAddressFromNominatim(
        report.location.latitude,
        report.location.longitude,
      );

      // ✅ Use Nominatim address if available
      if (address != null && address.isNotEmpty) {
        report.location.address = address;
      } 
      // ✅ If Nominatim fails AND coordinates are valid, use Flutter Geocoding fallback
      else if (report.location.latitude != 0.0 &&
              report.location.longitude != 0.0) {
        try {
          final placemarks = await placemarkFromCoordinates(
            report.location.latitude,
            report.location.longitude,
          );

          final place = placemarks.first;
          final resolvedAddress =
              '${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}';

          report.location.address = resolvedAddress;
        } catch (e) {
          logger.w("⚠️ Flutter geocoding failed: $e");
        }
      } 
      else {
        logger.w("⚠️ Invalid coordinates (0.0, 0.0) - skipping reverse geocoding");
      }

      // If we only have address but no coordinates, perform forward geocoding
      if ((report.location.latitude == 0.0 || report.location.longitude == 0.0) &&
          report.location.address != null &&
          report.location.address!.isNotEmpty) {
        try {
          final locations = await locationFromAddress(report.location.address!);

          if (locations.isNotEmpty) {
            final loc = locations.first;
            report.location.latitude = loc.latitude;
            report.location.longitude = loc.longitude;
          }
        } catch (e) {
          logger.d('⚠️ Forward geocoding failed: $e');
        }
      }

            
        

          
    final imageUrls = await CloudinaryUploader.uploadImages(images);

    final reportWithImages = report.copyWithFromMap({
      'imageUrls': imageUrls,
    });


    try {
      logger.i(reportWithImages.toString() );
      await _reportService.uploadReport(reportWithImages);
      _reports.insert(0, reportWithImages);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to upload report: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Update existing report
  Future<void> updateReport(String reportId, Map<String, dynamic> updates) async {
    _setLoading(true);
    try {
      await _reportService.updateReport(reportId, updates);
      final index = _reports.indexWhere((r) => r.reportId == reportId);
      if (index != -1) {
        _reports[index] = _reports[index].copyWithFromMap(updates);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update report: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Delete report
  Future<void> deleteReport(String reportId) async {
    _setLoading(true);
    try {
      await _reportService.deleteReport(reportId);
      _reports.removeWhere((r) => r.reportId == reportId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete report: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Utility to toggle loading
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }




   List<String> getImageUrlsForReport(String reportId) {
    final report = _reports.firstWhere(
      (report) => report.reportId == reportId,
      orElse: () => Report(
        reportId: '',
        title: '',
        type: '',
        description: '',
        imageUrls: [],
        location: ReportLocation(latitude: 0, longitude: 0, address: ''),
        status: ReportStatus.Submitted,
        createdAt: Timestamp.now(),
        userId: '',
      ),
    );
    return report.imageUrls;
  }

  // Downloads an image from a Cloudinary URL and returns the file path
  Future<String?> downloadImage(String imageUrl) async {
    logger.d('Attempting to download image: $imageUrl');
    try {
      final response = await http.get(Uri.parse(imageUrl));
      print('HTTP response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        // Create a temporary file to store the image
        final file = File('${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
        print('Saving image to: ${file.path}');
        await file.writeAsBytes(response.bodyBytes);
        print('Image saved successfully: ${file.path}');
        return file.path;
      } else {
        logger.d('Failed to download image: HTTP ${response.statusCode}');
        throw Exception('Failed to download image: ${response.statusCode}');
      }
    } catch (e) {
      logger.d('Error downloading image: $e');
      return null;
    }
  }


  
}
