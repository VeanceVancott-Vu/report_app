import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:report_app/viewmodels/report_viewmodel.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Logger logger = Logger();
  final MapController _mapController = MapController();
  Report? _selectedReport;
  String? _selectedType;
  String? _selectedStatus;
  String? _selectedReportSource; // null for All Reports, "My Reports", or userId
  bool _showFilterPanel = false;
  int _currentIndex = 1; // Map tab

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
    _selectedReportSource = null; // Default to All Reports
    context.read<ReportViewModel>().fetchAllReports();
    logger.d('MapScreen initialized, fetching all reports');
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    logger.d('Bottom navigation tapped: index $index');
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        // Already on MapScreen
        break;
      case 2:
        context.go('/settings');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  String _getDisplayStatus(ReportStatus status) {
    switch (status) {
      case ReportStatus.Submitted:
        return "Not Yet Resolved";
      case ReportStatus.Processing:
        return "Resolving";
      case ReportStatus.Done:
        return "Resolved";
      default:
        return "Unknown";
    }
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

  @override
  Widget build(BuildContext context) {
    final reportViewModel = context.watch<ReportViewModel>();
    final appUser = context.watch<AppUser?>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        elevation: 2,
        title: const Text(
          'Reports Map',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _showFilterPanel ? Icons.filter_list_off : Icons.filter_list,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showFilterPanel = !_showFilterPanel;
                _selectedReport = null; // Close popup when toggling filter
              });
              logger.d('Filter panel toggled: $_showFilterPanel');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Consumer<ReportViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.isLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (viewModel.error != null) {
                logger.e('Error: ${viewModel.error}');
                return Center(child: Text('Error: ${viewModel.error}'));
              } else if (viewModel.reports.isEmpty) {
                logger.d('No reports found for map');
                return const Center(child: Text('No reports found.'));
              }

              // Filter reports by coordinates
              var filteredReports = viewModel.reports
                  .where((r) =>
                      r.location.latitude != 0.0 && r.location.longitude != 0.0)
                  .toList();

              // Apply report source filter
              if (_selectedReportSource == 'My Reports' && appUser != null) {
                filteredReports = filteredReports
                    .where((r) => r.userId == appUser.userId)
                    .toList();
              } else if (_selectedReportSource != null &&
                  _selectedReportSource != 'My Reports') {
                filteredReports = filteredReports
                    .where((r) => r.userId == _selectedReportSource)
                    .toList();
              }

              // Apply type filter
              if (_selectedType != null && _selectedType != 'All Types') {
                filteredReports = filteredReports
                    .where((r) => r.type.toLowerCase() == _selectedType!.toLowerCase())
                    .toList();
              }

              // Apply status filter
              if (_selectedStatus != null && _selectedStatus != 'All Statuses') {
                filteredReports = filteredReports
                    .where((r) => _getDisplayStatus(r.status) == _selectedStatus)
                    .toList();
              }

              logger.d('Rendering ${filteredReports.length} filtered reports on map');

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: filteredReports.isNotEmpty
                      ? LatLng(
                          filteredReports.first.location.latitude,
                          filteredReports.first.location.longitude,
                        )
                      : const LatLng(16.0678, 108.2208), // Default: Hội An
                  initialZoom: 13.0,
                  onTap: (tapPosition, point) {
                    setState(() {
                      _selectedReport = null;
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.example.report_app',
                  ),
                  MarkerLayer(
                    markers: filteredReports.map((report) {
                      return Marker(
                        point: LatLng(
                          report.location.latitude,
                          report.location.longitude,
                        ),
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedReport = report;
                            });
                            logger.d(
                                'Marker tapped for report: ${report.reportId}');
                          },
                          child: Icon(
                            _typeToIcon[report.type.toLowerCase()] ??
                                Icons.location_pin,
                            color: _getStatusColor(report.status),
                            size: 40,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
          // Filter panel
          if (_showFilterPanel)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final users = snapshot.data!.docs
                              .map((doc) => AppUser.fromMap(doc.data() as Map<String, dynamic>))
                              .toList();
                          return DropdownButton<String>(
                            hint: const Text('Filter by Report Source'),
                            value: _selectedReportSource,
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('All Reports'),
                              ),
                              if (appUser != null)
                                const DropdownMenuItem<String>(
                                  value: 'My Reports',
                                  child: Text('My Reports'),
                                ),
                              ...users
                                  .where((user) =>
                                      appUser == null || user.uid != appUser.userId)
                                  .map((user) => DropdownMenuItem<String>(
                                        value: user.uid,
                                        child: Text('User: ${user.email}'),
                                      ))
                                  .toList()
                                ..sort((a, b) => (a.child as Text)
                                    .data!
                                    .compareTo((b.child as Text).data!)),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedReportSource = value;
                                _selectedReport = null;
                              });
                              logger.d('Selected report source filter: $value');
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 8),
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
                                  _selectedReport = null;
                                });
                                logger.d('Selected type filter: $value');
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
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
                                ...[
                                  'Not Yet Resolved',
                                  'Resolving',
                                  'Resolved'
                                ].map((status) => DropdownMenuItem<String>(
                                      value: status,
                                      child: Text(status),
                                    )),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedStatus = value;
                                  _selectedReport = null;
                                });
                                logger.d('Selected status filter: $value');
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Popup for selected report
          if (_selectedReport != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedReport!.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Type: ${_selectedReport!.type}',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status: ${_getDisplayStatus(_selectedReport!.status)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: _getStatusColor(_selectedReport!.status),
                        ),
                      ),
                      const SizedBox(height: 4),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(_selectedReport!.userId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.hasError) {
                            return Text(
                              'Submitted by: ${_selectedReport!.userId}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            );
                          }
                          final userData = snapshot.data!.data() as Map<String, dynamic>?;
                          final email = userData?['email'] as String? ?? _selectedReport!.userId;
                          return Text(
                            'Submitted by: $email',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            logger.d(
                                'Navigating to report detail: ${_selectedReport!.reportId}');
                            context.push(
                                '/report/${_selectedReport!.reportId}',
                                extra: _selectedReport);
                            setState(() {
                              _selectedReport = null;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('View Details'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
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