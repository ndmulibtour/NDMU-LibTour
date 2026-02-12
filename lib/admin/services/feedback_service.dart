import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/feedback_model.dart';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'feedback';

  // Submit feedback from user
  Future<bool> submitFeedback({
    required String name,
    required String email,
    required String message,
    required int rating,
  }) async {
    try {
      if (kDebugMode) {
        print('📝 Submitting feedback...');
      }

      await _firestore.collection(_collection).add({
        'name': name,
        'email': email,
        'message': message,
        'rating': rating,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'adminResponse': null,
        'respondedAt': null,
      });

      if (kDebugMode) {
        print('✅ Feedback submitted successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error submitting feedback: $e');
      }
      return false;
    }
  }

  // Get all feedback (for admin)
  Stream<List<Feedback>> getAllFeedback() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Feedback.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Get feedback by status
  Stream<List<Feedback>> getFeedbackByStatus(String status) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) {
      final feedbackList = snapshot.docs.map((doc) {
        return Feedback.fromMap(doc.id, doc.data());
      }).toList();

      // Sort by createdAt in memory
      feedbackList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return feedbackList;
    });
  }

  // Update feedback status
  Future<bool> updateFeedbackStatus(String id, String status) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating feedback status: $e');
      }
      return false;
    }
  }

  // Add admin response
  Future<bool> respondToFeedback(String id, String response) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'adminResponse': response,
        'respondedAt': FieldValue.serverTimestamp(),
        'status': 'reviewed',
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error responding to feedback: $e');
      }
      return false;
    }
  }

  // Delete feedback
  Future<bool> deleteFeedback(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting feedback: $e');
      }
      return false;
    }
  }

  // Get feedback statistics
  Future<Map<String, int>> getFeedbackStats() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final docs = snapshot.docs;

      int total = docs.length;
      int pending =
          docs.where((doc) => doc.data()['status'] == 'pending').length;
      int reviewed =
          docs.where((doc) => doc.data()['status'] == 'reviewed').length;
      int resolved =
          docs.where((doc) => doc.data()['status'] == 'resolved').length;

      // Calculate average rating
      int totalRating = 0;
      for (var doc in docs) {
        totalRating += (doc.data()['rating'] ?? 0) as int;
      }
      double avgRating = total > 0 ? totalRating / total : 0.0;

      return {
        'total': total,
        'pending': pending,
        'reviewed': reviewed,
        'resolved': resolved,
        'avgRating': avgRating.round(),
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting feedback stats: $e');
      }
      return {
        'total': 0,
        'pending': 0,
        'reviewed': 0,
        'resolved': 0,
        'avgRating': 0,
      };
    }
  }
}
