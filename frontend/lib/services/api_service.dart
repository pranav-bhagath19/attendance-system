import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Exception type used for all API-level failures so that
/// providers can surface clear, user-friendly messages and
/// avoid silent failures.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(
    this.message, {
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}

typedef UnauthorizedHandler = Future<void> Function();

class ApiService {
  static const String baseUrl =
      'https://attendance-system-1h6c.onrender.com/api';

  // ✅ SINGLE GLOBAL INSTANCE
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  late final Dio _dio;
  String? _token;
  UnauthorizedHandler? _unauthorizedHandler;

  // ✅ private constructor (called only once)
  ApiService._internal() {
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
          if (_token != null && _token!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          handler.next(options);
        },
        onError: (DioException error, handler) async {
          final statusCode = error.response?.statusCode;

          // Centralized logging for easier debugging
          if (kDebugMode) {
            debugPrint(
              'API Error: ${error.requestOptions.method} '
              '${error.requestOptions.uri} '
              'status=$statusCode type=${error.type} data=${error.response?.data}',
            );
          }

          // Unauthorized -> trigger logout flow once
          if (statusCode == 401 || statusCode == 403) {
            if (_unauthorizedHandler != null) {
              await _unauthorizedHandler!();
            }
          }

          handler.next(error);
        },
      ),
    );
  }

  // ================= TOKEN & SESSION HANDLING =================

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  void setUnauthorizedHandler(UnauthorizedHandler handler) {
    _unauthorizedHandler = handler;
  }

  // Wraps Dio calls to always throw ApiException with meaningful
  // messages instead of leaking raw DioException into the UI layer.
  Future<Map<String, dynamic>> _request(
    Future<Response<dynamic>> Function() call,
  ) async {
    try {
      final response = await call();
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      // Normalize non-map payloads
      return {'success': true, 'data': data};
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String message;

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        message =
            'The server is taking too long to respond. Please check your connection or try again in a moment.';
      } else if (statusCode == 401 || statusCode == 403) {
        message = 'Your session has expired. Please log in again.';
      } else if (e.type == DioExceptionType.connectionError) {
        message =
            'Unable to connect to the server. Please verify your internet connection.';
      } else if (e.response?.data is Map<String, dynamic> &&
          (e.response?.data['error'] != null)) {
        message = e.response!.data['error'].toString();
      } else {
        message = 'Unexpected server error. Please try again.';
      }

      throw ApiException(
        message,
        statusCode: statusCode,
        data: e.response?.data,
      );
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  // ================= AUTH =================

  Future<Map<String, dynamic>> login(String email, String password) async {
    return _request(
      () => _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      ),
    );
  }

  Future<void> logout() async {
    await _request(() => _dio.post('/auth/logout'));
  }

  Future<Map<String, dynamic>> getCurrentTeacher() async {
    return _request(() => _dio.get('/auth/me'));
  }

  // ================= CLASSES =================

  Future<Map<String, dynamic>> getClasses() async {
    return _request(() => _dio.get('/teacher/classes'));
  }

  Future<Map<String, dynamic>> getClassDetails(String classId) async {
    return _request(() => _dio.get('/teacher/class/$classId'));
  }

  Future<Map<String, dynamic>> getClassStudents(String classId) async {
    return _request(() => _dio.get('/teacher/class/$classId/students'));
  }

  // ================= ATTENDANCE =================

  Future<Map<String, dynamic>> markAttendance({
    required String studentId,
    required String classId,
    required String status,
    required String date,
    String? notes,
  }) async {
    return _request(
      () => _dio.post(
        '/attendance/mark',
        data: {
          'student_id': studentId,
          'class_id': classId,
          'status': status,
          'date': date,
          'notes': notes,
        },
      ),
    );
  }

  Future<Map<String, dynamic>> batchMarkAttendance({
    required String classId,
    required List<Map<String, dynamic>> attendanceData,
    required String date,
  }) async {
    return _request(
      () => _dio.post(
        '/attendance/batch-mark',
        data: {
          'class_id': classId,
          'attendance_data': attendanceData,
          'date': date,
        },
      ),
    );
  }

  Future<Map<String, dynamic>> getAttendanceReport(
    String classId, {
    required String date,
  }) async {
    return _request(
      () => _dio.get(
        '/attendance/class/$classId',
        queryParameters: {'date': date},
      ),
    );
  }

  Future<Map<String, dynamic>> updateAttendance(
    String attendanceId, {
    required String status,
    String? notes,
  }) async {
    return _request(
      () => _dio.put(
        '/attendance/$attendanceId',
        data: {
          'status': status,
          'notes': notes,
        },
      ),
    );
  }

  Future<Map<String, dynamic>> getAttendanceAnalytics(String classId) async {
    return _request(() => _dio.get('/attendance/analytics/$classId'));
  }

  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}