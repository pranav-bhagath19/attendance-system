/// API Service
/// Centralized HTTP client for all API calls

import 'package:dio/dio.dart';
import 'dart:io' show Platform;

class ApiService {
  // Determine the correct base URL based on platform
  static String get baseUrl {
    // For Android emulator: use 10.0.2.2
    // For iOS simulator: use 127.0.0.1
    // For physical device: use machine IP (192.168.29.212)
    // For web: use localhost

    if (Platform.isAndroid) {
      return 'http://192.168.29.212:5000/api'; // ✅ Updated for physical device
    } else if (Platform.isIOS) {
      return 'http://127.0.0.1:5000/api';
    } else {
      return 'http://localhost:5000/api';
    }
  }
  
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

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // API error occurred
          return handler.next(error);
        },
      ),
    );
  }

  // Set authentication token
  void setToken(String token) {
    _token = token;
  }

  // Helper method with retry logic
  Future<T> _executeWithRetry<T>(
    Future<T> Function() request, {
    int maxRetries = 3,
  }) async {
    int retryCount = 0;
    DioException? lastError;

    while (retryCount < maxRetries) {
      try {
        return await request();
      } on DioException catch (e) {
        lastError = e;
        // Only retry on timeout or connection errors
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout) {
          retryCount++;
          if (retryCount < maxRetries) {
            // Wait before retrying (exponential backoff)
            await Future.delayed(Duration(seconds: retryCount * 2));
            continue;
          }
        } else {
          // Don't retry for other errors
          rethrow;
        }
      }
    }

    throw lastError ?? Exception('Request failed after $maxRetries retries');
  }

  // ============ AUTH ENDPOINTS ============

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _executeWithRetry(
        () => _dio.post(
          '/auth/login',
          data: {
            'email': email,
            'password': password,
          },
        ),
        maxRetries: 3,
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } on DioException catch (_) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCurrentTeacher() async {
    try {
      final response = await _dio.get('/auth/me');
      return response.data;
    } on DioException catch (_) {
      rethrow;
    }
  }

  // ============ CLASS ENDPOINTS ============

  Future<Map<String, dynamic>> getClasses() async {
    try {
      final response = await _executeWithRetry(
        () => _dio.get('/teacher/classes'),
        maxRetries: 3,
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getClassDetails(String classId) async {
    try {
      final response = await _executeWithRetry(
        () => _dio.get('/teacher/class/$classId'),
        maxRetries: 3,
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getClassStudents(String classId) async {
    try {
      final response = await _executeWithRetry(
        () => _dio.get('/teacher/class/$classId/students'),
        maxRetries: 3,
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  // ============ ATTENDANCE ENDPOINTS ============

  Future<Map<String, dynamic>> markAttendance({
    required String studentId,
    required String classId,
    required String status,
    required String date,
    String? notes,
  }) async {
    try {
      final response = await _executeWithRetry(
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
        maxRetries: 3,
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> batchMarkAttendance({
    required String classId,
    required List<Map<String, dynamic>> attendanceData,
    required String date,
  }) async {
    try {
      final response = await _dio.post(
        '/attendance/batch-mark',
        data: {
          'class_id': classId,
          'attendance_data': attendanceData,
          'date': date,
        },
      );
      return response.data;
    } on DioException catch (_) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAttendanceReport(
    String classId, {
    required String date,
  }) async {
    try {
      final response = await _dio.get(
        '/attendance/class/$classId',
        queryParameters: {'date': date},
      );
      return response.data;
    } on DioException catch (_) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateAttendance(
    String attendanceId, {
    required String status,
    String? notes,
  }) async {
    try {
      final response = await _dio.put(
        '/attendance/$attendanceId',
        data: {
          'status': status,
          'notes': notes,
        },
      );
      return response.data;
    } on DioException catch (_) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getStudentAttendanceHistory(String studentId) async {
    try {
      final response = await _dio.get('/attendance/student/$studentId');
      return response.data;
    } on DioException catch (_) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAttendanceAnalytics(String classId) async {
    try {
      final response = await _dio.get('/attendance/analytics/$classId');
      return response.data;
    } on DioException catch (_) {
      rethrow;
    }
  }

  // ============ HEALTH CHECK ============

  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ============ ERROR HANDLING ============

  void _handleDioError(DioException error) {
    String errorMessage = 'Network error occurred';

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        errorMessage = 'Connection timeout. Server took too long to respond.';
        break;
      case DioExceptionType.sendTimeout:
        errorMessage = 'Request timeout. Failed to send data.';
        break;
      case DioExceptionType.receiveTimeout:
        errorMessage = 'Response timeout. Server not responding.';
        break;
      case DioExceptionType.badResponse:
        errorMessage = 'Server error: ${error.response?.statusCode}';
        break;
      case DioExceptionType.cancel:
        errorMessage = 'Request was cancelled.';
        break;
      case DioExceptionType.unknown:
        errorMessage = 'Unknown error: ${error.message}';
        break;
      case DioExceptionType.badCertificate:
        errorMessage = 'SSL certificate error.';
        break;
      case DioExceptionType.connectionError:
        errorMessage = 'Failed to connect to server. Check your internet connection.';
        break;
    }

    print('Dio Error: $errorMessage');
  }
}
