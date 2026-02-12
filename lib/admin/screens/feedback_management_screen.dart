import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/feedback_model.dart' as feedback_model;
import '../services/feedback_service.dart';

// Type alias to avoid conflict with Flutter's Feedback widget
typedef UserFeedback = feedback_model.Feedback;

class FeedbackManagementScreen extends StatefulWidget {
  const FeedbackManagementScreen({super.key});

  @override
  State<FeedbackManagementScreen> createState() =>
      _FeedbackManagementScreenState();
}

class _FeedbackManagementScreenState extends State<FeedbackManagementScreen> {
  final FeedbackService _feedbackService = FeedbackService();
  String _selectedFilter = 'all';
  String _searchQuery = '';
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _feedbackService.getFeedbackStats();
    setState(() => _stats = stats);
  }

  void _showResponseDialog(UserFeedback feedback) {
    final responseController = TextEditingController(
      text: feedback.adminResponse ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.reply,
                      color: Color(0xFF1B5E20),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Respond to Feedback',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Original Feedback
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            feedback.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        _buildRatingStars(feedback.rating),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      feedback.message,
                      style: TextStyle(
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Response Field
              TextField(
                controller: responseController,
                decoration: InputDecoration(
                  labelText: 'Your Response',
                  hintText: 'Enter your response to this feedback...',
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
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (responseController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a response'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      final success = await _feedbackService.respondToFeedback(
                        feedback.id,
                        responseController.text.trim(),
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Response sent successfully'
                                  : 'Failed to send response',
                            ),
                            backgroundColor:
                                success ? const Color(0xFF1B5E20) : Colors.red,
                          ),
                        );
                        if (success) _loadStats();
                      }
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Send Response'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailsDialog(UserFeedback feedback) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Feedback Details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Name', feedback.name),
              _buildDetailRow('Email', feedback.email),
              _buildDetailRow(
                'Submitted',
                DateFormat('MMM dd, yyyy - hh:mm a').format(feedback.createdAt),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'Rating: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  _buildRatingStars(feedback.rating),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Message:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  feedback.message,
                  style: const TextStyle(height: 1.6),
                ),
              ),
              if (feedback.adminResponse != null) ...[
                const SizedBox(height: 24),
                const Text(
                  'Admin Response:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feedback.adminResponse!,
                        style: const TextStyle(height: 1.6),
                      ),
                      if (feedback.respondedAt != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Responded: ${DateFormat('MMM dd, yyyy - hh:mm a').format(feedback.respondedAt!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(UserFeedback feedback) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Feedback'),
        content: const Text(
          'Are you sure you want to delete this feedback? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success =
                  await _feedbackService.deleteFeedback(feedback.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Feedback deleted successfully'
                          : 'Failed to delete feedback',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
                if (success) _loadStats();
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
          const Text(
            'Feedback Management',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'View and respond to user feedback',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),

          // Stats Cards
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildStatCard(
                'Total Feedback',
                _stats['total']?.toString() ?? '0',
                Icons.feedback,
                Colors.blue,
              ),
              _buildStatCard(
                'Pending',
                _stats['pending']?.toString() ?? '0',
                Icons.pending,
                Colors.orange,
              ),
              _buildStatCard(
                'Reviewed',
                _stats['reviewed']?.toString() ?? '0',
                Icons.check_circle,
                Colors.green,
              ),
              _buildStatCard(
                'Avg. Rating',
                '${_stats['avgRating'] ?? 0} ⭐',
                Icons.star,
                Colors.amber,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Filters and Search
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by name or email...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value.toLowerCase());
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: _selectedFilter,
                    items: const [
                      DropdownMenuItem(
                          value: 'all', child: Text('All Feedback')),
                      DropdownMenuItem(
                          value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(
                          value: 'reviewed', child: Text('Reviewed')),
                      DropdownMenuItem(
                          value: 'resolved', child: Text('Resolved')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedFilter = value ?? 'all');
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Feedback List
          Expanded(
            child: StreamBuilder<List<UserFeedback>>(
              stream: _selectedFilter == 'all'
                  ? _feedbackService.getAllFeedback()
                  : _feedbackService.getFeedbackByStatus(_selectedFilter),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                var feedbackList = snapshot.data ?? [];

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  feedbackList = feedbackList.where((f) {
                    final name = f.name.toLowerCase();
                    final email = f.email.toLowerCase();
                    return name.contains(_searchQuery) ||
                        email.contains(_searchQuery);
                  }).toList();
                }

                if (feedbackList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.feedback_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No feedback found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: feedbackList.length,
                  itemBuilder: (context, index) {
                    final feedback = feedbackList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(feedback.status),
                          child: Text(
                            feedback.name.isNotEmpty
                                ? feedback.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                feedback.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _buildRatingStars(feedback.rating),
                            const SizedBox(width: 12),
                            _buildStatusChip(feedback.status),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              feedback.email,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              feedback.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat('MMM dd, yyyy - hh:mm a')
                                  .format(feedback.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              color: Colors.blue,
                              tooltip: 'View Details',
                              onPressed: () => _showDetailsDialog(feedback),
                            ),
                            IconButton(
                              icon: const Icon(Icons.reply),
                              color: const Color(0xFF1B5E20),
                              tooltip: 'Respond',
                              onPressed: () => _showResponseDialog(feedback),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'delete') {
                                  _confirmDelete(feedback);
                                } else {
                                  await _feedbackService.updateFeedbackStatus(
                                    feedback.id,
                                    value,
                                  );
                                  _loadStats();
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'pending',
                                  child: Text('Mark as Pending'),
                                ),
                                const PopupMenuItem(
                                  value: 'reviewed',
                                  child: Text('Mark as Reviewed'),
                                ),
                                const PopupMenuItem(
                                  value: 'resolved',
                                  child: Text('Mark as Resolved'),
                                ),
                                const PopupMenuDivider(),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
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

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'reviewed':
        color = Colors.green;
        break;
      case 'resolved':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'reviewed':
        return Colors.green;
      case 'resolved':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
