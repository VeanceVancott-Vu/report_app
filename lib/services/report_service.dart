import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';

class ReportService {
  final CollectionReference _reportCollection =
      FirebaseFirestore.instance.collection('reports');

  /// Upload a new report with auto-generated ID
  Future<void> uploadReport(Report report) async {
    final docRef = _reportCollection.doc(); // Auto-generated ID
    final updatedReport = report.copyWithFromMap({'reportId': docRef.id});
    await docRef.set(updatedReport.toJson());
  }

  /// Get all reports
  Future<List<Report>> getAllReports() async {
    final snapshot =
        await _reportCollection.orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => Report.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Get report by ID
  Future<Report?> getReportById(String reportId) async {
    final doc = await _reportCollection.doc(reportId).get();
    if (doc.exists) {
      return Report.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  /// Get reports by userId
  Future<List<Report>> getReportsByUserId(String userId) async {
    final snapshot =
        await _reportCollection.where('userId', isEqualTo: userId).get();
    return snapshot.docs
        .map((doc) => Report.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Update a report
  Future<void> updateReport(String reportId, Map<String, dynamic> updates) async {
    await _reportCollection.doc(reportId).update(updates);
  }

  /// Delete a report
  Future<void> deleteReport(String reportId) async {
    await _reportCollection.doc(reportId).delete();
  }
}
