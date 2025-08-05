import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:report_app/viewmodels/report_viewmodel.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
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
  int _currentIndex = 2; // Analytics tab
  String _selectedTimeRange = '7 Days'; // Default time range filter
  final List<String> _timeRanges = ['7 Days', '30 Days', 'All Time'];

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
    logger.d('AdminAnalyticsScreen initialized, fetching all reports');
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
        context.go('/admin_map');
        break;
      case 2:
        // Already on AdminAnalyticsScreen
        break;
      case 3:
        context.go('/admin_profile');
        break;
    }
  }

  Map<String, int> _calculateTypeBreakdown(List<Report> reports) {
    final breakdown = <String, int>{};
    for (var type in _typeToIcon.keys) {
      breakdown[type] = reports.where((r) => r.type.toLowerCase() == type).length;
    }
    return breakdown;
  }

  Map<String, int> _calculateReportsOverTime(List<Report> reports, String timeRange) {
    final now = DateTime.now();
    final breakdown = <String, int>{};
    if (timeRange == 'All Time') {
      for (var report in reports) {
        final monthYear = '${report.createdAt.toDate().month}/${report.createdAt.toDate().year}';
        breakdown[monthYear] = (breakdown[monthYear] ?? 0) + 1;
      }
    } else {
      final days = timeRange == '7 Days' ? 7 : 30;
      for (var i = days - 1; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateStr = '${date.day}/${date.month}';
        breakdown[dateStr] = 0;
      }
      for (var report in reports) {
        final reportDate = report.createdAt.toDate();
        if (now.difference(reportDate).inDays < days) {
          final dateStr = '${reportDate.day}/${reportDate.month}';
          breakdown[dateStr] = (breakdown[dateStr] ?? 0) + 1;
        }
      }
    }
    return breakdown;
  }

  @override
  Widget build(BuildContext context) {
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
            logger.d('Back button pressed on AdminAnalyticsScreen');
            context.go('/admin');
          },
        ),
        title: const Text(
          'Analytics Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
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
                    children: _timeRanges
                        .map((range) => ListTile(
                              title: Text(range),
                              onTap: () {
                                setState(() {
                                  _selectedTimeRange = range;
                                });
                                logger.d('Selected time range: $range');
                                Navigator.pop(context);
                              },
                            ))
                        .toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Consumer<ReportViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.isLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (viewModel.error != null) {
                logger.e('Error: ${viewModel.error}');
                return Center(child: Text('Error: ${viewModel.error}'));
              } else if (viewModel.reports.isEmpty) {
                logger.d('No reports found');
                return const Center(child: Text('No reports found.'));
              }

              final reports = viewModel.reports;
              final totalReports = reports.length;
              final unresolvedReports = reports.where((r) => r.status != ReportStatus.Done).length;
              final resolvedReports = reports.where((r) => r.status == ReportStatus.Done).length;
              final typeBreakdown = _calculateTypeBreakdown(reports);
              final reportsOverTime = _calculateReportsOverTime(reports, _selectedTimeRange);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Metrics
                  const Text(
                    'Report Summary',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
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
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Reports: $totalReports',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.indigo,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Unresolved: $unresolvedReports',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.indigo.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Resolved: $resolvedReports',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.indigo.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Report Type Breakdown
                  const Text(
                    'Report Types',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
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
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: typeBreakdown.length,
                      itemBuilder: (context, index) {
                        final type = typeBreakdown.keys.elementAt(index);
                        final count = typeBreakdown[type]!;
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: index < typeBreakdown.length - 1
                                    ? Colors.indigo.shade200
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                          child: ListTile(
                            leading: Icon(
                              _typeToIcon[type] ?? Icons.help,
                              color: Colors.indigo.shade700,
                            ),
                            title: Text(
                              type,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.indigo,
                              ),
                            ),
                            subtitle: Text(
                              'Reports: $count',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.indigo.shade600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Reports Over Time
                  const Text(
                    'Reports Over Time',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
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
                    ),
                    padding: const EdgeInsets.all(16),
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: reportsOverTime.values.isNotEmpty
                            ? reportsOverTime.values.reduce((a, b) => a > b ? a : b).toDouble() + 1
                            : 10,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final date = reportsOverTime.keys.elementAt(value.toInt());
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(
                                    date,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.indigo.shade600,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.indigo.shade600,
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: reportsOverTime.entries.toList().asMap().entries.map(
                              (entry) => BarChartGroupData(
                                x: entry.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: entry.value.value.toDouble(),
                                    color: Colors.indigo.shade700,
                                    width: 16,
                                  ),
                                ],
                              ),
                            ).toList(),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: "Reports",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: "Map",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: "Analytics",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Admin",
          ),
        ],
      ),
    );
  }
}