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
  bool _showAllTypes = false; // Toggle for showing all report types
  bool _showAllLocations = false; // Toggle for showing all locations
  int _currentWeekIndexTotal = 0; // Week index for Total
  int _currentWeekIndexResolving = 0; // Week index for Resolving
  int _currentWeekIndexNotResolved = 0; // Week index for Not Yet Resolved
  int _currentWeekIndexResolved = 0; // Week index for Resolved
  int _currentMonthIndexTotal = 0; // Month index for Total
  int _currentMonthIndexResolving = 0; // Month index for Resolving
  int _currentMonthIndexNotResolved = 0; // Month index for Not Yet Resolved
  int _currentMonthIndexResolved = 0; // Month index for Resolved

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

  List<MapEntry<String, int>> _calculateTypeBreakdown(List<Report> reports, {bool showAll = false}) {
    final breakdown = <String, int>{};
    for (var type in _typeToIcon.keys) {
      breakdown[type] = reports.where((r) => r.type.toLowerCase() == type).length;
    }
    final sorted = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return showAll ? sorted : sorted.take(5).toList();
  }

  List<MapEntry<String, int>> _calculateLocationBreakdown(List<Report> reports, {bool showAll = false}) {
    final breakdown = <String, int>{};
    for (var report in reports) {
      final location = report.location.address != null
          ? report.location.address!
          : 'Lat: ${report.location.latitude.toStringAsFixed(4)}, Long: ${report.location.longitude.toStringAsFixed(4)}';
      breakdown[location] = (breakdown[location] ?? 0) + 1;
    }
    final sorted = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return showAll ? sorted : sorted.take(5).toList();
  }

  Map<String, int> _calculateReportsOverTime(
    List<Report> reports,
    String timeRange, {
    ReportStatus? statusFilter,
    int? weekIndex,
    int? monthIndex,
  }) {
    final now = DateTime.now();
    final breakdown = <String, int>{};

    if (timeRange == '7 Days') {
      // Show last 7 days
      for (var i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateStr = '${date.day}/${date.month}';
        breakdown[dateStr] = 0;
      }
      for (var report in reports) {
        if (statusFilter == null || report.status == statusFilter) {
          final reportDate = report.createdAt.toDate();
          if (now.difference(reportDate).inDays <= 6) {
            final dateStr = '${reportDate.day}/${reportDate.month}';
            breakdown[dateStr] = (breakdown[dateStr] ?? 0) + 1;
          }
        }
      }
    } else if (timeRange == '30 Days') {
      // Show 7 days for the selected week
      final weekStart = now.subtract(Duration(days: (weekIndex ?? 0) * 7 + 6));
      for (var i = 6; i >= 0; i--) {
        final date = weekStart.subtract(Duration(days: i));
        final dateStr = '${date.day}/${date.month}';
        breakdown[dateStr] = 0;
      }
      for (var report in reports) {
        if (statusFilter == null || report.status == statusFilter) {
          final reportDate = report.createdAt.toDate();
          final daysDiff = now.difference(reportDate).inDays;
          if (daysDiff >= (weekIndex ?? 0) * 7 && daysDiff < (weekIndex ?? 0) * 7 + 7) {
            final dateStr = '${reportDate.day}/${reportDate.month}';
            breakdown[dateStr] = (breakdown[dateStr] ?? 0) + 1;
          }
        }
      }
    } else if (timeRange == 'All Time') {
      // Show weeks for the selected month
      final selectedMonth = now.subtract(Duration(days: now.day - 1 + (monthIndex ?? 0) * 30));
      final daysInMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
      final weeksInMonth = (daysInMonth / 7).ceil();
      for (var week = 0; week < weeksInMonth; week++) {
        final weekStartDay = week * 7 + 1;
        final weekEndDay = (week + 1) * 7 > daysInMonth ? daysInMonth : (week + 1) * 7;
        final weekStart = DateTime(selectedMonth.year, selectedMonth.month, weekStartDay);
        final weekEnd = DateTime(selectedMonth.year, selectedMonth.month, weekEndDay);
        final weekStr = '${weekStart.day}-${weekEnd.day}/${weekStart.month}';
        breakdown[weekStr] = 0;
      }
      for (var report in reports) {
        if (statusFilter == null || report.status == statusFilter) {
          final reportDate = report.createdAt.toDate();
          if (reportDate.year == selectedMonth.year && reportDate.month == selectedMonth.month) {
            final dayOfMonth = reportDate.day;
            final weekIndex = ((dayOfMonth - 1) ~/ 7);
            final weekStartDay = weekIndex * 7 + 1;
            final weekEndDay = (weekIndex + 1) * 7 > daysInMonth ? daysInMonth : (weekIndex + 1) * 7;
            final weekStr = '$weekStartDay-$weekEndDay/${reportDate.month}';
            breakdown[weekStr] = (breakdown[weekStr] ?? 0) + 1;
          }
        }
      }
    }
    return breakdown;
  }

  String _getTimeMarker(String timeRange, {required int weekIndex, required int monthIndex}) {
    final now = DateTime.now();
    if (timeRange == '7 Days') {
      return 'Last 7 Days';
    } else if (timeRange == '30 Days') {
      final weekStart = now.subtract(Duration(days: weekIndex * 7 + 6));
      final weekEnd = weekStart.add(Duration(days: 6));
      return '${weekStart.day.toString().padLeft(2, '0')}/${weekStart.month.toString().padLeft(2, '0')} - '
          '${weekEnd.day.toString().padLeft(2, '0')}/${weekEnd.month.toString().padLeft(2, '0')}';
    } else {
      final selectedMonth = now.subtract(Duration(days: now.day - 1 + monthIndex * 30));
      return '${selectedMonth.month.toString().padLeft(2, '0')}/${selectedMonth.year}';
    }
  }

  void _handleSwipe(String timeRange, bool isLeft, String chartType) {
    setState(() {
      if (timeRange == '30 Days') {
        if (chartType == 'Total') {
          if (isLeft && _currentWeekIndexTotal < 3) {
            _currentWeekIndexTotal++;
          } else if (!isLeft && _currentWeekIndexTotal > 0) {
            _currentWeekIndexTotal--;
          }
          logger.d('Swiped ${isLeft ? 'left' : 'right'} for Total, weekIndex: $_currentWeekIndexTotal');
        } else if (chartType == 'Resolving') {
          if (isLeft && _currentWeekIndexResolving < 3) {
            _currentWeekIndexResolving++;
          } else if (!isLeft && _currentWeekIndexResolving > 0) {
            _currentWeekIndexResolving--;
          }
          logger.d('Swiped ${isLeft ? 'left' : 'right'} for Resolving, weekIndex: $_currentWeekIndexResolving');
        } else if (chartType == 'NotResolved') {
          if (isLeft && _currentWeekIndexNotResolved < 3) {
            _currentWeekIndexNotResolved++;
          } else if (!isLeft && _currentWeekIndexNotResolved > 0) {
            _currentWeekIndexNotResolved--;
          }
          logger.d('Swiped ${isLeft ? 'left' : 'right'} for Not Yet Resolved, weekIndex: $_currentWeekIndexNotResolved');
        } else if (chartType == 'Resolved') {
          if (isLeft && _currentWeekIndexResolved < 3) {
            _currentWeekIndexResolved++;
          } else if (!isLeft && _currentWeekIndexResolved > 0) {
            _currentWeekIndexResolved--;
          }
          logger.d('Swiped ${isLeft ? 'left' : 'right'} for Resolved, weekIndex: $_currentWeekIndexResolved');
        }
      } else if (timeRange == 'All Time') {
        if (chartType == 'Total') {
          if (isLeft) {
            _currentMonthIndexTotal++;
          } else if (_currentMonthIndexTotal > 0) {
            _currentMonthIndexTotal--;
          }
          logger.d('Swiped ${isLeft ? 'left' : 'right'} for Total, monthIndex: $_currentMonthIndexTotal');
        } else if (chartType == 'Resolving') {
          if (isLeft) {
            _currentMonthIndexResolving++;
          } else if (_currentMonthIndexResolving > 0) {
            _currentMonthIndexResolving--;
          }
          logger.d('Swiped ${isLeft ? 'left' : 'right'} for Resolving, monthIndex: $_currentMonthIndexResolving');
        } else if (chartType == 'NotResolved') {
          if (isLeft) {
            _currentMonthIndexNotResolved++;
          } else if (_currentMonthIndexNotResolved > 0) {
            _currentMonthIndexNotResolved--;
          }
          logger.d('Swiped ${isLeft ? 'left' : 'right'} for Not Yet Resolved, monthIndex: $_currentMonthIndexNotResolved');
        } else if (chartType == 'Resolved') {
          if (isLeft) {
            _currentMonthIndexResolved++;
          } else if (_currentMonthIndexResolved > 0) {
            _currentMonthIndexResolved--;
          }
          logger.d('Swiped ${isLeft ? 'left' : 'right'} for Resolved, monthIndex: $_currentMonthIndexResolved');
        }
      }
    });
  }

  Widget _buildBarChart(Map<String, int> data, String title, Color barColor, String timeRange, String chartType) {
    final weekIndex = chartType == 'Total'
        ? _currentWeekIndexTotal
        : chartType == 'Resolving'
            ? _currentWeekIndexResolving
            : chartType == 'NotResolved'
                ? _currentWeekIndexNotResolved
                : _currentWeekIndexResolved;
    final monthIndex = chartType == 'Total'
        ? _currentMonthIndexTotal
        : chartType == 'Resolving'
            ? _currentMonthIndexResolving
            : chartType == 'NotResolved'
                ? _currentMonthIndexNotResolved
                : _currentMonthIndexResolved;

    final canScrollLeft = timeRange == '30 Days' ? weekIndex < 3 : monthIndex > 0;
    final canScrollRight = timeRange == '30 Days' ? weekIndex > 0 : monthIndex > 0;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          final isLeftSwipe = details.primaryVelocity! < -50;
          final isRightSwipe = details.primaryVelocity! > 50;
          if (isLeftSwipe && canScrollLeft) {
            _handleSwipe(timeRange, true, chartType);
          } else if (isRightSwipe && canScrollRight) {
            _handleSwipe(timeRange, false, chartType);
          }
        }
      },
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.indigo,
                      ),
                    ),
                    if (timeRange != '7 Days') ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.arrow_left,
                          color: canScrollLeft ? Colors.indigo.shade700 : Colors.grey.shade400,
                        ),
                        onPressed: canScrollLeft
                            ? () => _handleSwipe(timeRange, true, chartType)
                            : null,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.arrow_right,
                          color: canScrollRight ? Colors.indigo.shade700 : Colors.grey.shade400,
                        ),
                        onPressed: canScrollRight
                            ? () => _handleSwipe(timeRange, false, chartType)
                            : null,
                      ),
                    ],
                  ],
                ),
                if (timeRange != '7 Days')
                  Text(
                    _getTimeMarker(timeRange, weekIndex: weekIndex, monthIndex: monthIndex),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.indigo.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: data.values.isNotEmpty
                      ? data.values.reduce((a, b) => a > b ? a : b).toDouble() + 1
                      : 10,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < 0 || value.toInt() >= data.keys.length) {
                            return const SizedBox.shrink();
                          }
                          final date = data.keys.elementAt(value.toInt());
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
                  barGroups: data.entries.toList().asMap().entries.map(
                        (entry) => BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.value.toDouble(),
                              color: barColor,
                              width: 12,
                            ),
                          ],
                        ),
                      ).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                                  _currentWeekIndexTotal = 0;
                                  _currentWeekIndexResolving = 0;
                                  _currentWeekIndexNotResolved = 0;
                                  _currentWeekIndexResolved = 0;
                                  _currentMonthIndexTotal = 0;
                                  _currentMonthIndexResolving = 0;
                                  _currentMonthIndexNotResolved = 0;
                                  _currentMonthIndexResolved = 0;
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
              final typeBreakdown = _calculateTypeBreakdown(reports, showAll: _showAllTypes);
              final locationBreakdown = _calculateLocationBreakdown(reports, showAll: _showAllLocations);
              final totalReportsOverTime = _calculateReportsOverTime(
                reports,
                _selectedTimeRange,
                weekIndex: _currentWeekIndexTotal,
                monthIndex: _currentMonthIndexTotal,
              );
              final resolvingReportsOverTime = _calculateReportsOverTime(
                reports,
                _selectedTimeRange,
                statusFilter: ReportStatus.Processing,
                weekIndex: _currentWeekIndexResolving,
                monthIndex: _currentMonthIndexResolving,
              );
              final notResolvedReportsOverTime = _calculateReportsOverTime(
                reports,
                _selectedTimeRange,
                statusFilter: ReportStatus.Submitted,
                weekIndex: _currentWeekIndexNotResolved,
                monthIndex: _currentMonthIndexNotResolved,
              );
              final resolvedReportsOverTime = _calculateReportsOverTime(
                reports,
                _selectedTimeRange,
                statusFilter: ReportStatus.Done,
                weekIndex: _currentWeekIndexResolved,
                monthIndex: _currentMonthIndexResolved,
              );

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
                  // Report Types
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Report Types',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showAllTypes = !_showAllTypes;
                          });
                          logger.d(_showAllTypes ? 'Show All Report Types toggled' : 'Show Less Report Types toggled');
                        },
                        child: Text(
                          _showAllTypes ? 'Show Less' : 'Show All',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.indigo,
                          ),
                        ),
                      ),
                    ],
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
                        final type = typeBreakdown[index].key;
                        final count = typeBreakdown[index].value;
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
                  // Report Locations
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Report Locations',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showAllLocations = !_showAllLocations;
                          });
                          logger.d(_showAllLocations ? 'Show All Report Locations toggled' : 'Show Less Report Locations toggled');
                        },
                        child: Text(
                          _showAllLocations ? 'Show Less' : 'Show All',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.indigo,
                          ),
                        ),
                      ),
                    ],
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
                      itemCount: locationBreakdown.length,
                      itemBuilder: (context, index) {
                        final location = locationBreakdown[index].key;
                        final count = locationBreakdown[index].value;
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: index < locationBreakdown.length - 1
                                    ? Colors.indigo.shade200
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.location_on,
                              color: Colors.indigo.shade700,
                            ),
                            title: Text(
                              location,
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
                  _buildBarChart(totalReportsOverTime, 'Total', Colors.indigo.shade700, _selectedTimeRange, 'Total'),
                  const SizedBox(height: 16),
                  _buildBarChart(resolvingReportsOverTime, 'Resolving', Colors.orangeAccent, _selectedTimeRange, 'Resolving'),
                  const SizedBox(height: 16),
                  _buildBarChart(notResolvedReportsOverTime, 'Not Yet Resolved', Colors.redAccent, _selectedTimeRange, 'NotResolved'),
                  const SizedBox(height: 16),
                  _buildBarChart(resolvedReportsOverTime, 'Resolved', Colors.greenAccent, _selectedTimeRange, 'Resolved'),
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