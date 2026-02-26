/// Attendance Report Screen
/// Shows summary of marked attendance with edit capability
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/class_provider.dart';
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
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  List<Map<String, dynamic>> _mergedAttendance = [];
  int _presentCount = 0;
  int _absentCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReport();
    });
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Fetch full student list
      await context.read<ClassProvider>().fetchClassStudents(widget.classId);
      final students = context.read<ClassProvider>().classStudents;

      // 2. Parse date and define startOfDay / endOfDay
      final selectedDate = DateTime.parse(widget.date);
      final startOfDay =
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final endOfDay = DateTime(selectedDate.year, selectedDate.month,
          selectedDate.day, 23, 59, 59, 999);

      // 3. Query attendance for this class and date
      final querySnapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where('class_id', isEqualTo: widget.classId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      debugPrint(
          "DEBUGLOG: Found ${querySnapshot.docs.length} attendance documents.");

      // 4. Extract records array and build Map<student_id, status>
      final Map<String, dynamic> statusMap = {};
      int recordsExtracted = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final records = data['records'] as List<dynamic>? ?? [];
        recordsExtracted += records.length;
        for (var record in records) {
          final sId =
              record['student_id']?.toString() ?? record['id']?.toString();
          if (sId != null) {
            statusMap[sId] = record['status'] ?? 'NOT_MARKED';
          }
        }
      }

      debugPrint("DEBUGLOG: Extracted $recordsExtracted records.");
      debugPrint("DEBUGLOG: statusMap keys: ${statusMap.keys.toList()}");

      // 5. Merge with full student list
      _mergedAttendance = students.map((s) {
        final stId = s['id']?.toString() ?? '';
        return {
          'student_id': stId,
          'student_name': s['name'] ?? 'Unknown',
          'roll_no': s['roll_no']?.toString() ?? 'N/A',
          'status': statusMap[stId] ?? 'NOT_MARKED',
          'notes': '',
        };
      }).toList();

      debugPrint(
          "DEBUGLOG: Merged list has ${_mergedAttendance.length} students.");

      _calculateCounts();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      debugPrint("Error loading report: $e");
    }
  }

  void _calculateCounts() {
    _presentCount =
        _mergedAttendance.where((a) => a['status'] == 'PRESENT').length;
    _absentCount =
        _mergedAttendance.where((a) => a['status'] == 'ABSENT').length;
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text('Error: $_errorMessage'));
    }

    if (_mergedAttendance.isEmpty) {
      return const Center(child: Text('No students found for this class'));
    }

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
                    count: _presentCount,
                    color: AppTheme.successGreen,
                  ),
                  _SummaryItem(
                    label: 'Absent',
                    count: _absentCount,
                    color: AppTheme.absentRed,
                  ),
                  _SummaryItem(
                    label: 'Total',
                    count: _mergedAttendance.length,
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
            itemCount: _mergedAttendance.length,
            itemBuilder: (context, index) {
              final record = _mergedAttendance[index];
              return _AttendanceRow(
                record: record,
                onStatusChanged: (newStatus) {
                  setState(() {
                    _mergedAttendance[index]['status'] = newStatus;
                    _calculateCounts();
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
                          _saveChanges(_mergedAttendance);
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
            'notes': a['notes'] ?? '',
          };
        })
        .where((a) => a['student_id'] != '' && a['status'] != 'NOT_MARKED')
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
