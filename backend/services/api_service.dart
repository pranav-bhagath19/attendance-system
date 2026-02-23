import 'package:dio/dio.dart';

class ApiService {

  static const String baseUrl =
      'https://attendance-system-1h6c.onrender.com/api';

  late Dio _dio;
  String? _token;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        contentType: Headers.jsonContentType,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          handler.next(options);
        },
      ),
    );
  }

  // ================= TOKEN =================

  void setToken(String token) {
    _token = token;
  }

  // ================= AUTH =================

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );
    return response.data;
  }

  Future<void> logout() async {
    await _dio.post('/auth/logout');
  }

  Future<Map<String, dynamic>> getCurrentTeacher() async {
    final response = await _dio.get('/auth/me');
    return response.data;
  }

  // ================= CLASSES =================

  Future<Map<String, dynamic>> getClasses() async {
    final response = await _dio.get('/teacher/classes');
    return response.data;
  }

  Future<Map<String, dynamic>> getClassDetails(String classId) async {
    final response = await _dio.get('/teacher/class/$classId');
    return response.data;
  }

  Future<Map<String, dynamic>> getClassStudents(String classId) async {
    final response = await _dio.get('/teacher/class/$classId/students');
    return response.data;
  }

  // ================= ATTENDANCE =================

  Future<Map<String, dynamic>> markAttendance({
    required String studentId,
    required String classId,
    required String status,
    required String date,
    String? notes,
  }) async {
    final response = await _dio.post(
      '/attendance/mark',
      data: {
        'student_id': studentId,
        'class_id': classId,
        'status': status,
        'date': date,
        'notes': notes,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> batchMarkAttendance({
    required String classId,
    required List<Map<String, dynamic>> attendanceData,
    required String date,
  }) async {
    final response = await _dio.post(
      '/attendance/batch-mark',
      data: {
        'class_id': classId,
        'attendance_data': attendanceData,
        'date': date,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getAttendanceReport(
    String classId, {
    required String date,
  }) async {
    final response = await _dio.get(
      '/attendance/class/$classId',
      queryParameters: {'date': date},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateAttendance(
    String attendanceId, {
    required String status,
    String? notes,
  }) async {
    final response = await _dio.put(
      '/attendance/$attendanceId',
      data: {
        'status': status,
        'notes': notes,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getAttendanceAnalytics(String classId) async {
    final response = await _dio.get('/attendance/analytics/$classId');
    return response.data;
  }

  // ================= HEALTH =================

  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}