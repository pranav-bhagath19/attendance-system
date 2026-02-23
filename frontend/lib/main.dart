/// Attendance Management App
/// Main entry point for Flutter application

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/dashboard_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/class_provider.dart';
import 'providers/attendance_provider.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Load SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Run App
  runApp(MyApp(sharedPreferences: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences sharedPreferences;

  const MyApp({super.key, required this.sharedPreferences});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth Provider
        ChangeNotifierProvider(
          create: (_) => AuthProvider(sharedPreferences),
        ),

        // Class Provider
        ChangeNotifierProxyProvider<AuthProvider, ClassProvider>(
          create: (_) => ClassProvider(),
          update: (_, authProvider, classProvider) {
            classProvider?.updateToken(authProvider.token);
            return classProvider ?? ClassProvider();
          },
        ),

        // Attendance Provider
        ChangeNotifierProxyProvider<AuthProvider, AttendanceProvider>(
          create: (_) => AttendanceProvider(),
          update: (_, authProvider, attendanceProvider) {
            attendanceProvider?.updateToken(authProvider.token);
            return attendanceProvider ?? AttendanceProvider();
          },
        ),
      ],
      child: MaterialApp(
        title: 'Attendance Manager',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,

        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (authProvider.token != null &&
                authProvider.token!.isNotEmpty) {
              return const DashboardScreen();
            } else {
              return const LoginScreen();
            }
          },
        ),

        routes: {
          '/login': (_) => const LoginScreen(),
          '/dashboard': (_) => const DashboardScreen(),
        },
      ),
    );
  }
}