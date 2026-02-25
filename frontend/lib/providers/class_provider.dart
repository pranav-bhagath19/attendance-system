/// Class Provider
/// Manages class and student data state
library;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<void> fetchClasses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final snapshot = await FirebaseFirestore.instance
          .collection("classes")
          .where("teacherId", isEqualTo: uid)
          .get();

      _classes = snapshot.docs
          .map((doc) => {
                "id": doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      _errorMessage = 'Error fetching classes: $e';
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

  Future<void> fetchClassStudents(String classId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("classes")
          .doc(classId)
          .collection("students")
          .get();

      _classStudents = snapshot.docs
          .map((doc) => {
                "id": doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      _errorMessage = 'Error fetching students: $e';
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
