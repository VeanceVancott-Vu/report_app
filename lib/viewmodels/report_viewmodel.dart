import 'package:flutter/material.dart';
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
  Future<void> addReport(Report report) async {
    _setLoading(true);


    // Try Nominatim first (network-based)
    final address = await fetchAddressFromNominatim(
      report.location.latitude,
      report.location.longitude,
    );

    if (address != null && address.isNotEmpty) {
      report.location.address = address;
    } else {
      // Fallback to Flutter geocoding
      final placemarks = await placemarkFromCoordinates(
        report.location.latitude,
        report.location.longitude,
      );

      final place = placemarks.first;
      final resolvedAddress =
          '${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}';

      report.location.address = resolvedAddress;
    }

      
    if ((report.location.latitude == 0 || report.location.longitude == 0) &&
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
        logger.d('Forward geocoding failed: $e');
      }
    }



    try {

      await _reportService.uploadReport(report);
      _reports.insert(0, report);
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
}
