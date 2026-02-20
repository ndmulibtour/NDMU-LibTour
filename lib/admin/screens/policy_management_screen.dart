import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:ndmu_libtour/admin/models/content_models.dart';
import 'package:ndmu_libtour/admin/services/content_services.dart';

class PolicyManagementScreen extends StatefulWidget {
  const PolicyManagementScreen({super.key});

  @override
  State<PolicyManagementScreen> createState() => _PolicyManagementScreenState();
}

class _PolicyManagementScreenState extends State<PolicyManagementScreen> {
  final ContentService _service = ContentService();

  Future<void> _delete(PolicyItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Policy'),
        content: Text('Delete "${item.title}"? This cannot be undone.'),
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
    if (confirm == true) {
      final ok = await _service.deletePolicy(item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? 'Policy deleted.' : 'Failed to delete policy.'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ));
      }
    }
  }

  void _openDialog({PolicyItem? item, required int nextOrder}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PolicyDialog(
        existing: item,
        nextOrder: nextOrder,
        service: _service,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Library Policies',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1B5E20),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<List<PolicyItem>>(
        stream: _service.getPolicies(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final items = snap.data ?? [];

          return Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                color: Colors.white,
                child: Row(
                  children: [
                    const Icon(Icons.policy, color: Color(0xFF1B5E20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${items.length} polic${items.length == 1 ? 'y' : 'ies'}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _openDialog(nextOrder: items.length),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Policy'),
                    ),
                  ],
                ),
              ),
              if (items.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.policy_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No policies yet.',
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        Text('Tap "Add Policy" to create the first one.',
                            style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    onReorder: (oldIndex, newIndex) async {
                      if (newIndex > oldIndex) newIndex--;
                      final reordered = List<PolicyItem>.from(items);
                      final moved = reordered.removeAt(oldIndex);
                      reordered.insert(newIndex, moved);
                      await _service.reorderPolicies(reordered);
                    },
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _PolicyTile(
                        key: ValueKey(item.id),
                        item: item,
                        onEdit: () =>
                            _openDialog(item: item, nextOrder: items.length),
                        onDelete: () => _delete(item),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Policy Tile ───────────────────────────────────────────────────────────────

class _PolicyTile extends StatelessWidget {
  final PolicyItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PolicyTile({
    required super.key,
    required this.item,
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
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E20).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(item.icon, color: const Color(0xFF1B5E20), size: 24),
        ),
        title: Text(item.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(
          item.plainText.isEmpty ? 'No content yet' : item.plainText,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Color(0xFF1B5E20)),
              tooltip: 'Edit',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
            const Icon(Icons.drag_handle, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// ─── Add/Edit Dialog ───────────────────────────────────────────────────────────
// ✅ Already a StatefulWidget — controllers in initState/dispose.
//    Only fix needed: flutter_quill v11 config: API on toolbar and editor.

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

  // ✅ Lifecycle-safe auxiliary objects owned by this State
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleCtrl = TextEditingController(text: existing?.title ?? '');
    _selectedIcon = existing?.iconName ?? kIconNameMap.keys.first;

    if (existing != null && existing.contentJson.isNotEmpty) {
      try {
        _quillCtrl = QuillController(
          document: Document.fromJson(existing.deltaJson),
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

  String get _contentJson => jsonEncode(_quillCtrl.document.toDelta().toJson());

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    bool ok;
    if (_isEdit) {
      ok = await widget.service.updatePolicy(widget.existing!.copyWith(
        title: _titleCtrl.text.trim(),
        iconName: _selectedIcon,
        contentJson: _contentJson,
      ));
    } else {
      ok = await widget.service.addPolicy(
        title: _titleCtrl.text.trim(),
        iconName: _selectedIcon,
        contentJson: _contentJson,
        order: widget.nextOrder,
      );
    }
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(ok ? 'Policy saved successfully.' : 'Failed to save policy.'),
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
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                color: Color(0xFF1B5E20),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(_isEdit ? Icons.edit : Icons.add,
                      color: const Color(0xFFFFD700)),
                  const SizedBox(width: 12),
                  Text(
                    _isEdit ? 'Edit Policy' : 'Add Policy',
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

            // Form body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: InputDecoration(
                          labelText: 'Policy Title *',
                          hintText: 'e.g. Library Hours',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Title is required'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      const Text('Icon',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedIcon,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                        ),
                        items: kIconNameMap.entries
                            .map((e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Row(
                                    children: [
                                      Icon(e.value,
                                          color: const Color(0xFF1B5E20),
                                          size: 20),
                                      const SizedBox(width: 12),
                                      Text(_formatIconName(e.key)),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedIcon = v);
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text('Content',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            // ✅ flutter_quill v11: config: not configurations:
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
                                // multiRowsToolbar: false,
                              ),
                            ),
                            const Divider(height: 1),
                            SizedBox(
                              height: 240,
                              // ✅ flutter_quill v11: config: not configurations:
                              child: QuillEditor(
                                controller: _quillCtrl,
                                scrollController: _scrollCtrl,
                                focusNode: _focusNode,
                                config: const QuillEditorConfig(
                                  placeholder: 'Enter policy content here...',
                                  padding: EdgeInsets.all(16),
                                  scrollable: true,
                                  expands: false,
                                  autoFocus: false,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
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
                    onPressed: _saving ? null : _save,
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
                        : Text(_isEdit ? 'Save Changes' : 'Add Policy'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatIconName(String name) => name
      .replaceAll('_rounded', '')
      .replaceAll('_outline', '')
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
