import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../models/section_model.dart';
import '../services/section_service.dart';
import '../services/imgbb_service.dart';

class SectionManagementScreen extends StatefulWidget {
  const SectionManagementScreen({super.key});

  @override
  State<SectionManagementScreen> createState() =>
      _SectionManagementScreenState();
}

class _SectionManagementScreenState extends State<SectionManagementScreen> {
  final SectionService _sectionService = SectionService();
  final ImgBBService _imgBBService = ImgBBService();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      color: Colors.grey[100],
      child: StreamBuilder<List<LibrarySection>>(
        stream: _sectionService.getSections(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final sections = snapshot.data ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Section Management',
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage library sections with rich content (${sections.length} total)',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditDialog(null),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Section'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Sections List
              Expanded(
                child: sections.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.library_books_outlined,
                                size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('No sections yet',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.grey[600])),
                            const SizedBox(height: 8),
                            Text(
                              'Click "Add Section" to create your first library section',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ReorderableListView.builder(
                        itemCount: sections.length,
                        onReorder: (oldIndex, newIndex) {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final reordered = List<LibrarySection>.from(sections);
                          final item = reordered.removeAt(oldIndex);
                          reordered.insert(newIndex, item);
                          _sectionService.reorderSections(reordered);
                        },
                        itemBuilder: (context, index) =>
                            _buildSectionCard(sections[index], index),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionCard(LibrarySection section, int index) {
    return Card(
      key: ValueKey(section.id),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.drag_handle, color: Colors.grey[400]),
            const SizedBox(width: 12),
            CircleAvatar(
              backgroundColor: const Color(0xFF1B5E20).withOpacity(0.1),
              child: Text(
                section.floor,
                style: const TextStyle(
                    color: Color(0xFF1B5E20), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        title: Text(section.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Floor: ${section.floor} • Order: ${section.order}',
                style: TextStyle(color: Colors.grey[600])),
            // Task 2: show linked scene ID at a glance in the card
            if (section.sceneId != null && section.sceneId!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.vrpano, size: 14, color: Colors.green[700]),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Scene: ${section.sceneId}',
                      style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                          fontFamily: 'monospace'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              section.plainText.isEmpty
                  ? 'No description'
                  : section.plainText.length > 80
                      ? '${section.plainText.substring(0, 80)}...'
                      : section.plainText,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            if (section.imageUrl != null) ...[
              const SizedBox(height: 8),
              Container(
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(section.imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF1B5E20)),
              onPressed: () => _showAddEditDialog(section),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(section),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditDialog(LibrarySection? section) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AddEditSectionDialog(
        section: section,
        sectionService: _sectionService,
        imgBBService: _imgBBService,
      ),
    );
  }

  void _confirmDelete(LibrarySection section) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Section'),
        content: Text('Are you sure you want to delete "${section.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _sectionService.deleteSection(section.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(success
                      ? 'Section deleted successfully'
                      : 'Failed to delete section'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ));
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ADD/EDIT DIALOG
// ═══════════════════════════════════════════════════════════════════════════════

class _AddEditSectionDialog extends StatefulWidget {
  final LibrarySection? section;
  final SectionService sectionService;
  final ImgBBService imgBBService;

  const _AddEditSectionDialog({
    this.section,
    required this.sectionService,
    required this.imgBBService,
  });

  @override
  State<_AddEditSectionDialog> createState() => _AddEditSectionDialogState();
}

class _AddEditSectionDialogState extends State<_AddEditSectionDialog> {
  late TextEditingController _nameController;
  late TextEditingController _floorController;
  late TextEditingController _sceneIdController; // Task 2
  late QuillController _descriptionController;

  String? _imageUrl;
  Uint8List? _selectedImageBytes;
  bool _isUploading = false;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.section?.name ?? '');
    _floorController =
        TextEditingController(text: widget.section?.floor ?? '1F');
    // Task 2: pre-fill with existing sceneId when editing, empty for new
    _sceneIdController =
        TextEditingController(text: widget.section?.sceneId ?? '');
    _imageUrl = widget.section?.imageUrl;

    if (widget.section != null && widget.section!.description.isNotEmpty) {
      try {
        _descriptionController = QuillController(
          document: Document.fromJson(widget.section!.descriptionJson),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        print('Error loading Quill document: $e');
        _descriptionController = QuillController.basic();
      }
    } else {
      _descriptionController = QuillController.basic();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _floorController.dispose();
    _sceneIdController.dispose(); // Task 2
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        constraints: const BoxConstraints(maxHeight: 750),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1B5E20),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.library_books, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    widget.section == null ? 'Add Section' : 'Edit Section',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Section Name',
                        hintText: 'e.g., Main Section, Filipiniana',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Floor
                    TextField(
                      controller: _floorController,
                      decoration: InputDecoration(
                        labelText: 'Floor',
                        hintText: 'e.g., 1F, 2F, 3F',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Task 2: Panoee Scene ID ──────────────────────────────
                    TextField(
                      controller: _sceneIdController,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: 'Panoee Scene ID (Optional)',
                        hintText: 'e.g., 6978265df7083ba3665904a6',
                        helperText:
                            'Copy from the Virtual Tour sidebar. Leave empty if no 360° view exists yet.',
                        helperMaxLines: 2,
                        prefixIcon: const Icon(Icons.vrpano),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        suffixIcon: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _sceneIdController,
                          builder: (_, value, __) => value.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  tooltip: 'Clear',
                                  onPressed: _sceneIdController.clear,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Image Upload
                    const Text('Section Image',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_selectedImageBytes != null || _imageUrl != null)
                      Stack(
                        children: [
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: _selectedImageBytes != null
                                    ? MemoryImage(_selectedImageBytes!)
                                    : NetworkImage(_imageUrl!) as ImageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black.withOpacity(0.54),
                              ),
                              onPressed: () => setState(() {
                                _imageUrl = null;
                                _selectedImageBytes = null;
                              }),
                            ),
                          ),
                        ],
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.upload),
                        label: const Text('Upload Image'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1B5E20),
                          side: const BorderSide(color: Color(0xFF1B5E20)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Description Editor
                    const Text('Description (Rich Text)',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          QuillSimpleToolbar(
                            controller: _descriptionController,
                            config: const QuillSimpleToolbarConfig(
                                multiRowsDisplay: false),
                          ),
                          const Divider(height: 1),
                          Container(
                            height: 200,
                            padding: const EdgeInsets.all(16),
                            child: QuillEditor.basic(
                              controller: _descriptionController,
                              config: const QuillEditorConfig(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isUploading ? null : _saveSection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(widget.section == null ? 'Add' : 'Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    setState(() => _uploadingImage = true);
    try {
      final XFile? picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) {
        if (mounted) setState(() => _uploadingImage = false);
        return;
      }
      final bytes = await picked.readAsBytes();
      final url = await ImgBBService().uploadImage(
        bytes,
        'section_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      if (mounted) {
        setState(() {
          _imageUrl = url;
          _uploadingImage = false;
        });
        if (url == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Image upload failed. Try again.'),
            backgroundColor: Colors.red,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _saveSection() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter section name')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? finalImageUrl = _imageUrl;

      if (_selectedImageBytes != null) {
        finalImageUrl = await widget.imgBBService.uploadImage(
          _selectedImageBytes!,
          '${_nameController.text.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
        );
        if (finalImageUrl == null) {
          throw Exception('Failed to upload image to ImgBB');
        }
      }

      final descriptionJson =
          jsonEncode(_descriptionController.document.toDelta().toJson());

      // Task 2: collect scene ID; treat empty string as null
      final sceneId = _sceneIdController.text.trim().isEmpty
          ? null
          : _sceneIdController.text.trim();

      bool success;
      if (widget.section == null) {
        success = await widget.sectionService.addSection(
          name: _nameController.text,
          description: descriptionJson,
          floor: _floorController.text,
          imageUrl: finalImageUrl,
          order: 0,
          sceneId: sceneId, // Task 2
        );
      } else {
        final updatedSection = widget.section!.copyWith(
          name: _nameController.text,
          description: descriptionJson,
          floor: _floorController.text,
          imageUrl: finalImageUrl,
          sceneId: sceneId, // Task 2
        );
        success = await widget.sectionService.updateSection(updatedSection);
      }

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(widget.section == null
                ? 'Section added successfully'
                : 'Section updated successfully'),
            backgroundColor: const Color(0xFF1B5E20),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save section')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}
