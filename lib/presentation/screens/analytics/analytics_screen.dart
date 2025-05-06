import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart'; // Import for grouping by week
import 'package:fl_chart/fl_chart.dart';

import 'package:pwd_verification_app/core/utils/logger.dart';
import 'package:pwd_verification_app/data/models/scan_result.dart';
import 'package:pwd_verification_app/data/repositories/scan_repository.dart';
import 'package:pwd_verification_app/di/service_locator.dart';
import 'package:pwd_verification_app/presentation/widgets/common/app_loader.dart';
import 'package:pwd_verification_app/presentation/widgets/common/error_view.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late final ScanRepository _scanRepository;

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // Statistics - Simplified
  int _totalScans = 0;

  // Data for Charts
  Map<String, int> _scansByDayOfWeek = {}; // Keep: Mon-Sun counts
  Map<DateTime, int> _scansByWeek = {}; // New: Week start date -> Count

  // Constants
  static const int _numberOfWeeksToShow = 6; // How many recent weeks to display

  @override
  void initState() {
    super.initState();
    _scanRepository = getIt<ScanRepository>();
    _loadAnalytics();
  }

  // Helper to get the start of the week (Monday) for a given date
  DateTime _getWeekStartDate(DateTime date) {
    // Weekday returns 1 for Monday, 7 for Sunday.
    // Subtract (weekday - 1) days to get to Monday.
    return date.subtract(Duration(days: date.weekday - 1));
  }

  Future<void> _loadAnalytics() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final scanHistory = await _scanRepository.getScanHistory() ?? [];
      _calculateStatistics(scanHistory);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      AppLogger.error('AnalyticsScreen', 'Error loading analytics: $e\nStackTrace: $stackTrace');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load analytics data. Please try again.';
      });
    }
  }

  void _calculateStatistics(List<ScanResult> scanHistory) {
    // Reset counts and chart data
    _totalScans = scanHistory.length;
    _scansByDayOfWeek = { 'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0, 'Fri': 0, 'Sat': 0, 'Sun': 0 };
    _scansByWeek = {};

    if (_totalScans == 0) return; // No further calculation needed

    // Use Map grouping for efficiency
    // Group by Day of Week
     _scansByDayOfWeek = groupBy(scanHistory, (ScanResult scan) => DateFormat('E').format(scan.scanTime))
        .map((key, value) => MapEntry(key, value.length));

    // Group by Week Start Date
    final scansGroupedByWeek = groupBy(scanHistory, (ScanResult scan) => _getWeekStartDate(scan.scanTime));

    // Create the final map with counts, sorted by week start date (most recent first)
    final sortedWeeks = scansGroupedByWeek.keys.toList()..sort((a, b) => b.compareTo(a)); // Sort descending

    for (final weekStartDate in sortedWeeks) {
       // Only include weeks up to the limit, starting from the most recent
      if (_scansByWeek.length < _numberOfWeeksToShow) {
         _scansByWeek[weekStartDate] = scansGroupedByWeek[weekStartDate]?.length ?? 0;
      } else {
         break; // Stop adding older weeks once we hit the limit
      }
    }

     // Ensure the final map is sorted ascending for chart display if needed,
     // although we usually process from sorted keys directly.
     // If chart needs map sorted ascending:
     // _scansByWeek = Map.fromEntries(_scansByWeek.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }


  // Helper function to check if a day (abbreviation) is weekend
  bool _isWeekend(String dayAbbreviation) {
    return dayAbbreviation == 'Sat' || dayAbbreviation == 'Sun';
  }

  // --- Build Methods ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          if (!_isLoading)
            IconButton( icon: const Icon(Icons.refresh), onPressed: _loadAnalytics, tooltip: 'Refresh Analytics' ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const AppLoader(message: 'Loading analytics...');
    if (_hasError) return ErrorView( message: _errorMessage, onRetry: _loadAnalytics );
    if (_totalScans == 0 && !_isLoading && !_hasError) {
      // Simplified empty state
      return Center( child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.analytics_outlined, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text( 'No scan data available yet.', style: TextStyle(fontSize: 18, color: Colors.grey), textAlign: TextAlign.center ),
            const SizedBox(height: 16),
            ElevatedButton.icon( icon: const Icon(Icons.refresh), label: const Text('Refresh'), onPressed: _loadAnalytics )
          ], ),
      );
    }
    return _buildAnalyticsContent();
  }

  Widget _buildAnalyticsContent() {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Removed Summary Section and Stat Cards

            // --- Weekly Scan Chart ---
            if (_scansByWeek.isNotEmpty) ...[
              _buildWeeklyBarChartCard(), // New Chart
              const SizedBox(height: 24),
            ],

            // --- Day of Week Scan Chart ---
            if (_scansByDayOfWeek.isNotEmpty && _scansByDayOfWeek.values.any((v) => v > 0)) ...[
              _buildDayOfWeekBarChartCard(), // Kept Chart
              const SizedBox(height: 24),
            ],

             // Message if charts have no data but total scans exist
            if (_scansByWeek.isEmpty && _scansByDayOfWeek.values.every((v) => v == 0) && _totalScans > 0)
               Padding(
                 padding: const EdgeInsets.symmetric(vertical: 32.0),
                 child: Center(
                    child: Text(
                      "Scan data exists, but not enough to display weekly/daily charts yet.",
                       style: TextStyle(color: Colors.grey[600]),
                       textAlign: TextAlign.center,
                    )
                 ),
               ),
          ],
        ),
      ),
    );
  }

  // --- Chart Widgets ---

  // --- NEW: Weekly Bar Chart ---
  Widget _buildWeeklyBarChartCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Scans Over Last $_numberOfWeeksToShow Weeks', // Dynamic title
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: BarChart(
                _buildWeeklyBarChartData(),
                swapAnimationDuration: const Duration(milliseconds: 150),
                swapAnimationCurve: Curves.linear,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartData _buildWeeklyBarChartData() {
    final barColor = Theme.of(context).colorScheme.secondary; // Use secondary color
    final barBackgroundColor = Colors.grey.shade200;
    const double barWidth = 18;

    // Sort keys (week start dates) ascending for the chart axis
    final sortedWeekKeys = _scansByWeek.keys.toList()..sort((a, b) => a.compareTo(b));

    final maxY = _scansByWeek.values.isEmpty ? 1.0 : _scansByWeek.values.reduce((a, b) => a > b ? a : b).toDouble();

    return BarChartData(
       maxY: maxY * 1.2, // Add padding
       barTouchData: BarTouchData( // Tooltip setup
         touchTooltipData: BarTouchTooltipData(
           // tooltipBgColor: Colors.blueGrey, // Commented out as per previous issue
           tooltipPadding: const EdgeInsets.all(8),
           tooltipMargin: 8,
           getTooltipItem: (group, groupIndex, rod, rodIndex) {
             if (groupIndex < 0 || groupIndex >= sortedWeekKeys.length) return null;
             final weekDate = sortedWeekKeys[groupIndex];
             final weekLabel = DateFormat('MMM d').format(weekDate); // Format: "Jan 20"
             return BarTooltipItem(
               'Week of $weekLabel\n',
               const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
               children: <TextSpan>[
                 TextSpan(
                   text: (rod.toY - 0.5).toInt().toString(), // Adjust if using offset
                   style: TextStyle(color: Colors.yellow.shade300, fontSize: 14, fontWeight: FontWeight.w500),
                 ),
               ],
             );
           },
         ),
       ),
       titlesData: FlTitlesData( // Axis titles
         show: true,
         rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
         topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
         bottomTitles: AxisTitles( // Week start dates
           sideTitles: SideTitles(
             showTitles: true,
             getTitlesWidget: (double value, TitleMeta meta) {
               final index = value.toInt();
               if (index < 0 || index >= sortedWeekKeys.length) return Container();
               final weekDate = sortedWeekKeys[index];
               // Show MM/DD format
               final title = DateFormat('M/d').format(weekDate);
               // --- Apply the workaround for SideTitleWidget based on your environment ---
               return SideTitleWidget(
                 // axisSide: meta.axisSide, // REMOVED as per your env
                 space: 4.0,
                 child: Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                 meta: meta, // ADDED as per your env
               );
             },
             reservedSize: 28,
             interval: 1, // Show title for every bar
           ),
         ),
         leftTitles: AxisTitles( // Scan counts
           sideTitles: SideTitles(
             showTitles: true,
             reservedSize: 30,
             interval: maxY > 5 ? (maxY / 4).ceilToDouble() : 1, // Adjust interval
             getTitlesWidget: (value, meta) {
               if (value == 0 || value > maxY) return Container(); // Hide 0 and values above max
                if (value % meta.appliedInterval != 0) return Container(); // Show only interval values
               return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10), textAlign: TextAlign.left);
             },
           ),
         ),
       ),
       borderData: FlBorderData(show: false),
       barGroups: List.generate(sortedWeekKeys.length, (index) { // Generate bars
         final weekDate = sortedWeekKeys[index];
         final value = _scansByWeek[weekDate]?.toDouble() ?? 0.0;
         return BarChartGroupData(
           x: index,
           barRods: [
             BarChartRodData(
               toY: value > 0 ? value + 0.5 : 0, // Add small offset
               color: barColor,
               width: barWidth,
               borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
               backDrawRodData: BackgroundBarChartRodData(
                 show: true, toY: maxY * 1.2, color: barBackgroundColor,
               ),
             ),
           ],
         );
       }),
       gridData: FlGridData( // Grid lines
         show: true, drawVerticalLine: false, horizontalInterval: maxY > 5 ? (maxY / 4).ceilToDouble() : 1,
         getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 0.5),
       ),
       alignment: BarChartAlignment.spaceAround,
     );
   }


  // --- Kept: Day of Week Bar Chart ---
  Widget _buildDayOfWeekBarChartCard() {
     return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Scans by Day of Week',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: BarChart(
                _buildDayOfWeekBarChartData(),
                swapAnimationDuration: const Duration(milliseconds: 150),
                swapAnimationCurve: Curves.linear,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartData _buildDayOfWeekBarChartData() {
     final barColor = Theme.of(context).colorScheme.primary;
     final weekendColor = Colors.orange.shade600;
     final barBackgroundColor = Colors.grey.shade200;
     const double barWidth = 18;

     // Define the order of days for the chart
     final daysOrder = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
     final Map<String, int> orderedScansByDay = { for (var day in daysOrder) day: _scansByDayOfWeek[day] ?? 0 };

     final maxY = orderedScansByDay.values.isEmpty ? 1.0 : orderedScansByDay.values.reduce((a, b) => a > b ? a : b).toDouble();

    return BarChartData(
      maxY: maxY * 1.2,
      barTouchData: BarTouchData(
         touchTooltipData: BarTouchTooltipData(
           // tooltipBgColor: Colors.blueGrey, // Commented out as per previous issue
           tooltipPadding: const EdgeInsets.all(8), tooltipMargin: 8,
           getTooltipItem: (group, groupIndex, rod, rodIndex) {
             if (groupIndex < 0 || groupIndex >= daysOrder.length) return null;
             String weekDay = daysOrder[groupIndex];
             return BarTooltipItem( '$weekDay\n', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
               children: <TextSpan>[ TextSpan( text: (rod.toY - 0.5).toInt().toString(), style: TextStyle(color: Colors.yellow.shade300, fontSize: 14, fontWeight: FontWeight.w500) ) ]
             );
           },
         ),
      ),
      titlesData: FlTitlesData(
        show: true, rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (double value, TitleMeta meta) {
              final index = value.toInt();
              if (index < 0 || index >= daysOrder.length) return Container();
              final title = daysOrder[index];
              // --- Apply the workaround for SideTitleWidget based on your environment ---
              return SideTitleWidget(
                 // axisSide: meta.axisSide, // REMOVED as per your env
                 space: 4.0,
                 child: Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                 meta: meta, // ADDED as per your env
               );
            },
            reservedSize: 28, interval: 1,
          ),
        ),
        leftTitles: AxisTitles(
           sideTitles: SideTitles(
             showTitles: true, reservedSize: 30,
             interval: maxY > 5 ? (maxY / 4).ceilToDouble() : 1,
             getTitlesWidget: (value, meta) {
                if (value == 0 || value > maxY) return Container();
                 if (value % meta.appliedInterval != 0) return Container();
                return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10), textAlign: TextAlign.left);
             },
           ),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: List.generate(daysOrder.length, (index) {
          final dayAbbr = daysOrder[index];
          final value = orderedScansByDay[dayAbbr]?.toDouble() ?? 0.0;
          final color = _isWeekend(dayAbbr) ? weekendColor : barColor;
          return BarChartGroupData( x: index, barRods: [ BarChartRodData( toY: value > 0 ? value + 0.5 : 0, color: color, width: barWidth, borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)), backDrawRodData: BackgroundBarChartRodData( show: true, toY: maxY * 1.2, color: barBackgroundColor ) ) ] );
       }),
      gridData: FlGridData(
         show: true, drawVerticalLine: false,
         horizontalInterval: maxY > 5 ? (maxY / 4).ceilToDouble() : 1,
         getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 0.5),
      ),
      alignment: BarChartAlignment.spaceAround,
    );
  }

} // End of _AnalyticsScreenState class