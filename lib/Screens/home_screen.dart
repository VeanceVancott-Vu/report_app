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

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _location = "Loading location...";
  int _currentIndex = 0;
  final logger = Logger();
  String? _selectedType;
  String? _selectedStatus;
  bool _sortAscending = true;

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
    final user = context.read<AppUser?>();
    if (user != null) {
      context.read<ReportViewModel>().fetchReportsByUserId(user.userId);
      logger.d('HomeScreen initialized, fetching reports for user: ${user.userId}');
    }
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
    VoidCallback onDelete,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30, color: Colors.blue.shade700),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Type: $type',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade600,
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
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent, size: 24),
                  onPressed: onDelete,
                  tooltip: 'Delete Report',
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
    switch (index) {
      case 0:
        // Already on HomeScreen (Reports), no navigation needed
        break;
      case 1:
        context.go('/map');
        break;
      case 2:
        context.go('/settings');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  Future<void> _deleteReport(BuildContext context, String reportId) async {
    final viewModel = context.read<ReportViewModel>();
    try {
      final user = context.read<AppUser?>();
      logger.d('User UID: ${user?.userId}');
      final reportData = await FirebaseFirestore.instance.collection('reports').doc(reportId).get();
      logger.d('Report userId: ${reportData.data()?['userId']}');

      await viewModel.deleteReport(reportId);
      logger.d('Deleted report: $reportId');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report deleted successfully')),
      );
    } catch (e) {
      logger.e('Error deleting report $reportId: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting report: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppUser? user = context.watch<AppUser?>();
    final reportViewModel = context.watch<ReportViewModel>();

    if (user == null) {
      logger.w('No user logged in');
      return const Center(child: CircularProgressIndicator());
    }

    logger.d("User logged in: ${user.email}, role=${user.role}");

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        elevation: 2,
        title: const Text(
          "My Reports",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              logger.d('Navigating to new report screen');
              context.go('/new_report');
            },
          ),
        ],
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
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(
                      Icons.person,
                      color: Colors.blue,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "Location: $_location",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
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
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      hint: const Text('Filter by Type'),
                      value: _selectedType,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Types'),
                        ),
                        ..._typeToIcon.keys.map((type) => DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value;
                        });
                        logger.d('Selected type filter: $value');
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButton<String>(
                      hint: const Text('Filter by Status'),
                      value: _selectedStatus,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Statuses'),
                        ),
                        ...ReportStatus.values.map((status) => DropdownMenuItem<String>(
                              value: status.toString(),
                              child: Text(_getDisplayStatus(status)),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value;
                        });
                        logger.d('Selected status filter: $value');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: Icon(
                      _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 16,
                    ),
                    label: const Text('Sort by Date'),
                    onPressed: () {
                      setState(() {
                        _sortAscending = !_sortAscending;
                      });
                      logger.d('Sort order changed to: ${_sortAscending ? "ascending" : "descending"}');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                "Your Reports",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
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
                    logger.d('No reports found for user: ${user.userId}');
                    return const Center(child: Text('No reports found.'));
                  } else {
                    var reports = viewModel.reports
                        .where((r) => r.userId == user.userId)
                        .toList();

                    // Apply type filter
                    if (_selectedType != null) {
                      reports = reports.where((r) => r.type.toLowerCase() == _selectedType!.toLowerCase()).toList();
                    }

                    // Apply status filter
                    if (_selectedStatus != null) {
                      reports = reports.where((r) => r.status.toString() == _selectedStatus).toList();
                    }

                    // Sort by date
                    reports.sort((a, b) {
                      final dateA = a.createdAt.toDate();
                      final dateB = b.createdAt.toDate();
                      return _sortAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
                    });

                    logger.d('Rendering ${reports.length} filtered and sorted reports for user: ${user.userId}');
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
                            context.go('/report/${report.reportId}', extra: report);
                          },
                          () {
                            logger.d('Delete button pressed for report: ${report.reportId}');
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Report'),
                                content: const Text('Are you sure you want to delete this report?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      logger.d('Delete cancelled for report: ${report.reportId}');
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _deleteReport(context, report.reportId!);
                                    },
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.redAccent),
                                    ),
                                  ),
                                ],
                              ),
                            );
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
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey.shade700,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.report), label: "Reports"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}