import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/attendance_provider.dart';
import '../../theme/app_theme.dart';

class AttendanceReviewScreen extends StatefulWidget {
  final String classId;
  final String className;
  final List<Map<String, dynamic>> students;
  final Map<String, String> initialAttendance;

  const AttendanceReviewScreen({
    super.key,
    required this.classId,
    required this.className,
    required this.students,
    required this.initialAttendance,
  });

  @override
  State<AttendanceReviewScreen> createState() => _AttendanceReviewScreenState();
}

class _AttendanceReviewScreenState extends State<AttendanceReviewScreen> {
  late Map<String, String> attendanceMarked;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    attendanceMarked = Map.from(widget.initialAttendance);
  }

  Future<void> _submitAttendance() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final data = attendanceMarked.entries
        .map((e) => {
              'student_id': e.key,
              'status': e.value,
              'notes': null,
            })
        .toList();

    await context.read<AttendanceProvider>().submitAttendance(
          widget.classId,
          data,
        );

    if (!mounted) return;

    if (context.read<AttendanceProvider>().errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Attendance marked successfully")),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/dashboard',
          (_) => false,
        );
      });
    } else {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<AttendanceProvider>().errorMessage ??
              "Failed to save"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Attendance'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.lg),
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.className,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  "Review before submission",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppTheme.lg),
              itemCount: widget.students.length,
              itemBuilder: (context, index) {
                final student = widget.students[index];
                final studentId = student['id'].toString();
                final currentStatus = attendanceMarked[studentId] ?? 'ABSENT';

                return _ReviewRow(
                  studentName: student['name'] ?? 'Unknown',
                  rollNo: student['roll_no']?.toString() ?? '-',
                  status: currentStatus,
                  onStatusChanged: (newStatus) {
                    setState(() {
                      attendanceMarked[studentId] = newStatus;
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.lg),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            // User clicked cancel
                            Navigator.pop(context);
                          },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitAttendance,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String studentName;
  final String rollNo;
  final String status;
  final Function(String) onStatusChanged;

  const _ReviewRow({
    required this.studentName,
    required this.rollNo,
    required this.status,
    required this.onStatusChanged,
  });

  Color _getStatusColor(String s) {
    switch (s) {
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

  String _getStatusDisplay(String s) {
    switch (s) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  'Roll: $rollNo',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: onStatusChanged,
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
                color: _getStatusColor(status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _getStatusColor(status)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getStatusDisplay(status),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.expand_more,
                    color: _getStatusColor(status),
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
