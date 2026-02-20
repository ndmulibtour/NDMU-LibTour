import 'package:cloud_firestore/cloud_firestore.dart';

/// Manages the single `system/settings` Firestore document.
///
/// Firestore structure:
///   system/settings {
///     isMaintenanceMode : bool,
///     globalAnnouncement: String,
///     updatedAt         : Timestamp,
///     updatedBy         : String (uid),
///   }
///
/// Firestore Rules to add (paste inside the existing rules block):
/// ─────────────────────────────────────────────────────────────────
///   match /system/settings {
///     allow read:  if true;          // public — needed for maintenance mode
///     allow write: if isAdmin();     // only admins can change settings
///   }
/// ─────────────────────────────────────────────────────────────────
class SystemSettingsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference get _doc => _db.doc('system/settings');

  // ── Real-time stream (used by user HomeScreen) ──────────────────────────
  Stream<SystemSettings> watchSettings() {
    return _doc.snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return SystemSettings.defaults();
      return SystemSettings.fromMap(snap.data() as Map<String, dynamic>);
    });
  }

  // ── One-time fetch (used by admin SettingsPage on init) ────────────────
  Future<SystemSettings> fetchSettings() async {
    try {
      final snap = await _doc.get();
      if (!snap.exists || snap.data() == null) return SystemSettings.defaults();
      return SystemSettings.fromMap(snap.data() as Map<String, dynamic>);
    } catch (e) {
      print('❌ fetchSettings error: $e');
      return SystemSettings.defaults();
    }
  }

  // ── Toggle maintenance mode ────────────────────────────────────────────
  Future<bool> setMaintenanceMode(bool enabled, String updatedByUid) async {
    try {
      await _doc.set({
        'isMaintenanceMode': enabled,
        'updatedAt': Timestamp.now(),
        'updatedBy': updatedByUid,
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      print('❌ setMaintenanceMode error: $e');
      return false;
    }
  }

  // ── Set / clear global announcement ───────────────────────────────────
  Future<bool> setAnnouncement(String text, String updatedByUid) async {
    try {
      await _doc.set({
        'globalAnnouncement': text.trim(),
        'updatedAt': Timestamp.now(),
        'updatedBy': updatedByUid,
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      print('❌ setAnnouncement error: $e');
      return false;
    }
  }
}

// ─── Model ────────────────────────────────────────────────────────────────────

class SystemSettings {
  final bool isMaintenanceMode;
  final String globalAnnouncement;
  final DateTime? updatedAt;

  const SystemSettings({
    required this.isMaintenanceMode,
    required this.globalAnnouncement,
    this.updatedAt,
  });

  factory SystemSettings.defaults() => const SystemSettings(
        isMaintenanceMode: false,
        globalAnnouncement: '',
      );

  factory SystemSettings.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return SystemSettings(
      isMaintenanceMode: map['isMaintenanceMode'] as bool? ?? false,
      globalAnnouncement: map['globalAnnouncement'] as String? ?? '',
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  bool get hasAnnouncement => globalAnnouncement.trim().isNotEmpty;
}
