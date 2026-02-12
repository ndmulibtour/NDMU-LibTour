import 'package:cloud_firestore/cloud_firestore.dart';

class Feedback {
  final String id;
  final String name;
  final String email;
  final String message;
  final int rating;
  final DateTime createdAt;
  final String status; // 'pending', 'reviewed', 'resolved'
  final String? adminResponse;
  final DateTime? respondedAt;

  Feedback({
    required this.id,
    required this.name,
    required this.email,
    required this.message,
    required this.rating,
    required this.createdAt,
    this.status = 'pending',
    this.adminResponse,
    this.respondedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'message': message,
      'rating': rating,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'adminResponse': adminResponse,
      'respondedAt':
          respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }

  factory Feedback.fromMap(String id, Map<String, dynamic> map) {
    return Feedback(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      message: map['message'] ?? '',
      rating: map['rating'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
      adminResponse: map['adminResponse'],
      respondedAt: map['respondedAt'] != null
          ? (map['respondedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Feedback copyWith({
    String? id,
    String? name,
    String? email,
    String? message,
    int? rating,
    DateTime? createdAt,
    String? status,
    String? adminResponse,
    DateTime? respondedAt,
  }) {
    return Feedback(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      message: message ?? this.message,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      adminResponse: adminResponse ?? this.adminResponse,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}
