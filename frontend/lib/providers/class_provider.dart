/// Class Provider
/// Manages class and student data state
library;

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ClassProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _classes = [];
  Map<String, dynamic>? _currentClass;
  List<Map<String, dynamic>> _classStudents = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Map<String, dynamic>> get classes => _classes;
  Map<String, dynamic>? get currentClass => _currentClass;
  List<Map<String, dynamic>> get classStudents => _classStudents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Set token from auth provider. When token is cleared (logout),
  // also clear all in-memory class data to avoid leaking state
  // between sessions.
  void updateToken(String? token) {
    if (token != null && token.isNotEmpty) {
      _apiService.setToken(token);
    } else {
      clearAllData();
    }
  }

  // ============ FETCH CLASSES ============

  Future<bool> fetchClasses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getClasses();

      if (response['success'] == true && response['classes'] != null) {
        _classes = List<Map<String, dynamic>>.from(response['classes']);
        return true;
      } else {
        _errorMessage = response['error'] ?? 'Failed to fetch classes';
        return false;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Error fetching classes: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============ FETCH CLASS DETAILS ============

  Future<bool> fetchClassDetails(String classId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getClassDetails(classId);

      if (response['success'] == true && response['class'] != null) {
        _currentClass = response['class'];
        _errorMessage = null;
        return true;
      } else {
        _errorMessage = response['error'] ?? 'Failed to fetch class details';
        return false;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Error fetching class details: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============ FETCH CLASS STUDENTS ============

  Future<bool> fetchClassStudents(String classId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getClassStudents(classId);

      if (response['success'] == true && response['students'] != null) {
        _classStudents =
            List<Map<String, dynamic>>.from(response['students']);
        _errorMessage = null;
        return true;
      } else {
        _errorMessage = response['error'] ?? 'Failed to fetch students';
        return false;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Error fetching students: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============ CLEAR DATA ============

  void clearClassData() {
    _currentClass = null;
    _classStudents = [];
    _errorMessage = null;
    notifyListeners();
  }

  void clearAllData() {
    _classes = [];
    _currentClass = null;
    _classStudents = [];
    _errorMessage = null;
    notifyListeners();
  }
}
