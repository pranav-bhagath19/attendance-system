/// Attendance Provider
/// Manages attendance marking and reporting state

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AttendanceProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  final Map<String, String> _pendingAttendance = {}; // student_id -> status
  Map<String, dynamic>? _attendanceReport;
  Map<String, dynamic>? _analytics;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSyncing = false;

  // Getters
  Map<String, String> get pendingAttendance => _pendingAttendance;
  Map<String, dynamic>? get attendanceReport => _attendanceReport;
  Map<String, dynamic>? get analytics => _analytics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSyncing => _isSyncing;

  // Set token from auth provider
  void updateToken(String? token) {
    if (token != null) {
      _apiService.setToken(token);
    }
  }

  // ============ MARK SINGLE ATTENDANCE ============

  Future<bool> markAttendance({
    required String studentId,
    required String classId,
    required String status,
    required String date,
    String? notes,
  }) async {
    _errorMessage = null;

    try {
      final response = await _apiService.markAttendance(
        studentId: studentId,
        classId: classId,
        status: status,
        date: date,
        notes: notes,
      );

      if (response['success'] == true) {
        _pendingAttendance[studentId] = status;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['error'] ?? 'Failed to mark attendance';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error marking attendance: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // ============ BATCH MARK ATTENDANCE ============

  Future<bool> batchMarkAttendance({
    required String classId,
    required List<Map<String, dynamic>> attendanceData,
    required String date,
  }) async {
    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.batchMarkAttendance(
        classId: classId,
        attendanceData: attendanceData,
        date: date,
      );

      if (response['success'] == true) {
        _pendingAttendance.clear();
        _isSyncing = false;
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['error'] ?? 'Failed to sync attendance';
        _isSyncing = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error syncing attendance: ${e.toString()}';
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  // ============ FETCH ATTENDANCE REPORT ============

  Future<bool> fetchAttendanceReport(String classId, String date) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getAttendanceReport(
        classId,
        date: date,
      );

      if (response['success'] == true && response['attendance'] != null) {
        _attendanceReport = response;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['error'] ?? 'Failed to fetch report';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error fetching report: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ============ FETCH ANALYTICS ============

  Future<bool> fetchAnalytics(String classId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getAttendanceAnalytics(classId);

      if (response['success'] == true && response['analytics'] != null) {
        _analytics = response;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['error'] ?? 'Failed to fetch analytics';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error fetching analytics: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ============ UPDATE ATTENDANCE ============

  Future<bool> updateAttendance(
    String attendanceId, {
    required String status,
    String? notes,
  }) async {
    _isLoading = true; // ✅ Set loading state
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.updateAttendance(
        attendanceId,
        status: status,
        notes: notes,
      );

      if (response['success'] == true) {
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['error'] ?? 'Failed to update attendance';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error updating attendance: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false; // ✅ Reset loading state
      notifyListeners();
    }
  }

  // ============ LOCAL PENDING MANAGEMENT ============

  void addPendingAttendance(String studentId, String status) {
    _pendingAttendance[studentId] = status;
    notifyListeners();
  }

  void removePendingAttendance(String studentId) {
    _pendingAttendance.remove(studentId);
    notifyListeners();
  }

  void clearPendingAttendance() {
    _pendingAttendance.clear();
    notifyListeners();
  }

  Map<String, dynamic> getPendingAsJson(String classId, String date) {
    return {
      'class_id': classId,
      'attendance_data': _pendingAttendance.entries.map((e) {
        return {
          'student_id': e.key,
          'status': e.value,
          'notes': null,
        };
      }).toList(),
      'date': date,
    };
  }

  // ============ CLEAR DATA ============

  void clearAttendanceData() {
    _attendanceReport = null;
    _analytics = null;
    _errorMessage = null;
    _pendingAttendance.clear();
    notifyListeners();
  }
}
