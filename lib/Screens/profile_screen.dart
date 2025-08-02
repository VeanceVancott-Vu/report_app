import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';
import '../viewmodels/report_viewmodel.dart';
import '../models/report_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final logger = Logger();
  int _currentIndex = 3; // Profile tab index from HomeScreen's BottomNavigationBar

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    logger.d('Bottom navigation tapped: index $index');
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/map');
        break;
      case 2:
        context.go('/settings');
        break;
      case 3:
        // Already on ProfileScreen
        break;
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

  Widget _buildReportSection({
    required String title,
    required Color titleColor,
    required List<Report> reports,
    required ReportStatus status,
  }) {
    const int maxReports = 5;
    final hasMore = reports.length > maxReports;
    final displayReports = reports.take(maxReports).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 8),
        if (reports.isEmpty)
          const Text(
            'No reports in this category.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayReports.length,
            itemBuilder: (context, index) {
              final report = displayReports[index];
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
              );
            },
          ),
        if (hasMore)
          TextButton(
            onPressed: () {
              logger.d('Show all pressed for status: $status');
              context.go('/reports/$status');
            },
            child: const Text(
              'Show All',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppUser? user = context.watch<AppUser?>();
    final reportViewModel = context.watch<ReportViewModel>();

    if (user == null) {
      logger.w('No user logged in');
      return const Center(child: CircularProgressIndicator());
    }

    logger.d("Rendering profile for user: ${user.email}, role=${user.role}");

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        elevation: 2,
        title: const Text(
          "Profile",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              logger.d('Edit profile button pressed for user: ${user.userId}');
              context.push('/edit_profile');
            },
            tooltip: 'Edit Profile',
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
                    backgroundImage: user.profilePictureUrl != null
                        ? NetworkImage(user.profilePictureUrl!)
                        : null,
                    child: user.profilePictureUrl == null
                        ? const Icon(
                            Icons.person,
                            color: Colors.blue,
                            size: 30,
                          )
                        : null,
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
                        Text(
                          'Role: ${user.role}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                "Personal Information",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Container(
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      icon: Icons.cake,
                      label: 'Date of Birth',
                      value: user.dob ?? 'Not provided',
                    ),
                    const Divider(height: 20),
                    _buildInfoRow(
                      icon: Icons.location_on,
                      label: 'Address',
                      value: user.address ?? 'Not provided',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
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
                  } else {
                    final reports = viewModel.reports
                        .where((r) => r.userId == user.userId)
                        .toList();

                    final resolvedReports = reports
                        .where((r) => r.status == ReportStatus.Done)
                        .toList();
                    final resolvingReports = reports
                        .where((r) => r.status == ReportStatus.Processing)
                        .toList();
                    final notResolvedReports = reports
                        .where((r) => r.status == ReportStatus.Submitted)
                        .toList();

                    logger.d('Rendering reports for user: ${user.userId} - '
                        'Resolved: ${resolvedReports.length}, '
                        'Resolving: ${resolvingReports.length}, '
                        'Not Resolved: ${notResolvedReports.length}');

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildReportSection(
                          title: 'Resolved Reports',
                          titleColor: Colors.green,
                          reports: resolvedReports,
                          status: ReportStatus.Done,
                        ),
                        _buildReportSection(
                          title: 'Resolving Reports',
                          titleColor: Colors.yellow.shade700,
                          reports: resolvingReports,
                          status: ReportStatus.Processing,
                        ),
                        _buildReportSection(
                          title: 'Not Yet Resolved Reports',
                          titleColor: Colors.redAccent,
                          reports: notResolvedReports,
                          status: ReportStatus.Submitted,
                        ),
                      ],
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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: Colors.blue.shade700),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}