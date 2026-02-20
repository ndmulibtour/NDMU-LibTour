import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class LibrarySection {
  final String id;
  final String name;
  final String description; // Rich text JSON string from Flutter Quill
  final String floor;
  final String? imageUrl; // URL from ImgBB
  final int order;
  final String? sceneId; // Task 1: Panoee scene ID for virtual tour deep-link
  final DateTime createdAt;
  final DateTime updatedAt;

  LibrarySection({
    required this.id,
    required this.name,
    required this.description,
    required this.floor,
    this.imageUrl,
    required this.order,
    this.sceneId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Helper to parse description JSON into Quill-compatible format
  List<dynamic> get descriptionJson {
    try {
      if (description.isEmpty) return [];
      final decoded = jsonDecode(description);
      return decoded is List ? decoded : [];
    } catch (e) {
      print('Error parsing description JSON: $e');
      return [];
    }
  }

  /// Helper to get plain text from Quill JSON (for previews/search)
  String get plainText {
    try {
      final delta = descriptionJson;
      if (delta.isEmpty) return '';
      return delta
          .where((op) => op['insert'] is String)
          .map((op) => op['insert'] as String)
          .join('')
          .trim();
    } catch (e) {
      return description;
    }
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'floor': floor,
      'imageUrl': imageUrl,
      'order': order,
      'sceneId': sceneId, // Task 1
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create from Firestore document
  factory LibrarySection.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    return LibrarySection(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      floor: map['floor'] ?? '1F',
      imageUrl: map['imageUrl'],
      order: map['order'] ?? 0,
      // Task 1: treat empty string as null so downstream null-checks are clean
      sceneId: (map['sceneId'] as String?)?.isEmpty == true
          ? null
          : map['sceneId'] as String?,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  // Create a copy with updated fields
  // Task 1: sceneId uses an Object? sentinel so callers can explicitly pass
  // null to *clear* a scene ID: section.copyWith(sceneId: null)
  LibrarySection copyWith({
    String? id,
    String? name,
    String? description,
    String? floor,
    String? imageUrl,
    int? order,
    Object? sceneId = _sentinel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LibrarySection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      floor: floor ?? this.floor,
      imageUrl: imageUrl ?? this.imageUrl,
      order: order ?? this.order,
      sceneId: sceneId == _sentinel ? this.sceneId : sceneId as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Private sentinel so copyWith can distinguish "not passed" from explicit null.
const Object _sentinel = Object();
