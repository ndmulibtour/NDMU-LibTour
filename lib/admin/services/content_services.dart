import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/content_models.dart';

class ContentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _policiesCol => _db.collection('policies');
  DocumentReference get _aboutDoc => _db.doc('about/info');
  CollectionReference get _staffCol =>
      _db.doc('about/info').collection('staff');

  Stream<List<PolicyItem>> getPolicies() {
    return _policiesCol.orderBy('order').snapshots().map((snap) => snap.docs
        .map((d) => PolicyItem.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList());
  }

  Future<List<PolicyItem>> fetchPolicies() async {
    try {
      final snap = await _policiesCol.orderBy('order').get();
      return snap.docs
          .map(
              (d) => PolicyItem.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ fetchPolicies error: $e');
      return [];
    }
  }

  Future<bool> addPolicy({
    required String title,
    required String iconName,
    required String contentJson,
    required int order,
  }) async {
    try {
      await _policiesCol.add({
        'title': title,
        'iconName': iconName,
        'contentJson': contentJson,
        'order': order,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('❌ addPolicy error: $e');
      return false;
    }
  }

  Future<bool> updatePolicy(PolicyItem item) async {
    try {
      await _policiesCol.doc(item.id).update({
        'title': item.title,
        'iconName': item.iconName,
        'contentJson': item.contentJson,
        'order': item.order,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('❌ updatePolicy error: $e');
      return false;
    }
  }

  Future<bool> deletePolicy(String id) async {
    try {
      await _policiesCol.doc(id).delete();
      return true;
    } catch (e) {
      print('❌ deletePolicy error: $e');
      return false;
    }
  }

  Future<bool> reorderPolicies(List<PolicyItem> items) async {
    try {
      final batch = _db.batch();
      for (var i = 0; i < items.length; i++) {
        batch.update(_policiesCol.doc(items[i].id), {
          'order': i,
          'updatedAt': Timestamp.now(),
        });
      }
      await batch.commit();
      return true;
    } catch (e) {
      print('❌ reorderPolicies error: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ABOUT — Mission & History
  // ═══════════════════════════════════════════════════════════════════════════

  /// Real-time stream of the single about document.
  Stream<AboutData> getAboutData() {
    return _aboutDoc.snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return AboutData.empty();
      return AboutData.fromMap(snap.data() as Map<String, dynamic>);
    });
  }

  /// One-shot fetch of about data.
  Future<AboutData> fetchAboutData() async {
    try {
      final snap = await _aboutDoc.get();
      if (!snap.exists || snap.data() == null) return AboutData.empty();
      return AboutData.fromMap(snap.data() as Map<String, dynamic>);
    } catch (e) {
      print('❌ fetchAboutData error: $e');
      return AboutData.empty();
    }
  }

  Future<bool> saveAboutData(AboutData data) async {
    try {
      await _aboutDoc.set({
        'missionJson': data.missionJson,
        'historyJson': data.historyJson,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      print('❌ saveAboutData error: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ABOUT — Staff
  // ═══════════════════════════════════════════════════════════════════════════

  Stream<List<StaffMember>> getStaff() {
    return _staffCol.orderBy('order').snapshots().map((snap) => snap.docs
        .map((d) => StaffMember.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList());
  }

  Future<List<StaffMember>> fetchStaff() async {
    try {
      final snap = await _staffCol.orderBy('order').get();
      return snap.docs
          .map((d) =>
              StaffMember.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ fetchStaff error: $e');
      return [];
    }
  }

  Future<bool> addStaff({
    required String name,
    required String position,
    String? imageUrl,
    required int order,
  }) async {
    try {
      await _staffCol.add({
        'name': name,
        'position': position,
        'imageUrl': imageUrl,
        'order': order,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('❌ addStaff error: $e');
      return false;
    }
  }

  Future<bool> updateStaff(StaffMember member) async {
    try {
      await _staffCol.doc(member.id).update({
        'name': member.name,
        'position': member.position,
        'imageUrl': member.imageUrl,
        'order': member.order,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('❌ updateStaff error: $e');
      return false;
    }
  }

  Future<bool> deleteStaff(String id) async {
    try {
      await _staffCol.doc(id).delete();
      return true;
    } catch (e) {
      print('❌ deleteStaff error: $e');
      return false;
    }
  }

  Future<bool> reorderStaff(List<StaffMember> members) async {
    try {
      final batch = _db.batch();
      for (var i = 0; i < members.length; i++) {
        batch.update(_staffCol.doc(members[i].id), {
          'order': i,
          'updatedAt': Timestamp.now(),
        });
      }
      await batch.commit();
      return true;
    } catch (e) {
      print('❌ reorderStaff error: $e');
      return false;
    }
  }
}
