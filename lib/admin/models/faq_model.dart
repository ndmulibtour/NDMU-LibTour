import 'package:cloud_firestore/cloud_firestore.dart';

class FAQ {
  final String id;
  final String question;
  final String answer;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  FAQ({
    required this.id,
    required this.question,
    required this.answer,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert FAQ to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'answer': answer,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create FAQ from Firebase document
  factory FAQ.fromMap(String id, Map<String, dynamic> map) {
    // Handle both Timestamp and String formats for backward compatibility
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    return FAQ(
      id: id,
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
      order: map['order'] ?? 0,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  // Create a copy with updated fields
  FAQ copyWith({
    String? id,
    String? question,
    String? answer,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FAQ(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
