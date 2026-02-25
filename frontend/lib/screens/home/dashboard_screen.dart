/// Dashboard Screen
/// Shows all classes assigned to the teacher
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/class_provider.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'attendance_screen.dart';
import 'attendance_report_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassProvider>().fetchClasses();
    });
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (!context.mounted) return;
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                return Tooltip(
                  message: authProvider.teacher?['email'] ?? 'Teacher',
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'profile') {
                        Navigator.pushNamed(context, '/profile');
                      } else if (value == 'settings') {
                        Navigator.pushNamed(context, '/settings');
                      } else if (value == 'logout') {
                        _handleLogout();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                          value: 'profile', child: Text('Profile')),
                      const PopupMenuItem(
                          value: 'settings', child: Text('Settings')),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                          value: 'logout', child: Text('Logout')),
                    ],
                    child: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Consumer<ClassProvider>(
        builder: (context, classProvider, _) {
          if (classProvider.isLoading && classProvider.classes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (classProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppTheme.errorColor),
                  const SizedBox(height: 16),
                  Text(classProvider.errorMessage!),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ClassProvider>().fetchClasses();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (classProvider.classes.isEmpty) {
            return const Center(child: Text('No classes found'));
          }

          return RefreshIndicator(
            onRefresh: () => context.read<ClassProvider>().fetchClasses(),
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.lg),
              children: [
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            authProvider.teacher?['name'] ?? 'Teacher',
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                ListView.separated(
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppTheme.lg),
                  itemCount: classProvider.classes.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final classData = classProvider.classes[index];
                    return _ClassCard(
                      classData: classData,
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final Map<String, dynamic> classData;

  const _ClassCard({
    required this.classData,
  });

  Future<void> _handleMarkAttendance(BuildContext context) async {
    final classProvider = context.read<ClassProvider>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    await classProvider.fetchClassStudents(classData['id'].toString());

    if (!context.mounted) return;
    Navigator.pop(context); // Safe dismiss of dialog

    if (classProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            classProvider.errorMessage ?? "Failed to load students",
          ),
        ),
      );
      return;
    }

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceScreen(
          classId: classData['id'].toString(),
          className: classData['name'].toString(),
          subject: classData['subject'].toString(),
        ),
      ),
    );
  }

  void _handleViewAttendance(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceReportScreen(
          classId: classData['id'].toString(),
          className: classData['name'].toString(),
          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.class_,
                      color: AppTheme.primaryColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classData['name'] ?? 'Class',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        classData['subject'] ?? 'Subject',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _handleViewAttendance(context),
                    child: const Text('View Today',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _handleMarkAttendance(context),
                    child: const Text('Mark Setup',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
