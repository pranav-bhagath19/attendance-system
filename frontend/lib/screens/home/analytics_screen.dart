/// Analytics Screen
/// Display attendance analytics and statistics

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/attendance_provider.dart';
import '../../theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  final String classId;

  const AnalyticsScreen({
    Key? key,
    required this.classId,
  }) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalytics();
    });
  }

  Future<void> _loadAnalytics() async {
    await context.read<AttendanceProvider>().fetchAnalytics(widget.classId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Analytics'),
      ),
      body: Consumer<AttendanceProvider>(
        builder: (context, attendanceProvider, _) {
          if (attendanceProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final analytics = attendanceProvider.analytics;
          if (analytics == null || analytics['analytics'] == null) {
            return const Center(child: Text('No analytics available'));
          }

          final studentAnalytics = List<Map<String, dynamic>>.from(
            analytics['analytics'] ?? [],
          );

          return ListView(
            padding: const EdgeInsets.all(AppTheme.lg),
            children: [
              // Summary Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Class Overview',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Total Students: ${studentAnalytics.length}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.lg),

              // Students List
              ...studentAnalytics.map((student) {
                return _StudentAnalyticsCard(student: student);
              }),
            ],
          );
        },
      ),
    );
  }
}

// ============ STUDENT ANALYTICS CARD ============

class _StudentAnalyticsCard extends StatelessWidget {
  final Map<String, dynamic> student;

  const _StudentAnalyticsCard({
    Key? key,
    required this.student,
  }) : super(key: key);

  Color _getStatusColor(int percentage) {
    if (percentage >= 75) return AppTheme.successGreen;
    if (percentage >= 50) return AppTheme.lateOrange;
    return AppTheme.absentRed;
  }

  @override
  Widget build(BuildContext context) {
    final percentage = student['attendance_percentage'] ?? 0;
    final status = student['status'] ?? 'POOR';

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.lg),
        child: Column(
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['student_name'] ?? 'Unknown',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Roll: ${student['roll_no']}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(percentage).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: _getStatusColor(percentage),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Attendance Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (percentage / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: AppTheme.borderColor,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getStatusColor(percentage),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Percentage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Overall Attendance',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _getStatusColor(percentage),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Stats Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatColumn(
                  label: 'Total Classes',
                  value: '${student['total_classes']}',
                  color: AppTheme.primaryColor,
                ),
                _StatColumn(
                  label: 'Present',
                  value: '${student['present']}',
                  color: AppTheme.successGreen,
                ),
                _StatColumn(
                  label: 'Late',
                  value: '${student['late']}',
                  color: AppTheme.lateOrange,
                ),
                _StatColumn(
                  label: 'Absent',
                  value: '${student['absent']}',
                  color: AppTheme.absentRed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============ STAT COLUMN ============

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatColumn({
    Key? key,
    required this.label,
    required this.value,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
