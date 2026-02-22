// lib/admin/screens/about_management_screen.dart
//
// Redesigned with NDMU glassmorphism theme using admin_ui_kit.dart
// All QuillController lifecycle safety, imgBB logic, and service calls
// from the original are fully preserved.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ndmu_libtour/admin/models/content_models.dart';
import 'package:ndmu_libtour/admin/services/content_services.dart';
import 'package:ndmu_libtour/admin/services/imgbb_service.dart';
import '../admin_ui_kit.dart';

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
    return Container(
      color: kAdmBg,
      child: Column(children: [
        // ── Header + tab bar ─────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
          color: kAdmBg,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AdmPageHeader(
              title: 'About the Library',
              subtitle: 'Edit mission, history, and staff information',
              icon: Icons.info_rounded,
            ),
            const SizedBox(height: 16),
            AdmGlass(
              padding: EdgeInsets.zero,
              child: TabBar(
                controller: _tabController,
                indicatorColor: kAdmGold,
                indicatorWeight: 3,
                labelColor: kAdmGreen,
                unselectedLabelColor: kAdmMuted,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13.5),
                unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.normal, fontSize: 13.5),
                tabs: const [
                  Tab(text: 'Info & Mission'),
                  Tab(text: 'Staff'),
                ],
              ),
            ),
          ]),
        ),

        // ── Tab content ──────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _InfoTab(service: _service),
              _StaffTab(service: _service),
            ],
          ),
        ),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 1 — Mission & History
// ═════════════════════════════════════════════════════════════════════════════

class _InfoTab extends StatefulWidget {
  final ContentService service;
  const _InfoTab({required this.service});

  @override
  State<_InfoTab> createState() => _InfoTabState();
}

class _InfoTabState extends State<_InfoTab> {
  QuillController? _missionCtrl;
  QuillController? _historyCtrl;
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
      admSnack(context, ok ? 'About info saved.' : 'Failed to save.',
          success: ok);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const AdmLoading(message: 'Loading content…');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Mission editor
            AdmSectionLabel(
                label: 'Mission & Vision', icon: Icons.flag_rounded),
            const SizedBox(height: 4),
            const Text('Displayed at the top of the About page.',
                style: TextStyle(fontSize: 12, color: kAdmMuted)),
            const SizedBox(height: 10),
            _QuillCard(
                ctrl: _missionCtrl!,
                scrollCtrl: _missionScroll,
                focusNode: _missionFocus),
            const SizedBox(height: 24),

            // History editor
            AdmSectionLabel(
                label: 'Historical Background',
                icon: Icons.history_edu_rounded),
            const SizedBox(height: 4),
            const Text('Library history shown below Mission & Vision.',
                style: TextStyle(fontSize: 12, color: kAdmMuted)),
            const SizedBox(height: 10),
            _QuillCard(
                ctrl: _historyCtrl!,
                scrollCtrl: _historyScroll,
                focusNode: _historyFocus),
            const SizedBox(height: 24),

            // Save button
            Align(
              alignment: Alignment.centerRight,
              child: AdmPrimaryBtn(
                label: 'Save Changes',
                icon: Icons.save_rounded,
                loading: _saving,
                onPressed: _save,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 2 — Staff
// ═════════════════════════════════════════════════════════════════════════════

class _StaffTab extends StatefulWidget {
  final ContentService service;
  const _StaffTab({required this.service});

  @override
  State<_StaffTab> createState() => _StaffTabState();
}

class _StaffTabState extends State<_StaffTab> {
  Future<void> _delete(StaffMember member) async {
    final ok = await admConfirmDelete(context,
        title: 'Remove Staff Member',
        body: '"${member.name}" will be permanently removed.');
    if (ok) await widget.service.deleteStaff(member.id);
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
          return const AdmLoading(message: 'Loading staff…');
        }
        final staff = snap.data ?? [];

        return Column(children: [
          // Sub-header
          Container(
            padding: const EdgeInsets.fromLTRB(28, 14, 28, 14),
            color: kAdmBg,
            child: Row(children: [
              Text(
                  '${staff.length} staff member${staff.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: kAdmMuted)),
              const Spacer(),
              AdmPrimaryBtn(
                label: 'Add Staff',
                icon: Icons.person_add_rounded,
                small: true,
                onPressed: () => _openDialog(nextOrder: staff.length),
              ),
            ]),
          ),

          Expanded(
            child: staff.isEmpty
                ? AdmEmpty(
                    icon: Icons.people_outline_rounded,
                    title: 'No staff members yet',
                    body: 'Tap "Add Staff" to add the first member.',
                    action: AdmPrimaryBtn(
                      label: 'Add Staff',
                      icon: Icons.person_add_rounded,
                      onPressed: () => _openDialog(nextOrder: 0),
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                    itemCount: staff.length,
                    onReorder: (oldIndex, newIndex) async {
                      if (newIndex > oldIndex) newIndex--;
                      final list = List<StaffMember>.from(staff);
                      final moved = list.removeAt(oldIndex);
                      list.insert(newIndex, moved);
                      await widget.service.reorderStaff(list);
                    },
                    itemBuilder: (_, i) => _StaffTile(
                      key: ValueKey(staff[i].id),
                      member: staff[i],
                      onEdit: () => _openDialog(
                          member: staff[i], nextOrder: staff.length),
                      onDelete: () => _delete(staff[i]),
                    ),
                  ),
          ),
        ]);
      },
    );
  }
}

// ── Staff tile ─────────────────────────────────────────────────────────────────

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
    return AdmHoverTile(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Icon(Icons.drag_handle_rounded,
              size: 18, color: kAdmMuted.withOpacity(0.5)),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 24,
            backgroundColor: kAdmGreen.withOpacity(0.1),
            backgroundImage:
                (member.imageUrl != null && member.imageUrl!.isNotEmpty)
                    ? CachedNetworkImageProvider(member.imageUrl!)
                    : null,
            child: (member.imageUrl == null || member.imageUrl!.isEmpty)
                ? const Icon(Icons.person_rounded, color: kAdmGreen, size: 24)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(member.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: kAdmText)),
                const SizedBox(height: 3),
                Text(member.position,
                    style: const TextStyle(fontSize: 12.5, color: kAdmMuted)),
              ])),
          AdmTileBtn(
              icon: Icons.edit_rounded,
              color: kAdmGreen,
              tooltip: 'Edit',
              onTap: onEdit),
          AdmTileBtn(
              icon: Icons.delete_outline_rounded,
              color: Colors.red,
              tooltip: 'Delete',
              onTap: onDelete),
        ]),
      ),
    );
  }
}

// ── Staff dialog ───────────────────────────────────────────────────────────────

class _StaffDialog extends StatefulWidget {
  final StaffMember? existing;
  final int nextOrder;
  final ContentService service;

  const _StaffDialog(
      {this.existing, required this.nextOrder, required this.service});

  @override
  State<_StaffDialog> createState() => _StaffDialogState();
}

class _StaffDialogState extends State<_StaffDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _posCtrl;

  String? _imageUrl;
  bool _uploadingImage = false;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _posCtrl = TextEditingController(text: widget.existing?.position ?? '');
    _imageUrl = widget.existing?.imageUrl;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _posCtrl.dispose();
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
      final url = await ImgBBService().uploadImage(
          bytes, 'staff_${DateTime.now().millisecondsSinceEpoch}.jpg');
      if (mounted) {
        setState(() {
          _imageUrl = url;
          _uploadingImage = false;
        });
        if (url == null)
          admSnack(context, 'Image upload failed.', success: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingImage = false);
        admSnack(context, 'Error: $e', success: false);
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
        position: _posCtrl.text.trim(),
        imageUrl: _imageUrl,
      ));
    } else {
      ok = await widget.service.addStaff(
        name: _nameCtrl.text.trim(),
        position: _posCtrl.text.trim(),
        imageUrl: _imageUrl,
        order: widget.nextOrder,
      );
    }
    if (mounted) {
      Navigator.pop(context);
      admSnack(context, ok ? 'Staff member saved.' : 'Failed to save.',
          success: ok);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdmDialog(
      title: _isEdit ? 'Edit Staff Member' : 'Add Staff Member',
      titleIcon: _isEdit ? Icons.edit_rounded : Icons.person_add_rounded,
      maxWidth: 520,
      body: Form(
        key: _formKey,
        child: Column(children: [
          // Avatar picker
          GestureDetector(
            onTap: _uploadingImage ? null : _pickImage,
            child: Stack(alignment: Alignment.bottomRight, children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: kAdmGreen.withOpacity(0.1),
                backgroundImage: (_imageUrl?.isNotEmpty == true)
                    ? CachedNetworkImageProvider(_imageUrl!)
                    : null,
                child: _uploadingImage
                    ? const CircularProgressIndicator(
                        color: kAdmGreen, strokeWidth: 2.5)
                    : (_imageUrl == null || _imageUrl!.isEmpty)
                        ? const Icon(Icons.person_rounded,
                            size: 50, color: kAdmGreen)
                        : null,
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                    color: kAdmGreen, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt_rounded,
                    color: Colors.white, size: 14),
              ),
            ]),
          ),
          const SizedBox(height: 6),
          Text(_uploadingImage ? 'Uploading…' : 'Tap to upload photo',
              style: const TextStyle(fontSize: 11.5, color: kAdmMuted)),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameCtrl,
            style: const TextStyle(fontSize: 14, color: kAdmText),
            decoration:
                admInput(label: 'Full Name *', prefixIcon: Icons.badge_rounded),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _posCtrl,
            style: const TextStyle(fontSize: 14, color: kAdmText),
            decoration: admInput(
                label: 'Position / Title *',
                hint: 'e.g. Head Librarian',
                prefixIcon: Icons.work_rounded),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Position is required' : null,
          ),
        ]),
      ),
      actions: [
        AdmOutlineBtn(label: 'Cancel', onPressed: () => Navigator.pop(context)),
        AdmPrimaryBtn(
          label: _isEdit ? 'Save Changes' : 'Add Member',
          icon: _isEdit ? Icons.save_rounded : Icons.add_rounded,
          loading: _saving || _uploadingImage,
          onPressed: _save,
        ),
      ],
    );
  }
}

// ── Glassmorphism Quill editor container ──────────────────────────────────────

class _QuillCard extends StatelessWidget {
  final QuillController ctrl;
  final ScrollController scrollCtrl;
  final FocusNode focusNode;

  const _QuillCard({
    required this.ctrl,
    required this.scrollCtrl,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kAdmGreen.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(children: [
          QuillSimpleToolbar(
            controller: ctrl,
            config: QuillSimpleToolbarConfig(
              showFontFamily: false,
              showFontSize: false,
              showInlineCode: false,
              showCodeBlock: false,
              showSubscript: false,
              showSuperscript: false,
              showLink: false,
              showSearchButton: false,
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 220,
            child: QuillEditor(
              controller: ctrl,
              scrollController: scrollCtrl,
              focusNode: focusNode,
              config: const QuillEditorConfig(
                placeholder: 'Write here…',
                padding: EdgeInsets.all(16),
                scrollable: true,
                expands: false,
                autoFocus: false,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
