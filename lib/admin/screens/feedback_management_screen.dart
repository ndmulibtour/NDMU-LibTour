// lib/admin/screens/feedback_management_screen.dart
//
// Redesigned with NDMU glassmorphism theme using admin_ui_kit.dart
// All functionality preserved. Consistent layout with all other admin screens.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/feedback_model.dart' as feedback_model;
import '../services/feedback_service.dart';
import '../admin_ui_kit.dart';

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
    if (mounted) setState(() => _stats = stats);
  }

  // ── Status helpers ─────────────────────────────────────────────────────────

  Color _statusColor(String status) => switch (status) {
        'reviewed' => kStatusReviewed,
        'resolved' => kStatusResolved,
        _ => kStatusPending,
      };

  String _statusLabel(String status) => switch (status) {
        'reviewed' => 'REVIEWED',
        'resolved' => 'RESOLVED',
        _ => 'PENDING',
      };

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _showDetailsDialog(UserFeedback fb) {
    showDialog(
      context: context,
      builder: (_) => AdmDialog(
        title: 'Feedback Details',
        titleIcon: Icons.rate_review_rounded,
        body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // User info row
          Row(children: [
            _Avatar(name: fb.name, color: _statusColor(fb.status)),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fb.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: kAdmText)),
                const SizedBox(height: 2),
                Text(fb.email,
                    style: const TextStyle(fontSize: 12.5, color: kAdmMuted)),
                const SizedBox(height: 6),
                Row(children: [
                  _Stars(rating: fb.rating),
                  const SizedBox(width: 10),
                  AdmStatusChip(
                      label: _statusLabel(fb.status),
                      color: _statusColor(fb.status)),
                ]),
              ],
            )),
          ]),
          const SizedBox(height: 16),
          AdmInfoRow(
              label: 'Submitted',
              value:
                  DateFormat('MMM dd, yyyy  •  hh:mm a').format(fb.createdAt),
              icon: Icons.calendar_today_rounded),
          const Divider(height: 24),
          AdmSectionLabel(
              label: 'Message', icon: Icons.chat_bubble_outline_rounded),
          const SizedBox(height: 10),
          _MessageBox(text: fb.message),
          if (fb.adminResponse != null) ...[
            const SizedBox(height: 16),
            AdmSectionLabel(label: 'Admin Response', icon: Icons.reply_rounded),
            const SizedBox(height: 10),
            _MessageBox(
                text: fb.adminResponse!,
                color: kAdmGreen.withOpacity(0.06),
                borderColor: kAdmGreen.withOpacity(0.2)),
            if (fb.respondedAt != null) ...[
              const SizedBox(height: 6),
              Text('Sent ${DateFormat('MMM dd, yyyy').format(fb.respondedAt!)}',
                  style: const TextStyle(fontSize: 11, color: kAdmMuted)),
            ],
          ],
        ]),
        actions: [
          AdmOutlineBtn(
              label: 'Close', onPressed: () => Navigator.pop(context)),
          AdmPrimaryBtn(
            label: 'Respond',
            icon: Icons.reply_rounded,
            onPressed: () {
              Navigator.pop(context);
              _showResponseDialog(fb);
            },
          ),
        ],
      ),
    );
  }

  void _showResponseDialog(UserFeedback fb) {
    final ctrl = TextEditingController(text: fb.adminResponse ?? '');
    bool sending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AdmDialog(
          title: 'Respond to Feedback',
          titleIcon: Icons.reply_rounded,
          body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Original message preview
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kAdmGreen.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kAdmGreen.withOpacity(0.14)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      _Avatar(
                          name: fb.name,
                          color: _statusColor(fb.status),
                          size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(fb.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: kAdmText))),
                      _Stars(rating: fb.rating),
                    ]),
                    const SizedBox(height: 8),
                    Text(fb.message,
                        style: const TextStyle(
                            fontSize: 13, color: kAdmMuted, height: 1.45),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                  ]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              maxLines: 5,
              decoration: admInput(
                label: 'Your Response',
                hint: 'Write a helpful response…',
                prefixIcon: Icons.edit_rounded,
                alignLabelWithHint: true,
              ),
              style: const TextStyle(fontSize: 13.5, color: kAdmText),
            ),
          ]),
          actions: [
            AdmOutlineBtn(label: 'Cancel', onPressed: () => Navigator.pop(ctx)),
            AdmPrimaryBtn(
              label: 'Send Response',
              icon: Icons.send_rounded,
              loading: sending,
              onPressed: () async {
                final text = ctrl.text.trim();
                if (text.isEmpty) {
                  admSnack(ctx, 'Please enter a response.', success: false);
                  return;
                }
                setLocal(() => sending = true);
                final ok =
                    await _feedbackService.respondToFeedback(fb.id, text);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  admSnack(context, ok ? 'Response sent.' : 'Failed to send.',
                      success: ok);
                  if (ok) _loadStats();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(UserFeedback fb) async {
    final ok = await admConfirmDelete(context,
        title: 'Delete Feedback',
        body: 'This feedback from ${fb.name} will be permanently removed.');
    if (!ok || !mounted) return;
    final success = await _feedbackService.deleteFeedback(fb.id);
    admSnack(context, success ? 'Feedback deleted.' : 'Failed to delete.',
        success: success);
    if (success) _loadStats();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kAdmBg,
      child: Column(children: [
        // ── Header region ────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
          color: kAdmBg,
          child: Column(children: [
            AdmPageHeader(
              title: 'Feedback',
              subtitle: 'View and respond to user feedback',
              icon: Icons.rate_review_rounded,
            ),
            const SizedBox(height: 20),

            // Stat cards
            LayoutBuilder(builder: (ctx, c) {
              final cols = c.maxWidth >= 600 ? 4 : 2;
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.4,
                children: [
                  AdmStatCard(
                      title: 'Total',
                      value: _stats['total']?.toString() ?? '0',
                      icon: Icons.rate_review_rounded,
                      color: kAdmGreen),
                  AdmStatCard(
                      title: 'Pending',
                      value: _stats['pending']?.toString() ?? '0',
                      icon: Icons.pending_rounded,
                      color: kStatusPending),
                  AdmStatCard(
                      title: 'Reviewed',
                      value: _stats['reviewed']?.toString() ?? '0',
                      icon: Icons.check_circle_outline_rounded,
                      color: kStatusReviewed),
                  AdmStatCard(
                      title: 'Avg Rating',
                      value: '${_stats['avgRating'] ?? 0} ★',
                      icon: Icons.star_rounded,
                      color: kAdmGold),
                ],
              );
            }),
            const SizedBox(height: 16),

            // Search + filter bar
            AdmGlass(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: LayoutBuilder(builder: (ctx, c) {
                final narrow = c.maxWidth < 550;
                final searchField = AdmSearchBar(
                  hint: 'Search by name or email…',
                  onChanged: (v) =>
                      setState(() => _searchQuery = v.toLowerCase()),
                );
                final chips = AdmFilterChips(
                  options: const ['all', 'pending', 'reviewed', 'resolved'],
                  labels: const {
                    'all': 'All',
                    'pending': 'Pending',
                    'reviewed': 'Reviewed',
                    'resolved': 'Resolved'
                  },
                  selected: _selectedFilter,
                  onSelected: (v) => setState(() => _selectedFilter = v),
                );
                if (narrow) {
                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        searchField,
                        const SizedBox(height: 10),
                        chips
                      ]);
                }
                return Row(children: [
                  Expanded(child: searchField),
                  const SizedBox(width: 14),
                  chips
                ]);
              }),
            ),
            const SizedBox(height: 16),
          ]),
        ),

        // ── List ─────────────────────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<List<UserFeedback>>(
            stream: _selectedFilter == 'all'
                ? _feedbackService.getAllFeedback()
                : _feedbackService.getFeedbackByStatus(_selectedFilter),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const AdmLoading(message: 'Loading feedback…');
              }
              if (snap.hasError) {
                return Center(
                    child: Text('Error: ${snap.error}',
                        style: const TextStyle(color: Colors.red)));
              }

              var list = snap.data ?? [];
              if (_searchQuery.isNotEmpty) {
                list = list
                    .where((f) =>
                        f.name.toLowerCase().contains(_searchQuery) ||
                        f.email.toLowerCase().contains(_searchQuery))
                    .toList();
              }

              if (list.isEmpty) {
                return AdmEmpty(
                  icon: Icons.rate_review_outlined,
                  title: 'No feedback found',
                  body: _searchQuery.isNotEmpty
                      ? 'Try a different search term.'
                      : 'No feedback matches the selected filter.',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                itemCount: list.length,
                itemBuilder: (_, i) => _FeedbackTile(
                  fb: list[i],
                  onView: () => _showDetailsDialog(list[i]),
                  onRespond: () => _showResponseDialog(list[i]),
                  onStatusChange: (status) async {
                    await _feedbackService.updateFeedbackStatus(
                        list[i].id, status);
                    _loadStats();
                  },
                  onDelete: () => _confirmDelete(list[i]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ── Feedback tile ──────────────────────────────────────────────────────────────

class _FeedbackTile extends StatelessWidget {
  final UserFeedback fb;
  final VoidCallback onView;
  final VoidCallback onRespond;
  final ValueChanged<String> onStatusChange;
  final VoidCallback onDelete;

  const _FeedbackTile({
    required this.fb,
    required this.onView,
    required this.onRespond,
    required this.onStatusChange,
    required this.onDelete,
  });

  Color get _color => switch (fb.status) {
        'reviewed' => kStatusReviewed,
        'resolved' => kStatusResolved,
        _ => kStatusPending,
      };

  @override
  Widget build(BuildContext context) {
    return AdmHoverTile(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          _Avatar(name: fb.name, color: _color),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                    child: Text(fb.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            color: kAdmText))),
                _Stars(rating: fb.rating),
                const SizedBox(width: 8),
                AdmStatusChip(label: _statusLabel(fb.status), color: _color),
              ]),
              const SizedBox(height: 3),
              Text(fb.email,
                  style: const TextStyle(fontSize: 12, color: kAdmMuted)),
              const SizedBox(height: 5),
              Text(fb.message,
                  style: const TextStyle(
                      fontSize: 12.5, color: kAdmText, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 5),
              Text(DateFormat('MMM dd, yyyy').format(fb.createdAt),
                  style: const TextStyle(fontSize: 11, color: kAdmMuted)),
            ],
          )),
          const SizedBox(width: 8),
          // Actions
          Row(mainAxisSize: MainAxisSize.min, children: [
            AdmTileBtn(
                icon: Icons.visibility_outlined,
                color: kAdmGreen,
                tooltip: 'View Details',
                onTap: onView),
            AdmTileBtn(
                icon: Icons.reply_rounded,
                color: const Color(0xFF0277BD),
                tooltip: 'Respond',
                onTap: onRespond),
            _AdmMoreBtn(
              onSelected: (v) {
                if (v == 'delete')
                  onDelete();
                else
                  onStatusChange(v);
              },
              itemBuilder: (_) => [
                _menuItem('pending', 'Mark Pending', Icons.pending_rounded,
                    kStatusPending),
                _menuItem('reviewed', 'Mark Reviewed',
                    Icons.check_circle_outline_rounded, kStatusReviewed),
                _menuItem('resolved', 'Mark Resolved', Icons.task_alt_rounded,
                    kStatusResolved),
                const PopupMenuDivider(),
                _menuItem('delete', 'Delete', Icons.delete_outline_rounded,
                    Colors.red),
              ],
            ),
          ]),
        ]),
      ),
    );
  }

  String _statusLabel(String s) => switch (s) {
        'reviewed' => 'REVIEWED',
        'resolved' => 'RESOLVED',
        _ => 'PENDING',
      };

  PopupMenuItem<String> _menuItem(
          String v, String label, IconData icon, Color c) =>
      PopupMenuItem(
        value: v,
        child: Row(children: [
          Icon(icon, size: 15, color: c),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 13, color: v == 'delete' ? Colors.red : kAdmText)),
        ]),
      );
}

// ── Styled "more" popup button matching AdmTileBtn ────────────────────────────

class _AdmMoreBtn extends StatefulWidget {
  final void Function(String) onSelected;
  final List<PopupMenuEntry<String>> Function(BuildContext) itemBuilder;
  const _AdmMoreBtn({required this.onSelected, required this.itemBuilder});

  @override
  State<_AdmMoreBtn> createState() => _AdmMoreBtnState();
}

class _AdmMoreBtnState extends State<_AdmMoreBtn> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: Tooltip(
        message: 'More',
        child: PopupMenuButton<String>(
          onSelected: widget.onSelected,
          itemBuilder: widget.itemBuilder,
          tooltip: '',
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _h
                  ? kAdmMuted.withOpacity(0.85)
                  : kAdmMuted.withOpacity(0.13),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: kAdmMuted.withOpacity(_h ? 0.0 : 0.35),
                width: 1.2,
              ),
            ),
            child: Icon(
              Icons.more_vert_rounded,
              size: 16,
              color: _h ? Colors.white : kAdmMuted,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared micro-widgets ───────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  final Color color;
  final double size;
  const _Avatar({required this.name, required this.color, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration:
          BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
      child: Center(
          child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
            fontSize: size * 0.38, fontWeight: FontWeight.bold, color: color),
      )),
    );
  }
}

class _Stars extends StatelessWidget {
  final int rating;
  const _Stars({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
            5,
            (i) => Icon(
                i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 13,
                color: i < rating ? kAdmGold : Colors.grey[300])));
  }
}

class _MessageBox extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? borderColor;
  const _MessageBox({required this.text, this.color, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color ?? Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor ?? Colors.grey.withOpacity(0.15)),
      ),
      child: Text(text,
          style:
              const TextStyle(fontSize: 13.5, color: kAdmText, height: 1.55)),
    );
  }
}
