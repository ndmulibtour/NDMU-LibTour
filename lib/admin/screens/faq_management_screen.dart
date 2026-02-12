import 'package:flutter/material.dart';
import '../models/faq_model.dart';
import '../services/faq_service.dart';

class FAQManagementScreen extends StatefulWidget {
  const FAQManagementScreen({super.key});

  @override
  State<FAQManagementScreen> createState() => _FAQManagementScreenState();
}

class _FAQManagementScreenState extends State<FAQManagementScreen> {
  final FAQService _faqService = FAQService();

  void _showAddEditDialog({FAQ? faq}) {
    final isEdit = faq != null;
    final questionController = TextEditingController(text: faq?.question ?? '');
    final answerController = TextEditingController(text: faq?.answer ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(32),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B5E20).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isEdit ? Icons.edit : Icons.add_circle_outline,
                          color: const Color(0xFF1B5E20),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        isEdit ? 'Edit FAQ' : 'Add New FAQ',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isEdit
                        ? 'Update the question and answer below'
                        : 'Create a new frequently asked question',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Question Field
                  Text(
                    'Question',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: questionController,
                    decoration: InputDecoration(
                      hintText: 'e.g., What are the library opening hours?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF1B5E20),
                          width: 2,
                        ),
                      ),
                      prefixIcon: const Icon(
                        Icons.help_outline,
                        color: Color(0xFF1B5E20),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    maxLines: 2,
                    style: const TextStyle(fontSize: 15),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a question';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Answer Field
                  Text(
                    'Answer',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: answerController,
                    decoration: InputDecoration(
                      hintText: 'Provide a clear and detailed answer...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF1B5E20),
                          width: 2,
                        ),
                      ),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 80),
                        child: Icon(
                          Icons.chat_bubble_outline,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    maxLines: 6,
                    style: const TextStyle(fontSize: 15),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an answer';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            bool success;
                            try {
                              if (isEdit) {
                                success = await _faqService.updateFAQ(
                                  faq.copyWith(
                                    question: questionController.text.trim(),
                                    answer: answerController.text.trim(),
                                    updatedAt: DateTime.now(),
                                  ),
                                );
                              } else {
                                success = await _faqService.addFAQ(
                                  question: questionController.text.trim(),
                                  answer: answerController.text.trim(),
                                  order: 0,
                                );
                              }

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          success
                                              ? Icons.check_circle
                                              : Icons.error,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          success
                                              ? isEdit
                                                  ? 'FAQ updated successfully'
                                                  : 'FAQ added successfully'
                                              : 'Failed to save FAQ',
                                        ),
                                      ],
                                    ),
                                    backgroundColor: success
                                        ? const Color(0xFF1B5E20)
                                        : Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.error,
                                            color: Colors.white),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text('Error: ${e.toString()}'),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                        },
                        icon: Icon(isEdit ? Icons.save : Icons.add),
                        label: Text(
                          isEdit ? 'Update FAQ' : 'Add FAQ',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(FAQ faq) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete FAQ'),
        content: Text(
            'Are you sure you want to delete this FAQ?\n\n"${faq.question}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await _faqService.deleteFAQ(faq.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'FAQ deleted successfully'
                        : 'Failed to delete FAQ'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'FAQ Management',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddEditDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add FAQ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage frequently asked questions',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 32),

          // FAQ List
          Expanded(
            child: StreamBuilder<List<FAQ>>(
              stream: _faqService.getFAQs(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final faqs = snapshot.data ?? [];

                if (faqs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.question_answer_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No FAQs yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Click "Add FAQ" to create your first question',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ReorderableListView.builder(
                  itemCount: faqs.length,
                  onReorder: (oldIndex, newIndex) async {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final item = faqs.removeAt(oldIndex);
                    faqs.insert(newIndex, item);
                    await _faqService.reorderFAQs(faqs);
                  },
                  itemBuilder: (context, index) {
                    final faq = faqs[index];
                    return Card(
                      key: ValueKey(faq.id),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.drag_handle, color: Colors.grey[400]),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              backgroundColor: const Color(0xFF1B5E20),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        title: Text(
                          faq.question,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          faq.answer,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              color: Colors.blue,
                              onPressed: () => _showAddEditDialog(faq: faq),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              color: Colors.red,
                              onPressed: () => _confirmDelete(faq),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
