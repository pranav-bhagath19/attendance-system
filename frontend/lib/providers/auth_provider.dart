import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? user;
  Map<String, dynamic>? teacherData;
  bool isLoading = false;
  String? error;

  // Add getters to align with existing references in main.dart and other screens
  String? get token => null;
  bool get isInitializing => isLoading;
  bool get isLoggedIn => user != null;
  Map<String, dynamic>? get teacher => teacherData;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthChanged);
  }

  void _onAuthChanged(User? firebaseUser) async {
    user = firebaseUser;

    if (user != null) {
      await _loadTeacherData();
    }

    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    try {
      isLoading = true;
      notifyListeners();

      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      user = cred.user;
      await _loadTeacherData();
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadTeacherData() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("teachers")
        .doc(user!.uid)
        .get();

    if (!doc.exists) {
      await logout();
      throw Exception("Not authorized teacher");
    }

    teacherData = doc.data();

    if (teacherData?["active"] != true) {
      await logout();
      throw Exception("Account disabled");
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    user = null;
    teacherData = null;
    notifyListeners();
  }
}
