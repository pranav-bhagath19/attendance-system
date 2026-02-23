/// Auth Provider
/// Manages authentication state and JWT token handling

import 'dart:convert'; // ✅ Add for jsonEncode/jsonDecode
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  final ApiService _apiService = ApiService();

  String? _token;
  Map<String, dynamic>? _teacher;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  String? get token => _token;
  Map<String, dynamic>? get teacher => _teacher;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  AuthProvider(this._prefs) {
    _initializeToken();
  }

  // ============ INITIALIZATION ============

  Future<void> _initializeToken() async {
    _token = _prefs.getString('auth_token');
    final teacherData = _prefs.getString('teacher_data'); // ✅ Load teacher data
    if (teacherData != null) {
      _teacher = jsonDecode(teacherData); // ✅ Parse JSON
    }
    if (_token != null) {
      _apiService.setToken(_token!);
      await _verifyToken();
    }
  }

  // ============ LOGIN ============

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.login(email, password);

      if (response['success'] == true && response['token'] != null) {
        _token = response['token'];
        _teacher = response['teacher'];

        // Save token to local storage
        await _prefs.setString('auth_token', _token!);
        await _prefs.setString('teacher_data', _convertToJson(_teacher!));

        // Set token in API service
        _apiService.setToken(_token!);

        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['error'] ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Login error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ============ LOGOUT ============

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      // Logout error handling
    }

    _token = null;
    _teacher = null;
    await _prefs.remove('auth_token');
    await _prefs.remove('teacher_data');
    _errorMessage = null;
    notifyListeners();
  }

  // ============ VERIFY TOKEN ============

  Future<bool> _verifyToken() async {
    try {
      final response = await _apiService.getCurrentTeacher();
      if (response['success'] == true) {
        _teacher = response['teacher'];
        notifyListeners();
        return true;
      } else {
        await logout();
        return false;
      }
    } catch (e) {
      // Token verification error, logging out
      await logout();
      return false;
    }
  }

  // ============ REFRESH TEACHER DATA ============

  Future<void> refreshTeacherData() async {
    try {
      final response = await _apiService.getCurrentTeacher();
      if (response['success'] == true) {
        _teacher = response['teacher'];
        notifyListeners();
      }
    } catch (e) {
      // Error refreshing teacher data
    }
  }

  // ============ HELPERS ============

  String _convertToJson(Map<String, dynamic> data) {
    return jsonEncode(data); // ✅ Proper JSON conversion
  }

  Future<bool> isTokenValid() async {
    if (_token == null) return false;
    
    try {
      final response = await _apiService.getCurrentTeacher();
      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }
}
