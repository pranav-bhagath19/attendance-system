import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

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

    // Detect swipe up for mentor details (dy is negative for up)
    if (drag.dy < -_swipeThreshold && drag.dx.abs() < _swipeThreshold * 1.5) {
      _showMentorDetails();
      setState(() => drag = Offset.zero);
      return;
    }

    if (drag.dx > _swipeThreshold) {
      _completeSwipe("PRESENT", drag);
    } else if (drag.dx < -_swipeThreshold) {
      _completeSwipe("ABSENT", drag);
    } else {
      setState(() => drag = Offset.zero);
    }
  }

  void _showMentorDetails() {
    if (students.isEmpty || currentIndex >= students.length) return;

    final student = students[currentIndex];
    final mentorName = student['mentor_name']?.toString() ?? "";
    final mentorPhone = student['mentor_phone']?.toString() ?? "";
    final studentName = student['name']?.toString() ?? "Student";

    Vibration.hasVibrator().then((hasVibe) {
      if (hasVibe ?? false) Vibration.vibrate(duration: 30);
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Icon(Icons.support_agent,
                  size: 48, color: Colors.blueAccent),
              const SizedBox(height: 16),
              const Text(
                "Mentor Details",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                studentName,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              if (mentorName.isEmpty && mentorPhone.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Mentor info not available",
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, color: Colors.blue.shade700),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Mentor Name",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  mentorName.isNotEmpty ? mentorName : "N/A",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.blue.shade200),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.phone, color: Colors.blue.shade700),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Phone Number",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  mentorPhone.isNotEmpty ? mentorPhone : "N/A",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (mentorPhone.isNotEmpty)
                            ElevatedButton.icon(
                              onPressed: () async {
                                final uri = Uri.parse("tel:$mentorPhone");
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text("Could not launch dialer")),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.call,
                                  size: 16, color: Colors.white),
                              label: const Text("Call",
                                  style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
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
