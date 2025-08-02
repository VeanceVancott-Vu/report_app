import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:report_app/utils/cloudinary_upload.dart';
import 'package:report_app/utils/logger.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';
import 'package:geocoding/geocoding.dart';
import '../utils/reverse_geocoding.dart';

class ReportViewModel extends ChangeNotifier {
  final ReportService _reportService;

  ReportViewModel(this._reportService);

  List<Report> _reports = [];
  List<Report> get reports => _reports;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// Load reports based on user role
  Future<void> fetchAllReports() async {
    _setLoading(true);
    try {
      _reports = await _reportService.getAllReports();
      _error = null;
      logger.d('Fetched ${_reports.length} reports');
    } catch (e) {
      _error = 'Failed to fetch reports: $e';
      logger.e(_error);
    } finally {
      _setLoading(false);
    }
  }

  /// Load reports for a specific user (citizens only)
  Future<void> fetchReportsByUserId(String userId) async {
    _setLoading(true);
    try {
      _reports = await _reportService.getReportsByUserId(userId);
      _error = null;
      logger.d('Fetched ${_reports.length} reports for user $userId');
    } catch (e) {
      _error = 'Failed to fetch reports for user: $e';
      logger.e(_error);
    } finally {
      _setLoading(false);
    }
  }

  /// Upload a new report
  Future<void> addReport(Report report, {required List<File> images}) async {
    _setLoading(true);
    try {
      // Fetch address using Nominatim
      final address = await fetchAddressFromNominatim(
        report.location.latitude,
        report.location.longitude,
      );

      // Use Nominatim address if available
      if (address != null && address.isNotEmpty) {
        report = report.copyWithFromMap({
          'location': ReportLocation(
            latitude: report.location.latitude,
            longitude: report.location.longitude,
            address: address,
          ),
        });
      } 
      // Fallback to Flutter Geocoding if Nominatim fails and coordinates are valid
      else if (report.location.latitude != 0.0 && report.location.longitude != 0.0) {
        try {
          final placemarks = await placemarkFromCoordinates(
            report.location.latitude,
            report.location.longitude,
          );
          final place = placemarks.first;
          final resolvedAddress =
              '${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}';
          report = report.copyWithFromMap({
            'location': ReportLocation(
              latitude: report.location.latitude,
              longitude: report.location.longitude,
              address: resolvedAddress,
            ),
          });
        } catch (e) {
          logger.w('Flutter geocoding failed: $e');
        }
      } else {
        logger.w('Invalid coordinates (0.0, 0.0) - skipping reverse geocoding');
      }

      // Forward geocoding if only address is provided
      if ((report.location.latitude == 0.0 || report.location.longitude == 0.0) &&
          report.location.address != null &&
          report.location.address!.isNotEmpty) {
        try {
          final locations = await locationFromAddress(report.location.address!);
          if (locations.isNotEmpty) {
            final loc = locations.first;
            report = report.copyWithFromMap({
              'location': ReportLocation(
                latitude: loc.latitude,
                longitude: loc.longitude,
                address: report.location.address,
              ),
            });
          }
        } catch (e) {
          logger.w('Forward geocoding failed: $e');
        }
      }

      // Upload images to Cloudinary
      final imageUrls = await CloudinaryUploader.uploadImages(images);

      // Update report with image URLs
      final reportWithImages = report.copyWithFromMap({
        'imageUrls': imageUrls,
      });

      // Upload report to Firestore
      await _reportService.uploadReport(reportWithImages);
      _reports.insert(0, reportWithImages);
      _error = null;
      logger.i('Uploaded report: ${reportWithImages.reportId}');
      notifyListeners();
    } catch (e) {
      _error = 'Failed to upload report: $e';
      logger.e(_error);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Upload images for a report
  Future<List<String>> addReportImages(List<File> images) async {
    try {
      final imageUrls = await CloudinaryUploader.uploadImages(images);
      logger.d('Uploaded ${imageUrls.length} images');
      return imageUrls;
    } catch (e) {
      logger.e('Error uploading images: $e');
      rethrow;
    }
  }

  /// Update report status (admin only)
  Future<void> updateReportStatus(String reportId, ReportStatus newStatus) async {
    _setLoading(true);
    try {
      await _reportService.updateReport(reportId, {
        'status': newStatus.toString().split('.').last,
      });
      final index = _reports.indexWhere((r) => r.reportId == reportId);
      if (index != -1) {
        _reports[index] = _reports[index].copyWithFromMap({
          'status': newStatus,
        });
        _error = null;
        logger.d('Updated report $reportId to status: $newStatus');
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update report status: $e';
      logger.e(_error);
      rethrow;
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
        _error = null;
        logger.d('Updated report: $reportId with $updates');
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update report: $e';
      logger.e(_error);
      rethrow;
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
      _error = null;
      logger.d('Deleted report: $reportId');
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete report: $e';
      logger.e(_error);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Download an image from a Cloudinary URL
  Future<String?> downloadImage(String imageUrl) async {
    logger.d('Attempting to download image: $imageUrl');
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final file = File('${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await file.writeAsBytes(response.bodyBytes);
        logger.d('Image saved successfully: ${file.path}');
        return file.path;
      } else {
        logger.w('Failed to download image: HTTP ${response.statusCode}');
        throw Exception('Failed to download image: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Error downloading image: $e');
      return null;
    }
  }

  /// Get image URLs for a report
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
    logger.d('Retrieved image URLs for report $reportId: ${report.imageUrls}');
    return report.imageUrls;
  }

  /// Utility to toggle loading
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}