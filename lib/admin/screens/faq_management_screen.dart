// lib/admin/screens/faq_management_screen.dart
//
// Redesigned with NDMU glassmorphism theme using admin_ui_kit.dart

import 'package:flutter/material.dart';
import '../models/faq_model.dart';
import '../services/faq_service.dart';
import '../admin_ui_kit.dart';

class FAQManagementScreen extends StatefulWidget {
  const FAQManagementScreen({super.key});

  @override
  State<FAQManagementScreen> createState() => _FAQManagementScreenState();
}

class _FAQManagementScreenState extends State<FAQManagementScreen> {
  final FAQService _faqService = FAQService();

  // ── Dialog ─────────────────────────────────────────────────────────────────

  void _showAddEditDialog({FAQ? faq}) {
    final isEdit = faq != null;
    final questionCtrl = TextEditingController(text: faq?.question ?? '');
    final answerCtrl = TextEditingController(text: faq?.answer ?? '');
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AdmDialog(
          title: isEdit ? 'Edit FAQ' : 'Add New FAQ',
          titleIcon:
              isEdit ? Icons.edit_rounded : Icons.add_circle_outline_rounded,
          maxWidth: 620,
          body: Form(
            key: formKey,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                isEdit
                    ? 'Update the question and answer below.'
                    : 'Create a new frequently asked question.',
                style: const TextStyle(fontSize: 13, color: kAdmMuted),
              ),
              const SizedBox(height: 20),
              AdmSectionLabel(
                  label: 'Question', icon: Icons.help_outline_rounded),
              const SizedBox(height: 8),
              TextFormField(
                controller: questionCtrl,
                maxLines: 2,
                style: const TextStyle(fontSize: 14, color: kAdmText),
                decoration: admInput(
                  label: 'Question',
                  hint: 'e.g., What are the library opening hours?',
                  prefixIcon: Icons.help_outline_rounded,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter a question.'
                    : null,
              ),
              const SizedBox(height: 18),
              AdmSectionLabel(
                  label: 'Answer', icon: Icons.chat_bubble_outline_rounded),
              const SizedBox(height: 8),
              TextFormField(
                controller: answerCtrl,
                maxLines: 6,
                style: const TextStyle(fontSize: 14, color: kAdmText),
                decoration: admInput(
                  label: 'Answer',
                  hint: 'Provide a clear and detailed answer…',
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter an answer.'
                    : null,
              ),
            ]),
          ),
          actions: [
            AdmOutlineBtn(label: 'Cancel', onPressed: () => Navigator.pop(ctx)),
            AdmPrimaryBtn(
              label: isEdit ? 'Save Changes' : 'Add FAQ',
              icon: isEdit ? Icons.save_rounded : Icons.add_rounded,
              loading: saving,
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                setLocal(() => saving = true);
                bool ok;
                try {
                  if (isEdit) {
                    ok = await _faqService.updateFAQ(faq.copyWith(
                      question: questionCtrl.text.trim(),
                      answer: answerCtrl.text.trim(),
                      updatedAt: DateTime.now(),
                    ));
                  } else {
                    ok = await _faqService.addFAQ(
                      question: questionCtrl.text.trim(),
                      answer: answerCtrl.text.trim(),
                      order: 0,
                    );
                  }
                } catch (_) {
                  ok = false;
                }
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  admSnack(
                      context,
                      ok
                          ? (isEdit ? 'FAQ updated.' : 'FAQ added.')
                          : 'Failed to save FAQ.',
                      success: ok);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(FAQ faq) async {
    final ok = await admConfirmDelete(context,
        title: 'Delete FAQ',
        body:
            '"${faq.question.length > 60 ? '${faq.question.substring(0, 60)}…' : faq.question}"');
    if (!ok || !mounted) return;
    final success = await _faqService.deleteFAQ(faq.id);
    admSnack(context, success ? 'FAQ deleted.' : 'Failed to delete.',
        success: success);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kAdmBg,
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
          color: kAdmBg,
          child: AdmPageHeader(
            title: 'FAQs',
            subtitle: 'Manage frequently asked questions',
            icon: Icons.quiz_rounded,
            actions: [
              AdmPrimaryBtn(
                label: 'Add FAQ',
                icon: Icons.add_rounded,
                onPressed: () => _showAddEditDialog(),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: StreamBuilder<List<FAQ>>(
            stream: _faqService.getFAQs(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const AdmLoading(message: 'Loading FAQs…');
              }
              if (snap.hasError) {
                return Center(
                    child: Text('Error: ${snap.error}',
                        style: const TextStyle(color: Colors.red)));
              }

              final faqs = snap.data ?? [];

              if (faqs.isEmpty) {
                return AdmEmpty(
                  icon: Icons.quiz_outlined,
                  title: 'No FAQs yet',
                  body: 'Tap "Add FAQ" to create your first question.',
                  action: AdmPrimaryBtn(
                    label: 'Add FAQ',
                    icon: Icons.add_rounded,
                    onPressed: () => _showAddEditDialog(),
                  ),
                );
              }

              return ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                buildDefaultDragHandles: false,
                itemCount: faqs.length,
                onReorder: (oldIndex, newIndex) async {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final reordered = List<FAQ>.from(faqs);
                  final item = reordered.removeAt(oldIndex);
                  reordered.insert(newIndex, item);
                  await _faqService.reorderFAQs(reordered);
                },
                itemBuilder: (context, i) => _FaqTile(
                  key: ValueKey(faqs[i].id),
                  faq: faqs[i],
                  index: i,
                  onEdit: () => _showAddEditDialog(faq: faqs[i]),
                  onDelete: () => _confirmDelete(faqs[i]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ── FAQ tile ───────────────────────────────────────────────────────────────────

class _FaqTile extends StatelessWidget {
  final FAQ faq;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FaqTile({
    required super.key,
    required this.faq,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AdmHoverTile(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          // Drag handle
          ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_handle_rounded,
                color: kAdmMuted, size: 20),
          ),
          const SizedBox(width: 10),
          // Index badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: kAdmGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
                child: Text(
              '${index + 1}',
              style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: kAdmGreen),
            )),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(faq.question,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: kAdmText)),
              const SizedBox(height: 5),
              Text(faq.answer,
                  style: const TextStyle(
                      fontSize: 12.5, color: kAdmMuted, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
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
