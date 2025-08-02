import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';
import '../viewmodels/report_viewmodel.dart';
import '../models/report_model.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  String _location = "Loading location...";
  int _currentIndex = 0;
  final logger = Logger();
<<<<<<< HEAD
  ReportStatus? _selectedFilter; // For filtering reports by status
  String _filterTitle = "All Reports"; // Dynamic title based on filter

=======

  // Map to associate report types with icons (same as HomeScreen)
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
  final Map<String, IconData> _typeToIcon = {
    'broken equipment': Icons.build,
    'infrastructure': Icons.architecture,
    'traffic signal issue': Icons.traffic,
    'power outage': Icons.power_off,
    'water leakage': Icons.water_damage,
    'sewage issue': Icons.plumbing,
    'waste management': Icons.delete,
    'environment': Icons.eco,
    'graffiti / vandalism': Icons.format_paint,
    'noise disturbance': Icons.volume_up,
    'public safety': Icons.security,
    'illegal parking': Icons.local_parking,
    'animal control': Icons.pets,
    'pest infestation': Icons.bug_report,
    'public transportation': Icons.directions_bus,
    'other': Icons.help,
  };

  @override
  void initState() {
    super.initState();
    _getLocation();
<<<<<<< HEAD
=======
    // Fetch reports using ViewModel
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
    context.read<ReportViewModel>().fetchAllReports();
    logger.d('AdminHomeScreen initialized, fetching all reports');
  }

  Future<void> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _location = "Location service disabled.";
      });
      logger.w('Location service disabled');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _location = "Location permission denied.";
        });
        logger.w('Location permission denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _location = "Location permission permanently denied.";
      });
      logger.w('Location permission permanently denied');
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
        localeIdentifier: "en_US",
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _location =
              "${place.thoroughfare}, ${place.locality}, ${place.administrativeArea}${place.country != null && place.country!.isNotEmpty ? ", ${place.country}" : ""}";
        });
        logger.d('Location fetched: $_location');
      } else {
        setState(() {
          _location = "Location details not found.";
        });
        logger.w('Location details not found');
      }
    } catch (e) {
      setState(() {
        _location = "Error getting location: ${e.toString()}";
      });
      logger.e('Error getting location: $e');
    }
  }

  Widget _buildReportTile(
    String title,
    String type,
    String description,
    String status,
    Color statusColor,
    IconData icon,
    String timeAgo,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
<<<<<<< HEAD
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.indigo.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.shade100.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
=======
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade400),
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
<<<<<<< HEAD
            Icon(icon, size: 30, color: Colors.indigo.shade700),
=======
            Icon(icon, size: 30, color: Colors.black87),
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
<<<<<<< HEAD
                      fontWeight: FontWeight.w700,
                      color: Colors.indigo,
=======
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Type: $type',
<<<<<<< HEAD
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.indigo.shade600,
=======
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.black54,
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeAgo,
<<<<<<< HEAD
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
=======
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.Submitted:
        return Colors.redAccent;
      case ReportStatus.Processing:
        return Colors.orangeAccent;
      case ReportStatus.Done:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForType(String type) {
    String key = type.toLowerCase();
    return _typeToIcon[key] ?? Icons.help;
  }

  String _getTimeAgo(Timestamp createdAt) {
    final now = DateTime.now();
    final reportTime = createdAt.toDate();
    final difference = now.difference(reportTime);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  String _getDisplayStatus(ReportStatus status) {
    switch (status) {
      case ReportStatus.Submitted:
        return "Not yet resolved";
      case ReportStatus.Processing:
        return "Resolving";
      case ReportStatus.Done:
        return "Resolved";
      default:
        return "Unknown";
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    logger.d('Bottom navigation tapped: index $index');
    // TODO: Implement navigation for other tabs (e.g., Map, Admin Settings)
  }

<<<<<<< HEAD
  void _filterReports(ReportStatus? status) {
    setState(() {
      _selectedFilter = status;
      _filterTitle = status == null ? "All Reports" : "${_getDisplayStatus(status)} Reports";
    });
    logger.d('Filtering reports by status: $status, title: $_filterTitle');
  }

=======
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
  @override
  Widget build(BuildContext context) {
    final AppUser? user = context.watch<AppUser?>();
    final reportViewModel = context.watch<ReportViewModel>();

    if (user == null) {
      logger.w('No user logged in');
      return const Center(child: CircularProgressIndicator());
    }

<<<<<<< HEAD
    logger.d("Admin logged in: ${user.email}, role=${user.role}");

    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade700,
        elevation: 2,
        title: const Text(
          "Admin Control Panel",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
=======
    logger.d("Admin logged in: ${user.email}");

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
          onPressed: () {
            logger.d('Menu button pressed');
            // TODO: Implement admin menu
          },
        ),
<<<<<<< HEAD
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                builder: (context) => Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('All Reports'),
                        onTap: () {
                          _filterReports(null);
                          Navigator.pop(context);
                        },
                      ),
                      ...ReportStatus.values.map((status) => ListTile(
                            title: Text(_getDisplayStatus(status)),
                            onTap: () {
                              _filterReports(status);
                              Navigator.pop(context);
                            },
                          )),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
=======
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
<<<<<<< HEAD
                    backgroundColor: Colors.indigo.shade100,
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.indigo,
                      size: 30,
                    ),
=======
                    backgroundColor: Colors.blueAccent.withOpacity(0.2),
                    child: const Icon(Icons.admin_panel_settings, color: Colors.blueAccent, size: 30),
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Admin: ${user.email}",
                          style: const TextStyle(
<<<<<<< HEAD
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
=======
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
<<<<<<< HEAD
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.indigo.shade600,
                            ),
=======
                            Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "Location: $_location",
<<<<<<< HEAD
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.indigo.shade600,
                                ),
=======
                                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
<<<<<<< HEAD
              Text(
                _filterTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
=======
              const Text(
                "All Reports",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
              ),
              const SizedBox(height: 16),
              Consumer<ReportViewModel>(
                builder: (context, viewModel, child) {
                  if (viewModel.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (viewModel.error != null) {
                    logger.e('Error: ${viewModel.error}');
                    return Center(child: Text('Error: ${viewModel.error}'));
                  } else if (viewModel.reports.isEmpty) {
                    logger.d('No reports found');
                    return const Center(child: Text('No reports found.'));
                  } else {
<<<<<<< HEAD
                    final reports = _selectedFilter == null
                        ? viewModel.reports
                        : viewModel.reports
                            .where((r) => r.status == _selectedFilter)
                            .toList();
=======
                    final reports = viewModel.reports;
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
                    logger.d('Rendering ${reports.length} reports');
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reports.length,
                      itemBuilder: (context, index) {
                        final report = reports[index];
                        return _buildReportTile(
                          report.title,
                          report.type,
                          report.description,
                          _getDisplayStatus(report.status),
                          _getStatusColor(report.status),
                          _getIconForType(report.type),
                          _getTimeAgo(report.createdAt),
                          () {
                            logger.d('Navigating to report detail: ${report.reportId}');
<<<<<<< HEAD
                            context.go('/admin/report/${report.reportId}',
                                extra: report);
=======
                            context.go('/admin/report/${report.reportId}', extra: report);
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
                          },
                        );
                      },
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        iconSize: 28,
<<<<<<< HEAD
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey.shade700,
=======
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey[700],
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
<<<<<<< HEAD
          BottomNavigationBarItem(
              icon: Icon(Icons.report), label: "Reports"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"),
          BottomNavigationBarItem(
              icon: Icon(Icons.analytics), label: "Analytics"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: "Admin"),
=======
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Reports"),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: "Map"),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: "Settings"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
>>>>>>> 4242409f0f5550ed92524603c314442f494e19fb
        ],
      ),
    );
  }
}