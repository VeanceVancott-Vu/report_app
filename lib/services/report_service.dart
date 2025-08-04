import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/report_model.dart';
import 'package:logger/logger.dart';

class ReportService {
  final CollectionReference _reportCollection =
      FirebaseFirestore.instance.collection('reports');
  final CollectionReference _userCollection =
      FirebaseFirestore.instance.collection('users');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final logger = Logger();

  /// Get the current user's role from Firestore
  Future<String?> _getUserRole() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        logger.w('No authenticated user');
        return null;
      }
      final doc = await _userCollection.doc(user.uid).get();
      if (doc.exists) {
        // Cast doc.data() to Map<String, dynamic> to allow map access
        final data = doc.data() as Map<String, dynamic>?;
        final role = data?['role'] as String? ?? 'citizen';
        logger.d('Fetched role for user ${user.uid}: $role');
        return role;
      }
      logger.w('User document not found for ${user.uid}');
      return null;
    } catch (e) {
      logger.e('Error fetching user role: $e');
      return null;
    }
  }

  /// Upload a new report with auto-generated ID
  Future<void> uploadReport(Report report) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        logger.e('No authenticated user');
        throw Exception('User not authenticated');
      }
      if (report.userId != user.uid) {
        logger.w('Report userId ${report.userId} does not match authenticated user ${user.uid}');
        throw Exception('Unauthorized userId');
      }
      final docRef = _reportCollection.doc(); // Auto-generated ID
      final updatedReport = report.copyWithFromMap({'reportId': docRef.id});
      await docRef.set(updatedReport.toJson());
      logger.d('Uploaded report: ${docRef.id}');
    } catch (e) {
      logger.e('Error uploading report: $e');
      rethrow;
    }
  }

Future<List<Report>> getAllReports() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        logger.e('No authenticated user');
        throw Exception('User not authenticated');
      }

      // Fetch all reports without user-specific or role-based filtering
      final snapshot = await _reportCollection.get();
      final reports = snapshot.docs
          .map((doc) => Report.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      logger.d('Fetched ${reports.length} reports for user: ${user.uid}');
      return reports;
    } catch (e) {
      logger.e('Error fetching reports: $e');
      rethrow;
    }
  }

  /// Get report by ID
  Future<Report?> getReportById(String reportId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        logger.e('No authenticated user');
        throw Exception('User not authenticated');
      }
      final role = await _getUserRole() ?? 'citizen';

      final doc = await _reportCollection.doc(reportId).get();
      if (doc.exists) {
        final report = Report.fromJson(doc.data() as Map<String, dynamic>);
        if (role != 'admin' && report.userId != user.uid) {
          logger.w('Unauthorized access to report $reportId by user ${user.uid}');
          throw Exception('Unauthorized');
        }
        logger.d('Fetched report: $reportId');
        return report;
      }
      logger.w('Report not found: $reportId');
      return null;
    } catch (e) {
      logger.e('Error fetching report $reportId: $e');
      rethrow;
    }
  }

  /// Get reports by userId (for citizens)
  Future<List<Report>> getReportsByUserId(String userId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        logger.e('No authenticated user');
        throw Exception('User not authenticated');
      }
      final role = await _getUserRole() ?? 'citizen';
      if (role != 'admin' && user.uid != userId) {
        logger.w('Unauthorized access by user ${user.uid} to reports of $userId');
        throw Exception('Unauthorized');
      }

      final snapshot = await _reportCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      final reports = snapshot.docs
          .map((doc) => Report.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      logger.d('Fetched ${reports.length} reports for user: $userId');
      return reports;
    } catch (e) {
      logger.e('Error fetching reports for user $userId: $e');
      rethrow;
    }
  }

  /// Update a report
  Future<void> updateReport(String reportId, Map<String, dynamic> updates) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        logger.e('No authenticated user');
        throw Exception('User not authenticated');
      }
      final role = await _getUserRole() ?? 'citizen';
      if (updates.containsKey('userId') && role != 'admin') {
        logger.w('Non-admin user ${user.uid} attempted to change userId');
        throw Exception('Unauthorized to change userId');
      }
      await _reportCollection.doc(reportId).update(updates);
      logger.d('Updated report: $reportId with $updates');
    } catch (e) {
      logger.e('Error updating report $reportId: $e');
      rethrow;
    }
  }

  /// Delete a report
  Future<void> deleteReport(String reportId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        logger.e('No authenticated user');
        throw Exception('User not authenticated');
      }
      final role = await _getUserRole() ?? 'citizen';
      if (role != 'admin') {
        // Check if the report belongs to the user
        final reportSnapshot = await _reportCollection.doc(reportId).get();
        if (!reportSnapshot.exists) {
          logger.e('Report $reportId does not exist');
          throw Exception('Report does not exist');
        }
        final reportData = reportSnapshot.data() as Map<String, dynamic>?;
        if (reportData == null) {
          logger.e('Report $reportId has no data');
          throw Exception('Report data is missing');
        }
        final reportUserId = reportData['userId'] as String?;
        if (reportUserId != user.uid) {
          logger.w('Non-admin user ${user.uid} attempted to delete report $reportId owned by $reportUserId');
          throw Exception('Only admins or the report owner can delete this report');
        }
      }
      await _reportCollection.doc(reportId).delete();
      logger.d('Deleted report: $reportId');
    } catch (e) {
      logger.e('Error deleting report $reportId: $e');
      rethrow;
    }
  }
}