import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import '../models/report_model.dart';
import '../viewmodels/report_viewmodel.dart';

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
    // Fetch all reports from all users when the screen initializes
    context.read<ReportViewModel>().fetchAllReports();
    logger.d('MapScreen initialized, fetching all reports from all users');
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
        // Already on MapScreen, no navigation needed
        break;
      case 2:
        context.go('/settings');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportViewModel = context.watch<ReportViewModel>();

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
              Icons.filter_list,
              color: _showFilterPanel ? Colors.white70 : Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showFilterPanel = !_showFilterPanel;
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

              // Filter reports to ensure valid coordinates (no user-specific filtering)
              var filteredReports = viewModel.reports
                  .where((r) =>
                      r.location.latitude != 0.0 && r.location.longitude != 0.0)
                  .toList();

              // Apply type filter
              if (_selectedType != null) {
                filteredReports = filteredReports
                    .where((r) => r.type.toLowerCase() == _selectedType!.toLowerCase())
                    .toList();
              }

              // Apply status filter
              if (_selectedStatus != null) {
                filteredReports = filteredReports
                    .where((r) => r.status.toString() == _selectedStatus)
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
                      : const LatLng(0.0, 0.0),
                  initialZoom: 13.0,
                  onTap: (tapPosition, point) {
                    // Close popup when tapping outside
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
              top: 0,
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
                    children: [
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
                                  _selectedReport = null; // Close popup on filter change
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
                                  _selectedReport = null; // Close popup on filter change
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
          // Popup window for selected report
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
                              _selectedReport = null; // Close popup
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

  // Helper methods for status display and color
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
}