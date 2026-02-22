// lib/admin/screens/contact_management_screen.dart
//
// Redesigned with NDMU glassmorphism theme using admin_ui_kit.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/contact_model.dart';
import '../services/contact_service.dart';
import '../admin_ui_kit.dart';

class ContactManagementScreen extends StatefulWidget {
  const ContactManagementScreen({super.key});

  @override
  State<ContactManagementScreen> createState() =>
      _ContactManagementScreenState();
}

class _ContactManagementScreenState extends State<ContactManagementScreen> {
  final ContactService _contactService = ContactService();
  String _selectedFilter = 'all';
  String _searchQuery = '';
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _contactService.getContactStats();
    if (mounted) setState(() => _stats = stats);
  }

  // ── Status helpers ─────────────────────────────────────────────────────────

  Color _statusColor(String s) => switch (s) {
        'read' => kStatusRead,
        'responded' => kStatusResponded,
        _ => kStatusNew,
      };

  String _statusLabel(String s) => switch (s) {
        'read' => 'READ',
        'responded' => 'RESPONDED',
        _ => 'NEW',
      };

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _showDetailsDialog(ContactMessage c) {
    showDialog(
      context: context,
      builder: (_) => AdmDialog(
        title: 'Contact Details',
        titleIcon: Icons.mark_email_unread_rounded,
        body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Sender card
          Row(children: [
            _Avatar(name: c.name, color: _statusColor(c.status)),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: kAdmText)),
                const SizedBox(height: 4),
                AdmStatusChip(
                    label: _statusLabel(c.status),
                    color: _statusColor(c.status)),
              ],
            )),
          ]),
          const SizedBox(height: 14),
          AdmInfoRow(
              label: 'Email', value: c.email, icon: Icons.email_outlined),
          AdmInfoRow(
              label: 'Phone', value: c.phoneNumber, icon: Icons.phone_outlined),
          AdmInfoRow(
              label: 'Received',
              value: DateFormat('MMM dd, yyyy  •  hh:mm a').format(c.createdAt),
              icon: Icons.schedule_rounded),
          const Divider(height: 24),
          AdmSectionLabel(
              label: 'Message', icon: Icons.chat_bubble_outline_rounded),
          const SizedBox(height: 10),
          _MessageBox(text: c.message),
          if (c.adminResponse != null) ...[
            const SizedBox(height: 16),
            AdmSectionLabel(label: 'Admin Response', icon: Icons.reply_rounded),
            const SizedBox(height: 10),
            _MessageBox(
                text: c.adminResponse!,
                color: kAdmGreen.withOpacity(0.06),
                borderColor: kAdmGreen.withOpacity(0.2)),
            if (c.respondedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                    'Sent ${DateFormat('MMM dd, yyyy').format(c.respondedAt!)}',
                    style: const TextStyle(fontSize: 11, color: kAdmMuted)),
              ),
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
              _showResponseDialog(c);
            },
          ),
        ],
      ),
    );
  }

  void _showResponseDialog(ContactMessage c) {
    final ctrl = TextEditingController(text: c.adminResponse ?? '');
    bool sending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AdmDialog(
          title: 'Respond to Message',
          titleIcon: Icons.reply_rounded,
          body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                          name: c.name,
                          color: _statusColor(c.status),
                          size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(c.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: kAdmText))),
                    ]),
                    const SizedBox(height: 6),
                    Text('${c.email}  •  ${c.phoneNumber}',
                        style:
                            const TextStyle(fontSize: 11.5, color: kAdmMuted)),
                    const SizedBox(height: 8),
                    Text(c.message,
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
                final ok = await _contactService.respondToContact(c.id, text);
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

  Future<void> _confirmDelete(ContactMessage c) async {
    final ok = await admConfirmDelete(context,
        title: 'Delete Message',
        body: 'Message from ${c.name} will be permanently removed.');
    if (!ok || !mounted) return;
    final success = await _contactService.deleteContactMessage(c.id);
    admSnack(context, success ? 'Message deleted.' : 'Failed to delete.',
        success: success);
    if (success) _loadStats();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kAdmBg,
      child: Column(children: [
        // Header region
        Container(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
          color: kAdmBg,
          child: Column(children: [
            AdmPageHeader(
              title: 'Contact Messages',
              subtitle: 'View and respond to incoming messages',
              icon: Icons.mark_email_unread_rounded,
            ),
            const SizedBox(height: 20),

            // Stats
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
                      icon: Icons.mail_rounded,
                      color: kAdmGreen),
                  AdmStatCard(
                      title: 'New',
                      value: _stats['new']?.toString() ?? '0',
                      icon: Icons.mark_email_unread_rounded,
                      color: kStatusNew),
                  AdmStatCard(
                      title: 'Read',
                      value: _stats['read']?.toString() ?? '0',
                      icon: Icons.drafts_rounded,
                      color: kStatusRead),
                  AdmStatCard(
                      title: 'Responded',
                      value: _stats['responded']?.toString() ?? '0',
                      icon: Icons.reply_rounded,
                      color: kStatusResponded),
                ],
              );
            }),
            const SizedBox(height: 16),

            // Search + filter
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
                  options: const ['all', 'new', 'read', 'responded'],
                  labels: const {
                    'all': 'All',
                    'new': 'New',
                    'read': 'Read',
                    'responded': 'Responded'
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

        // List
        Expanded(
          child: StreamBuilder<List<ContactMessage>>(
            stream: _selectedFilter == 'all'
                ? _contactService.getAllContactMessages()
                : _contactService.getContactMessagesByStatus(_selectedFilter),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const AdmLoading(message: 'Loading messages…');
              }
              if (snap.hasError) {
                final err = snap.error.toString();
                final denied = err.contains('permission-denied') ||
                    err.contains('PERMISSION_DENIED');
                return AdmEmpty(
                  icon: denied
                      ? Icons.lock_outline_rounded
                      : Icons.error_outline_rounded,
                  title: denied ? 'Permission Denied' : 'Failed to Load',
                  body: denied
                      ? 'Add the contact_messages collection to your Firestore Security Rules.'
                      : err,
                );
              }

              var list = snap.data ?? [];
              if (_searchQuery.isNotEmpty) {
                list = list
                    .where((c) =>
                        c.name.toLowerCase().contains(_searchQuery) ||
                        c.email.toLowerCase().contains(_searchQuery))
                    .toList();
              }

              if (list.isEmpty) {
                return AdmEmpty(
                  icon: Icons.mail_outline_rounded,
                  title: 'No messages found',
                  body: 'No messages match the selected filter.',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                itemCount: list.length,
                itemBuilder: (_, i) => _ContactTile(
                  c: list[i],
                  onView: () => _showDetailsDialog(list[i]),
                  onRespond: () => _showResponseDialog(list[i]),
                  onStatusChange: (status) async {
                    await _contactService.updateContactStatus(
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

// ── Contact tile ───────────────────────────────────────────────────────────────

class _ContactTile extends StatelessWidget {
  final ContactMessage c;
  final VoidCallback onView;
  final VoidCallback onRespond;
  final ValueChanged<String> onStatusChange;
  final VoidCallback onDelete;

  const _ContactTile({
    required this.c,
    required this.onView,
    required this.onRespond,
    required this.onStatusChange,
    required this.onDelete,
  });

  Color get _color => switch (c.status) {
        'read' => kStatusRead,
        'responded' => kStatusResponded,
        _ => kStatusNew,
      };

  String get _label => switch (c.status) {
        'read' => 'READ',
        'responded' => 'RESPONDED',
        _ => 'NEW',
      };

  @override
  Widget build(BuildContext context) {
    return AdmHoverTile(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          _Avatar(name: c.name, color: _color),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                    child: Text(c.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            color: kAdmText))),
                AdmStatusChip(label: _label, color: _color),
              ]),
              const SizedBox(height: 3),
              Text('${c.email}  •  ${c.phoneNumber}',
                  style: const TextStyle(fontSize: 12, color: kAdmMuted)),
              const SizedBox(height: 5),
              Text(c.message,
                  style: const TextStyle(
                      fontSize: 12.5, color: kAdmText, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 5),
              Text(DateFormat('MMM dd, yyyy').format(c.createdAt),
                  style: const TextStyle(fontSize: 11, color: kAdmMuted)),
            ],
          )),
          const SizedBox(width: 8),
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
                _mi('new', 'Mark New', Icons.mark_email_unread_rounded,
                    kStatusNew),
                _mi('read', 'Mark Read', Icons.drafts_rounded, kStatusRead),
                _mi('responded', 'Mark Responded', Icons.reply_rounded,
                    kStatusResponded),
                const PopupMenuDivider(),
                _mi('delete', 'Delete', Icons.delete_outline_rounded,
                    Colors.red),
              ],
            ),
          ]),
        ]),
      ),
    );
  }

  PopupMenuItem<String> _mi(String v, String label, IconData icon, Color c) =>
      PopupMenuItem(
          value: v,
          child: Row(children: [
            Icon(icon, size: 15, color: c),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: v == 'delete' ? Colors.red : kAdmText)),
          ]));
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
