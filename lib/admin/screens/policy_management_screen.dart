// lib/admin/screens/policy_management_screen.dart
//
// Redesigned with NDMU glassmorphism theme using admin_ui_kit.dart
// All Quill v11 logic and business logic from original is preserved.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:ndmu_libtour/admin/models/content_models.dart';
import 'package:ndmu_libtour/admin/services/content_services.dart';
import '../admin_ui_kit.dart';

class PolicyManagementScreen extends StatefulWidget {
  const PolicyManagementScreen({super.key});

  @override
  State<PolicyManagementScreen> createState() => _PolicyManagementScreenState();
}

class _PolicyManagementScreenState extends State<PolicyManagementScreen> {
  final ContentService _service = ContentService();

  Future<void> _delete(PolicyItem item) async {
    final ok = await admConfirmDelete(context,
        title: 'Delete Policy',
        body: '"${item.title}" cannot be recovered after deletion.');
    if (ok) {
      final success = await _service.deletePolicy(item.id);
      if (mounted)
        admSnack(context, success ? 'Policy deleted.' : 'Failed to delete.',
            success: success);
    }
  }

  void _openDialog({PolicyItem? item, required int nextOrder}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PolicyDialog(
          existing: item, nextOrder: nextOrder, service: _service),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kAdmBg,
      child: StreamBuilder<List<PolicyItem>>(
        stream: _service.getPolicies(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const AdmLoading(message: 'Loading policies…');
          }
          if (snap.hasError) {
            return Center(
                child: Text('Error: ${snap.error}',
                    style: const TextStyle(color: Colors.red)));
          }
          final items = snap.data ?? [];

          return Column(children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
              color: kAdmBg,
              child: AdmPageHeader(
                title: 'Library Policies',
                subtitle:
                    '${items.length} polic${items.length == 1 ? 'y' : 'ies'} — drag to reorder',
                icon: Icons.policy_rounded,
                actions: [
                  AdmPrimaryBtn(
                    label: 'Add Policy',
                    icon: Icons.add_rounded,
                    onPressed: () => _openDialog(nextOrder: items.length),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: items.isEmpty
                  ? AdmEmpty(
                      icon: Icons.policy_outlined,
                      title: 'No policies yet',
                      body: 'Tap "Add Policy" to create the first one.',
                      action: AdmPrimaryBtn(
                        label: 'Add Policy',
                        icon: Icons.add_rounded,
                        onPressed: () => _openDialog(nextOrder: 0),
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                      buildDefaultDragHandles: false,
                      itemCount: items.length,
                      onReorder: (oldIndex, newIndex) async {
                        if (newIndex > oldIndex) newIndex--;
                        final reordered = List<PolicyItem>.from(items);
                        final moved = reordered.removeAt(oldIndex);
                        reordered.insert(newIndex, moved);
                        await _service.reorderPolicies(reordered);
                      },
                      itemBuilder: (context, i) => _PolicyTile(
                        key: ValueKey(items[i].id),
                        index: i,
                        item: items[i],
                        onEdit: () => _openDialog(
                            item: items[i], nextOrder: items.length),
                        onDelete: () => _delete(items[i]),
                      ),
                    ),
            ),
          ]);
        },
      ),
    );
  }
}

// ── Policy tile ────────────────────────────────────────────────────────────────

class _PolicyTile extends StatelessWidget {
  final PolicyItem item;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PolicyTile({
    required super.key,
    required this.item,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AdmHoverTile(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          // Drag handle
          ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_handle_rounded,
                color: kAdmMuted, size: 20),
          ),
          const SizedBox(width: 10),
          // Icon box
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: kAdmGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: kAdmGreen, size: 18),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: kAdmText)),
              const SizedBox(height: 4),
              Text(
                item.plainText.isEmpty ? 'No content yet' : item.plainText,
                style: const TextStyle(
                    fontSize: 12.5, color: kAdmMuted, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          )),
          const SizedBox(width: 8),
          AdmTileBtn(
              icon: Icons.edit_rounded,
              color: kAdmGreen,
              tooltip: 'Edit',
              onTap: onEdit),
          const SizedBox(width: 6),
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

// ── Policy dialog ──────────────────────────────────────────────────────────────

class _PolicyDialog extends StatefulWidget {
  final PolicyItem? existing;
  final int nextOrder;
  final ContentService service;

  const _PolicyDialog({
    this.existing,
    required this.nextOrder,
    required this.service,
  });

  @override
  State<_PolicyDialog> createState() => _PolicyDialogState();
}

class _PolicyDialogState extends State<_PolicyDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late String _selectedIcon;
  late QuillController _quillCtrl;
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _selectedIcon = e?.iconName ?? kIconNameMap.keys.first;
    if (e != null && e.contentJson.isNotEmpty) {
      try {
        _quillCtrl = QuillController(
          document: Document.fromJson(e.deltaJson),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (_) {
        _quillCtrl = QuillController.basic();
      }
    } else {
      _quillCtrl = QuillController.basic();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _quillCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final contentJson = jsonEncode(_quillCtrl.document.toDelta().toJson());
    bool ok;
    if (_isEdit) {
      ok = await widget.service.updatePolicy(widget.existing!.copyWith(
        title: _titleCtrl.text.trim(),
        iconName: _selectedIcon,
        contentJson: contentJson,
      ));
    } else {
      ok = await widget.service.addPolicy(
        title: _titleCtrl.text.trim(),
        iconName: _selectedIcon,
        contentJson: contentJson,
        order: widget.nextOrder,
      );
    }
    if (mounted) {
      Navigator.pop(context);
      admSnack(context, ok ? 'Policy saved.' : 'Failed to save.', success: ok);
    }
  }

  String _fmtIconName(String name) => name
      .replaceAll('_rounded', '')
      .replaceAll('_outline', '')
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  @override
  Widget build(BuildContext context) {
    return AdmDialog(
      title: _isEdit ? 'Edit Policy' : 'Add Policy',
      titleIcon:
          _isEdit ? Icons.edit_rounded : Icons.add_circle_outline_rounded,
      maxWidth: 700,
      body: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Title
          TextFormField(
            controller: _titleCtrl,
            style: const TextStyle(fontSize: 14, color: kAdmText),
            decoration: admInput(
                label: 'Policy Title *',
                hint: 'e.g., Library Hours',
                prefixIcon: Icons.policy_rounded),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Title is required.' : null,
          ),
          const SizedBox(height: 16),

          // Icon picker
          AdmSectionLabel(label: 'Icon', icon: Icons.emoji_symbols_rounded),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedIcon,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.75),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: kAdmGreen.withOpacity(0.18))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: kAdmGreen.withOpacity(0.18))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kAdmGreen, width: 2)),
            ),
            items: kIconNameMap.entries
                .map((e) => DropdownMenuItem(
                      value: e.key,
                      child: Row(children: [
                        Icon(e.value, color: kAdmGreen, size: 18),
                        const SizedBox(width: 10),
                        Text(_fmtIconName(e.key),
                            style: const TextStyle(
                                fontSize: 13.5, color: kAdmText)),
                      ]),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedIcon = v);
            },
          ),
          const SizedBox(height: 16),

          // Content editor
          AdmSectionLabel(label: 'Content', icon: Icons.description_rounded),
          const SizedBox(height: 8),
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
                  controller: _quillCtrl,
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
                  height: 240,
                  child: QuillEditor(
                    controller: _quillCtrl,
                    scrollController: _scrollCtrl,
                    focusNode: _focusNode,
                    config: const QuillEditorConfig(
                      placeholder: 'Enter policy content here…',
                      padding: EdgeInsets.all(14),
                      scrollable: true,
                      expands: false,
                      autoFocus: false,
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
      actions: [
        AdmOutlineBtn(label: 'Cancel', onPressed: () => Navigator.pop(context)),
        AdmPrimaryBtn(
          label: _isEdit ? 'Save Changes' : 'Add Policy',
          icon: _isEdit ? Icons.save_rounded : Icons.add_rounded,
          loading: _saving,
          onPressed: _save,
        ),
      ],
    );
  }
}
