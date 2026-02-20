import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
// ✅ FIX 1 — Replaced image_picker_web (Web-only, crashes on Android/iOS) with
//            the official cross-platform image_picker package.
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ndmu_libtour/admin/models/content_models.dart';
import 'package:ndmu_libtour/admin/services/content_services.dart';
import 'package:ndmu_libtour/admin/services/imgbb_service.dart';

class AboutManagementScreen extends StatefulWidget {
  const AboutManagementScreen({super.key});

  @override
  State<AboutManagementScreen> createState() => _AboutManagementScreenState();
}

class _AboutManagementScreenState extends State<AboutManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ContentService _service = ContentService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('About the Library',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1B5E20),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFD700),
          labelColor: const Color(0xFFFFD700),
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: 'Info & Mission'),
            Tab(icon: Icon(Icons.people_outline), text: 'Staff'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _InfoTab(service: _service),
          _StaffTab(service: _service),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 1 — Mission & History
//
// ✅ FIX 2 — StreamBuilder-inside-edit-form bug resolved:
//   • Data loaded once via fetchAboutData() (Future, not Stream) so mid-session
//     Firestore writes cannot reset the editor while the admin is typing.
//   • All QuillControllers, ScrollControllers, and FocusNodes are fields
//     declared once and freed in dispose() — zero memory leaks.
// ═══════════════════════════════════════════════════════════════════════════════

class _InfoTab extends StatefulWidget {
  final ContentService service;
  const _InfoTab({required this.service});

  @override
  State<_InfoTab> createState() => _InfoTabState();
}

class _InfoTabState extends State<_InfoTab> {
  QuillController? _missionCtrl;
  QuillController? _historyCtrl;

  // Owned here, disposed here — no leaks ✅
  final ScrollController _missionScroll = ScrollController();
  final ScrollController _historyScroll = ScrollController();
  final FocusNode _missionFocus = FocusNode();
  final FocusNode _historyFocus = FocusNode();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadOnce();
  }

  Future<void> _loadOnce() async {
    final data = await widget.service.fetchAboutData();
    if (!mounted) return;
    setState(() {
      _missionCtrl = _buildCtrl(data.missionDelta);
      _historyCtrl = _buildCtrl(data.historyDelta);
      _loading = false;
    });
  }

  QuillController _buildCtrl(List<dynamic> delta) {
    try {
      return QuillController(
        document: Document.fromJson(delta),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (_) {
      return QuillController.basic();
    }
  }

  @override
  void dispose() {
    _missionCtrl?.dispose();
    _historyCtrl?.dispose();
    _missionScroll.dispose();
    _historyScroll.dispose();
    _missionFocus.dispose();
    _historyFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await widget.service.saveAboutData(AboutData(
      missionJson: jsonEncode(_missionCtrl!.document.toDelta().toJson()),
      historyJson: jsonEncode(_historyCtrl!.document.toDelta().toJson()),
      updatedAt: DateTime.now(),
    ));
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'About info saved.' : 'Failed to save.'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel(
                label: 'Mission & Vision',
                hint: 'Displayed at the top of the About page.',
              ),
              const SizedBox(height: 12),
              _QuillEditorCard(
                controller: _missionCtrl!,
                scrollController: _missionScroll,
                focusNode: _missionFocus,
              ),
              const SizedBox(height: 28),
              const _SectionLabel(
                label: 'Historical Background',
                hint: 'Library history shown below Mission & Vision.',
              ),
              const SizedBox(height: 12),
              _QuillEditorCard(
                controller: _historyCtrl!,
                scrollController: _historyScroll,
                focusNode: _historyFocus,
              ),
              const SizedBox(height: 32),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_outlined),
                  label: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 2 — Staff  (StreamBuilder is correct: list view, not edit form)
// ═══════════════════════════════════════════════════════════════════════════════

class _StaffTab extends StatefulWidget {
  final ContentService service;
  const _StaffTab({required this.service});

  @override
  State<_StaffTab> createState() => _StaffTabState();
}

class _StaffTabState extends State<_StaffTab> {
  Future<void> _delete(StaffMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Staff Member'),
        content: Text('Remove "${member.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) await widget.service.deleteStaff(member.id);
  }

  void _openDialog({StaffMember? member, required int nextOrder}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _StaffDialog(
        existing: member,
        nextOrder: nextOrder,
        service: widget.service,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StaffMember>>(
      stream: widget.service.getStaff(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final staff = snap.data ?? [];

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              color: Colors.white,
              child: Row(
                children: [
                  const Icon(Icons.people, color: Color(0xFF1B5E20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${staff.length} staff member${staff.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openDialog(nextOrder: staff.length),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.person_add_outlined),
                    label: const Text('Add Staff'),
                  ),
                ],
              ),
            ),
            if (staff.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No staff members added yet.',
                          style:
                              TextStyle(fontSize: 17, color: Colors.grey[600])),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: staff.length,
                  onReorder: (oldIndex, newIndex) async {
                    if (newIndex > oldIndex) newIndex--;
                    final list = List<StaffMember>.from(staff);
                    final moved = list.removeAt(oldIndex);
                    list.insert(newIndex, moved);
                    await widget.service.reorderStaff(list);
                  },
                  itemBuilder: (context, index) {
                    final member = staff[index];
                    return _StaffTile(
                      key: ValueKey(member.id),
                      member: member,
                      onEdit: () =>
                          _openDialog(member: member, nextOrder: staff.length),
                      onDelete: () => _delete(member),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─── Staff Tile ────────────────────────────────────────────────────────────────

class _StaffTile extends StatelessWidget {
  final StaffMember member;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StaffTile({
    required super.key,
    required this.member,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFF1B5E20).withOpacity(0.1),
          backgroundImage:
              (member.imageUrl != null && member.imageUrl!.isNotEmpty)
                  ? CachedNetworkImageProvider(member.imageUrl!)
                  : null,
          child: (member.imageUrl == null || member.imageUrl!.isEmpty)
              ? const Icon(Icons.person, color: Color(0xFF1B5E20), size: 28)
              : null,
        ),
        title: Text(member.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(member.position,
            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                icon: const Icon(Icons.edit_outlined, color: Color(0xFF1B5E20)),
                onPressed: onEdit),
            IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onDelete),
            const Icon(Icons.drag_handle, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// ─── Staff Add/Edit Dialog ─────────────────────────────────────────────────────

class _StaffDialog extends StatefulWidget {
  final StaffMember? existing;
  final int nextOrder;
  final ContentService service;

  const _StaffDialog({
    this.existing,
    required this.nextOrder,
    required this.service,
  });

  @override
  State<_StaffDialog> createState() => _StaffDialogState();
}

class _StaffDialogState extends State<_StaffDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _positionCtrl;

  String? _imageUrl;
  bool _uploadingImage = false;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _positionCtrl =
        TextEditingController(text: widget.existing?.position ?? '');
    _imageUrl = widget.existing?.imageUrl;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _positionCtrl.dispose();
    super.dispose();
  }

  // ✅ FIX 1: cross-platform image_picker — works on Web, Android, iOS.
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
        'staff_${DateTime.now().millisecondsSinceEpoch}.jpg',
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    bool ok;
    if (_isEdit) {
      ok = await widget.service.updateStaff(widget.existing!.copyWith(
        name: _nameCtrl.text.trim(),
        position: _positionCtrl.text.trim(),
        imageUrl: _imageUrl,
      ));
    } else {
      ok = await widget.service.addStaff(
        name: _nameCtrl.text.trim(),
        position: _positionCtrl.text.trim(),
        imageUrl: _imageUrl,
        order: widget.nextOrder,
      );
    }
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Staff member saved.' : 'Failed to save.'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                color: Color(0xFF1B5E20),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(_isEdit ? Icons.edit : Icons.person_add,
                      color: const Color(0xFFFFD700)),
                  const SizedBox(width: 12),
                  Text(
                    _isEdit ? 'Edit Staff Member' : 'Add Staff Member',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
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
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _uploadingImage ? null : _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 56,
                            backgroundColor:
                                const Color(0xFF1B5E20).withOpacity(0.1),
                            backgroundImage:
                                (_imageUrl != null && _imageUrl!.isNotEmpty)
                                    ? CachedNetworkImageProvider(_imageUrl!)
                                    : null,
                            child: _uploadingImage
                                ? const CircularProgressIndicator()
                                : (_imageUrl == null || _imageUrl!.isEmpty)
                                    ? const Icon(Icons.person,
                                        size: 56, color: Color(0xFF1B5E20))
                                    : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1B5E20),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _uploadingImage ? 'Uploading...' : 'Tap to upload photo',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Full Name *',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _positionCtrl,
                      decoration: InputDecoration(
                        labelText: 'Position / Title *',
                        hintText: 'e.g. Head Librarian',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Position is required'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: (_saving || _uploadingImage) ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(_isEdit ? 'Save Changes' : 'Add Member'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final String hint;
  const _SectionLabel({required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20))),
        const SizedBox(height: 2),
        Text(hint, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }
}

/// Editable Quill card — receives externally-owned nodes so it owns nothing. ✅
class _QuillEditorCard extends StatelessWidget {
  final QuillController controller;
  final ScrollController scrollController;
  final FocusNode focusNode;

  const _QuillEditorCard({
    required this.controller,
    required this.scrollController,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ✅ flutter_quill v11 API — config: (not configurations:)
          QuillSimpleToolbar(
            controller: controller,
            config: QuillSimpleToolbarConfig(
              showFontFamily: false,
              showFontSize: false,
              showInlineCode: false,
              showCodeBlock: false,
              showSubscript: false,
              showSuperscript: false,
              showLink: false,
              showSearchButton: false,
              // multiRowsToolbar: false,
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 220,
            // ✅ flutter_quill v11 API — config: (not configurations:)
            child: QuillEditor(
              controller: controller,
              scrollController: scrollController,
              focusNode: focusNode,
              config: const QuillEditorConfig(
                placeholder: 'Write here...',
                padding: EdgeInsets.all(16),
                scrollable: true,
                expands: false,
                autoFocus: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
