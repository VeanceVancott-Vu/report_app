import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:report_app/viewmodels/report_viewmodel.dart';
import '../models/report_model.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AdminMapScreen extends StatefulWidget {
  const AdminMapScreen({Key? key}) : super(key: key);

  @override
  State<AdminMapScreen> createState() => _AdminMapScreenState();
}

class _AdminMapScreenState extends State<AdminMapScreen> {
  final Logger logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );
  final MapController _mapController = MapController();
  Report? _selectedReport;
  String? _selectedType;
  String? _selectedStatus;
  String? _selectedUserId;
  bool _showFilterPanel = false;
  bool _sortByDateDescending = true;
  final List<String> _selectedReportIds = [];
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

  final Map<ReportStatus, String> _statusToDisplay = {
    ReportStatus.Submitted: 'Not Yet Resolved',
    ReportStatus.Processing: 'Resolving',
    ReportStatus.Done: 'Resolved',
  };

  @override
  void initState() {
    super.initState();
    context.read<ReportViewModel>().fetchAllReports();
    logger.d('AdminMapScreen initialized, fetching all reports');
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    logger.d('Bottom navigation tapped: index $index');
    switch (index) {
      case 0:
        context.go('/admin');
        break;
      case 1:
        // Already on AdminMapScreen
        break;
      case 2:
        context.go('/admin_analytics');
        break;
      case 3:
        context.go('/admin_profile');
        break;
    }
  }

  void _batchUpdateStatus(String status) async {
    try {
      final reportStatus = _statusToDisplay.entries
          .firstWhere((entry) => entry.value == status)
          .key;
      for (String reportId in _selectedReportIds) {
        await context.read<ReportViewModel>().updateReportStatus(
              reportId,
              reportStatus,
            );
      }
      setState(() {
        _selectedReportIds.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated $status for ${_selectedReportIds.length} reports')),
      );
      logger.d('Batch updated status to $status for reports: $_selectedReportIds');
    } catch (e) {
      logger.e('Error batch updating reports: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update reports: $e')),
      );
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

    if (appUser?.role != 'admin') {
      return const Center(child: Text('Access denied: Admin only'));
    }

    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade700,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            logger.d('Back button pressed on AdminMapScreen');
            context.go('/admin');
          },
        ),
        title: const Text(
          'Admin Map',
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
              });
              logger.d('Filter panel toggled: $_showFilterPanel');
            },
          ),
          IconButton(
            icon: const Icon(Icons.people, color: Colors.white),
            onPressed: () {
              logger.d('Navigate to user management');
              context.go('/admin_profile');
            },
            tooltip: 'User Management',
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

              // Filter reports with valid coordinates
              var filteredReports = viewModel.reports
                  .where((r) => r.location.latitude != 0.0 && r.location.longitude != 0.0)
                  .toList();

              // Apply type filter
              if (_selectedType != null && _selectedType != 'All Types') {
                filteredReports = filteredReports
                    .where((r) => r.type.toLowerCase() == _selectedType!.toLowerCase())
                    .toList();
              }

              // Apply status filter
              if (_selectedStatus != null && _selectedStatus != 'All Statuses') {
                filteredReports = filteredReports
                    .where((r) => _statusToDisplay[r.status] == _selectedStatus)
                    .toList();
              }

              // Apply user filter
              if (_selectedUserId != null && _selectedUserId != 'All Users') {
                filteredReports = filteredReports
                    .where((r) => r.userId == _selectedUserId)
                    .toList();
              }

              // Sort reports
              filteredReports.sort((a, b) => _sortByDateDescending
                  ? b.createdAt.compareTo(a.createdAt)
                  : a.createdAt.compareTo(b.createdAt));

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
                      _selectedReportIds.clear();
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                              if (_selectedReportIds.contains(report.reportId)) {
                                _selectedReportIds.remove(report.reportId);
                              } else {
                                _selectedReportIds.add(report.reportId!);
                              }
                            });
                            logger.d('Marker tapped for report: ${report.reportId}');
                          },
                          onLongPress: () {
                            logger.d('Navigating to report detail: ${report.reportId}');
                            context.push('/report/${report.reportId}');
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                _typeToIcon[report.type.toLowerCase()] ?? Icons.location_pin,
                                color: _selectedReportIds.contains(report.reportId)
                                    ? Colors.red
                                    : _getStatusColor(report.status),
                                size: 40,
                              ),
                              if (_selectedReportIds.contains(report.reportId))
                                const Icon(
                                  Icons.check_circle,
                                  size: 20,
                                  color: Colors.white,
                                ),
                            ],
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
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.indigo.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('users').snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const CircularProgressIndicator();
                          }
                          final users = snapshot.data!.docs
                              .map((doc) => AppUser.fromMap(doc.data() as Map<String, dynamic>))
                              .toList();
                          return DropdownButton<String>(
                            hint: const Text('Filter by User'),
                            value: _selectedUserId,
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('All Users'),
                              ),
                              ...users.map((user) => DropdownMenuItem<String>(
                                    value: user.uid,
                                    child: Text(user.email),
                                  )),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedUserId = value;
                                _selectedReport = null;
                                _selectedReportIds.clear();
                              });
                              logger.d('Selected user filter: $value');
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
                                  _selectedReportIds.clear();
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
                                ..._statusToDisplay.values.map((status) => DropdownMenuItem<String>(
                                      value: status,
                                      child: Text(status),
                                    )),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedStatus = value;
                                  _selectedReport = null;
                                  _selectedReportIds.clear();
                                });
                                logger.d('Selected status filter: $value');
                              },
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _sortByDateDescending = !_sortByDateDescending;
                                  _selectedReportIds.clear();
                                });
                                logger.d('Toggled sort order: $_sortByDateDescending');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(_sortByDateDescending ? 'Sort: Newest' : 'Sort: Oldest'),
                            ),
                          ),
                          if (_selectedReportIds.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButton<String>(
                                hint: const Text('Batch Action'),
                                isExpanded: true,
                                items: _statusToDisplay.values
                                    .map((status) => DropdownMenuItem<String>(
                                          value: status,
                                          child: Text('Set to $status'),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    _batchUpdateStatus(value);
                                  }
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Analytics card
          Positioned(
            top: _showFilterPanel ? 160 : 16,
            right: 16,
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.indigo.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('reports').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Text('Loading stats...');
                    }
                    final reports = snapshot.data!.docs
                        .map((doc) => Report.fromJson(doc.data() as Map<String, dynamic>))
                        .toList();
                    final totalReports = reports.length;
                    final unresolvedReports =
                        reports.where((r) => r.status != ReportStatus.Done).length;
                    final topType = _typeToIcon.keys
                        .map((type) => MapEntry(
                            type, reports.where((r) => r.type == type).length))
                        .reduce((a, b) => a.value > b.value ? a : b)
                        .key;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Reports: $totalReports',
                            style: TextStyle(fontSize: 14, color: Colors.indigo.shade600)),
                        Text('Unresolved: $unresolvedReports',
                            style: TextStyle(fontSize: 14, color: Colors.indigo.shade600)),
                        Text('Top Type: $topType',
                            style: TextStyle(fontSize: 14, color: Colors.indigo.shade600)),
                      ],
                    );
                  },
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
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.indigo.shade200),
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
                          fontWeight: FontWeight.w700,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Type: ${_selectedReport!.type}',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.indigo.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_selectedReport!.status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _statusToDisplay[_selectedReport!.status]!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
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
                                color: Colors.indigo.shade600,
                              ),
                            );
                          }
                          final userData = snapshot.data!.data() as Map<String, dynamic>?;
                          final email = userData?['email'] as String? ?? _selectedReport!.userId;
                          return Text(
                            'Submitted by: $email',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.indigo.shade600,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            logger.d('Navigating to report detail: ${_selectedReport!.reportId}');
                            context.push('/report/${_selectedReport!.reportId}');
                            setState(() {
                              _selectedReport = null;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade700,
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
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey.shade700,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.report), label: "Reports"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: "Analytics"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Admin"),
        ],
      ),
    );
  }
}