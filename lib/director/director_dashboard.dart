// lib/director/director_dashboard.dart
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// NDMU LibTour — Director Dashboard  (Read-Only) — Glassmorphism Edition
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// Redesigned with the exact same glassmorphism + NDMU green/gold design tokens
// as admin_ui_kit.dart.  All functionality is preserved; only the presentation
// layer has been upgraded.
//
// Architecture (unchanged):
//   • DirectorDashboard        — root widget, responsive layout
//   • _DirSidebar              — collapsible animated nav sidebar
//   • _DirTopBar               — breadcrumb + greeting + read-only badge
//   • DirectorOverviewScreen   — live KPIs, inbox summary, recent activity
//   • DirectorFeedbackScreen   — view + filter feedback (read-only)
//   • DirectorContactScreen    — view + filter contacts (read-only)
//   • DirectorAnalyticsScreen  — full analytics mirroring admin analytics
//
// Read-only enforcement is unchanged:
//   • No write buttons are rendered
//   • Firestore rules block writes; UI simply doesn't offer them
//   • Persistent "Read-Only Access" badge on every screen

import 'dart:math' as math;
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../admin/models/contact_model.dart';
import '../admin/models/feedback_model.dart' as fb;
import '../admin/models/section_model.dart';
import '../admin/services/analytics_data_service.dart';
import '../admin/services/contact_service.dart';
import '../admin/services/feedback_service.dart';
import '../admin/services/section_service.dart';
import '../admin/services/system_settings_service.dart';

// ── Type alias ────────────────────────────────────────────────────────────────
typedef _UserFeedback = fb.Feedback;

// ── Design tokens (mirrors admin_ui_kit.dart exactly) ─────────────────────────
const _kGreen = Color(0xFF1B5E20);
const _kGreenMid = Color(0xFF2E7D32);
const _kDarkGreen = Color(0xFF0D3F0F);
const _kGold = Color(0xFFFFD700);
const _kGoldDeep = Color(0xFFF9A825);
const _kBg = Color(0xFFF0F4EF);
const _kText = Color(0xFF1A2E1A);
const _kMuted = Color(0xFF6B7E6B);
const _kOrange = Color(0xFFE65100);
const _kPink = Color(0xFFAD1457);

// Status palette
const _kStatusPending = Color(0xFFE65100);
const _kStatusReviewed = Color(0xFF2E7D32);
const _kStatusResolved = Color(0xFF0277BD);
const _kStatusNew = Color(0xFFE65100);
const _kStatusRead = Color(0xFF6A1B9A);
const _kStatusResponded = Color(0xFF2E7D32);

// Layout
const double _kBreakpoint = 1100.0;
const double _kSidebarFull = 268.0;
const double _kSidebarMini = 70.0;

// ══════════════════════════════════════════════════════════════════════════════
// Nav item descriptor
// ══════════════════════════════════════════════════════════════════════════════
class _DirNavItem {
  final String title;
  final IconData icon;
  final IconData activeIcon;
  final String? group;
  final Color accent;
  final Widget Function() builder;

  const _DirNavItem({
    required this.title,
    required this.icon,
    required this.activeIcon,
    required this.builder,
    this.group,
    this.accent = _kGold,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// DirectorDashboard — root
// ══════════════════════════════════════════════════════════════════════════════
class DirectorDashboard extends StatefulWidget {
  const DirectorDashboard({super.key});
  @override
  State<DirectorDashboard> createState() => _DirectorDashboardState();
}

class _DirectorDashboardState extends State<DirectorDashboard>
    with TickerProviderStateMixin {
  int _selectedIdx = 0;
  bool _collapsed = false;

  late AnimationController _contentCtrl;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;
  late AnimationController _sidebarCtrl;
  late Animation<double> _sidebarW;

  final Map<int, Widget> _cache = {};

  static final List<_DirNavItem> _nav = [
    _DirNavItem(
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      builder: () => const DirectorOverviewScreen(),
    ),
    _DirNavItem(
      title: 'Feedback',
      icon: Icons.rate_review_outlined,
      activeIcon: Icons.rate_review_rounded,
      builder: () => const DirectorFeedbackScreen(),
      group: 'Inbox',
      accent: _kOrange,
    ),
    _DirNavItem(
      title: 'Contact',
      icon: Icons.mark_email_unread_outlined,
      activeIcon: Icons.mark_email_unread_rounded,
      builder: () => const DirectorContactScreen(),
      group: 'Inbox',
      accent: _kPink,
    ),
    _DirNavItem(
      title: 'Analytics',
      icon: Icons.insights_outlined,
      activeIcon: Icons.insights_rounded,
      builder: () => const DirectorAnalyticsScreen(),
      group: 'Insights',
      accent: _kGold,
    ),
  ];

  Widget _screen(int i) => _cache.putIfAbsent(i, () => _nav[i].builder());

  @override
  void initState() {
    super.initState();
    _contentCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _contentFade = CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
    _contentSlide = Tween<Offset>(
            begin: const Offset(0.015, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut));

    _sidebarCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 240));
    _sidebarW = Tween<double>(begin: _kSidebarFull, end: _kSidebarMini).animate(
        CurvedAnimation(parent: _sidebarCtrl, curve: Curves.easeInOut));

    _contentCtrl.forward();
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    _sidebarCtrl.dispose();
    super.dispose();
  }

  void _pick(int i) {
    if (_selectedIdx == i) return;
    _contentCtrl.reset();
    setState(() => _selectedIdx = i);
    _contentCtrl.forward();
  }

  void _toggleSidebar() {
    setState(() => _collapsed = !_collapsed);
    _collapsed ? _sidebarCtrl.forward() : _sidebarCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final wide = MediaQuery.of(context).size.width >= _kBreakpoint;

    final body = FadeTransition(
      opacity: _contentFade,
      child: SlideTransition(
          position: _contentSlide, child: _screen(_selectedIdx)),
    );

    if (wide) {
      return Scaffold(
        backgroundColor: _kBg,
        body: Row(children: [
          AnimatedBuilder(
            animation: _sidebarW,
            builder: (_, __) => SizedBox(
              width: _sidebarW.value,
              child: _DirSidebar(
                nav: _nav,
                selected: _selectedIdx,
                collapsed: _collapsed,
                auth: auth,
                onPick: _pick,
                onToggle: _toggleSidebar,
              ),
            ),
          ),
          Expanded(
            child: Column(children: [
              _DirTopBar(
                title: _nav[_selectedIdx].title,
                auth: auth,
                onMenuTap: _toggleSidebar,
              ),
              Expanded(child: body),
            ]),
          ),
        ]),
      );
    }

    // Mobile layout
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kGreen,
        elevation: 0,
        leading: Builder(
            builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Colors.white),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                )),
        title: Text(_nav[_selectedIdx].title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [_kGreen, _kDarkGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            border: Border(bottom: BorderSide(color: _kGold, width: 2)),
          ),
        ),
      ),
      drawer: Drawer(
        child: _DirSidebar(
          nav: _nav,
          selected: _selectedIdx,
          collapsed: false,
          auth: auth,
          onPick: (i) {
            _pick(i);
            Navigator.pop(context);
          },
          onToggle: () {},
        ),
      ),
      body: body,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Top Bar — glassmorphism card
// ══════════════════════════════════════════════════════════════════════════════
class _DirTopBar extends StatelessWidget {
  final String title;
  final AuthService auth;
  final VoidCallback onMenuTap;

  const _DirTopBar(
      {required this.title, required this.auth, required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greet = now.hour < 12
        ? 'Good morning'
        : now.hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final name = auth.user?.displayName?.split(' ').first ?? 'Director';

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            border: Border(
              bottom: BorderSide(color: _kGreen.withOpacity(0.12), width: 1.5),
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(children: [
            // Gold accent bar + title
            Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_kGold, _kGoldDeep],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter),
                  borderRadius: BorderRadius.circular(2),
                )),
            const SizedBox(width: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold, color: _kText)),
            const SizedBox(width: 12),
            // Read-only badge
            _GlassBadge(
              icon: Icons.visibility_rounded,
              label: 'Read-Only',
              color: _kOrange,
            ),
            const Spacer(),
            Text('$greet, $name',
                style: const TextStyle(
                    fontSize: 13, color: _kMuted, fontWeight: FontWeight.w500)),
            const SizedBox(width: 16),
            // Avatar
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_kGreen, _kGreenMid],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                shape: BoxShape.circle,
                border: Border.all(color: _kGold, width: 2),
                boxShadow: [
                  BoxShadow(
                      color: _kGreen.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: const Icon(Icons.person_rounded,
                  size: 18, color: Colors.white),
            ),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Sidebar
// ══════════════════════════════════════════════════════════════════════════════
class _DirSidebar extends StatelessWidget {
  final List<_DirNavItem> nav;
  final int selected;
  final bool collapsed;
  final AuthService auth;
  final void Function(int) onPick;
  final VoidCallback onToggle;

  const _DirSidebar({
    required this.nav,
    required this.selected,
    required this.collapsed,
    required this.auth,
    required this.onPick,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [_kGreen, _kDarkGreen],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 20,
              offset: const Offset(4, 0))
        ],
      ),
      child: Column(children: [
        _buildHeader(),
        Expanded(child: _buildList()),
        _buildFooter(context),
      ]),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 20, 12, 16),
      decoration: BoxDecoration(
          border:
              Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1)))),
      child: Row(children: [
        // Logo box with gold glow
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                  color: _kGold.withOpacity(0.55),
                  blurRadius: 12,
                  spreadRadius: 1)
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Image.asset('assets/images/ndmu_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.school_rounded,
                      color: _kGreen, size: 24)),
            ),
          ),
        ),
        if (!collapsed) ...[
          const SizedBox(width: 11),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('NDMU LibTour',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      letterSpacing: 0.2)),
              Container(
                margin: const EdgeInsets.only(top: 3),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _kGold.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _kGold.withOpacity(0.4)),
                ),
                child: const Text('Director Panel',
                    style: TextStyle(
                        color: _kGold,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6)),
              ),
            ],
          )),
          _CollapseBtn(collapsed: collapsed, onTap: onToggle),
        ],
      ]),
    );
  }

  Widget _buildList() {
    final groups = <String?, List<(int, _DirNavItem)>>{};
    for (var i = 0; i < nav.length; i++) {
      groups.putIfAbsent(nav[i].group, () => []).add((i, nav[i]));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      children: [
        ...groups[null]!.map((p) => _DirNavTile(
            item: p.$2,
            idx: p.$1,
            sel: selected == p.$1,
            collapsed: collapsed,
            onTap: () => onPick(p.$1))),
        for (final g in ['Inbox', 'Insights'])
          if (groups.containsKey(g)) ...[
            _GroupDivider(label: g, collapsed: collapsed),
            ...groups[g]!.map((p) => _DirNavTile(
                item: p.$2,
                idx: p.$1,
                sel: selected == p.$1,
                collapsed: collapsed,
                onTap: () => onPick(p.$1))),
          ],
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    final name = auth.user?.displayName ?? 'Director';
    final email = auth.user?.email ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'D';

    return Container(
      padding: EdgeInsets.fromLTRB(collapsed ? 12 : 14, 12, 12, 20),
      decoration: BoxDecoration(
          border:
              Border(top: BorderSide(color: Colors.white.withOpacity(0.1)))),
      child: collapsed
          ? Center(
              child: _LogoutBtn(
                  collapsed: collapsed,
                  onTap: () async {
                    await auth.signOut();
                    if (context.mounted)
                      Navigator.pushReplacementNamed(context, '/');
                  }),
            )
          : Column(children: [
              // User info card
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Row(children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _kGold.withOpacity(0.25),
                    child: Text(initial,
                        style: const TextStyle(
                            color: _kGold,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                      Text(email,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 10.5),
                          overflow: TextOverflow.ellipsis),
                    ],
                  )),
                ]),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 18),
                child: _LogoutBtn(
                    collapsed: collapsed,
                    onTap: () async {
                      await auth.signOut();
                      if (context.mounted)
                        Navigator.pushReplacementNamed(context, '/');
                    }),
              ),
            ]),
    );
  }
}

class _LogoutBtn extends StatefulWidget {
  final bool collapsed;
  final VoidCallback onTap;
  const _LogoutBtn({required this.collapsed, required this.onTap});
  @override
  State<_LogoutBtn> createState() => _LogoutBtnState();
}

class _LogoutBtnState extends State<_LogoutBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
              horizontal: widget.collapsed ? 0 : 11, vertical: 10),
          decoration: BoxDecoration(
            color: _h
                ? Colors.red.withOpacity(0.14)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: _h
                    ? Colors.red.withOpacity(0.28)
                    : Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            mainAxisAlignment: widget.collapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(Icons.logout_rounded,
                  size: 17,
                  color: _h
                      ? Colors.red.shade300
                      : Colors.white.withOpacity(0.55)),
              if (!widget.collapsed) ...[
                const SizedBox(width: 9),
                Text('Sign Out',
                    style: TextStyle(
                        color: _h
                            ? Colors.red.shade300
                            : Colors.white.withOpacity(0.55),
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Nav tile ──────────────────────────────────────────────────────────────────
class _DirNavTile extends StatefulWidget {
  final _DirNavItem item;
  final int idx;
  final bool sel;
  final bool collapsed;
  final VoidCallback onTap;
  const _DirNavTile({
    required this.item,
    required this.idx,
    required this.sel,
    required this.collapsed,
    required this.onTap,
  });
  @override
  State<_DirNavTile> createState() => _DirNavTileState();
}

class _DirNavTileState extends State<_DirNavTile> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) {
    final sel = widget.sel;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: EdgeInsets.symmetric(
              horizontal: widget.collapsed ? 14 : 12, vertical: 10),
          decoration: BoxDecoration(
            color: sel
                ? Colors.white.withOpacity(0.16)
                : _hov
                    ? Colors.white.withOpacity(0.08)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color:
                    sel ? Colors.white.withOpacity(0.22) : Colors.transparent),
          ),
          child: Row(children: [
            if (sel)
              Container(
                  width: 3,
                  height: 18,
                  margin: const EdgeInsets.only(right: 9),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.item.accent,
                        widget.item.accent.withOpacity(0.6)
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ))
            else
              const SizedBox(width: 12),
            Icon(sel ? widget.item.activeIcon : widget.item.icon,
                size: 19, color: sel ? widget.item.accent : Colors.white70),
            if (!widget.collapsed) ...[
              const SizedBox(width: 12),
              Expanded(
                  child: Text(widget.item.title,
                      style: TextStyle(
                          color: sel ? Colors.white : Colors.white70,
                          fontSize: 13.5,
                          fontWeight:
                              sel ? FontWeight.w600 : FontWeight.normal),
                      overflow: TextOverflow.ellipsis)),
            ],
          ]),
        ),
      ),
    );
  }
}

// ── Group divider ─────────────────────────────────────────────────────────────
class _GroupDivider extends StatelessWidget {
  final String label;
  final bool collapsed;
  const _GroupDivider({required this.label, required this.collapsed});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(collapsed ? 8 : 12, 14, 8, 4),
      child: collapsed
          ? Divider(color: Colors.white.withOpacity(0.15), height: 1)
          : Row(children: [
              Expanded(
                  child: Divider(
                      color: Colors.white.withOpacity(0.15), height: 1)),
              const SizedBox(width: 8),
              Text(label.toUpperCase(),
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.38),
                      fontSize: 9.5,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Expanded(
                  child: Divider(
                      color: Colors.white.withOpacity(0.15), height: 1)),
            ]),
    );
  }
}

// ── Collapse button ───────────────────────────────────────────────────────────
class _CollapseBtn extends StatelessWidget {
  final bool collapsed;
  final VoidCallback onTap;
  const _CollapseBtn({required this.collapsed, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Icon(
            collapsed
                ? Icons.chevron_right_rounded
                : Icons.chevron_left_rounded,
            size: 16,
            color: Colors.white70),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 1. DIRECTOR OVERVIEW SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class DirectorOverviewScreen extends StatefulWidget {
  const DirectorOverviewScreen({super.key});
  @override
  State<DirectorOverviewScreen> createState() => _DirectorOverviewScreenState();
}

class _DirectorOverviewScreenState extends State<DirectorOverviewScreen> {
  final _analytics = AnalyticsDataService();
  final _feedbackSvc = FeedbackService();
  final _contactSvc = ContactService();
  final _settingsSvc = SystemSettingsService();

  bool _loading = true;
  Map<String, int> _todayTotals = {};
  Map<String, int> _feedbackStats = {};
  Map<String, int> _contactStats = {};
  SystemSettings _settings = SystemSettings.defaults();
  List<Map<String, dynamic>> _recentEvents = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final today = DateTime.now();
      final from = DateTime(today.year, today.month, today.day);
      final results = await Future.wait([
        _analytics.getRangeTotals(from, today),
        _feedbackSvc.getFeedbackStats(),
        _contactSvc.getContactStats(),
        _settingsSvc.fetchSettings(),
        _analytics.getRecentEvents(limit: 8).first,
      ]);
      if (!mounted) return;
      setState(() {
        _todayTotals = results[0] as Map<String, int>;
        _feedbackStats = results[1] as Map<String, int>;
        _contactStats = results[2] as Map<String, int>;
        _settings = results[3] as SystemSettings;
        _recentEvents = results[4] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      debugPrint('DirectorOverview load error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: _kGreen))
          : RefreshIndicator(
              onRefresh: _load,
              color: _kGreen,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroBanner(),
                    const SizedBox(height: 24),
                    _DirSectionLabel(
                        label: "Today's Snapshot", icon: Icons.today_rounded),
                    const SizedBox(height: 12),
                    _buildKpiGrid(),
                    const SizedBox(height: 24),
                    _DirSectionLabel(
                        label: 'Inbox Summary', icon: Icons.inbox_rounded),
                    const SizedBox(height: 12),
                    _buildInboxRow(),
                    const SizedBox(height: 24),
                    _DirSectionLabel(
                        label: 'System Status',
                        icon: Icons.monitor_heart_rounded),
                    const SizedBox(height: 12),
                    _buildSystemStatus(),
                    const SizedBox(height: 24),
                    _DirSectionLabel(
                        label: 'Live Activity', icon: Icons.bolt_rounded),
                    const SizedBox(height: 12),
                    _buildLiveActivity(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeroBanner() {
    final now = DateTime.now();
    final greet = now.hour < 12
        ? 'Good Morning'
        : now.hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [_kGreen, _kDarkGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: _kGreen.withOpacity(0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 8))
            ],
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$greet, Director 👋',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  const Text('NDMU Library Overview',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.4)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    _GlassBadge(
                        icon: Icons.visibility_rounded,
                        label: 'Read-Only Access',
                        color: _kOrange),
                    _GlassBadge(
                        icon: Icons.calendar_today_rounded,
                        label:
                            DateFormat('MMMM d, yyyy').format(DateTime.now()),
                        color: _kGold),
                  ]),
                ],
              ),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: _kGold.withOpacity(0.8), width: 2.5),
                boxShadow: [
                  BoxShadow(
                      color: _kGold.withOpacity(0.2),
                      blurRadius: 16,
                      spreadRadius: 2)
                ],
              ),
              child: const Icon(Icons.local_library_rounded,
                  color: _kGold, size: 36),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildKpiGrid() {
    final cards = [
      _KpiData("Total Visits", '${_todayTotals['totalVisits'] ?? 0}',
          Icons.people_rounded, [_kGreen, _kGreenMid]),
      _KpiData("Page Views", '${_todayTotals['totalPageViews'] ?? 0}',
          Icons.pageview_rounded, [Color(0xFF1565C0), Color(0xFF1E88E5)]),
      _KpiData("Tour Entries", '${_todayTotals['tourEntries'] ?? 0}',
          Icons.vrpano_rounded, [_kOrange, Color(0xFFF57C00)]),
      _KpiData("Internal Visitors", '${_todayTotals['internalVisits'] ?? 0}',
          Icons.domain_rounded, [Color(0xFF6A1B9A), Color(0xFF8E24AA)]),
      _KpiData("External Visitors", '${_todayTotals['externalVisits'] ?? 0}',
          Icons.public_rounded, [Color(0xFF00695C), Color(0xFF00897B)]),
      _KpiData("Scene Navigations", '${_todayTotals['tourSceneChanges'] ?? 0}',
          Icons.place_rounded, [_kPink, Color(0xFFD81B60)]),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 900
          ? 3
          : constraints.maxWidth > 600
              ? 2
              : 1;
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: cols,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.7,
        children: cards.map((d) => _KpiCard(data: d)).toList(),
      );
    });
  }

  Widget _buildInboxRow() {
    return Row(children: [
      Expanded(
          child: _InboxCard(
        label: 'Feedback',
        icon: Icons.rate_review_rounded,
        total: _feedbackStats['total'] ?? 0,
        pending: _feedbackStats['pending'] ?? 0,
        pendingLabel: 'Pending',
        color: _kOrange,
      )),
      const SizedBox(width: 14),
      Expanded(
          child: _InboxCard(
        label: 'Contact Messages',
        icon: Icons.mark_email_unread_rounded,
        total: _contactStats['total'] ?? 0,
        pending: _contactStats['new'] ?? 0,
        pendingLabel: 'New',
        color: _kPink,
      )),
    ]);
  }

  Widget _buildSystemStatus() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statusRow('Firestore Connection', 'Connected',
              Icons.cloud_done_rounded, Colors.green),
          const _GlassDivider(),
          _statusRow(
              'Maintenance Mode',
              _settings.isMaintenanceMode ? 'ACTIVE' : 'Off',
              _settings.isMaintenanceMode
                  ? Icons.construction_rounded
                  : Icons.check_circle_rounded,
              _settings.isMaintenanceMode ? Colors.orange : Colors.green),
          const _GlassDivider(),
          _statusRow(
              'Global Announcement',
              _settings.hasAnnouncement
                  ? '"${_settings.globalAnnouncement.length > 40 ? '${_settings.globalAnnouncement.substring(0, 40)}…' : _settings.globalAnnouncement}"'
                  : 'None',
              _settings.hasAnnouncement
                  ? Icons.campaign_rounded
                  : Icons.campaign_outlined,
              _settings.hasAnnouncement ? _kGold : _kMuted),
        ],
      ),
    );
  }

  Widget _statusRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: _kMuted))),
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  Widget _buildLiveActivity() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _PulseDot(),
            const SizedBox(width: 8),
            const Text('Live Events',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13, color: _kText)),
            const Spacer(),
            _GhostButton(
              label: 'Refresh',
              icon: Icons.refresh_rounded,
              onTap: _load,
            ),
          ]),
          const SizedBox(height: 14),
          if (_recentEvents.isEmpty)
            const _DirEmpty(
                label: 'No recent activity', icon: Icons.timeline_rounded)
          else
            ..._recentEvents.map((e) => _EventTile(event: e)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 2. DIRECTOR FEEDBACK SCREEN (read-only)
// ══════════════════════════════════════════════════════════════════════════════
class DirectorFeedbackScreen extends StatefulWidget {
  const DirectorFeedbackScreen({super.key});
  @override
  State<DirectorFeedbackScreen> createState() => _DirectorFeedbackScreenState();
}

class _DirectorFeedbackScreenState extends State<DirectorFeedbackScreen> {
  final FeedbackService _svc = FeedbackService();
  String _filter = 'all';
  String _searchQuery = '';
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final s = await _svc.getFeedbackStats();
    if (mounted) setState(() => _stats = s);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      child: Column(children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatCards(),
                const SizedBox(height: 24),
                _DirSectionLabel(
                    label: 'Submissions', icon: Icons.rate_review_rounded),
                const SizedBox(height: 12),
                _buildFeedbackList(),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeader() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 18, 28, 18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            border:
                Border(bottom: BorderSide(color: _kGreen.withOpacity(0.12))),
          ),
          child: Row(children: [
            // Icon box
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [_kOrange, _kOrange.withOpacity(0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: _kOrange.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: const Icon(Icons.rate_review_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Feedback',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _kText)),
              Text('${_stats['total'] ?? 0} total submissions',
                  style: const TextStyle(fontSize: 12.5, color: _kMuted)),
            ]),
            const Spacer(),
            // Search field
            SizedBox(
              width: 220,
              height: 38,
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(fontSize: 13, color: _kText),
                decoration: InputDecoration(
                  hintText: 'Search feedback…',
                  hintStyle:
                      TextStyle(fontSize: 13, color: _kMuted.withOpacity(0.6)),
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 17, color: _kGreen),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.75),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _kGreen.withOpacity(0.18))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _kGreen, width: 2)),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Filter chips
            Wrap(spacing: 6, children: [
              _DirChip(
                  label: 'All',
                  value: 'all',
                  current: _filter,
                  onTap: (v) => setState(() => _filter = v)),
              _DirChip(
                  label: 'Pending',
                  value: 'pending',
                  current: _filter,
                  onTap: (v) => setState(() => _filter = v)),
              _DirChip(
                  label: 'Reviewed',
                  value: 'reviewed',
                  current: _filter,
                  onTap: (v) => setState(() => _filter = v)),
              _DirChip(
                  label: 'Resolved',
                  value: 'resolved',
                  current: _filter,
                  onTap: (v) => setState(() => _filter = v)),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    return Wrap(spacing: 14, runSpacing: 14, children: [
      _SmallStatCard(
          label: 'Total',
          value: '${_stats['total'] ?? 0}',
          icon: Icons.rate_review_rounded,
          color: _kGreen),
      _SmallStatCard(
          label: 'Pending',
          value: '${_stats['pending'] ?? 0}',
          icon: Icons.hourglass_empty_rounded,
          color: Colors.orange),
      _SmallStatCard(
          label: 'Reviewed',
          value: '${_stats['reviewed'] ?? 0}',
          icon: Icons.check_circle_rounded,
          color: Colors.blue),
      _SmallStatCard(
          label: 'Resolved',
          value: '${_stats['resolved'] ?? 0}',
          icon: Icons.done_all_rounded,
          color: Colors.green),
      _SmallStatCard(
          label: 'Avg Rating',
          value: '${_stats['avgRating'] ?? 0}⭐',
          icon: Icons.star_rounded,
          color: _kGold),
    ]);
  }

  Widget _buildFeedbackList() {
    Stream<List<_UserFeedback>> stream = _filter == 'all'
        ? _svc.getAllFeedback()
        : _svc.getFeedbackByStatus(_filter);

    return StreamBuilder<List<_UserFeedback>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _kGreen));
        }
        var items = snap.data ?? [];
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          items = items
              .where((f) =>
                  f.name.toLowerCase().contains(q) ||
                  f.email.toLowerCase().contains(q) ||
                  f.message.toLowerCase().contains(q))
              .toList();
        }
        if (items.isEmpty) {
          return const _DirEmpty(
              label: 'No feedback found', icon: Icons.feedback_outlined);
        }
        return _GlassCard(
          padding: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: _kGreen.withOpacity(0.08)),
            itemBuilder: (context, i) => _FeedbackTile(
              feedback: items[i],
              onTap: () => _showDetails(items[i]),
            ),
          ),
        );
      },
    );
  }

  void _showDetails(_UserFeedback fb) {
    showDialog(
        context: context, builder: (_) => _FeedbackDetailDialog(feedback: fb));
  }
}

// ── Feedback tile ─────────────────────────────────────────────────────────────
class _FeedbackTile extends StatefulWidget {
  final _UserFeedback feedback;
  final VoidCallback onTap;
  const _FeedbackTile({required this.feedback, required this.onTap});
  @override
  State<_FeedbackTile> createState() => _FeedbackTileState();
}

class _FeedbackTileState extends State<_FeedbackTile> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        color: _hov ? _kGreen.withOpacity(0.03) : Colors.transparent,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: _kGreen.withOpacity(0.1),
            child: Text(
                widget.feedback.name.isNotEmpty
                    ? widget.feedback.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: _kGreen, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          title: Row(children: [
            Expanded(
                child: Text(widget.feedback.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: _kText))),
            _ratingStars(widget.feedback.rating),
            const SizedBox(width: 8),
            _StatusChip(status: widget.feedback.status),
          ]),
          subtitle:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 4),
            Text(widget.feedback.email,
                style: const TextStyle(fontSize: 12, color: _kMuted)),
            const SizedBox(height: 6),
            Text(widget.feedback.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 13, color: _kText, height: 1.4)),
            const SizedBox(height: 6),
            Text(
                DateFormat('MMM d, yyyy • h:mm a')
                    .format(widget.feedback.createdAt),
                style: const TextStyle(fontSize: 11, color: _kMuted)),
          ]),
          trailing: Tooltip(
            message: 'View Details',
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kGreen.withOpacity(0.25)),
                ),
                child: const Icon(Icons.visibility_rounded,
                    color: _kGreen, size: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ratingStars(int rating) {
    return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
            5,
            (i) => Icon(
                i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                color: Colors.amber,
                size: 14)));
  }
}

// ── Feedback detail dialog ─────────────────────────────────────────────────────
class _FeedbackDetailDialog extends StatelessWidget {
  final _UserFeedback feedback;
  const _FeedbackDetailDialog({required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: 560,
            constraints: const BoxConstraints(maxHeight: 640),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: Colors.white.withOpacity(0.80), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 32,
                    offset: const Offset(0, 8))
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: _kGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.rate_review_rounded,
                          color: _kGreen, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                        child: Text('Feedback Details',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _kText))),
                    IconButton(
                        icon: const Icon(Icons.close_rounded, color: _kMuted),
                        onPressed: () => Navigator.pop(context)),
                  ]),
                  const SizedBox(height: 8),
                  const _ReadOnlyBadge(),
                  const SizedBox(height: 16),
                  Divider(color: _kGreen.withOpacity(0.12)),
                  const SizedBox(height: 14),
                  _InfoRow(label: 'Name', value: feedback.name),
                  _InfoRow(label: 'Email', value: feedback.email),
                  _InfoRow(
                      label: 'Date',
                      value: DateFormat('MMMM d, yyyy • h:mm a')
                          .format(feedback.createdAt)),
                  _InfoRow(label: 'Rating', value: '${feedback.rating}/5 ⭐'),
                  _InfoRow(
                      label: 'Status', value: feedback.status.toUpperCase()),
                  const SizedBox(height: 14),
                  _DirSectionLabel(
                      label: 'Message', icon: Icons.message_rounded),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: _kBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _kGreen.withOpacity(0.12))),
                    child: Text(feedback.message,
                        style: const TextStyle(
                            height: 1.6, fontSize: 14, color: _kText)),
                  ),
                  if (feedback.adminResponse != null &&
                      feedback.adminResponse!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _DirSectionLabel(
                        label: 'Admin Response', icon: Icons.reply_rounded),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: _kGreen.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _kGreen.withOpacity(0.2))),
                      child: Text(feedback.adminResponse!,
                          style: const TextStyle(
                              height: 1.6, fontSize: 14, color: _kText)),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 3. DIRECTOR CONTACT SCREEN (read-only)
// ══════════════════════════════════════════════════════════════════════════════
class DirectorContactScreen extends StatefulWidget {
  const DirectorContactScreen({super.key});
  @override
  State<DirectorContactScreen> createState() => _DirectorContactScreenState();
}

class _DirectorContactScreenState extends State<DirectorContactScreen> {
  final ContactService _svc = ContactService();
  String _filter = 'all';
  String _searchQuery = '';
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final s = await _svc.getContactStats();
    if (mounted) setState(() => _stats = s);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      child: Column(children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatCards(),
                const SizedBox(height: 24),
                _DirSectionLabel(label: 'Messages', icon: Icons.mail_rounded),
                const SizedBox(height: 12),
                _buildContactList(),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeader() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 18, 28, 18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            border:
                Border(bottom: BorderSide(color: _kGreen.withOpacity(0.12))),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [_kPink, _kPink.withOpacity(0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: _kPink.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: const Icon(Icons.mark_email_unread_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Contact Messages',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _kText)),
              Text('${_stats['total'] ?? 0} total messages',
                  style: const TextStyle(fontSize: 12.5, color: _kMuted)),
            ]),
            const Spacer(),
            SizedBox(
              width: 220,
              height: 38,
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(fontSize: 13, color: _kText),
                decoration: InputDecoration(
                  hintText: 'Search messages…',
                  hintStyle:
                      TextStyle(fontSize: 13, color: _kMuted.withOpacity(0.6)),
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 17, color: _kGreen),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.75),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _kGreen.withOpacity(0.18))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _kGreen, width: 2)),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Wrap(spacing: 6, children: [
              _DirChip(
                  label: 'All',
                  value: 'all',
                  current: _filter,
                  onTap: (v) => setState(() => _filter = v)),
              _DirChip(
                  label: 'New',
                  value: 'new',
                  current: _filter,
                  onTap: (v) => setState(() => _filter = v)),
              _DirChip(
                  label: 'Read',
                  value: 'read',
                  current: _filter,
                  onTap: (v) => setState(() => _filter = v)),
              _DirChip(
                  label: 'Responded',
                  value: 'responded',
                  current: _filter,
                  onTap: (v) => setState(() => _filter = v)),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    return Wrap(spacing: 14, runSpacing: 14, children: [
      _SmallStatCard(
          label: 'Total',
          value: '${_stats['total'] ?? 0}',
          icon: Icons.mail_rounded,
          color: _kGreen),
      _SmallStatCard(
          label: 'New',
          value: '${_stats['new'] ?? 0}',
          icon: Icons.mark_email_unread_rounded,
          color: Colors.orange),
      _SmallStatCard(
          label: 'Read',
          value: '${_stats['read'] ?? 0}',
          icon: Icons.drafts_rounded,
          color: Colors.purple),
      _SmallStatCard(
          label: 'Responded',
          value: '${_stats['responded'] ?? 0}',
          icon: Icons.mark_email_read_rounded,
          color: Colors.green),
    ]);
  }

  Widget _buildContactList() {
    Stream<List<ContactMessage>> stream = _filter == 'all'
        ? _svc.getAllContactMessages()
        : _svc.getContactMessagesByStatus(_filter);

    return StreamBuilder<List<ContactMessage>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _kGreen));
        }
        var items = snap.data ?? [];
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          items = items
              .where((c) =>
                  c.name.toLowerCase().contains(q) ||
                  c.email.toLowerCase().contains(q) ||
                  c.message.toLowerCase().contains(q))
              .toList();
        }
        if (items.isEmpty) {
          return const _DirEmpty(
              label: 'No messages found', icon: Icons.mail_outline_rounded);
        }
        return _GlassCard(
          padding: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: _kGreen.withOpacity(0.08)),
            itemBuilder: (context, i) => _ContactTile(
              contact: items[i],
              onTap: () => showDialog(
                  context: context,
                  builder: (_) => _ContactDetailDialog(contact: items[i])),
            ),
          ),
        );
      },
    );
  }
}

// ── Contact tile ──────────────────────────────────────────────────────────────
class _ContactTile extends StatefulWidget {
  final ContactMessage contact;
  final VoidCallback onTap;
  const _ContactTile({required this.contact, required this.onTap});
  @override
  State<_ContactTile> createState() => _ContactTileState();
}

class _ContactTileState extends State<_ContactTile> {
  bool _hov = false;

  Color get _statusColor {
    return switch (widget.contact.status) {
      'responded' => _kStatusResponded,
      'read' => _kStatusRead,
      'new' => _kStatusNew,
      _ => _kMuted,
    };
  }

  String get _statusLabel => widget.contact.status.toUpperCase();

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        color: _hov ? _kPink.withOpacity(0.025) : Colors.transparent,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: _kPink.withOpacity(0.1),
            child: Text(
                widget.contact.name.isNotEmpty
                    ? widget.contact.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: _kPink, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          title: Row(children: [
            Expanded(
                child: Text(widget.contact.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: _kText))),
            _StatusChip(status: widget.contact.status),
          ]),
          subtitle:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 4),
            Text('${widget.contact.email} • ${widget.contact.phoneNumber}',
                style: const TextStyle(fontSize: 12, color: _kMuted)),
            const SizedBox(height: 6),
            Text(widget.contact.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 13, color: _kText, height: 1.4)),
            const SizedBox(height: 6),
            Text(
                DateFormat('MMM d, yyyy • h:mm a')
                    .format(widget.contact.createdAt),
                style: const TextStyle(fontSize: 11, color: _kMuted)),
          ]),
          trailing: Tooltip(
            message: 'View Details',
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kGreen.withOpacity(0.25)),
                ),
                child: const Icon(Icons.visibility_rounded,
                    color: _kGreen, size: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Contact detail dialog ─────────────────────────────────────────────────────
class _ContactDetailDialog extends StatelessWidget {
  final ContactMessage contact;
  const _ContactDetailDialog({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: 560,
            constraints: const BoxConstraints(maxHeight: 640),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: Colors.white.withOpacity(0.80), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 32,
                    offset: const Offset(0, 8))
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: _kPink.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.mark_email_unread_rounded,
                          color: _kPink, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                        child: Text('Contact Details',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _kText))),
                    IconButton(
                        icon: const Icon(Icons.close_rounded, color: _kMuted),
                        onPressed: () => Navigator.pop(context)),
                  ]),
                  const SizedBox(height: 8),
                  const _ReadOnlyBadge(),
                  const SizedBox(height: 16),
                  Divider(color: _kGreen.withOpacity(0.12)),
                  const SizedBox(height: 14),
                  _InfoRow(label: 'Name', value: contact.name),
                  _InfoRow(label: 'Email', value: contact.email),
                  _InfoRow(label: 'Phone', value: contact.phoneNumber),
                  _InfoRow(
                      label: 'Date',
                      value: DateFormat('MMMM d, yyyy • h:mm a')
                          .format(contact.createdAt)),
                  _InfoRow(
                      label: 'Status', value: contact.status.toUpperCase()),
                  const SizedBox(height: 14),
                  _DirSectionLabel(
                      label: 'Message', icon: Icons.message_rounded),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: _kBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _kGreen.withOpacity(0.12))),
                    child: Text(contact.message,
                        style: const TextStyle(
                            height: 1.6, fontSize: 14, color: _kText)),
                  ),
                  if (contact.adminResponse != null &&
                      contact.adminResponse!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _DirSectionLabel(
                        label: 'Admin Response', icon: Icons.reply_rounded),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: _kGreen.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _kGreen.withOpacity(0.2))),
                      child: Text(contact.adminResponse!,
                          style: const TextStyle(
                              height: 1.6, fontSize: 14, color: _kText)),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 4. DIRECTOR ANALYTICS SCREEN (full read)
// ══════════════════════════════════════════════════════════════════════════════
class DirectorAnalyticsScreen extends StatefulWidget {
  const DirectorAnalyticsScreen({super.key});
  @override
  State<DirectorAnalyticsScreen> createState() =>
      _DirectorAnalyticsScreenState();
}

class _DirectorAnalyticsScreenState extends State<DirectorAnalyticsScreen> {
  final AnalyticsDataService _svc = AnalyticsDataService();
  final SectionService _sectionSvc = SectionService();

  _DateRange _range = _DateRange.today;
  DateTime _customFrom = DateTime.now().subtract(const Duration(days: 7));
  DateTime _customTo = DateTime.now();

  bool _loading = true;
  Map<String, int> _totals = {};
  List<Map<String, dynamic>> _dailyData = [];
  Map<int, int> _hourly = {};
  Map<String, int> _sectionCounts = {};
  Map<String, int> _userSubtypes = {};
  Map<String, int> _sceneCounts = {};
  List<LibrarySection> _sections = [];

  @override
  void initState() {
    super.initState();
    _load();
    _sectionSvc.getSections().first.then((s) {
      if (mounted) setState(() => _sections = s);
    });
  }

  DateTime get _from {
    final now = DateTime.now();
    return switch (_range) {
      _DateRange.today => DateTime(now.year, now.month, now.day),
      _DateRange.week => now.subtract(Duration(days: now.weekday - 1)),
      _DateRange.month => DateTime(now.year, now.month, 1),
      _DateRange.custom => _customFrom,
    };
  }

  DateTime get _to => _range == _DateRange.custom ? _customTo : DateTime.now();

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _svc.getRangeTotals(_from, _to),
        _svc.getDateRangeSummary(_from, _to),
        _svc.getHourlyDistribution(_from, _to),
        _svc.getSectionViewCounts(_from, _to),
        _svc.getUserTypeBreakdown(_from, _to),
        _svc.getTourSceneCounts(_from, _to),
      ]);
      if (!mounted) return;
      setState(() {
        _totals = results[0] as Map<String, int>;
        _dailyData = results[1] as List<Map<String, dynamic>>;
        _hourly = results[2] as Map<int, int>;
        _sectionCounts = results[3] as Map<String, int>;
        _userSubtypes = results[4] as Map<String, int>;
        _sceneCounts = results[5] as Map<String, int>;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      child: Column(children: [
        _buildTopBar(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _kGreen))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildKpiRow(),
                      const SizedBox(height: 24),
                      _DirSectionLabel(
                          label: 'Visitor Trends',
                          icon: Icons.trending_up_rounded),
                      const SizedBox(height: 12),
                      _responsiveRow([_buildLineChart(), _buildHourlyBar()]),
                      const SizedBox(height: 24),
                      _DirSectionLabel(
                          label: 'Content Engagement',
                          icon: Icons.library_books_rounded),
                      const SizedBox(height: 12),
                      _responsiveRow([_buildSectionTable(), _buildUserDonut()]),
                      const SizedBox(height: 24),
                      _DirSectionLabel(
                          label: 'Virtual Tour & Live Activity',
                          icon: Icons.vrpano_rounded),
                      const SizedBox(height: 12),
                      _responsiveRow([_buildTourHeatmap(), _buildLiveFeed()]),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      ]),
    );
  }

  Widget _buildTopBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 18, 28, 18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            border:
                Border(bottom: BorderSide(color: _kGreen.withOpacity(0.12))),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_kGold, _kGoldDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: _kGold.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: const Icon(Icons.insights_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Analytics & Reports',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _kText)),
              Text('${_fmtDate(_from)} → ${_fmtDate(_to)}',
                  style: const TextStyle(fontSize: 12.5, color: _kMuted)),
            ]),
            const Spacer(),
            // Date range chips
            Wrap(
                spacing: 6,
                children: _DateRange.values.map((r) {
                  final sel = _range == r;
                  return GestureDetector(
                    onTap: () async {
                      if (r == _DateRange.custom) {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2024),
                          lastDate: DateTime.now(),
                          initialDateRange:
                              DateTimeRange(start: _customFrom, end: _customTo),
                          builder: (ctx, child) => Theme(
                            data: Theme.of(ctx).copyWith(
                              colorScheme: const ColorScheme.light(
                                  primary: _kGreen, secondary: _kGold),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked == null) return;
                        _customFrom = picked.start;
                        _customTo = picked.end;
                      }
                      setState(() => _range = r);
                      _load();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? _kGreen : Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: sel ? _kGreen : _kGreen.withOpacity(0.2)),
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                    color: _kGreen.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2))
                              ]
                            : [],
                      ),
                      child: Text(r.label,
                          style: TextStyle(
                              color: sel ? Colors.white : _kMuted,
                              fontSize: 12.5,
                              fontWeight:
                                  sel ? FontWeight.w600 : FontWeight.normal)),
                    ),
                  );
                }).toList()),
            const SizedBox(width: 12),
            // Refresh btn
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildKpiRow() {
    final kpis = [
      _KpiData('Total Visits', '${_totals['totalVisits'] ?? 0}',
          Icons.people_rounded, [_kGreen, _kGreenMid]),
      _KpiData('Page Views', '${_totals['totalPageViews'] ?? 0}',
          Icons.pageview_rounded, [Color(0xFF1565C0), Color(0xFF1E88E5)]),
      _KpiData('Tour Entries', '${_totals['tourEntries'] ?? 0}',
          Icons.vrpano_rounded, [_kOrange, Color(0xFFF57C00)]),
      _KpiData('Internal Visitors', '${_totals['internalVisits'] ?? 0}',
          Icons.domain_rounded, [Color(0xFF6A1B9A), Color(0xFF8E24AA)]),
      _KpiData('External Visitors', '${_totals['externalVisits'] ?? 0}',
          Icons.public_rounded, [Color(0xFF00695C), Color(0xFF00897B)]),
      _KpiData('Scene Changes', '${_totals['tourSceneChanges'] ?? 0}',
          Icons.place_rounded, [_kPink, Color(0xFFD81B60)]),
    ];

    return LayoutBuilder(builder: (ctx, constraints) {
      final cols = constraints.maxWidth > 900
          ? 3
          : constraints.maxWidth > 600
              ? 2
              : 1;
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: cols,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.7,
        children: kpis.map((d) => _KpiCard(data: d)).toList(),
      );
    });
  }

  Widget _buildLineChart() {
    return _AnalyticsCard(
      title: 'Daily Visits',
      icon: Icons.show_chart_rounded,
      child: SizedBox(
        height: 220,
        child: _dailyData.isEmpty
            ? const _DirEmpty(label: 'No data', icon: Icons.show_chart)
            : CustomPaint(
                painter: _LinePainter(data: _dailyData),
                child: const SizedBox.expand()),
      ),
    );
  }

  Widget _buildHourlyBar() {
    return _AnalyticsCard(
      title: 'Peak Hours',
      icon: Icons.bar_chart_rounded,
      child: SizedBox(
        height: 220,
        child: _hourly.isEmpty
            ? const _DirEmpty(label: 'No data', icon: Icons.bar_chart)
            : CustomPaint(
                painter: _BarPainter(data: _hourly),
                child: const SizedBox.expand()),
      ),
    );
  }

  Widget _buildSectionTable() {
    String sectionName(String id) {
      try {
        return _sections.firstWhere((s) => s.id == id).name;
      } catch (_) {
        return id;
      }
    }

    final sorted = _sectionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(8).toList();

    return _AnalyticsCard(
      title: 'Section Popularity',
      icon: Icons.library_books_rounded,
      child: top.isEmpty
          ? const _DirEmpty(label: 'No data', icon: Icons.library_books)
          : Column(
              children: top.asMap().entries.map((e) {
                final max = top.first.value.clamp(1, 999999);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    SizedBox(
                        width: 22,
                        child: Text('${e.key + 1}',
                            style:
                                const TextStyle(fontSize: 11, color: _kMuted))),
                    Expanded(
                        child: Text(sectionName(e.value.key),
                            style: const TextStyle(fontSize: 13, color: _kText),
                            overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 90,
                      child: LinearProgressIndicator(
                        value: e.value.value / max,
                        backgroundColor: _kGreen.withOpacity(0.1),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(_kGreen),
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${e.value.value}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _kGreen)),
                  ]),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildUserDonut() {
    const colors = [
      Color(0xFF1B5E20),
      Color(0xFF1565C0),
      Color(0xFFE65100),
      Color(0xFF6A1B9A),
      Color(0xFF00695C),
      Color(0xFFAD1457),
    ];
    final total = _userSubtypes.values.fold(0, (a, b) => a + b);

    return _AnalyticsCard(
      title: 'Visitor Types',
      icon: Icons.pie_chart_rounded,
      child: _userSubtypes.isEmpty || total == 0
          ? const _DirEmpty(label: 'No visitor data', icon: Icons.pie_chart)
          : Column(children: [
              SizedBox(
                height: 150,
                child: CustomPaint(
                    painter: _DonutPainter(data: _userSubtypes, colors: colors),
                    child: Center(
                        child: Text('$total',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _kText)))),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children:
                    _userSubtypes.entries.toList().asMap().entries.map((e) {
                  final color = colors[e.key % colors.length];
                  final pct = (e.value.value / total * 100).toStringAsFixed(0);
                  return Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 4),
                    Text('${e.value.key} ($pct%)',
                        style: const TextStyle(fontSize: 11, color: _kText)),
                  ]);
                }).toList(),
              ),
            ]),
    );
  }

  Widget _buildTourHeatmap() {
    const sceneNames = {
      '6978265df7083ba3665904a6': 'NDMU Library',
      '697825f6f7083bc155590495': 'Library Entrance',
      '6978296b70f11a7b5a1085f6': 'CSCAM & Archives',
      '697858a270f11a45ea108937': 'Law School Library',
      '697863c0f7083b566c5908c8': 'Graduate School Library',
      '6978668770f11a701b108aaa': 'EMC',
      '6982e78b9da68288a5139bef': 'Filipiniana Section',
      '6982f3539da68242ef139c80': 'Director of Libraries',
      '6982f3539822ba02d869d6d8': 'Technical Section',
      '6982f3769822ba124369d6db': 'Internet Section',
      '6982f9b89822ba2cbf69d736': 'Main Section',
      '698307b16fccac7e5ec6d72d': 'Discussion Room',
    };

    final sorted = _sceneCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = sorted.isNotEmpty ? sorted.first.value.clamp(1, 999999) : 1;

    return _AnalyticsCard(
      title: 'Tour Scene Visits',
      icon: Icons.vrpano_rounded,
      child: sorted.isEmpty
          ? const _DirEmpty(label: 'No tour data', icon: Icons.vrpano)
          : Column(
              children: sorted.map((e) {
                final name = sceneNames[e.key] ?? e.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    const Icon(Icons.place_rounded, size: 14, color: _kMuted),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(name,
                            style: const TextStyle(fontSize: 12, color: _kText),
                            overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: LinearProgressIndicator(
                        value: e.value / maxVal,
                        backgroundColor: _kOrange.withOpacity(0.1),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(_kOrange),
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${e.value}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _kOrange)),
                  ]),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildLiveFeed() {
    return _AnalyticsCard(
      title: 'Live Activity',
      icon: Icons.bolt_rounded,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _svc.getRecentEvents(limit: 12),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _kGreen));
          }
          final events = snap.data ?? [];
          if (events.isEmpty) {
            return const _DirEmpty(
                label: 'No recent events', icon: Icons.timeline);
          }
          return Column(
              children: events.map((e) => _EventTile(event: e)).toList());
        },
      ),
    );
  }

  Widget _responsiveRow(List<Widget> children) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= 900) {
        return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children
                .map((c) => Expanded(child: c))
                .toList()
                .expand((w) => [w, const SizedBox(width: 16)])
                .toList()
              ..removeLast());
      }
      return Column(
          children:
              children.expand((c) => [c, const SizedBox(height: 16)]).toList()
                ..removeLast());
    });
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SHARED DESIGN COMPONENTS
// ══════════════════════════════════════════════════════════════════════════════

// ── Glass card ────────────────────────────────────────────────────────────────
class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double radius;

  const _GlassCard({required this.child, this.padding, this.radius = 16});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.91),
            borderRadius: BorderRadius.circular(radius),
            border:
                Border.all(color: Colors.white.withOpacity(0.80), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.048),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ── Section label (matches AdmSectionLabel) ───────────────────────────────────
class _DirSectionLabel extends StatelessWidget {
  final String label;
  final IconData? icon;
  const _DirSectionLabel({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 3,
        height: 16,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kGold, _kGoldDeep],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      if (icon != null) ...[
        Icon(icon, size: 14, color: _kGreen),
        const SizedBox(width: 5),
      ],
      Text(label,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: _kText,
            letterSpacing: -0.1,
          )),
    ]);
  }
}

// ── Glass badge ───────────────────────────────────────────────────────────────
class _GlassBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _GlassBadge(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 11),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 10.5, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ── Read-only badge ───────────────────────────────────────────────────────────
class _ReadOnlyBadge extends StatelessWidget {
  const _ReadOnlyBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.visibility_rounded, size: 11, color: Colors.orange[700]),
        const SizedBox(width: 5),
        Text('Read-Only — Cannot make changes',
            style: TextStyle(
                color: Colors.orange[700],
                fontSize: 10.5,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ── Status chip ───────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'pending' => (_kStatusPending, 'PENDING'),
      'reviewed' => (_kStatusReviewed, 'REVIEWED'),
      'resolved' => (_kStatusResolved, 'RESOLVED'),
      'new' => (_kStatusNew, 'NEW'),
      'read' => (_kStatusRead, 'READ'),
      'responded' => (_kStatusResponded, 'RESPONDED'),
      _ => (_kMuted, status.toUpperCase()),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

// ── Info row (for detail dialogs) ─────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 82,
            child: Text('$label:',
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    color: _kMuted))),
        Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 12.5, color: _kText))),
      ]),
    );
  }
}

// ── KPI data model + card ────────────────────────────────────────────────────
class _KpiData {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> colors;
  const _KpiData(this.label, this.value, this.icon, this.colors);
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;
  const _KpiCard({required this.data});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: data.colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: data.colors.first.withOpacity(0.32),
              blurRadius: 14,
              offset: const Offset(0, 6))
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(data.icon, color: Colors.white, size: 18),
            ),
            const Spacer(),
          ]),
          const SizedBox(height: 8),
          Text(data.value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          Text(data.label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Inbox summary card ────────────────────────────────────────────────────────
class _InboxCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final int total;
  final int pending;
  final String pendingLabel;
  final Color color;
  const _InboxCard({
    required this.label,
    required this.icon,
    required this.total,
    required this.pending,
    required this.pendingLabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.91),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.22), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.048),
                  blurRadius: 18,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kMuted)),
                  const SizedBox(height: 4),
                  Text('$total',
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _kText)),
                ],
              ),
            ),
            if (pending > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.withOpacity(0.4)),
                ),
                child: Text('$pending $pendingLabel',
                    style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
          ]),
        ),
      ),
    );
  }
}

// ── Small stat card ───────────────────────────────────────────────────────────
class _SmallStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SmallStatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: 180,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.91),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 10),
              Text(value,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _kText)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 12, color: _kMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────
class _DirChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final void Function(String) onTap;
  const _DirChip(
      {required this.label,
      required this.value,
      required this.current,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sel = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? _kGreen : Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? _kGreen : _kGreen.withOpacity(0.2)),
          boxShadow: sel
              ? [
                  BoxShadow(
                      color: _kGreen.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Text(label,
            style: TextStyle(
                color: sel ? Colors.white : _kMuted,
                fontSize: 12,
                fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}

// ── Analytics card wrapper ────────────────────────────────────────────────────
class _AnalyticsCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget child;
  const _AnalyticsCard({required this.title, this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                    color: _kGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 14, color: _kGreen),
              ),
              const SizedBox(width: 8),
            ],
            Text(title,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: _kText)),
          ]),
          const SizedBox(height: 14),
          Divider(height: 1, color: _kGreen.withOpacity(0.08)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ── Ghost button (text + icon) ────────────────────────────────────────────────
class _GhostButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GhostButton(
      {required this.label, required this.icon, required this.onTap});
  @override
  State<_GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<_GhostButton> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _hov ? _kGreen.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(widget.icon, size: 14, color: _kGreen),
            const SizedBox(width: 5),
            Text(widget.label,
                style: const TextStyle(
                    fontSize: 12, color: _kGreen, fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _DirEmpty extends StatelessWidget {
  final String label;
  final IconData icon;
  const _DirEmpty({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kGreen.withOpacity(0.06),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 32, color: _kGreen.withOpacity(0.3)),
        ),
        const SizedBox(height: 10),
        Text(label,
            style: const TextStyle(color: _kMuted, fontSize: 13),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

// ── Divider for glass cards ───────────────────────────────────────────────────
class _GlassDivider extends StatelessWidget {
  const _GlassDivider();
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: _kGreen.withOpacity(0.08));
}

// ── Pulse dot ────────────────────────────────────────────────────────────────
class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
    _a = Tween<double>(begin: 0.35, end: 1.0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _a,
        builder: (_, __) => Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: Color.lerp(const Color(0xFF81C784),
                      const Color(0xFF2E7D32), _a.value),
                  shape: BoxShape.circle),
            ));
  }
}

// ── Live event tile ───────────────────────────────────────────────────────────
class _EventTile extends StatelessWidget {
  final Map<String, dynamic> event;
  const _EventTile({required this.event});

  static const _icons = {
    'page_view': Icons.pageview_rounded,
    'section_view': Icons.library_books_rounded,
    'tour_entry': Icons.vrpano_rounded,
    'tour_scene': Icons.place_rounded,
    'user_classified': Icons.person_rounded,
    'visit': Icons.login_rounded,
  };
  static const _colors = {
    'page_view': Color(0xFF1565C0),
    'section_view': _kGreen,
    'tour_entry': _kOrange,
    'tour_scene': Color(0xFF7B1FA2),
    'user_classified': _kGold,
    'visit': Color(0xFF00838F),
  };

  @override
  Widget build(BuildContext context) {
    final type = event['eventType'] as String? ?? 'unknown';
    final uType = event['userType'] as String? ?? 'unknown';
    final icon = _icons[type] ?? Icons.circle_rounded;
    final color = _colors[type] ?? Colors.grey;

    String label = type.replaceAll('_', ' ');
    if (type == 'section_view')
      label = event['sectionName'] as String? ?? label;
    else if (type == 'tour_scene')
      label = event['sceneName'] as String? ?? label;
    else if (type == 'page_view') label = 'Viewed: ${event['pageName'] ?? ''}';

    final ts = event['timestamp'];
    String timeAgo = '';
    if (ts is Timestamp) {
      final diff = DateTime.now().difference(ts.toDate());
      if (diff.inSeconds < 60)
        timeAgo = '${diff.inSeconds}s ago';
      else if (diff.inMinutes < 60)
        timeAgo = '${diff.inMinutes}m ago';
      else
        timeAgo = '${diff.inHours}h ago';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: _kText),
                  overflow: TextOverflow.ellipsis),
              Row(children: [
                _UserBadge(userType: uType),
                const SizedBox(width: 6),
                Text(timeAgo,
                    style: const TextStyle(fontSize: 10, color: _kMuted)),
              ]),
            ],
          ),
        ),
      ]),
    );
  }
}

class _UserBadge extends StatelessWidget {
  final String userType;
  const _UserBadge({required this.userType});
  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (userType) {
      'internal' => (const Color(0xFF1B5E20), 'Internal'),
      'external' => (const Color(0xFF1565C0), 'External'),
      _ => (_kMuted, 'Unknown'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}

// ── Date range enum ───────────────────────────────────────────────────────────
enum _DateRange {
  today('Today'),
  week('This Week'),
  month('This Month'),
  custom('Custom');

  final String label;
  const _DateRange(this.label);
}

String _fmtDate(DateTime d) => DateFormat('MMM d, yyyy').format(d);

// ── Custom painters ───────────────────────────────────────────────────────────
class _LinePainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  const _LinePainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final visits =
        data.map((d) => (d['totalVisits'] as int? ?? 0).toDouble()).toList();
    final maxV = visits.reduce(math.max).clamp(1.0, double.infinity);
    final dx = size.width / (visits.length - 1).clamp(1, 9999);
    final dy = (size.height - 20) / maxV;

    final linePaint = Paint()
      ..color = _kGreen
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
              colors: [_kGreen.withOpacity(0.3), _kGreen.withOpacity(0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter)
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    for (var i = 0; i < visits.length; i++) {
      final x = i * dx;
      final y = size.height - 10 - visits[i] * dy;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo((visits.length - 1) * dx, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()
      ..color = _kGreen
      ..style = PaintingStyle.fill;
    for (var i = 0; i < visits.length; i++) {
      canvas.drawCircle(
          Offset(i * dx, size.height - 10 - visits[i] * dy), 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.data != data;
}

class _BarPainter extends CustomPainter {
  final Map<int, int> data;
  const _BarPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxV = data.values.reduce(math.max).clamp(1, 999999).toDouble();
    final barW = size.width / 24 - 2;

    for (var h = 0; h < 24; h++) {
      final val = (data[h] ?? 0).toDouble();
      final barH = val / maxV * (size.height - 20);
      final x = h * (barW + 2);
      final y = size.height - 10 - barH;

      final paint = Paint()
        ..color = h >= 8 && h <= 17
            ? _kGreen.withOpacity(0.75)
            : _kGreen.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, barW, barH), const Radius.circular(3)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.data != data;
}

class _DonutPainter extends CustomPainter {
  final Map<String, int> data;
  final List<Color> colors;
  const _DonutPainter({required this.data, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.values.fold(0, (a, b) => a + b).clamp(1, 999999);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    var start = -math.pi / 2;
    var i = 0;

    for (final entry in data.entries) {
      if (entry.value == 0) {
        i++;
        continue;
      }
      final sweep = entry.value / total * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        Paint()
          ..color = colors[i % colors.length]
          ..strokeWidth = 26
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.butt,
      );
      start += sweep + 0.03;
      i++;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.data != data;
}
