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

    final docRef =
        FirebaseFirestore.instance.collection("teachers").doc(user!.uid);

    final doc = await docRef.get();

    // STEP 1 — if teacher doc does not exist → create automatically
    if (!doc.exists) {
      await docRef.set({
        "email": user!.email,
        "role": "teacher",
        "active": true,
        "created_at": FieldValue.serverTimestamp(),
      });

      teacherData = {
        "email": user!.email,
        "role": "teacher",
        "active": true,
      };

      return;
    }

    teacherData = doc.data();

    // STEP 2 — if active field missing → assume active and update DB
    if (!teacherData!.containsKey("active")) {
      await docRef.update({"active": true});
      teacherData!["active"] = true;
    }

    // STEP 3 — block only if explicitly disabled
    if (teacherData!["active"] == false) {
      await FirebaseAuth.instance.signOut();
      throw Exception("Your account has been disabled. Contact admin.");
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    user = null;
    teacherData = null;
    notifyListeners();
  }
}
