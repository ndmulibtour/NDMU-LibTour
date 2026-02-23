import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ── Hidden domain used to convert usernames into Firebase-compatible emails ─
// Firebase Auth requires email-format identifiers. Admins and Directors type
// only a plain username (e.g. "admin_juan"); this constant is appended
// silently so the user never sees it.
const String _kAuthDomain = '@ndmu.local';

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
  bool get isAdmin => _userRole == 'admin';
  bool get isDirector => _userRole == 'director';

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  // ── Username → Firebase email conversion ─────────────────────────────────
  /// Appends [_kAuthDomain] to a plain username so Firebase Auth receives a
  /// valid email-format string.  The domain is never shown to the user.
  ///
  /// Examples:
  ///   'admin_juan'  →  'admin_juan@ndmu.local'
  ///   'director1'   →  'director1@ndmu.local'
  ///
  /// If the caller accidentally passes something that already contains '@'
  /// (e.g. during a migration), it is returned unchanged to avoid
  /// double-appending.
  static String _toEmail(String username) {
    final trimmed = username.trim();
    return trimmed.contains('@') ? trimmed : '$trimmed$_kAuthDomain';
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
      if (kDebugMode) debugPrint('Error loading user role: $e'); // L-2
    }
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SIGN IN  (Task 2 — username-based)
  // ─────────────────────────────────────────────────────────────────────────
  /// [username] is the plain username typed by the user (no '@' needed).
  /// It is converted to a Firebase-compatible email via [_toEmail] before
  /// being passed to signInWithEmailAndPassword.
  Future<Map<String, dynamic>> signIn(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final email = _toEmail(username);
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _loadUserRole();
      _isLoading = false;
      notifyListeners();
      return {'success': true, 'role': _userRole};
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _mapFirebaseAuthError(e.code)};
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CREATE ACCOUNT  (Task 2 — username-based; Admin-only action)
  // ─────────────────────────────────────────────────────────────────────────
  /// [username] is the plain username chosen for the new account.
  /// [_toEmail] converts it to the hidden Firebase email format before
  /// passing it to createUserWithEmailAndPassword.
  Future<Map<String, dynamic>> createAccount(
    String username,
    String password,
    String name,
    String role,
  ) async {
    // Security guard: only admins may create accounts
    if (!isAdmin) {
      return {
        'success': false,
        'message':
            'Permission denied. Only administrators can create accounts.',
      };
    }

    _isLoading = true;
    notifyListeners();

    try {
      final email = _toEmail(username);
      final currentAdmin = _auth.currentUser;

      // Create the new user via a secondary FirebaseAuth instance so the
      // current admin session is preserved.
      final secondaryApp = await Firebase.initializeApp(
        name: 'secondaryApp_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final UserCredential result =
          await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await result.user!.updateDisplayName(name);

      // Store the plain username in Firestore for display purposes.
      // The email field stores the hidden @ndmu.local address so it is
      // consistent with what Firebase Auth has on record.
      await _firestore.collection('users').doc(result.user!.uid).set({
        'name': name,
        'username': username, // plain username — shown in the UI
        'email': email, // hidden @ndmu.local address — matches Auth
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': currentAdmin?.uid ?? 'system',
      });

      await secondaryAuth.signOut();
      await secondaryApp.delete();

      _isLoading = false;
      notifyListeners();

      return {'success': true, 'role': role};
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _mapFirebaseAuthError(e.code)};
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SUCCESSION / ACCOUNT DELETION LOGIC
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns the total number of admin accounts in Firestore.
  Future<int> getAdminCount() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      if (kDebugMode) debugPrint('Error counting admins: $e'); // L-2
      return 1; // fail-safe: assume only 1 so deletion is blocked
    }
  }

  /// Returns true only if the current admin is allowed to delete their account
  /// (i.e., there is at least one other admin to take over).
  Future<bool> canDeleteAccount() async {
    if (!isAdmin) return true; // directors can always self-delete
    final count = await getAdminCount();
    return count > 1;
  }

  /// Deletes the currently authenticated account after verifying the
  /// succession constraint for admins.
  ///
  /// [password] is the plain password — the email is derived from the
  /// currently signed-in user's Firebase Auth email field (which already
  /// contains the @ndmu.local domain).
  Future<Map<String, dynamic>> deleteOwnAccount(String password) async {
    if (_user == null) {
      return {'success': false, 'message': 'No authenticated user found.'};
    }

    // ── Succession guard ──────────────────────────────────────────────────
    if (isAdmin) {
      final adminCount = await getAdminCount();
      if (adminCount <= 1) {
        return {
          'success': false,
          'message': 'You must appoint a successor before resigning. '
              'Create or promote another admin account first.',
        };
      }
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Re-authenticate before deletion (Firebase requirement).
      // _user!.email already contains the @ndmu.local address stored by Auth.
      final credential = EmailAuthProvider.credential(
        email: _user!.email!,
        password: password,
      );
      await _user!.reauthenticateWithCredential(credential);

      // Delete Firestore record first
      await _firestore.collection('users').doc(_user!.uid).delete();

      // Then delete the Firebase Auth account
      await _user!.delete();

      _isLoading = false;
      notifyListeners();

      return {'success': true};
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _mapFirebaseAuthError(e.code)};
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Deletion failed: $e'};
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DIRECTOR WRITE GUARD
  // ─────────────────────────────────────────────────────────────────────────

  /// Throws a [PermissionDeniedException] if the current user is a Director.
  void assertWritePermission() {
    if (isDirector) {
      throw PermissionDeniedException(
        'Directors have read-only access. This action is not permitted.',
      );
    }
  }

  /// Returns an error map if the current user is a Director, null otherwise.
  Map<String, dynamic>? checkWritePermission() {
    if (isDirector) {
      return {
        'success': false,
        'message':
            'Read-only access. Directors cannot perform write operations.',
      };
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
    _userRole = null;
    notifyListeners();
  }

  /// Sends a password-reset email to the Firebase address derived from
  /// [username].  The '@ndmu.local' domain is appended automatically.
  Future<void> resetPassword(String username) async {
    await _auth.sendPasswordResetEmail(email: _toEmail(username));
  }

  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        // Intentionally unified: do not reveal whether the username exists.
        return 'Invalid username or password.';
      case 'invalid-email':
        // Users only type a username; this error should never surface.
        return 'Invalid username format.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'weak-password':
        return 'Password is too weak (min 6 characters).';
      case 'email-already-in-use':
        return 'An account with this username already exists.';
      case 'requires-recent-login':
        return 'Please log out and log back in before performing this action.';
      default:
        return 'An error occurred ($code).';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom exception for Director write-block
// ─────────────────────────────────────────────────────────────────────────────
class PermissionDeniedException implements Exception {
  final String message;
  const PermissionDeniedException(this.message);

  @override
  String toString() => 'PermissionDeniedException: $message';
}
