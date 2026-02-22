// lib/admin/screens/section_management_screen.dart
//
// Redesigned with NDMU glassmorphism theme using admin_ui_kit.dart
// All existing business logic and dialog content preserved.

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../models/section_model.dart';
import '../services/section_service.dart';
import '../services/imgbb_service.dart';
import '../admin_ui_kit.dart';

class SectionManagementScreen extends StatefulWidget {
  const SectionManagementScreen({super.key});

  @override
  State<SectionManagementScreen> createState() =>
      _SectionManagementScreenState();
}

class _SectionManagementScreenState extends State<SectionManagementScreen> {
  final SectionService _sectionService = SectionService();
  final ImgBBService _imgBBService = ImgBBService();

  void _showAddEditDialog(LibrarySection? section) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SectionDialog(
        section: section,
        sectionService: _sectionService,
        imgBBService: _imgBBService,
      ),
    );
  }

  Future<void> _confirmDelete(LibrarySection section) async {
    final ok = await admConfirmDelete(context,
        title: 'Delete Section',
        body:
            '"${section.name}" will be permanently removed from the library.');
    if (!ok || !mounted) return;
    final success = await _sectionService.deleteSection(section.id);
    admSnack(context, success ? 'Section deleted.' : 'Failed to delete.',
        success: success);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kAdmBg,
      child: StreamBuilder<List<LibrarySection>>(
        stream: _sectionService.getSections(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const AdmLoading(message: 'Loading sections…');
          }
          if (snap.hasError) {
            return Center(
                child: Text('Error: ${snap.error}',
                    style: const TextStyle(color: Colors.red)));
          }
          final sections = snap.data ?? [];

          return Column(children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
              color: kAdmBg,
              child: AdmPageHeader(
                title: 'Sections',
                subtitle:
                    'Manage library sections with rich content (${sections.length} total)',
                icon: Icons.library_books_rounded,
                actions: [
                  AdmPrimaryBtn(
                    label: 'Add Section',
                    icon: Icons.add_rounded,
                    onPressed: () => _showAddEditDialog(null),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: sections.isEmpty
                  ? AdmEmpty(
                      icon: Icons.library_books_outlined,
                      title: 'No sections yet',
                      body:
                          'Tap "Add Section" to create your first library section.',
                      action: AdmPrimaryBtn(
                        label: 'Add Section',
                        icon: Icons.add_rounded,
                        onPressed: () => _showAddEditDialog(null),
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                      buildDefaultDragHandles: false,
                      itemCount: sections.length,
                      onReorder: (oldIndex, newIndex) {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final reordered = List<LibrarySection>.from(sections);
                        final item = reordered.removeAt(oldIndex);
                        reordered.insert(newIndex, item);
                        _sectionService.reorderSections(reordered);
                      },
                      itemBuilder: (_, i) => _SectionTile(
                        key: ValueKey(sections[i].id),
                        index: i,
                        section: sections[i],
                        onEdit: () => _showAddEditDialog(sections[i]),
                        onDelete: () => _confirmDelete(sections[i]),
                      ),
                    ),
            ),
          ]);
        },
      ),
    );
  }
}

// ── Section tile ───────────────────────────────────────────────────────────────

class _SectionTile extends StatelessWidget {
  final LibrarySection section;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SectionTile({
    required super.key,
    required this.section,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AdmHoverTile(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle_rounded,
                  color: kAdmMuted, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          // Thumbnail or floor badge
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: section.imageUrl != null
                ? Image.network(section.imageUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _FloorBadge(floor: section.floor))
                : _FloorBadge(floor: section.floor),
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                    child: Text(section.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            color: kAdmText))),
                AdmStatusChip(
                    label: 'Floor ${section.floor}', color: kAdmGreen),
              ]),
              const SizedBox(height: 4),
              if (section.sceneId != null && section.sceneId!.isNotEmpty) ...[
                Row(children: [
                  Icon(Icons.vrpano_rounded, size: 12, color: kAdmGreenMid),
                  const SizedBox(width: 4),
                  Flexible(
                      child: Text('Scene: ${section.sceneId}',
                          style: TextStyle(
                              fontSize: 11,
                              color: kAdmGreenMid,
                              fontFamily: 'monospace'),
                          overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 4),
              ],
              Text(
                section.plainText.isEmpty
                    ? 'No description'
                    : section.plainText,
                style: const TextStyle(
                    fontSize: 12.5, color: kAdmMuted, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text('Order: ${section.order}',
                  style: const TextStyle(fontSize: 11, color: kAdmMuted)),
            ],
          )),
          const SizedBox(width: 8),
          Column(children: [
            AdmTileBtn(
                icon: Icons.edit_rounded,
                color: kAdmGreen,
                tooltip: 'Edit',
                onTap: onEdit),
            const SizedBox(height: 6),
            AdmTileBtn(
                icon: Icons.delete_outline_rounded,
                color: Colors.red,
                tooltip: 'Delete',
                onTap: onDelete),
          ]),
        ]),
      ),
    );
  }
}

class _FloorBadge extends StatelessWidget {
  final String floor;
  const _FloorBadge({required this.floor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: kAdmGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
          child: Text(floor,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kAdmGreen))),
    );
  }
}

// ── Section add/edit dialog ────────────────────────────────────────────────────

class _SectionDialog extends StatefulWidget {
  final LibrarySection? section;
  final SectionService sectionService;
  final ImgBBService imgBBService;

  const _SectionDialog({
    required this.section,
    required this.sectionService,
    required this.imgBBService,
  });

  @override
  State<_SectionDialog> createState() => _SectionDialogState();
}

class _SectionDialogState extends State<_SectionDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _floorCtrl;
  late final TextEditingController _sceneIdCtrl;
  late final QuillController _descCtrl;

  String? _imageUrl;
  Uint8List? _imageBytes;
  bool _uploadingImage = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.section;
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _floorCtrl = TextEditingController(text: s?.floor ?? '');
    _sceneIdCtrl = TextEditingController(text: s?.sceneId ?? '');
    _imageUrl = s?.imageUrl;
    _descCtrl = _buildQuillCtrl(s?.description);
  }

  QuillController _buildQuillCtrl(String? json) {
    if (json == null || json.isEmpty) return QuillController.basic();
    try {
      return QuillController(
        document: Document.fromJson(jsonDecode(json)),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (_) {
      return QuillController.basic();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _floorCtrl.dispose();
    _sceneIdCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _uploadingImage = true);
    try {
      final XFile? picked = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) {
        setState(() => _uploadingImage = false);
        return;
      }
      final bytes = await picked.readAsBytes();
      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _uploadingImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingImage = false);
        admSnack(context, 'Error picking image: $e', success: false);
      }
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      admSnack(context, 'Please enter a section name.', success: false);
      return;
    }
    setState(() => _saving = true);

    try {
      String? finalUrl = _imageUrl;
      if (_imageBytes != null) {
        finalUrl = await widget.imgBBService.uploadImage(
          _imageBytes!,
          '${_nameCtrl.text.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
        );
        if (finalUrl == null) throw Exception('Image upload failed.');
      }

      final descJson = jsonEncode(_descCtrl.document.toDelta().toJson());
      final sceneId =
          _sceneIdCtrl.text.trim().isEmpty ? null : _sceneIdCtrl.text.trim();

      bool ok;
      if (widget.section == null) {
        ok = await widget.sectionService.addSection(
          name: _nameCtrl.text.trim(),
          description: descJson,
          floor: _floorCtrl.text.trim(),
          imageUrl: finalUrl,
          order: 0,
          sceneId: sceneId,
        );
      } else {
        ok = await widget.sectionService.updateSection(widget.section!.copyWith(
          name: _nameCtrl.text.trim(),
          description: descJson,
          floor: _floorCtrl.text.trim(),
          imageUrl: finalUrl,
          sceneId: sceneId,
        ));
      }

      if (mounted) {
        Navigator.pop(context);
        admSnack(
            context,
            ok
                ? (widget.section == null
                    ? 'Section added.'
                    : 'Section updated.')
                : 'Failed to save section.',
            success: ok);
      }
    } catch (e) {
      if (mounted) admSnack(context, 'Error: $e', success: false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.section != null;

    return AdmDialog(
      title: isEdit ? 'Edit Section' : 'Add Section',
      titleIcon: isEdit ? Icons.edit_rounded : Icons.add_circle_outline_rounded,
      maxWidth: 660,
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Name + Floor row
        LayoutBuilder(builder: (ctx, c) {
          final wide = c.maxWidth >= 400;
          final nameField = TextFormField(
            controller: _nameCtrl,
            style: const TextStyle(fontSize: 14, color: kAdmText),
            decoration: admInput(
                label: 'Section Name',
                hint: 'e.g., Filipiniana Section',
                prefixIcon: Icons.label_rounded),
          );
          final floorField = SizedBox(
            width: wide ? 130 : double.infinity,
            child: TextFormField(
              controller: _floorCtrl,
              style: const TextStyle(fontSize: 14, color: kAdmText),
              decoration: admInput(label: 'Floor', hint: 'e.g., 2F'),
            ),
          );
          if (wide) {
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: nameField),
              const SizedBox(width: 12),
              floorField,
            ]);
          }
          return Column(
              children: [nameField, const SizedBox(height: 12), floorField]);
        }),
        const SizedBox(height: 14),

        // Scene ID
        TextFormField(
          controller: _sceneIdCtrl,
          style: const TextStyle(
              fontSize: 13.5, color: kAdmText, fontFamily: 'monospace'),
          decoration: admInput(
              label: 'Virtual Tour Scene ID (optional)',
              hint: 'e.g., scene_filipiniana',
              prefixIcon: Icons.vrpano_rounded),
        ),
        const SizedBox(height: 18),

        // Image
        AdmSectionLabel(label: 'Section Image', icon: Icons.image_rounded),
        const SizedBox(height: 10),
        if (_imageBytes != null || _imageUrl != null)
          Stack(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _imageBytes != null
                  ? Image.memory(_imageBytes!,
                      height: 140, width: double.infinity, fit: BoxFit.cover)
                  : Image.network(_imageUrl!,
                      height: 140, width: double.infinity, fit: BoxFit.cover),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => setState(() {
                  _imageUrl = null;
                  _imageBytes = null;
                }),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                ),
              ),
            ),
          ])
        else
          AdmOutlineBtn(
            label: _uploadingImage ? 'Uploading…' : 'Upload Image',
            icon: Icons.upload_rounded,
            onPressed: _uploadingImage ? null : _pickImage,
          ),
        const SizedBox(height: 18),

        // Rich text description
        AdmSectionLabel(label: 'Description', icon: Icons.description_rounded),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kAdmGreen.withOpacity(0.18)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Column(children: [
              QuillSimpleToolbar(
                controller: _descCtrl,
                config: const QuillSimpleToolbarConfig(multiRowsDisplay: false),
              ),
              const Divider(height: 1),
              SizedBox(
                height: 180,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: QuillEditor.basic(
                      controller: _descCtrl, config: const QuillEditorConfig()),
                ),
              ),
            ]),
          ),
        ),
      ]),
      actions: [
        AdmOutlineBtn(label: 'Cancel', onPressed: () => Navigator.pop(context)),
        AdmPrimaryBtn(
          label: isEdit ? 'Save Changes' : 'Add Section',
          icon: isEdit ? Icons.save_rounded : Icons.add_rounded,
          loading: _saving,
          onPressed: _save,
        ),
      ],
    );
  }
}
