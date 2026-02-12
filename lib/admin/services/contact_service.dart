import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/contact_model.dart';

class ContactService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'contact_messages';

  // Submit contact message from user
  Future<bool> submitContactMessage({
    required String name,
    required String email,
    required String phoneNumber,
    required String message,
  }) async {
    try {
      if (kDebugMode) {
        print('📧 Submitting contact message...');
      }

      await _firestore.collection(_collection).add({
        'name': name,
        'email': email,
        'phoneNumber': phoneNumber,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'new',
        'adminResponse': null,
        'respondedAt': null,
      });

      if (kDebugMode) {
        print('✅ Contact message submitted successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error submitting contact message: $e');
      }
      return false;
    }
  }

  // Get all contact messages (for admin)
  Stream<List<ContactMessage>> getAllContactMessages() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ContactMessage.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Get contact messages by status
  Stream<List<ContactMessage>> getContactMessagesByStatus(String status) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) {
      final messagesList = snapshot.docs.map((doc) {
        return ContactMessage.fromMap(doc.id, doc.data());
      }).toList();

      // Sort by createdAt in memory
      messagesList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return messagesList;
    });
  }

  // Update contact message status
  Future<bool> updateContactStatus(String id, String status) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating contact status: $e');
      }
      return false;
    }
  }

  // Add admin response
  Future<bool> respondToContact(String id, String response) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'adminResponse': response,
        'respondedAt': FieldValue.serverTimestamp(),
        'status': 'responded',
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error responding to contact: $e');
      }
      return false;
    }
  }

  // Delete contact message
  Future<bool> deleteContactMessage(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting contact message: $e');
      }
      return false;
    }
  }

  // Get contact statistics
  Future<Map<String, int>> getContactStats() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final docs = snapshot.docs;

      int total = docs.length;
      int newMessages =
          docs.where((doc) => doc.data()['status'] == 'new').length;
      int read = docs.where((doc) => doc.data()['status'] == 'read').length;
      int responded =
          docs.where((doc) => doc.data()['status'] == 'responded').length;

      return {
        'total': total,
        'new': newMessages,
        'read': read,
        'responded': responded,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting contact stats: $e');
      }
      return {
        'total': 0,
        'new': 0,
        'read': 0,
        'responded': 0,
      };
    }
  }
}
