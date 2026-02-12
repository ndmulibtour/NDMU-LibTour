import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/faq_model.dart';

class FAQService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // FIXED: Use the correct path where FAQs are actually stored
  String get _collection => 'content/faqs/items';

  // Get all FAQs (ordered)
  Stream<List<FAQ>> getFAQs() {
    if (kDebugMode) {
      print('🔍 Loading FAQs from: $_collection');
    }

    return _firestore
        .collection(_collection)
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
      if (kDebugMode) {
        print('📦 Loaded ${snapshot.docs.length} FAQs');
      }

      return snapshot.docs.map((doc) {
        return FAQ.fromMap(doc.id, doc.data());
      }).toList();
    }).handleError((error) {
      if (kDebugMode) {
        print('❌ Error loading FAQs: $error');
      }
      return <FAQ>[];
    });
  }

  // Get single FAQ
  Future<FAQ?> getFAQ(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return FAQ.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FAQ: $e');
      }
      return null;
    }
  }

  // Add new FAQ
  Future<bool> addFAQ({
    required String question,
    required String answer,
    required int order,
  }) async {
    try {
      if (kDebugMode) {
        print('➕ Adding FAQ to: $_collection');
      }
      final now = Timestamp.now();
      final docRef = await _firestore.collection(_collection).add({
        'question': question,
        'answer': answer,
        'order': order,
        'createdAt': now,
        'updatedAt': now,
      });
      if (kDebugMode) {
        print('✅ FAQ added with ID: ${docRef.id}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error adding FAQ: $e');
      }
      return false;
    }
  }

  // Update FAQ
  Future<bool> updateFAQ(FAQ faq) async {
    try {
      await _firestore.collection(_collection).doc(faq.id).update({
        'question': faq.question,
        'answer': faq.answer,
        'order': faq.order,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating FAQ: $e');
      }
      return false;
    }
  }

  // Delete FAQ
  Future<bool> deleteFAQ(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting FAQ: $e');
      }
      return false;
    }
  }

  // Reorder FAQs
  Future<bool> reorderFAQs(List<FAQ> faqs) async {
    try {
      final batch = _firestore.batch();
      for (var i = 0; i < faqs.length; i++) {
        final docRef = _firestore.collection(_collection).doc(faqs[i].id);
        batch.update(docRef, {
          'order': i,
          'updatedAt': Timestamp.now(),
        });
      }
      await batch.commit();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error reordering FAQs: $e');
      }
      return false;
    }
  }
}
