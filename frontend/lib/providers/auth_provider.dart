import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'attendance_provider.dart';
import 'class_provider.dart';

class AuthProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  final ApiService _apiService = ApiService();

  String? _token;
  Map<String, dynamic>? _teacher;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitializing = true;

  String? get token => _token;
  Map<String, dynamic>? get teacher => _teacher;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  bool get isInitializing => _isInitializing;

  AuthProvider(this._prefs) {
    // Register a central unauthorized handler so that any 401/403
    // coming from ApiService will automatically clear the session.
    _apiService.setUnauthorizedHandler(_handleUnauthorized);
    _initializeToken();
  }

  Future<void> _initializeToken() async {
    _isInitializing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _token = _prefs.getString('auth_token');
      final teacherData = _prefs.getString('teacher_data');

      if (teacherData != null) {
        _teacher = jsonDecode(teacherData);
      }

      if (_token != null && _token!.isNotEmpty) {
        _apiService.setToken(_token!);
        await _verifyToken();
      }
    } catch (e) {
      _errorMessage = 'Failed to restore session. Please log in again.';
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<bool> login(
    BuildContext context,
    String email,
    String password,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.login(email, password);

      if (response['success'] == true && response['token'] != null) {
        _token = response['token'];
        _teacher = response['teacher'];

        await _prefs.setString('auth_token', _token!);
        await _prefs.setString('teacher_data', jsonEncode(_teacher));

        _apiService.setToken(_token!);

        // Propagate token into dependent providers
        context.read<ClassProvider>().updateToken(_token);
        context.read<AttendanceProvider>().updateToken(_token);

        return true;
      } else {
        _errorMessage = response['error'] ?? 'Login failed';
        return false;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Login error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _clearStoredSession() async {
    _token = null;
    _teacher = null;
    await _prefs.remove('auth_token');
    await _prefs.remove('teacher_data');
    _apiService.clearToken();
  }

  Future<void> _handleUnauthorized() async {
    _errorMessage = 'Your session has expired. Please log in again.';
    await _clearStoredSession();
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Best-effort server logout; ignore failures because the
      // local session will be cleared regardless.
      await _apiService.logout();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Logout error: $e';
    } finally {
      await _clearStoredSession();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _verifyToken() async {
    try {
      final response = await _apiService.getCurrentTeacher();

      if (response['success'] == true) {
        _teacher = response['teacher'];
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        await _clearStoredSession();
        notifyListeners();
        return false;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      await _clearStoredSession();
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Session verification failed: $e';
      await _clearStoredSession();
      notifyListeners();
      return false;
    }
  }
}