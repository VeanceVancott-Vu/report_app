import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for report status
enum ReportStatus { Submitted, Processing, Done }

/// Location model
class ReportLocation {
  double latitude;
  double longitude;
  String? address;

  ReportLocation({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      };

  factory ReportLocation.fromJson(Map<String, dynamic> json) => ReportLocation(
        latitude: json['latitude'] ?? 0.0,
        longitude: json['longitude'] ?? 0.0,
        address: json['address'],
      );
}

/// Main Report model
class Report {
  final String? reportId;
  final String title;
  final String type;
  final String description;
  late final List<String> imageUrls;
  late final List<String> videoUrls; // Added videoUrls
  final ReportLocation location;
  final ReportStatus status;
  final Timestamp createdAt;
  final String userId;

  Report({
    this.reportId,
    required this.title,
    required this.type,
    required this.description,
    required this.imageUrls,
    required this.videoUrls, // Added videoUrls
    required this.location,
    required this.status,
    required this.createdAt,
    required this.userId,
  });

  /// Convert ReportStatus enum to string for storage
  static String statusToString(ReportStatus status) {
    return status.toString().split('.').last;
  }

  /// Convert string to ReportStatus enum
  static ReportStatus statusFromString(String status) {
    return ReportStatus.values.firstWhere(
      (e) => e.toString().split('.').last == status,
      orElse: () => ReportStatus.Submitted,
    );
  }

  /// Convert object to JSON for Firestore
  Map<String, dynamic> toJson() => {
        'reportId': reportId,
        'title': title,
        'type': type,
        'description': description,
        'imageUrls': imageUrls,
        'videoUrls': videoUrls, // Added videoUrls
        'location': location.toJson(),
        'status': statusToString(status),
        'createdAt': createdAt,
        'userId': userId,
      };

  /// Create object from Firestore snapshot or JSON
  factory Report.fromJson(Map<String, dynamic> json) => Report(
        reportId: json['reportId'],
        title: json['title'] ?? '',
        type: json['type'] ?? '',
        description: json['description'] ?? '',
        imageUrls: List<String>.from(json['imageUrls'] ?? []),
        videoUrls: List<String>.from(json['videoUrls'] ?? []), // Added videoUrls
        location: ReportLocation.fromJson(json['location'] ?? {'latitude': 0.0, 'longitude': 0.0}),
        status: statusFromString(json['status'] ?? 'Submitted'),
        createdAt: json['createdAt'] ?? Timestamp.now(),
        userId: json['userId'] ?? '',
      );

  Report copyWithFromMap(Map<String, dynamic> updates) {
    return Report(
      reportId: updates['reportId'] ?? reportId,
      title: updates['title'] ?? title,
      type: updates['type'] ?? type,
      description: updates['description'] ?? description,
      imageUrls: List<String>.from(updates['imageUrls'] ?? imageUrls),
      videoUrls: List<String>.from(updates['videoUrls'] ?? videoUrls), // Added videoUrls
      location: updates['location'] != null
          ? ReportLocation.fromJson(updates['location'])
          : location,
      status: updates['status'] != null
          ? ReportStatus.values.firstWhere(
              (e) => e.name == updates['status'],
              orElse: () => status,
            )
          : status,
      createdAt: updates['createdAt'] ?? createdAt,
      userId: updates['userId'] ?? userId,
    );
  }

  @override
  String toString() {
    return '''
Report(
  reportId: $reportId,
  userId: $userId,
  title: $title,
  type: $type,
  description: $description,
  imageUrls: $imageUrls,
  videoUrls: $videoUrls,
  location: $location,
  status: $status,
  createdAt: $createdAt
)
''';
  }
}