// import 'package:flutter/material.dart';
// import 'package:flutter_quill/flutter_quill.dart';
// import 'package:image_picker_web/image_picker_web.dart';
// import 'dart:typed_data';
// import 'dart:convert';
// import '../models/section_model.dart';
// import '../services/section_service.dart';
// import '../services/imgbb_service.dart';

// class SectionManagementScreen extends StatefulWidget {
//   const SectionManagementScreen({super.key});

//   @override
//   State<SectionManagementScreen> createState() =>
//       _SectionManagementScreenState();
// }

// class _SectionManagementScreenState extends State<SectionManagementScreen> {
//   final SectionService _sectionService = SectionService();
//   final ImgBBService _imgBBService = ImgBBService();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF1B5E20),
//         title: const Text(
//           'Section Management',
//           style: TextStyle(color: Colors.white),
//         ),
//         elevation: 2,
//       ),
//       body: StreamBuilder<List<LibrarySection>>(
//         stream: _sectionService.getSections(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(
//               child: CircularProgressIndicator(
//                 color: Color(0xFF1B5E20),
//               ),
//             );
//           }

//           if (snapshot.hasError) {
//             return Center(
//               child: Text('Error: ${snapshot.error}'),
//             );
//           }

//           final sections = snapshot.data ?? [];

//           return Column(
//             children: [
//               // Header with Add Button
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 color: Colors.white,
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Library Sections (${sections.length})',
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF1B5E20),
//                       ),
//                     ),
//                     ElevatedButton.icon(
//                       onPressed: () => _showAddEditDialog(null),
//                       icon: const Icon(Icons.add),
//                       label: const Text('Add Section'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF1B5E20),
//                         foregroundColor: Colors.white,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               // Sections List
//               Expanded(
//                 child: sections.isEmpty
//                     ? Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(
//                               Icons.library_books_outlined,
//                               size: 80,
//                               color: Colors.grey[400],
//                             ),
//                             const SizedBox(height: 16),
//                             Text(
//                               'No sections yet',
//                               style: TextStyle(
//                                 fontSize: 18,
//                                 color: Colors.grey[600],
//                               ),
//                             ),
//                           ],
//                         ),
//                       )
//                     : ReorderableListView.builder(
//                         padding: const EdgeInsets.all(16),
//                         itemCount: sections.length,
//                         onReorder: (oldIndex, newIndex) {
//                           setState(() {
//                             if (newIndex > oldIndex) {
//                               newIndex -= 1;
//                             }
//                             final item = sections.removeAt(oldIndex);
//                             sections.insert(newIndex, item);
//                           });
//                           _sectionService.reorderSections(sections);
//                         },
//                         itemBuilder: (context, index) {
//                           final section = sections[index];
//                           return _buildSectionCard(section, index);
//                         },
//                       ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildSectionCard(LibrarySection section, int index) {
//     return Card(
//       key: ValueKey(section.id),
//       margin: const EdgeInsets.only(bottom: 12),
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: ListTile(
//         contentPadding: const EdgeInsets.all(16),
//         leading: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(Icons.drag_handle, color: Colors.grey[400]),
//             const SizedBox(width: 12),
//             CircleAvatar(
//               backgroundColor: const Color(0xFF1B5E20).withValues(alpha: 0.1),
//               child: Text(
//                 section.floor,
//                 style: const TextStyle(
//                   color: Color(0xFF1B5E20),
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ],
//         ),
//         title: Text(
//           section.name,
//           style: const TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 16,
//           ),
//         ),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 8),
//             Text(
//               'Floor: ${section.floor} • Order: ${section.order}',
//               style: TextStyle(color: Colors.grey[600]),
//             ),
//             if (section.imageUrl != null) ...[
//               const SizedBox(height: 8),
//               Container(
//                 height: 100,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(8),
//                   image: DecorationImage(
//                     image: NetworkImage(section.imageUrl!),
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//               ),
//             ],
//           ],
//         ),
//         trailing: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             IconButton(
//               icon: const Icon(Icons.edit, color: Color(0xFF1B5E20)),
//               onPressed: () => _showAddEditDialog(section),
//             ),
//             IconButton(
//               icon: const Icon(Icons.delete, color: Colors.red),
//               onPressed: () => _confirmDelete(section),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showAddEditDialog(LibrarySection? section) {
//     showDialog(
//       context: context,
//       builder: (context) => _AddEditSectionDialog(
//         section: section,
//         sectionService: _sectionService,
//         imgBBService: _imgBBService,
//       ),
//     );
//   }

//   void _confirmDelete(LibrarySection section) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Delete Section'),
//         content: Text('Are you sure you want to delete "${section.name}"?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               await _sectionService.deleteSection(section.id);
//               if (mounted) {
//                 Navigator.pop(context);
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('Section deleted')),
//                 );
//               }
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               foregroundColor: Colors.white,
//             ),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _AddEditSectionDialog extends StatefulWidget {
//   final LibrarySection? section;
//   final SectionService sectionService;
//   final ImgBBService imgBBService;

//   const _AddEditSectionDialog({
//     this.section,
//     required this.sectionService,
//     required this.imgBBService,
//   });

//   @override
//   State<_AddEditSectionDialog> createState() => _AddEditSectionDialogState();
// }

// class _AddEditSectionDialogState extends State<_AddEditSectionDialog> {
//   late TextEditingController _nameController;
//   late QuillController _descriptionController;
//   late TextEditingController _floorController;
//   String? _imageUrl;
//   Uint8List? _selectedImageBytes;
//   bool _isUploading = false;

//   @override
//   void initState() {
//     super.initState();
//     _nameController = TextEditingController(text: widget.section?.name ?? '');
//     _floorController =
//         TextEditingController(text: widget.section?.floor ?? '1F');
//     _imageUrl = widget.section?.imageUrl;

//     // Initialize Quill controller
//     if (widget.section != null && widget.section!.description.isNotEmpty) {
//       try {
//         final doc = Document.fromJson(jsonDecode(widget.section!.description));
//         _descriptionController = QuillController(
//           document: doc,
//           selection: const TextSelection.collapsed(offset: 0),
//         );
//       } catch (e) {
//         _descriptionController = QuillController.basic();
//       }
//     } else {
//       _descriptionController = QuillController.basic();
//     }
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _floorController.dispose();
//     _descriptionController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       child: Container(
//         width: 800,
//         constraints: const BoxConstraints(maxHeight: 700),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Header
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: const BoxDecoration(
//                 color: Color(0xFF1B5E20),
//                 borderRadius: BorderRadius.only(
//                   topLeft: Radius.circular(12),
//                   topRight: Radius.circular(12),
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   const Icon(Icons.library_books, color: Colors.white),
//                   const SizedBox(width: 12),
//                   Text(
//                     widget.section == null ? 'Add Section' : 'Edit Section',
//                     style: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                   const Spacer(),
//                   IconButton(
//                     icon: const Icon(Icons.close, color: Colors.white),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                 ],
//               ),
//             ),

//             // Body
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(24),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Name Field
//                     TextField(
//                       controller: _nameController,
//                       decoration: const InputDecoration(
//                         labelText: 'Section Name',
//                         border: OutlineInputBorder(),
//                         focusedBorder: OutlineInputBorder(
//                           borderSide: BorderSide(color: Color(0xFF1B5E20)),
//                         ),
//                         labelStyle: TextStyle(color: Color(0xFF1B5E20)),
//                       ),
//                     ),
//                     const SizedBox(height: 16),

//                     // Floor Field
//                     TextField(
//                       controller: _floorController,
//                       decoration: const InputDecoration(
//                         labelText: 'Floor (e.g., 1F, 2F, 3F)',
//                         border: OutlineInputBorder(),
//                         focusedBorder: OutlineInputBorder(
//                           borderSide: BorderSide(color: Color(0xFF1B5E20)),
//                         ),
//                         labelStyle: TextStyle(color: Color(0xFF1B5E20)),
//                       ),
//                     ),
//                     const SizedBox(height: 16),

//                     // Image Upload
//                     const Text(
//                       'Section Image',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     if (_imageUrl != null || _selectedImageBytes != null)
//                       Stack(
//                         children: [
//                           Container(
//                             height: 200,
//                             width: double.infinity,
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(8),
//                               image: DecorationImage(
//                                 image: _selectedImageBytes != null
//                                     ? MemoryImage(_selectedImageBytes!)
//                                     : NetworkImage(_imageUrl!) as ImageProvider,
//                                 fit: BoxFit.cover,
//                               ),
//                             ),
//                           ),
//                           Positioned(
//                             top: 8,
//                             right: 8,
//                             child: IconButton(
//                               icon:
//                                   const Icon(Icons.close, color: Colors.white),
//                               style: IconButton.styleFrom(
//                                 backgroundColor:
//                                     Colors.black.withValues(alpha: 0.54),
//                               ),
//                               onPressed: () {
//                                 setState(() {
//                                   _imageUrl = null;
//                                   _selectedImageBytes = null;
//                                 });
//                               },
//                             ),
//                           ),
//                         ],
//                       )
//                     else
//                       OutlinedButton.icon(
//                         onPressed: _pickImage,
//                         icon: const Icon(Icons.upload),
//                         label: const Text('Upload Image'),
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: const Color(0xFF1B5E20),
//                           side: const BorderSide(color: Color(0xFF1B5E20)),
//                         ),
//                       ),
//                     const SizedBox(height: 16),

//                     // Description Editor
//                     const Text(
//                       'Description',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Container(
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.grey[300]!),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Column(
//                         children: [
//                           // Toolbar
//                           QuillSimpleToolbar(
//                             controller: _descriptionController,
//                             config: const QuillSimpleToolbarConfig(),
//                           ),
//                           // Editor
//                           Container(
//                             height: 200,
//                             padding: const EdgeInsets.all(16),
//                             child: QuillEditor.basic(
//                               controller: _descriptionController,
//                               config: const QuillEditorConfig(),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             // Footer with Actions
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.grey[100],
//                 border: Border(
//                   top: BorderSide(color: Colors.grey[300]!),
//                 ),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   TextButton(
//                     onPressed: () => Navigator.pop(context),
//                     child: const Text('Cancel'),
//                   ),
//                   const SizedBox(width: 12),
//                   ElevatedButton(
//                     onPressed: _isUploading ? null : _saveSection,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF1B5E20),
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 32,
//                         vertical: 12,
//                       ),
//                     ),
//                     child: _isUploading
//                         ? const SizedBox(
//                             width: 20,
//                             height: 20,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               color: Colors.white,
//                             ),
//                           )
//                         : Text(widget.section == null ? 'Add' : 'Save'),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _pickImage() async {
//     final pickedImage = await ImagePickerWeb.getImageAsBytes();
//     if (pickedImage != null) {
//       setState(() {
//         _selectedImageBytes = pickedImage;
//       });
//     }
//   }

//   Future<void> _saveSection() async {
//     if (_nameController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please enter section name')),
//       );
//       return;
//     }

//     setState(() => _isUploading = true);

//     try {
//       String? finalImageUrl = _imageUrl;

//       // Upload image if a new one was selected
//       if (_selectedImageBytes != null) {
//         finalImageUrl = await widget.imgBBService.uploadImage(
//           _selectedImageBytes!,
//           '${_nameController.text}_${DateTime.now().millisecondsSinceEpoch}',
//         );
//       }

//       // Get description as JSON
//       final descriptionJson =
//           jsonEncode(_descriptionController.document.toDelta().toJson());

//       bool success;
//       if (widget.section == null) {
//         // Add new section
//         success = await widget.sectionService.addSection(
//           name: _nameController.text,
//           description: descriptionJson,
//           floor: _floorController.text,
//           imageUrl: finalImageUrl,
//           order: 0,
//         );
//       } else {
//         // Update existing section
//         final updatedSection = widget.section!.copyWith(
//           name: _nameController.text,
//           description: descriptionJson,
//           floor: _floorController.text,
//           imageUrl: finalImageUrl,
//         );
//         success = await widget.sectionService.updateSection(updatedSection);
//       }

//       if (mounted) {
//         if (success) {
//           Navigator.pop(context);
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 widget.section == null
//                     ? 'Section added successfully'
//                     : 'Section updated successfully',
//               ),
//             ),
//           );
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Failed to save section')),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error: $e')),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isUploading = false);
//       }
//     }
//   }
// }
