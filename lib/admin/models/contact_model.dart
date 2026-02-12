import 'package:cloud_firestore/cloud_firestore.dart';

class ContactMessage {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String message;
  final DateTime createdAt;
  final String status; // 'new', 'read', 'responded'
  final String? adminResponse;
  final DateTime? respondedAt;

  ContactMessage({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.message,
    required this.createdAt,
    this.status = 'new',
    this.adminResponse,
    this.respondedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'adminResponse': adminResponse,
      'respondedAt':
          respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }

  factory ContactMessage.fromMap(String id, Map<String, dynamic> map) {
    return ContactMessage(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      message: map['message'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'new',
      adminResponse: map['adminResponse'],
      respondedAt: map['respondedAt'] != null
          ? (map['respondedAt'] as Timestamp).toDate()
          : null,
    );
  }

  ContactMessage copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? message,
    DateTime? createdAt,
    String? status,
    String? adminResponse,
    DateTime? respondedAt,
  }) {
    return ContactMessage(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      adminResponse: adminResponse ?? this.adminResponse,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}
