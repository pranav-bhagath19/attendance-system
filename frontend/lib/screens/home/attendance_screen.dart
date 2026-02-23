/// Attendance Screen (Swipe-Based)
/// Core feature: Swipe cards to mark attendance
/// Right: Present (Green)
/// Left: Absent (Red)
/// Down: Late (Orange)
/// Up: View Details
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/class_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../theme/app_theme.dart';
import 'attendance_report_screen.dart';

class AttendanceScreen extends StatefulWidget {
  final String classId;
  final String className;
  final String subject;

  const AttendanceScreen({
    super.key,
    required this.classId,
    required this.className,
    required this.subject,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with TickerProviderStateMixin {
  late List<Map<String, dynamic>> students = [];
  int currentIndex = 0;
  Map<String, String> attendanceMarked = {};
  List<SwipeAction> history = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStudents();
    });
  }

  Future<void> _loadStudents() async {
    final success = await context.read<ClassProvider>().fetchClassStudents(
          widget.classId,
        );
    if (success && mounted) {
      setState(() {
        students = context.read<ClassProvider>().classStudents;
      });
    }
  }

  void _markAttendance(String status) {
    if (currentIndex >= students.length) return;

    final student = students[currentIndex];
    final studentId = student['id'];

    // Record in local state
    attendanceMarked[studentId] = status;

    // Add to history for undo
    history.add(SwipeAction(
      studentId: studentId,
      status: status,
      index: currentIndex,
    ));

    // Store in provider
    context.read<AttendanceProvider>().addPendingAttendance(
          studentId,
          status,
        );

    // Move to next student with animation
    _moveToNext();
  }

  void _moveToNext() {
    if (currentIndex < students.length - 1) {
      setState(() {
        currentIndex++;
      });
    } else {
      // Last student marked, show completion dialog
      _showCompletionDialog();
    }
  }

  void _undoLastSwipe() {
    if (history.isNotEmpty && currentIndex > 0) {
      final lastAction = history.removeLast();
      attendanceMarked.remove(lastAction.studentId);
      context.read<AttendanceProvider>().removePendingAttendance(
            lastAction.studentId,
          );

      setState(() {
        currentIndex--;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Last swipe undone'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Attendance Complete'),
        content: Text(
          'You have marked attendance for all ${students.length} students.\n\nWould you like to submit now?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Allow reviewing
            },
            child: const Text('Review'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitAttendance();
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAttendance() async {
    final attendanceProvider = context.read<AttendanceProvider>();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Prepare attendance data
    final attendanceData = attendanceMarked.entries
        .map((e) => {
              'student_id': e.key,
              'status': e.value,
              'notes': null,
            })
        .toList();

    // Submit to backend
    final success = await attendanceProvider.batchMarkAttendance(
      classId: widget.classId,
      attendanceData: attendanceData,
      date: today,
    );

    if (success && mounted) {
      // Navigate to report screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AttendanceReportScreen(
            classId: widget.classId,
            className: widget.className,
            date: today,
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            attendanceProvider.errorMessage ?? 'Failed to submit attendance',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showDetailsPanel(Map<String, dynamic> student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StudentDetailsPanel(
        student: student,
        onMarkPresent: () {
          Navigator.pop(context);
          _markAttendance('PRESENT');
        },
        onMarkAbsent: () {
          Navigator.pop(context);
          _markAttendance('ABSENT');
        },
        onMarkLate: () {
          Navigator.pop(context);
          _markAttendance('LATE');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ClassProvider>().isLoading;
    final errorMessage = context.watch<ClassProvider>().errorMessage;

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mark Attendance')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mark Attendance')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: 16),
              Text(errorMessage),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadStudents,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (students.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mark Attendance')),
        body: const Center(child: Text('No students found in this class')),
      );
    }

    final totalMarked = attendanceMarked.length;
    final remaining = students.length - totalMarked;

    return PopScope(
      canPop: false,
      // ignore: deprecated_member_use
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (attendanceMarked.isNotEmpty) {
          showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Discard Attendance?'),
                  content: const Text(
                    'You have unmarked attendance records. Are you sure?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Discard'),
                    ),
                  ],
                ),
              );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mark Attendance'),
        ),
        body: Stack(
          children: [
            // Main content
            Column(
              children: [
                // Progress bar
                Container(
                  height: 4,
                  margin: const EdgeInsets.only(top: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: (currentIndex + 1) / students.length,
                      backgroundColor: AppTheme.borderColor,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),

                // Stats
                Padding(
                  padding: const EdgeInsets.all(AppTheme.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatCounter(
                        label: 'Marked',
                        count: totalMarked,
                        color: AppTheme.successGreen,
                      ),
                      _StatCounter(
                        label: 'Remaining',
                        count: remaining,
                        color: AppTheme.warningColor,
                      ),
                    ],
                  ),
                ),

                // Card Stack
                Expanded(
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      // Handled by card gestures
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: List.generate(
                        students.length - currentIndex,
                        (index) {
                          final student =
                              students[currentIndex + index];
                          final isActive = index == 0;

                          return Transform.translate(
                            offset: Offset(0, index * 4.0),
                            child: StudentCard(
                              student: student,
                              isActive: isActive,
                              onSwipeRight: () => _markAttendance('PRESENT'),
                              onSwipeLeft: () => _markAttendance('ABSENT'),
                              onSwipeDown: () => _markAttendance('LATE'),
                              onSwipeUp: () => _showDetailsPanel(student),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.all(AppTheme.lg),
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: attendanceMarked.isEmpty ? null : _undoLastSwipe,
                        icon: const Icon(Icons.undo),
                        label: const Text('Undo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.warningColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: attendanceMarked.length == students.length
                            ? _submitAttendance
                            : null,
                        icon: const Icon(Icons.check),
                        label: const Text('Submit'),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Error message
            if (context.watch<AttendanceProvider>().errorMessage != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: AppTheme.errorColor,
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    context.read<AttendanceProvider>().errorMessage ?? '',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============ STUDENT CARD WIDGET ============

class StudentCard extends StatefulWidget {
  final Map<String, dynamic> student;
  final bool isActive;
  final VoidCallback onSwipeRight;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeDown;
  final VoidCallback onSwipeUp;

  const StudentCard({
    super.key,
    required this.student,
    required this.isActive,
    required this.onSwipeRight,
    required this.onSwipeLeft,
    required this.onSwipeDown,
    required this.onSwipeUp,
  });

  @override
  State<StudentCard> createState() => _StudentCardState();
}

class _StudentCardState extends State<StudentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Offset _dragOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDragEnd() {
    final dx = _dragOffset.dx;
    final dy = _dragOffset.dy;
    const threshold = 100.0;

    if (!widget.isActive) return;

    // Right swipe - Present
    if (dx > threshold) {
      widget.onSwipeRight();
    }
    // Left swipe - Absent
    else if (dx < -threshold) {
      widget.onSwipeLeft();
    }
    // Down swipe - Late
    else if (dy > threshold) {
      widget.onSwipeDown();
    }
    // Up swipe - Details
    else if (dy < -threshold) {
      widget.onSwipeUp();
    }

    setState(() {
      _dragOffset = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return Transform.translate(
        offset: const Offset(0, 0),
        child: Opacity(
          opacity: 0.5,
          child: _buildCard(),
        ),
      );
    }

    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _dragOffset += details.delta;
        });
      },
      onPanEnd: (_) => _handleDragEnd(),
      child: Transform.translate(
        offset: _dragOffset,
        child: _buildCard(),
      ),
    );
  }

  Widget _buildCard() {
    Color? bgColor;

    if (_dragOffset.dx > 50) {
      bgColor = AppTheme.successGreen.withValues(alpha: 0.1);
    } else if (_dragOffset.dx < -50) {
      bgColor = AppTheme.absentRed.withValues(alpha: 0.1);
    } else if (_dragOffset.dy > 50) {
      bgColor = AppTheme.lateOrange.withValues(alpha: 0.1);
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      color: bgColor ?? Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Student Photo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.borderColor,
                  width: 2,
                ),
              ),
              child: widget.student['photo'] != null
                  ? ClipOval(
                      child: Image.network(
                        widget.student['photo'],
                        fit: BoxFit.cover,
                        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) {
                          return const Icon(Icons.person, size: 60);
                        },
                      ),
                    )
                  : const Icon(Icons.person, size: 60),
            ),

            const SizedBox(height: 24),

            // Student Name
            Text(
              widget.student['name'] ?? 'Unknown',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Roll Number
            Text(
              'Roll: ${widget.student['roll_no']}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 16),

            // Attendance Percentage
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Attendance: ${widget.student['attendance_percentage']}%',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),

            const SizedBox(height: 32),

            // Gesture Hints
            _buildGestureHints(),
          ],
        ),
      ),
    );
  }

  Widget _buildGestureHints() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _GestureHint(
              icon: Icons.arrow_forward,
              label: 'Present',
              color: AppTheme.successGreen,
              opacity: _dragOffset.dx > 30 ? 1.0 : 0.4,
            ),
            _GestureHint(
              icon: Icons.arrow_back,
              label: 'Absent',
              color: AppTheme.absentRed,
              opacity: _dragOffset.dx < -30 ? 1.0 : 0.4,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _GestureHint(
              icon: Icons.arrow_upward,
              label: 'Details',
              color: Colors.blue,
              opacity: _dragOffset.dy < -30 ? 1.0 : 0.4,
            ),
            _GestureHint(
              icon: Icons.arrow_downward,
              label: 'Late',
              color: AppTheme.lateOrange,
              opacity: _dragOffset.dy > 30 ? 1.0 : 0.4,
            ),
          ],
        ),
      ],
    );
  }
}

// ============ GESTURE HINT WIDGET ============

class _GestureHint extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double opacity;

  const _GestureHint({
    required this.icon,
    required this.label,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 200),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============ STUDENT DETAILS PANEL ============

class _StudentDetailsPanel extends StatelessWidget {
  final Map<String, dynamic> student;
  final VoidCallback onMarkPresent;
  final VoidCallback onMarkAbsent;
  final VoidCallback onMarkLate;

  const _StudentDetailsPanel({
    required this.student,
    required this.onMarkPresent,
    required this.onMarkAbsent,
    required this.onMarkLate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppTheme.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.lg),
              child: Column(
                children: [
                  // Photo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: student['photo'] != null
                        ? ClipOval(
                            child: Image.network(
                              student['photo'],
                              fit: BoxFit.cover,
                              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) {
                                return const Icon(Icons.person, size: 50);
                              },
                            ),
                          )
                        : const Icon(Icons.person, size: 50),
                  ),

                  const SizedBox(height: 16),

                  // Name
                  Text(
                    student['name'] ?? 'Unknown',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),

                  const SizedBox(height: 8),

                  // Details
                  _DetailItem(
                    label: 'Roll No',
                    value: student['roll_no'] ?? 'N/A',
                  ),
                  _DetailItem(
                    label: 'Email',
                    value: student['email'] ?? 'N/A',
                  ),
                  _DetailItem(
                    label: 'Phone',
                    value: student['phone'] ?? 'N/A',
                  ),
                  _DetailItem(
                    label: 'Attendance',
                    value: '${student['attendance_percentage']}%',
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onMarkPresent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successGreen,
                          ),
                          child: const Text('Present'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onMarkLate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.lateOrange,
                          ),
                          child: const Text('Late'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onMarkAbsent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.absentRed,
                          ),
                          child: const Text('Absent'),
                        ),
                      ),
                    ],
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

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

// ============ STAT COUNTER ============

class _StatCounter extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatCounter({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

// ============ SWIPE ACTION RECORD ============

class SwipeAction {
  final String studentId;
  final String status;
  final int index;

  SwipeAction({
    required this.studentId,
    required this.status,
    required this.index,
  });
}
