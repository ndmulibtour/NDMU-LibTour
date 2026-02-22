// lib/admin/admin_dashboard.dart
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// NDMU LibTour — Premium Admin Dashboard
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// Architecture:
//   • AdminDashboard        — root widget, responsive layout
//   • _Sidebar              — collapsible animated nav sidebar
//   • _TopBar               — breadcrumb + greeting + avatar
//   • DashboardOverview     — the main home screen
//     ├ _HeroBanner         — time-aware greeting + system pills
//     ├ _KpiGrid            — 6 live gradient cards w/ sparklines
//     ├ _ContentSummaryCard — stat grid (sections, feedback, contacts)
//     ├ _RecentFeedback     — live stream of latest feedback
//     ├ _LiveActivityFeed   — real-time analytics event stream
//     ├ _InboxSummaryCard   — inbox counts per status
//     ├ _QuickActionsGrid   — shortcut tiles to every section
//     └ _SystemStatusBar    — Firestore / maintenance / announcement status

import 'dart:math' as math;
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ndmu_libtour/admin/screens/about_management_screen.dart';
import 'package:ndmu_libtour/admin/screens/analytics_screen.dart';
import 'package:ndmu_libtour/admin/screens/contact_management_screen.dart';
import 'package:ndmu_libtour/admin/screens/feedback_management_screen.dart';
import 'package:ndmu_libtour/admin/screens/policy_management_screen.dart';
import 'package:ndmu_libtour/admin/screens/section_management_screen.dart';
import 'package:ndmu_libtour/admin/screens/settings_page.dart';
import 'package:ndmu_libtour/admin/screens/staff_management_screen.dart';
import 'package:ndmu_libtour/admin/services/analytics_data_service.dart';
import 'package:ndmu_libtour/admin/services/contact_service.dart';
import 'package:ndmu_libtour/admin/services/feedback_service.dart';
import 'package:ndmu_libtour/admin/services/section_service.dart';
import 'package:ndmu_libtour/admin/services/system_settings_service.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'screens/faq_management_screen.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kGreen = Color(0xFF1B5E20);
const _kGreenMid = Color(0xFF2E7D32);
const _kDarkGreen = Color(0xFF0D3F0F);
const _kGold = Color(0xFFFFD700);
const _kGoldDeep = Color(0xFFF9A825);
const _kBg = Color(0xFFF0F4EF);
const _kSurface = Color(0xFFFFFFFF);
const _kText = Color(0xFF1A2E1A);
const _kTextMuted = Color(0xFF6B7E6B);

// Layout
const double _kBreakpoint = 1100.0;
const double _kSidebarFull = 268.0;
const double _kSidebarMini = 70.0;

// ──────────────────────────────────────────────────────────────────────────────
// Nav item descriptor
// ──────────────────────────────────────────────────────────────────────────────
class _NavItem {
  final String title;
  final IconData icon;
  final IconData activeIcon;
  final String? group;
  final Color accent;
  final Widget Function() builder;

  const _NavItem({
    required this.title,
    required this.icon,
    required this.activeIcon,
    required this.builder,
    this.group,
    this.accent = _kGold,
  });
}

// ──────────────────────────────────────────────────────────────────────────────
// AdminDashboard — root
// ──────────────────────────────────────────────────────────────────────────────
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  int _selectedIdx = 0;
  bool _collapsed = false;

  late AnimationController _contentCtrl;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  late AnimationController _sidebarCtrl;
  late Animation<double> _sidebarW;

  // Screen cache — avoids rebuilding completed management screens
  final Map<int, Widget> _cache = {};

  static final List<_NavItem> _nav = [
    _NavItem(
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      builder: () => const DashboardOverview(),
    ),
    // ── Content ──────────────────────────────────────────────────────────────
    _NavItem(
      title: 'About',
      icon: Icons.info_outline_rounded,
      activeIcon: Icons.info_rounded,
      builder: () => const AboutManagementScreen(),
      group: 'Content',
      accent: Color(0xFF00897B),
    ),
    _NavItem(
      title: 'Policies',
      icon: Icons.policy_outlined,
      activeIcon: Icons.policy_rounded,
      builder: () => const PolicyManagementScreen(),
      group: 'Content',
      accent: Color(0xFF0277BD),
    ),
    _NavItem(
      title: 'Sections',
      icon: Icons.library_books_outlined,
      activeIcon: Icons.library_books_rounded,
      builder: () => const SectionManagementScreen(),
      group: 'Content',
      accent: Color(0xFF6A1B9A),
    ),
    _NavItem(
      title: 'FAQs',
      icon: Icons.quiz_outlined,
      activeIcon: Icons.quiz_rounded,
      builder: () => const FAQManagementScreen(),
      group: 'Content',
      accent: Color(0xFF558B2F),
    ),
    // ── Inbox ─────────────────────────────────────────────────────────────────
    _NavItem(
      title: 'Feedback',
      icon: Icons.rate_review_outlined,
      activeIcon: Icons.rate_review_rounded,
      builder: () => const FeedbackManagementScreen(),
      group: 'Inbox',
      accent: Color(0xFFE65100),
    ),
    _NavItem(
      title: 'Contact',
      icon: Icons.mark_email_unread_outlined,
      activeIcon: Icons.mark_email_unread_rounded,
      builder: () => const ContactManagementScreen(),
      group: 'Inbox',
      accent: Color(0xFFAD1457),
    ),
    // ── Insights ──────────────────────────────────────────────────────────────
    _NavItem(
      title: 'Analytics',
      icon: Icons.insights_outlined,
      activeIcon: Icons.insights_rounded,
      builder: () => const AnalyticsDashboardScreen(),
      group: 'Insights',
      accent: _kGold,
    ),
    // ── Admin ─────────────────────────────────────────────────────────────────
    _NavItem(
      title: 'Staff',
      icon: Icons.manage_accounts_outlined,
      activeIcon: Icons.manage_accounts_rounded,
      builder: () => const StaffManagementPage(),
      group: 'Admin',
      accent: Color(0xFF00838F),
    ),
    _NavItem(
      title: 'Settings',
      icon: Icons.tune_outlined,
      activeIcon: Icons.tune_rounded,
      builder: () => const SettingsPage(),
      group: 'Admin',
      accent: Color(0xFF546E7A),
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
            builder: (_, __) {
              final w = _collapsed
                  ? _kSidebarMini +
                      _sidebarCtrl.value * (_kSidebarFull - _kSidebarMini) * 0
                  // reverse: full → mini; forward: mini → full (already driven by _sidebarCtrl)
                  : _kSidebarFull;
              // Actually just use the raw animated double:
              final ww = _sidebarW.value;
              return SizedBox(
                width: ww,
                child: _Sidebar(
                  nav: _nav,
                  selected: _selectedIdx,
                  collapsed: _collapsed,
                  auth: auth,
                  onPick: _pick,
                  onToggle: _toggleSidebar,
                ),
              );
            },
          ),
          Expanded(
            child: Column(children: [
              _TopBar(
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
        child: _Sidebar(
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

// ──────────────────────────────────────────────────────────────────────────────
// Top bar
// ──────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String title;
  final AuthService auth;
  final VoidCallback onMenuTap;
  const _TopBar(
      {required this.title, required this.auth, required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greet = now.hour < 12
        ? 'Good morning'
        : now.hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final name = auth.user?.displayName?.split(' ').first ?? 'Admin';

    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: _kSurface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
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

        const Spacer(),

        // Greeting
        Text('$greet, $name',
            style: const TextStyle(
                fontSize: 13, color: _kTextMuted, fontWeight: FontWeight.w500)),
        const SizedBox(width: 18),

        // Notification icon
        _IconBtn(icon: Icons.notifications_outlined, onTap: () {}),
        const SizedBox(width: 8),

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
          ),
          child:
              const Icon(Icons.person_rounded, size: 18, color: Colors.white),
        ),
      ]),
    );
  }
}

class _IconBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});
  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
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
          duration: const Duration(milliseconds: 140),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _h ? _kGreen.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(widget.icon, size: 19, color: _h ? _kGreen : _kTextMuted),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Sidebar
// ──────────────────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final List<_NavItem> nav;
  final int selected;
  final bool collapsed;
  final AuthService auth;
  final void Function(int) onPick;
  final VoidCallback onToggle;
  const _Sidebar(
      {required this.nav,
      required this.selected,
      required this.collapsed,
      required this.auth,
      required this.onPick,
      required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [_kGreen, _kDarkGreen],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter),
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
        // Logo
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                  color: _kGold.withOpacity(0.5),
                  blurRadius: 10,
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
              Text('Admin Panel',
                  style: TextStyle(
                      color: _kGold,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4)),
            ],
          )),
          // Collapse toggle
          _CollapseBtn(collapsed: collapsed, onTap: onToggle),
        ],
      ]),
    );
  }

  Widget _buildList() {
    final groups = <String?, List<(int, _NavItem)>>{};
    for (var i = 0; i < nav.length; i++) {
      groups.putIfAbsent(nav[i].group, () => []).add((i, nav[i]));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 7),
      children: [
        // Dashboard (no group)
        ...groups[null]!.map((p) => _NavTile(
            item: p.$2,
            idx: p.$1,
            sel: selected == p.$1,
            collapsed: collapsed,
            onTap: () => onPick(p.$1))),
        for (final g in ['Content', 'Inbox', 'Insights', 'Admin'])
          if (groups.containsKey(g)) ...[
            _GroupDivider(label: g, collapsed: collapsed),
            ...groups[g]!.map((p) => _NavTile(
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
    final name = auth.user?.displayName ?? 'Administrator';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'A';

    return Container(
      decoration: BoxDecoration(
          border:
              Border(top: BorderSide(color: Colors.white.withOpacity(0.1)))),
      child: Column(children: [
        if (!collapsed) ...[
          Container(
            margin: const EdgeInsets.fromLTRB(10, 12, 10, 4),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Row(children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [_kGold, _kGoldDeep],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  shape: BoxShape.circle,
                ),
                child: Center(
                    child: Text(initial,
                        style: const TextStyle(
                            color: _kDarkGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 15))),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                  const Text('Library Admin',
                      style: TextStyle(
                          color: _kGold,
                          fontSize: 10,
                          fontWeight: FontWeight.w500)),
                ],
              )),
            ]),
          ),
        ],
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

// ── Sidebar sub-widgets ────────────────────────────────────────────────────────

class _CollapseBtn extends StatefulWidget {
  final bool collapsed;
  final VoidCallback onTap;
  const _CollapseBtn({required this.collapsed, required this.onTap});
  @override
  State<_CollapseBtn> createState() => _CollapseBtnState();
}

class _CollapseBtnState extends State<_CollapseBtn> {
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
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _h
                ? Colors.white.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Icon(
            widget.collapsed
                ? Icons.keyboard_arrow_right_rounded
                : Icons.keyboard_arrow_left_rounded,
            color: Colors.white,
            size: 17,
          ),
        ),
      ),
    );
  }
}

class _GroupDivider extends StatelessWidget {
  final String label;
  final bool collapsed;
  const _GroupDivider({required this.label, required this.collapsed});
  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Divider(color: Colors.white.withOpacity(0.15), height: 1),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 16, 6, 3),
      child: Row(children: [
        Text(label.toUpperCase(),
            style: TextStyle(
                color: Colors.white.withOpacity(0.38),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5)),
        const SizedBox(width: 8),
        Expanded(
            child: Divider(color: Colors.white.withOpacity(0.1), height: 1)),
      ]),
    );
  }
}

class _NavTile extends StatefulWidget {
  final _NavItem item;
  final int idx;
  final bool sel;
  final bool collapsed;
  final VoidCallback onTap;
  const _NavTile(
      {required this.item,
      required this.idx,
      required this.sel,
      required this.collapsed,
      required this.onTap});
  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final sel = widget.sel;
    final accent = widget.item.accent;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: Tooltip(
        message: widget.collapsed ? widget.item.title : '',
        preferBelow: false,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 170),
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: EdgeInsets.symmetric(
                horizontal: widget.collapsed ? 0 : 9, vertical: 9),
            decoration: BoxDecoration(
              color: sel
                  ? Colors.white.withOpacity(0.14)
                  : _h
                      ? Colors.white.withOpacity(0.06)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: sel
                  ? Border.all(color: Colors.white.withOpacity(0.18))
                  : null,
            ),
            child: Row(
              mainAxisAlignment: widget.collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                // Accent bar
                if (!widget.collapsed)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 170),
                    width: 3,
                    height: 18,
                    margin: const EdgeInsets.only(right: 9),
                    decoration: BoxDecoration(
                      color: sel ? accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                // Icon
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: sel
                        ? accent.withOpacity(0.18)
                        : _h
                            ? Colors.white.withOpacity(0.05)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(sel ? widget.item.activeIcon : widget.item.icon,
                      size: 17,
                      color: sel ? accent : Colors.white.withOpacity(0.68)),
                ),
                if (!widget.collapsed) ...[
                  const SizedBox(width: 9),
                  Expanded(
                      child: Text(widget.item.title,
                          style: TextStyle(
                            color: sel
                                ? Colors.white
                                : Colors.white.withOpacity(0.68),
                            fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 13,
                          ))),
                  if (sel)
                    Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: accent, shape: BoxShape.circle)),
                ],
              ],
            ),
          ),
        ),
      ),
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

// ──────────────────────────────────────────────────────────────────────────────
// DashboardOverview — the real home
// ──────────────────────────────────────────────────────────────────────────────
class DashboardOverview extends StatefulWidget {
  const DashboardOverview({super.key});
  @override
  State<DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<DashboardOverview>
    with SingleTickerProviderStateMixin {
  final _analytics = AnalyticsDataService();
  final _feedbackSvc = FeedbackService();
  final _contactSvc = ContactService();
  final _sectionSvc = SectionService();
  final _settingsSvc = SystemSettingsService();

  late AnimationController _stagger;

  Map<String, int> _fbStats = {};
  Map<String, int> _ctStats = {};
  int _sectionCount = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _stagger.forward();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final res = await Future.wait([
      _feedbackSvc.getFeedbackStats(),
      _contactSvc.getContactStats(),
      _sectionSvc.getSections().first,
    ]);
    if (!mounted) return;
    setState(() {
      _fbStats = res[0] as Map<String, int>;
      _ctStats = res[1] as Map<String, int>;
      _sectionCount = (res[2] as List).length;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _stagger.dispose();
    super.dispose();
  }

  // Staggered reveal helper
  Widget _s(int i, Widget child) {
    final s = (i * 0.07).clamp(0.0, 0.7);
    final e = (s + 0.4).clamp(0.0, 1.0);
    return FadeTransition(
      opacity: CurvedAnimation(
          parent: _stagger, curve: Interval(s, e, curve: Curves.easeOut)),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.035), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _stagger,
                curve: Interval(s, e, curve: Curves.easeOut))),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = AnalyticsDataService.dateStr(DateTime.now());
    final sw = MediaQuery.of(context).size.width;

    return Container(
      color: _kBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 36),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── 1. Hero banner ─────────────────────────────────────────────────
          _s(0, _HeroBanner(settingsSvc: _settingsSvc)),
          const SizedBox(height: 26),

          // ── 2. KPI cards — live stream ──────────────────────────────────────
          _s(1,
              _SectionLabel(label: 'Live Overview', icon: Icons.bolt_rounded)),
          const SizedBox(height: 12),
          _s(
              2,
              StreamBuilder<Map<String, dynamic>>(
                stream: _analytics.getDailySummary(today),
                builder: (context, snap) {
                  // Handle errors (like permission-denied)
                  if (snap.hasError) {
                    return _ErrorKpiGrid(error: snap.error.toString());
                  }
                  // Handle loading state
                  if (snap.connectionState == ConnectionState.waiting) {
                    return _LoadingKpiGrid();
                  }
                  // Normal data display
                  return _KpiGrid(data: snap.data ?? {});
                },
              )),
          const SizedBox(height: 28),

          // ── 3. Middle two-column layout ─────────────────────────────────────
          _s(
              3,
              _SectionLabel(
                  label: 'Content & Inbox', icon: Icons.grid_view_rounded)),
          const SizedBox(height: 12),
          _s(
            4,
            sw >= 900
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 3, child: _buildLeft()),
                    const SizedBox(width: 18),
                    Expanded(flex: 2, child: _buildRight()),
                  ])
                : Column(children: [
                    _buildLeft(),
                    const SizedBox(height: 18),
                    _buildRight()
                  ]),
          ),
          const SizedBox(height: 28),

          // ── 4. Quick actions ────────────────────────────────────────────────
          _s(
              5,
              _SectionLabel(
                  label: 'Quick Actions', icon: Icons.flash_on_rounded)),
          const SizedBox(height: 12),
          _s(6, _QuickActionsGrid()),
          const SizedBox(height: 28),

          // ── 5. System status ────────────────────────────────────────────────
          _s(
              7,
              _SectionLabel(
                  label: 'System Status',
                  icon: Icons.health_and_safety_outlined)),
          const SizedBox(height: 12),
          _s(8, _SystemStatusBar(settingsSvc: _settingsSvc)),
        ]),
      ),
    );
  }

  Widget _buildLeft() => Column(children: [
        _ContentSummaryCard(
          sectionCount: _sectionCount,
          fbStats: _fbStats,
          ctStats: _ctStats,
          loaded: _loaded,
        ),
        const SizedBox(height: 18),
        _RecentFeedbackCard(feedbackSvc: _feedbackSvc),
      ]);

  Widget _buildRight() => Column(children: [
        _LiveActivityFeed(analytics: _analytics),
        const SizedBox(height: 18),
        _InboxSummaryCard(
            fbStats: _fbStats, ctStats: _ctStats, loaded: _loaded),
      ]);
}

// ──────────────────────────────────────────────────────────────────────────────
// Hero Banner
// ──────────────────────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final SystemSettingsService settingsSvc;
  const _HeroBanner({required this.settingsSvc});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    final greet = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';
    final emoji = hour < 12
        ? '☀️'
        : hour < 17
            ? '🌤️'
            : '🌙';
    final wdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final date =
        '${wdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kGreen, _kGreenMid, _kDarkGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: _kGreen.withOpacity(0.38),
                  blurRadius: 28,
                  offset: const Offset(0, 10))
            ],
          ),
          child: Stack(children: [
            // Decorative circles
            Positioned(
                right: -24,
                top: -24,
                child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.04)))),
            Positioned(
                right: 70,
                bottom: -36,
                child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _kGold.withOpacity(0.07)))),
            // Gold left bar
            Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_kGold, _kGoldDeep],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter),
                      borderRadius: BorderRadius.circular(2),
                    ))),

            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Row(children: [
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 7),
                      Text(greet,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.78),
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                    ]),
                    const SizedBox(height: 5),
                    const Text('NDMU Library Admin',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.4)),
                    const SizedBox(height: 3),
                    Text(date,
                        style: const TextStyle(
                            color: _kGold,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 16),
                    // Status pills
                    StreamBuilder<SystemSettings>(
                      stream: settingsSvc.watchSettings(),
                      builder: (ctx, snap) {
                        final s = snap.data ?? SystemSettings.defaults();
                        return Wrap(spacing: 8, runSpacing: 6, children: [
                          _HeroPill(
                              icon: Icons.circle,
                              label: 'System Online',
                              color: const Color(0xFF4CAF50)),
                          _HeroPill(
                            icon: s.isMaintenanceMode
                                ? Icons.construction_rounded
                                : Icons.public_rounded,
                            label: s.isMaintenanceMode
                                ? 'Maintenance Mode'
                                : 'Library Open',
                            color: s.isMaintenanceMode
                                ? _kGold
                                : const Color(0xFF4CAF50),
                          ),
                          if (s.hasAnnouncement)
                            _HeroPill(
                                icon: Icons.campaign_rounded,
                                label: 'Announcement Active',
                                color: const Color(0xFF29B6F6)),
                        ]);
                      },
                    ),
                  ],
                )),
                // NDMU logo
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 5))
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.all(9),
                      child: Image.asset('assets/images/ndmu_logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.school_rounded,
                              color: _kGreen,
                              size: 38)),
                    ),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// KPI Grid — 6 gradient cards with sparklines
// ──────────────────────────────────────────────────────────────────────────────
class _KpiGrid extends StatelessWidget {
  final Map<String, dynamic> data;
  const _KpiGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    // Safe integer extractor with proper null handling
    int _i(String k) {
      final value = data[k];
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    final cards = [
      _KD(
          'Total Visits',
          _i('totalVisits').toString(),
          Icons.people_alt_rounded,
          [Color(0xFF1B5E20), Color(0xFF33691E)],
          'Today'),
      _KD(
          'Internal Users',
          _i('internalVisits').toString(),
          Icons.school_rounded,
          [Color(0xFF0D47A1), Color(0xFF1976D2)],
          'Students, Faculty & Staff'),
      _KD(
          'External Users',
          _i('externalVisits').toString(),
          Icons.public_rounded,
          [Color(0xFF4A148C), Color(0xFF7B1FA2)],
          'Visitors & Researchers'),
      _KD('Tour Entries', _i('tourEntries').toString(), Icons.vrpano_rounded,
          [Color(0xFFBF360C), Color(0xFFE64A19)], 'Virtual tour starts'),
      _KD(
          'Page Views',
          _i('totalPageViews').toString(),
          Icons.remove_red_eye_rounded,
          [Color(0xFF006064), Color(0xFF00838F)],
          'Across all screens'),
      _KD(
          'Section Views',
          _i('totalSectionViews').toString(),
          Icons.library_books_rounded,
          [Color(0xFF01579B), Color(0xFF0288D1)],
          'Content engagement'),
    ];

    return LayoutBuilder(builder: (ctx, c) {
      final cols = c.maxWidth >= 900
          ? 6
          : c.maxWidth >= 600
              ? 3
              : 2;
      // On desktop 6-col layout, taller aspect ratio fills space better
      final ratio = c.maxWidth >= 900
          ? 1.35
          : c.maxWidth >= 600
              ? 1.1
              : 1.3;
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: ratio,
        children: cards.map((d) => _KpiCard(d: d)).toList(),
      );
    });
  }
}

class _KD {
  // KPI Data
  final String label, value, sub;
  final IconData icon;
  final List<Color> grad;
  const _KD(this.label, this.value, this.icon, this.grad, this.sub);
}

class _KpiCard extends StatefulWidget {
  final _KD d;
  const _KpiCard({required this.d});
  @override
  State<_KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<_KpiCard> {
  bool _h = false;
  List<double> get _spark {
    final v = int.tryParse(widget.d.value) ?? 0;
    if (v == 0) return List.filled(7, 0.0);
    final r = math.Random(v + widget.d.label.hashCode);
    return List.generate(7, (_) => r.nextDouble() * v.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _h
            ? (Matrix4.identity()..translate(0.0, -4.0))
            : Matrix4.identity(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: widget.d.grad,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.white.withOpacity(_h ? 0.2 : 0.08), width: 1),
                boxShadow: [
                  BoxShadow(
                      color: widget.d.grad[0].withOpacity(_h ? 0.48 : 0.26),
                      blurRadius: _h ? 22 : 10,
                      offset: const Offset(0, 6))
                ],
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(8)),
                      child: Icon(widget.d.icon, size: 15, color: Colors.white),
                    ),
                    const Spacer(),
                    Text(widget.d.value,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            height: 1.1)),
                    const SizedBox(height: 2),
                    Text(widget.d.label,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.88),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(widget.d.sub,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.52),
                            fontSize: 9.5)),
                    const SizedBox(height: 7),
                    SizedBox(
                        height: 22,
                        child: CustomPaint(
                            painter: _Sparkline(data: _spark),
                            size: const Size(double.infinity, 22))),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sparkline ─────────────────────────────────────────────────────────────────
class _Sparkline extends CustomPainter {
  final List<double> data;
  const _Sparkline({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final mx = data.reduce(math.max).clamp(1.0, double.infinity);

    final fill = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height - (data[i] / mx * size.height * 0.82);
      i == 0 ? fill.moveTo(x, y) : fill.lineTo(x, y);
    }
    fill
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(colors: [
            Colors.white.withOpacity(0.28),
            Colors.white.withOpacity(0.0)
          ], begin: Alignment.topCenter, end: Alignment.bottomCenter)
              .createShader(Rect.fromLTWH(0, 0, size.width, size.height)));

    final line = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height - (data[i] / mx * size.height * 0.82);
      i == 0 ? line.moveTo(x, y) : line.lineTo(x, y);
    }
    canvas.drawPath(
        line,
        Paint()
          ..color = Colors.white.withOpacity(0.78)
          ..strokeWidth = 1.4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_Sparkline o) => o.data != data;
}

// ──────────────────────────────────────────────────────────────────────────────
// Glass card wrapper
// ──────────────────────────────────────────────────────────────────────────────
class _Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _Glass({required this.child, this.padding = const EdgeInsets.all(18)});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.93),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: Colors.white.withOpacity(0.82), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.045),
                  blurRadius: 18,
                  offset: const Offset(0, 4))
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Content Summary Card
// ──────────────────────────────────────────────────────────────────────────────
class _ContentSummaryCard extends StatelessWidget {
  final int sectionCount;
  final Map<String, int> fbStats, ctStats;
  final bool loaded;
  const _ContentSummaryCard(
      {required this.sectionCount,
      required this.fbStats,
      required this.ctStats,
      required this.loaded});

  @override
  Widget build(BuildContext context) {
    String _v(int? v) => loaded ? (v ?? 0).toString() : '—';

    final cells = [
      _CS('Sections', _v(sectionCount), Icons.library_books_rounded,
          Color(0xFF6A1B9A)),
      _CS('Total Feedback', _v(fbStats['total']), Icons.rate_review_rounded,
          Color(0xFFE65100)),
      _CS('Pending', _v(fbStats['pending']), Icons.pending_rounded,
          Color(0xFFF9A825)),
      _CS('Avg Rating', loaded ? '${fbStats['avgRating'] ?? 0}★' : '—',
          Icons.star_rounded, Color(0xFFFFD700)),
      _CS('Contact Msgs', _v(ctStats['total']), Icons.contact_mail_rounded,
          Color(0xFFAD1457)),
      _CS('New Messages', _v(ctStats['new']), Icons.mark_email_unread_rounded,
          Color(0xFF1565C0)),
    ];

    return _Glass(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CardHeader(icon: Icons.grid_view_rounded, label: 'Content Summary'),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: cells.map((c) => _CSCell(c: c)).toList(),
        ),
      ]),
    );
  }
}

class _CS {
  final String label, value;
  final IconData icon;
  final Color color;
  const _CS(this.label, this.value, this.icon, this.color);
}

class _CSCell extends StatefulWidget {
  final _CS c;
  const _CSCell({required this.c});
  @override
  State<_CSCell> createState() => _CSCellState();
}

class _CSCellState extends State<_CSCell> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _h
              ? widget.c.color.withOpacity(0.09)
              : Colors.grey.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: _h
                  ? widget.c.color.withOpacity(0.28)
                  : Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.c.icon, size: 16, color: widget.c.color),
              const SizedBox(height: 5),
              Text(widget.c.value,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: widget.c.color)),
              const SizedBox(height: 2),
              Text(widget.c.label,
                  style: const TextStyle(fontSize: 10, color: _kTextMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ]),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Recent Feedback Card — live stream, uses Feedback model fields
// ──────────────────────────────────────────────────────────────────────────────
class _RecentFeedbackCard extends StatelessWidget {
  final FeedbackService feedbackSvc;
  const _RecentFeedbackCard({required this.feedbackSvc});

  @override
  Widget build(BuildContext context) {
    return _Glass(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CardHeader(icon: Icons.rate_review_rounded, label: 'Recent Feedback'),
        const SizedBox(height: 12),
        StreamBuilder<List>(
          stream: feedbackSvc.getAllFeedback(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                      child: CircularProgressIndicator(
                          color: _kGreen, strokeWidth: 2)));
            }
            final items = (snap.data ?? []).take(4).toList();
            if (items.isEmpty)
              return _Empty(
                  label: 'No feedback yet', icon: Icons.rate_review_outlined);
            return Column(
              children: items
                  .asMap()
                  .entries
                  .map((e) => Column(children: [
                        _FbRow(fb: e.value),
                        if (e.key < items.length - 1)
                          Divider(
                              height: 1, color: Colors.grey.withOpacity(0.12)),
                      ]))
                  .toList(),
            );
          },
        ),
      ]),
    );
  }
}

class _FbRow extends StatelessWidget {
  final dynamic fb; // Feedback model
  const _FbRow({required this.fb});

  @override
  Widget build(BuildContext context) {
    final name = (fb.name ?? '') as String;
    final msg = (fb.message ?? '') as String;
    final rating = (fb.rating ?? 0) as int;
    final status = (fb.status ?? 'pending') as String;
    final color = status == 'reviewed'
        ? const Color(0xFF2E7D32)
        : status == 'resolved'
            ? const Color(0xFF0277BD)
            : const Color(0xFFE65100);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Avatar
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              color: _kGreen.withOpacity(0.1), shape: BoxShape.circle),
          child: Center(
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _kGreen))),
        ),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        color: _kText))),
            // Stars
            Row(
                children: List.generate(
                    5,
                    (i) => Icon(
                          i < rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 11,
                          color: i < rating ? _kGold : Colors.grey[300],
                        ))),
          ]),
          const SizedBox(height: 2),
          Text(msg,
              style: const TextStyle(
                  fontSize: 11, color: _kTextMuted, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4)),
            child: Text(status.toUpperCase(),
                style: TextStyle(
                    color: color,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5)),
          ),
        ])),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Live Activity Feed
// ──────────────────────────────────────────────────────────────────────────────
class _LiveActivityFeed extends StatelessWidget {
  final AnalyticsDataService analytics;
  const _LiveActivityFeed({required this.analytics});

  static const _icons = <String, IconData>{
    'page_view': Icons.pageview_rounded,
    'section_view': Icons.library_books_rounded,
    'tour_entry': Icons.vrpano_rounded,
    'tour_scene': Icons.place_rounded,
    'user_classified': Icons.person_rounded,
    'visit': Icons.login_rounded,
  };
  static const _colors = <String, Color>{
    'page_view': Color(0xFF1565C0),
    'section_view': _kGreen,
    'tour_entry': Color(0xFFE65100),
    'tour_scene': Color(0xFF6A1B9A),
    'user_classified': Color(0xFFF9A825),
    'visit': Color(0xFF00838F),
  };

  @override
  Widget build(BuildContext context) {
    return _Glass(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _CardHeader(icon: Icons.rss_feed_rounded, label: 'Live Activity'),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.14),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green.withOpacity(0.28)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _PulseDot(),
              const SizedBox(width: 4),
              const Text('LIVE',
                  style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8)),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        const Divider(height: 1),
        const SizedBox(height: 8),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: analytics.getRecentEvents(limit: 12),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                      child: CircularProgressIndicator(
                          color: _kGreen, strokeWidth: 2)));
            }
            final events = snap.data ?? [];
            if (events.isEmpty)
              return _Empty(
                  label: 'No events yet', icon: Icons.rss_feed_outlined);
            return Column(
                children: events
                    .map(
                        (e) => _EvRow(event: e, icons: _icons, colors: _colors))
                    .toList());
          },
        ),
      ]),
    );
  }
}

class _EvRow extends StatelessWidget {
  final Map<String, dynamic> event;
  final Map<String, IconData> icons;
  final Map<String, Color> colors;
  const _EvRow(
      {required this.event, required this.icons, required this.colors});

  @override
  Widget build(BuildContext context) {
    final type = event['eventType'] as String? ?? 'unknown';
    final icon = icons[type] ?? Icons.circle_rounded;
    final color = colors[type] ?? Colors.grey;
    final ut = event['userType'] as String? ?? 'unknown';

    String label = type.replaceAll('_', ' ');
    if (type == 'section_view')
      label = event['sectionName'] as String? ?? label;
    else if (type == 'tour_scene')
      label = event['sceneName'] as String? ?? label;
    else if (type == 'page_view') label = 'Viewed: ${event['pageName'] ?? ''}';

    String ago = '';
    final ts = event['timestamp'];
    if (ts is Timestamp) {
      final d = DateTime.now().difference(ts.toDate());
      ago = d.inSeconds < 60
          ? '${d.inSeconds}s'
          : d.inMinutes < 60
              ? '${d.inMinutes}m'
              : '${d.inHours}h';
    }

    final (bc, bl) = switch (ut) {
      'internal' => (_kGreen, 'INT'),
      'external' => (const Color(0xFF1565C0), 'EXT'),
      _ => (Colors.grey, '?'),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(children: [
        Container(
            width: 27,
            height: 27,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(7)),
            child: Icon(icon, size: 13, color: color)),
        const SizedBox(width: 8),
        Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w500, color: _kText),
                overflow: TextOverflow.ellipsis)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
              color: bc.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4)),
          child: Text(bl,
              style: TextStyle(
                  color: bc, fontSize: 8.5, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 5),
        Text(ago, style: const TextStyle(fontSize: 10, color: _kTextMuted)),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Inbox Summary
// ──────────────────────────────────────────────────────────────────────────────
class _InboxSummaryCard extends StatelessWidget {
  final Map<String, int> fbStats, ctStats;
  final bool loaded;
  const _InboxSummaryCard(
      {required this.fbStats, required this.ctStats, required this.loaded});

  @override
  Widget build(BuildContext context) {
    String _v(int? v) => loaded ? (v ?? 0).toString() : '—';
    final rows = [
      _IR('Pending Feedback', fbStats['pending'], Icons.rate_review_rounded,
          Color(0xFFE65100)),
      _IR('Reviewed Feedback', fbStats['reviewed'],
          Icons.check_circle_outline_rounded, Color(0xFF2E7D32)),
      _IR('New Contact Messages', ctStats['new'],
          Icons.mark_email_unread_rounded, Color(0xFF1565C0)),
      _IR('Responded Messages', ctStats['responded'], Icons.reply_rounded,
          Color(0xFF6A1B9A)),
    ];

    return _Glass(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CardHeader(icon: Icons.inbox_rounded, label: 'Inbox Summary'),
        const SizedBox(height: 10),
        ...rows.asMap().entries.map((e) => Column(children: [
              if (e.key > 0)
                Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Row(children: [
                  Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                          color: e.value.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child:
                          Icon(e.value.icon, size: 15, color: e.value.color)),
                  const SizedBox(width: 11),
                  Expanded(
                      child: Text(e.value.label,
                          style: const TextStyle(
                              fontSize: 12.5,
                              color: _kText,
                              fontWeight: FontWeight.w500))),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: (e.value.count != null && (e.value.count ?? 0) > 0)
                          ? e.value.color.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(loaded ? (e.value.count ?? 0).toString() : '—',
                        style: TextStyle(
                            color: (e.value.count != null &&
                                    (e.value.count ?? 0) > 0)
                                ? e.value.color
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ),
                ]),
              ),
            ])),
      ]),
    );
  }
}

class _IR {
  final String label;
  final int? count;
  final IconData icon;
  final Color color;
  const _IR(this.label, this.count, this.icon, this.color);
}

// ──────────────────────────────────────────────────────────────────────────────
// Quick Actions Grid
// ──────────────────────────────────────────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    final acts = [
      _QA('Add Section', Icons.add_circle_rounded, const Color(0xFF6A1B9A)),
      _QA('Add FAQ', Icons.quiz_rounded, const Color(0xFF00838F)),
      _QA('Edit Policies', Icons.policy_rounded, const Color(0xFF0277BD)),
      _QA('Update About', Icons.info_rounded, const Color(0xFF00897B)),
      _QA('Analytics', Icons.insights_rounded, _kGoldDeep),
      _QA('Manage Staff', Icons.manage_accounts_rounded,
          const Color(0xFF546E7A)),
    ];

    return LayoutBuilder(builder: (ctx, c) {
      final cols = c.maxWidth >= 900
          ? 6
          : c.maxWidth >= 600
              ? 3
              : 3;
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: c.maxWidth >= 900 ? 1.3 : 1.1,
        children: acts.map((a) => _QATile(a: a)).toList(),
      );
    });
  }
}

class _QA {
  final String label;
  final IconData icon;
  final Color color;
  const _QA(this.label, this.icon, this.color);
}

class _QATile extends StatefulWidget {
  final _QA a;
  const _QATile({required this.a});
  @override
  State<_QATile> createState() => _QATileState();
}

class _QATileState extends State<_QATile> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: () {},
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 170),
              transform: _h
                  ? (Matrix4.identity()..translate(0.0, -3.0))
                  : Matrix4.identity(),
              decoration: BoxDecoration(
                color: _h
                    ? widget.a.color.withOpacity(0.1)
                    : Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _h
                        ? widget.a.color.withOpacity(0.38)
                        : Colors.white.withOpacity(0.82),
                    width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: _h
                          ? widget.a.color.withOpacity(0.22)
                          : Colors.black.withOpacity(0.04),
                      blurRadius: _h ? 16 : 6,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                          color: widget.a.color.withOpacity(0.12),
                          shape: BoxShape.circle),
                      child:
                          Icon(widget.a.icon, color: widget.a.color, size: 19),
                    ),
                    const SizedBox(height: 7),
                    Text(widget.a.label,
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: _h ? widget.a.color : _kText),
                        textAlign: TextAlign.center),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// System Status Bar
// ──────────────────────────────────────────────────────────────────────────────
class _SystemStatusBar extends StatelessWidget {
  final SystemSettingsService settingsSvc;
  const _SystemStatusBar({required this.settingsSvc});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SystemSettings>(
      stream: settingsSvc.watchSettings(),
      builder: (ctx, snap) {
        final s = snap.data ?? SystemSettings.defaults();
        final tiles = [
          _ST('Firestore', 'Connected', Icons.cloud_done_rounded, true),
          _ST('Maintenance Mode', s.isMaintenanceMode ? 'Active' : 'Off',
              Icons.construction_rounded, !s.isMaintenanceMode),
          _ST('Announcement', s.hasAnnouncement ? 'Set' : 'None',
              Icons.campaign_rounded, true),
          _ST('Analytics Service', 'Running', Icons.insights_rounded, true),
        ];

        return LayoutBuilder(builder: (ctx, c) {
          if (c.maxWidth < 600) {
            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.0,
              children: tiles.map((t) => _STile(t: t)).toList(),
            );
          }
          return Row(
            children: tiles
                .expand((t) => [
                      Expanded(child: _STile(t: t)),
                      if (t != tiles.last) const SizedBox(width: 12),
                    ])
                .toList(),
          );
        });
      },
    );
  }
}

class _ST {
  final String label, status;
  final IconData icon;
  final bool ok;
  const _ST(this.label, this.status, this.icon, this.ok);
}

class _STile extends StatelessWidget {
  final _ST t;
  const _STile({required this.t});
  @override
  Widget build(BuildContext context) {
    final color = t.ok ? const Color(0xFF2E7D32) : const Color(0xFFE65100);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ],
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(t.icon, size: 15, color: color),
              const Spacer(),
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 4,
                            spreadRadius: 1)
                      ])),
            ]),
            const SizedBox(height: 9),
            Text(t.status,
                style: TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(t.label,
                style: const TextStyle(fontSize: 10, color: _kTextMuted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ──────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          width: 3,
          height: 17,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [_kGold, _kGoldDeep],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter),
            borderRadius: BorderRadius.circular(2),
          )),
      const SizedBox(width: 9),
      Icon(icon, size: 15, color: _kGreen),
      const SizedBox(width: 5),
      Text(label,
          style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: _kText,
              letterSpacing: -0.2)),
    ]);
  }
}

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _CardHeader({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
            color: _kGreen.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 15, color: _kGreen),
      ),
      const SizedBox(width: 9),
      Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 13.5, color: _kText)),
    ]);
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _HeroPill(
      {required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.35))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 10),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 10.5, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _Empty extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Empty({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(children: [
        Icon(icon, size: 34, color: Colors.grey[300]),
        const SizedBox(height: 8),
        Text(label,
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

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
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                  color: Color.lerp(const Color(0xFF81C784),
                      const Color(0xFF2E7D32), _a.value),
                  shape: BoxShape.circle),
            ));
  }
}

// ── DashboardSection kept for backward compatibility ──────────────────────────
class DashboardSection {
  final String title;
  final IconData icon;
  final Widget widget;
  DashboardSection(
      {required this.title, required this.icon, required this.widget});
}

// ═════════════════════════════════════════════════════════════════════════════
// ERROR & LOADING STATES FOR KPI GRID
// ═════════════════════════════════════════════════════════════════════════════

class _ErrorKpiGrid extends StatelessWidget {
  final String error;
  const _ErrorKpiGrid({required this.error});

  @override
  Widget build(BuildContext context) {
    final isPermissionDenied = error.contains('permission-denied');
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            isPermissionDenied
                ? 'Analytics Permission Denied'
                : 'Failed to Load Analytics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPermissionDenied
                ? 'Please check your Firestore rules for the analytics collection.\nEnsure staff/admin have read access.'
                : error,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.red[600]),
          ),
        ],
      ),
    );
  }
}

class _LoadingKpiGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.6,
      children: List.generate(
        6,
        (i) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[300]!, Colors.grey[200]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Colors.grey[400]),
            ),
          ),
        ),
      ),
    );
  }
}
