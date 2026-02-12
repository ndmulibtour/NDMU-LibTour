// import 'package:cloud_firestore/cloud_firestore.dart';

// class LibrarySection {
//   final String id;
//   final String name;
//   final String description; // Rich text JSON from Flutter Quill
//   final String floor;
//   final String? imageUrl; // URL from ImgBB
//   final int order;
//   final DateTime createdAt;
//   final DateTime updatedAt;

//   LibrarySection({
//     required this.id,
//     required this.name,
//     required this.description,
//     required this.floor,
//     this.imageUrl,
//     required this.order,
//     required this.createdAt,
//     required this.updatedAt,
//   });

//   // Convert to Map for Firestore
//   Map<String, dynamic> toMap() {
//     return {
//       'name': name,
//       'description': description,
//       'floor': floor,
//       'imageUrl': imageUrl,
//       'order': order,
//       'createdAt': Timestamp.fromDate(createdAt),
//       'updatedAt': Timestamp.fromDate(updatedAt),
//     };
//   }

//   // Create from Firestore document
//   factory LibrarySection.fromMap(String id, Map<String, dynamic> map) {
//     DateTime parseDate(dynamic value) {
//       if (value == null) return DateTime.now();
//       if (value is Timestamp) return value.toDate();
//       if (value is String) return DateTime.parse(value);
//       return DateTime.now();
//     }

//     return LibrarySection(
//       id: id,
//       name: map['name'] ?? '',
//       description: map['description'] ?? '',
//       floor: map['floor'] ?? '1F',
//       imageUrl: map['imageUrl'],
//       order: map['order'] ?? 0,
//       createdAt: parseDate(map['createdAt']),
//       updatedAt: parseDate(map['updatedAt']),
//     );
//   }

//   // Create a copy with updated fields
//   LibrarySection copyWith({
//     String? id,
//     String? name,
//     String? description,
//     String? floor,
//     String? imageUrl,
//     int? order,
//     DateTime? createdAt,
//     DateTime? updatedAt,
//   }) {
//     return LibrarySection(
//       id: id ?? this.id,
//       name: name ?? this.name,
//       description: description ?? this.description,
//       floor: floor ?? this.floor,
//       imageUrl: imageUrl ?? this.imageUrl,
//       order: order ?? this.order,
//       createdAt: createdAt ?? this.createdAt,
//       updatedAt: updatedAt ?? this.updatedAt,
//     );
//   }
// }
