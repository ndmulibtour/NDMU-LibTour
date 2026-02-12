// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/section_model.dart';

// class SectionService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final String _collection = 'content/sections/items';

//   // Get all sections (ordered)
//   Stream<List<LibrarySection>> getSections() {
//     return _firestore
//         .collection(_collection)
//         .orderBy('order')
//         .snapshots()
//         .map((snapshot) {
//       return snapshot.docs
//           .map((doc) => LibrarySection.fromMap(doc.id, doc.data()))
//           .toList();
//     });
//   }

//   // Get single section
//   Future<LibrarySection?> getSection(String id) async {
//     try {
//       final doc = await _firestore.collection(_collection).doc(id).get();
//       if (doc.exists) {
//         return LibrarySection.fromMap(doc.id, doc.data()!);
//       }
//       return null;
//     } catch (e) {
//       print('Error getting section: $e');
//       return null;
//     }
//   }

//   // Add new section
//   Future<bool> addSection({
//     required String name,
//     required String description,
//     required String floor,
//     String? imageUrl,
//     required int order,
//   }) async {
//     try {
//       final now = Timestamp.now();
//       await _firestore.collection(_collection).add({
//         'name': name,
//         'description': description,
//         'floor': floor,
//         'imageUrl': imageUrl,
//         'order': order,
//         'createdAt': now,
//         'updatedAt': now,
//       });
//       print('✅ Section added successfully');
//       return true;
//     } catch (e) {
//       print('❌ Error adding section: $e');
//       return false;
//     }
//   }

//   // Update section
//   Future<bool> updateSection(LibrarySection section) async {
//     try {
//       await _firestore.collection(_collection).doc(section.id).update({
//         'name': section.name,
//         'description': section.description,
//         'floor': section.floor,
//         'imageUrl': section.imageUrl,
//         'order': section.order,
//         'updatedAt': Timestamp.now(),
//       });
//       print('✅ Section updated successfully');
//       return true;
//     } catch (e) {
//       print('❌ Error updating section: $e');
//       return false;
//     }
//   }

//   // Delete section
//   Future<bool> deleteSection(String id) async {
//     try {
//       await _firestore.collection(_collection).doc(id).delete();
//       print('✅ Section deleted successfully');
//       return true;
//     } catch (e) {
//       print('❌ Error deleting section: $e');
//       return false;
//     }
//   }

//   // Reorder sections
//   Future<bool> reorderSections(List<LibrarySection> sections) async {
//     try {
//       final batch = _firestore.batch();
//       for (var i = 0; i < sections.length; i++) {
//         final docRef = _firestore.collection(_collection).doc(sections[i].id);
//         batch.update(docRef, {
//           'order': i,
//           'updatedAt': Timestamp.now(),
//         });
//       }
//       await batch.commit();
//       print('✅ Sections reordered successfully');
//       return true;
//     } catch (e) {
//       print('❌ Error reordering sections: $e');
//       return false;
//     }
//   }
// }
