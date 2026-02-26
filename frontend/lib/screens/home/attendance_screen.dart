import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../providers/class_provider.dart';
import '../../providers/attendance_provider.dart';
import 'attendance_review_screen.dart';

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
  final AudioPlayer _player = AudioPlayer();

  List<Map<String, dynamic>> students = [];
  int currentIndex = 0;
  Map<String, String> attendanceMarked = {};

  Offset drag = Offset.zero;
  late AnimationController _throwController;
  late Animation<Offset> _throwAnimation;

  final double _swipeThreshold = 60;
  bool _isSwiping = false;
  bool _isSubmitting = false;

  // ========================= INIT =========================
  @override
  void initState() {
    super.initState();

    _throwController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    debugPrint("Students received: ${students.length}");
    _initStudents();
  }

  void _initStudents() {
    final fetched = context.read<ClassProvider>().classStudents;

    // fix state pass-by-reference mutation by taking a copy
    final List<Map<String, dynamic>> fetchedCopy = List.from(fetched);

    // sort stable order
    fetchedCopy.sort((a, b) {
      final r1 = a['roll_no'] ?? '';
      final r2 = b['roll_no'] ?? '';
      return r1.toString().compareTo(r2.toString());
    });

    students = fetchedCopy;

    // preload images (IMPORTANT FOR SMOOTH SWIPE)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final s in students) {
        final url = s['image_url'] ?? s['photo'];
        if (url != null && url.toString().isNotEmpty) {
          precacheImage(NetworkImage(url), context);
        }
      }
    });

    debugPrint("Students received: ${students.length}");
  }

  @override
  void dispose() {
    _throwController.dispose();
    super.dispose();
  }

  // ========================= SWIPE =========================

  Future<void> _completeSwipe(String status, Offset direction) async {
    if (_isSwiping) return;
    setState(() => _isSwiping = true);

    final size = MediaQuery.of(context).size;

    final endOffset = Offset(
      direction.dx.sign == 0
          ? 1 * size.width * 1.3
          : direction.dx.sign * size.width * 1.3,
      direction.dy.sign == 0
          ? 1 * size.height * 1.3
          : direction.dy.sign * size.height * 1.3,
    );

    _throwAnimation = Tween(begin: drag, end: endOffset).animate(
      CurvedAnimation(parent: _throwController, curve: Curves.easeOut),
    );

    await _throwController.forward();

    final student = students[currentIndex];
    final studentId = student['id'].toString();

    attendanceMarked[studentId] = status;

    if (mounted) {
      context.read<AttendanceProvider>().addPendingAttendance(
            studentId,
            status,
          );
    }

    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 60);
    }

    _player.play(AssetSource("sounds/swipe.mp3"));

    if (!mounted) return;

    if (currentIndex < students.length - 1) {
      setState(() {
        currentIndex++;
        drag = Offset.zero;
        _throwController.reset();
        _isSwiping = false;
      });
    } else {
      setState(() {
        currentIndex++;
        drag = Offset.zero;
      });
      // Fire and forget to not block tree rebuild
      Future.microtask(() => _submitAttendance());
    }
  }

  void _onPanEnd(DragEndDetails d) {
    if (_isSwiping) return;

    if (drag.dx > _swipeThreshold) {
      _completeSwipe("PRESENT", drag);
    } else if (drag.dx < -_swipeThreshold) {
      _completeSwipe("ABSENT", drag);
    } else {
      setState(() => drag = Offset.zero);
    }
  }

  // ========================= SUBMIT =========================

  Future<void> _submitAttendance() async {
    if (_isSubmitting) return;
    _isSubmitting = true;

    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AttendanceReviewScreen(
            classId: widget.classId,
            className: widget.className,
            students: students,
            initialAttendance: attendanceMarked,
          ),
        ),
      );
    });
  }

  // ========================= UI =========================

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("No students found")),
      );
    }

    if (currentIndex >= students.length) {
      return const Scaffold(
        body: Center(child: Text("Submitting attendance...")),
      );
    }

    final student = students.isNotEmpty && currentIndex < students.length
        ? students[currentIndex]
        : <String, dynamic>{};
    final rotation = drag.dx / 300;

    return Scaffold(
      appBar: AppBar(title: const Text("Mark Attendance")),
      body: Stack(
        children: [
          if (currentIndex + 1 < students.length)
            Center(
              child: Transform.scale(
                scale: 0.95,
                child: _buildCard(students[currentIndex + 1]),
              ),
            ),
          if (student.isNotEmpty)
            AnimatedBuilder(
              animation: _throwController,
              builder: (_, __) {
                final offset =
                    _throwController.isAnimating ? _throwAnimation.value : drag;

                return Transform.translate(
                  offset: offset,
                  child: Transform.rotate(
                    angle: rotation,
                    child: GestureDetector(
                      onPanUpdate: (d) {
                        if (!_isSwiping) setState(() => drag += d.delta);
                      },
                      onPanEnd: _onPanEnd,
                      child: _buildCard(student),
                    ),
                  ),
                );
              },
            ),
          if (drag.dx > 20)
            _overlay("PRESENT", const Color.fromARGB(0, 76, 175, 79)),
          if (drag.dx < -20)
            _overlay("ABSENT", const Color.fromARGB(0, 244, 67, 54)),
        ],
      ),
    );
  }

  // ========================= WIDGETS =========================

  Widget _overlay(String text, Color color) {
    return Container(
      color: color.withValues(alpha: 0.15),
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.all(60),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> student) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      width: double.infinity,
      height: double.infinity,
      child: Card(
        elevation: 16,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40),
        ),
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(40)),
                child: Builder(
                  builder: (context) {
                    final imageUrl =
                        student['image_url'] ?? student['photo'] ?? "";
                    if (imageUrl.toString().isEmpty) {
                      return const Center(
                        child:
                            Icon(Icons.person, size: 120, color: Colors.grey),
                      );
                    }
                    return CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain, // Fits entire image appropriately
                      width: double.infinity,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (_, __, ___) => const Center(
                        child:
                            Icon(Icons.person, size: 120, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(40)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      student['name'] ?? "Unknown Student",
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Roll No: ${student['roll_no']}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
