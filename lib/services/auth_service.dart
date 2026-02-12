import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  String? _userRole;
  bool _isLoading = false;

  User? get user => _user;
  String? get userRole => _userRole;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _user = user;
    if (user != null) {
      await _loadUserRole();
    } else {
      _userRole = null;
    }
    notifyListeners();
  }

  Future<void> _loadUserRole() async {
    if (_user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        _userRole = doc.data()?['role'] as String?;
      }
    } catch (e) {
      debugPrint('Error loading user role: $e');
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _loadUserRole();

      _isLoading = false;
      notifyListeners();

      return {
        'success': true,
        'role': _userRole,
      };
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();

      String message = 'An error occurred';
      if (e.code == 'user-not-found') {
        message = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      } else if (e.code == 'user-disabled') {
        message = 'This account has been disabled';
      }

      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  Future<Map<String, dynamic>> createAccount(
    String email,
    String password,
    String name,
    String role,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(result.user!.uid).set({
        'name': name,
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await result.user!.updateDisplayName(name);

      _userRole = role;
      _isLoading = false;
      notifyListeners();

      return {
        'success': true,
        'role': role,
      };
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();

      String message = 'An error occurred';
      if (e.code == 'weak-password') {
        message = 'Password is too weak';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email already in use';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      }

      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _userRole = null;
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
