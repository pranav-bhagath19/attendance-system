/// Attendance Report Screen
/// Shows summary of marked attendance with edit capability
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/attendance_provider.dart';
import '../../theme/app_theme.dart';
import 'analytics_screen.dart';

class AttendanceReportScreen extends StatefulWidget {
  final String classId;
  final String className;
  final String date;

  const AttendanceReportScreen({
    super.key,
    required this.classId,
    required this.className,
    required this.date,
  });

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  bool _isSaving = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReport();
    });
  }

  Future<void> _loadReport() async {
    await context.read<AttendanceProvider>().fetchAttendanceReport(
          widget.classId,
          widget.date,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnalyticsScreen(
                    classId: widget.classId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<AttendanceProvider>(
        builder: (context, attendanceProvider, _) {
          if (attendanceProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final report = attendanceProvider.attendanceReport;
          if (report == null) {
            return const Center(child: Text('No report available'));
          }

          final attendance = List<Map<String, dynamic>>.from(
            report['attendance'] ?? [],
          );

          final presentCount =
              attendance.where((a) => a['status'] == 'PRESENT').length;
          final absentCount =
              attendance.where((a) => a['status'] == 'ABSENT').length;
          final lateCount =
              attendance.where((a) => a['status'] == 'LATE').length;

          return Column(
            children: [
              // Header Summary
              Container(
                padding: const EdgeInsets.all(AppTheme.lg),
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.className,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy')
                          .format(DateTime.parse(widget.date)),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SummaryItem(
                          label: 'Present',
                          count: presentCount,
                          color: AppTheme.successGreen,
                        ),
                        _SummaryItem(
                          label: 'Late',
                          count: lateCount,
                          color: AppTheme.lateOrange,
                        ),
                        _SummaryItem(
                          label: 'Absent',
                          count: absentCount,
                          color: AppTheme.absentRed,
                        ),
                        _SummaryItem(
                          label: 'Total',
                          count: attendance.length,
                          color: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Attendance List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.lg),
                  itemCount: attendance.length,
                  itemBuilder: (context, index) {
                    final record = attendance[index];
                    return _AttendanceRow(
                      record: record,
                      onStatusChanged: (newStatus) {
                        setState(() {
                          attendance[index]['status'] = newStatus;
                        });
                      },
                    );
                  },
                ),
              ),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(AppTheme.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () {
                                Navigator.pop(context);
                              },
                        icon: const Icon(Icons.close),
                        label: const Text('Discard'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () {
                                _saveChanges(attendance);
                              },
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check),
                        label: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveChanges(List<Map<String, dynamic>> attendance) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final formatData = attendance
        .map((a) {
          return {
            'student_id':
                a['student_id']?.toString() ?? a['id']?.toString() ?? '',
            'status': a['status'],
            'notes': a['notes'],
          };
        })
        .where((a) => a['student_id'] != '')
        .toList();

    await context.read<AttendanceProvider>().submitAttendance(
          widget.classId,
          formatData,
        );

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (context.read<AttendanceProvider>().errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance updated successfully')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<AttendanceProvider>().errorMessage ??
                'Failed to update attendance',
          ),
        ),
      );
    }
  }
}

// ============ SUMMARY ITEM ============

class _SummaryItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

// ============ ATTENDANCE ROW ============

class _AttendanceRow extends StatefulWidget {
  final Map<String, dynamic> record;
  final Function(String) onStatusChanged;

  const _AttendanceRow({
    required this.record,
    required this.onStatusChanged,
  });

  @override
  State<_AttendanceRow> createState() => _AttendanceRowState();
}

class _AttendanceRowState extends State<_AttendanceRow> {
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.record['status'] ?? 'NOT_MARKED';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PRESENT':
        return AppTheme.successGreen;
      case 'ABSENT':
        return AppTheme.absentRed;
      case 'LATE':
        return AppTheme.lateOrange;
      default:
        return AppTheme.textTertiary;
    }
  }

  String _getStatusDisplay(String status) {
    switch (status) {
      case 'PRESENT':
        return '✓ Present';
      case 'ABSENT':
        return '✗ Absent';
      case 'LATE':
        return '⏱ Late';
      default:
        return 'Not Marked';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Roll Number and Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.record['student_name'] ?? 'Unknown',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  'Roll: ${widget.record['roll_no']}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // Status Dropdown
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _currentStatus = value;
                widget.onStatusChanged(value);
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'PRESENT',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.successGreen),
                    SizedBox(width: 8),
                    Text('Present'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'LATE',
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: AppTheme.lateOrange),
                    SizedBox(width: 8),
                    Text('Late'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'ABSENT',
                child: Row(
                  children: [
                    Icon(Icons.cancel, color: AppTheme.absentRed),
                    SizedBox(width: 8),
                    Text('Absent'),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(_currentStatus).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _getStatusColor(_currentStatus),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getStatusDisplay(_currentStatus),
                    style: TextStyle(
                      color: _getStatusColor(_currentStatus),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.expand_more,
                    color: _getStatusColor(_currentStatus),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
