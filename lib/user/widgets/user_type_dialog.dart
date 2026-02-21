// lib/user/widgets/user_type_dialog.dart
//
// Shows a non-dismissible two-step dialog on the user's very first visit.
// Step 1 — Internal or External?
// Step 2 — Subcategory (Student/Faculty/Staff or Researcher/Visitor/Other)
//
// After confirming:
//   • Saves choice to window.localStorage
//   • Fires AnalyticsService.logUserClassified() (fire-and-forget)
//   • Dismisses itself — never shown again on this device

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:ndmu_libtour/services/analytics_service.dart';

class UserTypeDialog extends StatefulWidget {
  const UserTypeDialog({super.key});

  // ── Public entry point ─────────────────────────────────────────────────────
  /// Call from MainNavigator.initState() via addPostFrameCallback.
  /// Shows the dialog only if the user hasn't classified themselves yet.
  static void showIfNeeded(BuildContext context) {
    final stored = html.window.localStorage['ndmu_user_type'];
    if (stored != null && stored.isNotEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) => const UserTypeDialog(),
    );
  }

  @override
  State<UserTypeDialog> createState() => _UserTypeDialogState();
}

class _UserTypeDialogState extends State<UserTypeDialog>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  int _step = 1; // 1 = primary choice, 2 = subcategory
  String? _primaryChoice; // 'internal' | 'external'
  String? _subchoice; // selected subcategory

  late AnimationController _anim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── Constants ──────────────────────────────────────────────────────────────
  static const _green = Color(0xFF1B5E20);
  static const _darkGreen = Color(0xFF0D3F0F);
  static const _gold = Color(0xFFFFD700);

  static const _internalSubs = ['Student', 'Faculty', 'Staff'];
  static const _externalSubs = ['Researcher', 'Visitor', 'Other Institution'];

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _goToStep2(String primary) {
    setState(() {
      _primaryChoice = primary;
      _subchoice = null;
    });
    _anim.reset();
    Future.microtask(() {
      setState(() => _step = 2);
      _anim.forward();
    });
  }

  void _confirm() {
    if (_subchoice == null) return;

    // Persist to localStorage
    html.window.localStorage['ndmu_user_type'] = _primaryChoice!;
    html.window.localStorage['ndmu_user_subtype'] = _subchoice!;

    // Fire-and-forget analytics event
    AnalyticsService().logUserClassified(_primaryChoice!, _subchoice!);

    Navigator.of(context).pop();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:
          EdgeInsets.symmetric(horizontal: isMobile ? 20 : 60, vertical: 40),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 560),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 40,
                    offset: const Offset(0, 16))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
                  child: _step == 1 ? _buildStep1() : _buildStep2(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_green, _darkGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Logo + step indicator
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: _gold.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2)
                  ],
                ),
                child: Image.asset(
                  'assets/images/ndmu_logo.png',
                  height: 36,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.school, size: 32, color: _green),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NDMU LibTour',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Text('Notre Dame of Marbel University',
                        style: TextStyle(color: _gold, fontSize: 11)),
                  ],
                ),
              ),
              // Step pill
              _StepPill(current: _step, total: 2),
            ],
          ),
          const SizedBox(height: 20),
          // Title text
          Text(
            _step == 1
                ? 'Welcome! How are you visiting today?'
                : 'One more thing...',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.3),
          ),
          const SizedBox(height: 6),
          Text(
            _step == 1
                ? 'This helps us understand how the library is being used.'
                : 'Please select your role so we can serve you better.',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Step 1 — Internal vs External ─────────────────────────────────────────

  Widget _buildStep1() {
    return Column(
      children: [
        _PrimaryCard(
          icon: Icons.school_rounded,
          title: 'Internal User',
          subtitle: 'I am part of NDMU\n(student, faculty, or staff)',
          color: _green,
          onTap: () => _goToStep2('internal'),
        ),
        const SizedBox(height: 16),
        _PrimaryCard(
          icon: Icons.public_rounded,
          title: 'External User',
          subtitle: 'I am visiting from\noutside NDMU',
          color: const Color(0xFF1565C0), // blue for contrast
          onTap: () => _goToStep2('external'),
        ),
      ],
    );
  }

  // ── Step 2 — Subcategory ───────────────────────────────────────────────────

  Widget _buildStep2() {
    final subs = _primaryChoice == 'internal' ? _internalSubs : _externalSubs;
    final color =
        _primaryChoice == 'internal' ? _green : const Color(0xFF1565C0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Back" link
        GestureDetector(
          onTap: () {
            _anim.reset();
            setState(() {
              _step = 1;
              _subchoice = null;
            });
            _anim.forward();
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_ios_rounded,
                  size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text('Change selection',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Primary choice badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                  _primaryChoice == 'internal'
                      ? Icons.school_rounded
                      : Icons.public_rounded,
                  color: color,
                  size: 16),
              const SizedBox(width: 8),
              Text(
                _primaryChoice == 'internal'
                    ? 'Internal User'
                    : 'External User',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Subcategory chips
        Text('Select your role:',
            style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: subs.map((sub) {
            final selected = _subchoice == sub;
            return GestureDetector(
              onTap: () => setState(() => _subchoice = sub),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? color : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: selected ? color : Colors.grey.shade300,
                      width: selected ? 2 : 1.5),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                              color: color.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 4))
                        ]
                      : [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2))
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selected) ...[
                      Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      sub,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.grey[800],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // Confirm button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _subchoice != null ? _confirm : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              disabledBackgroundColor: Colors.grey[200],
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Continue to LibTour',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 0.3)),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: _subchoice != null ? _gold : Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),
        Center(
          child: Text(
            'Your preference is saved locally and never shared.',
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

// ─── Primary choice card ──────────────────────────────────────────────────────

class _PrimaryCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _PrimaryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_PrimaryCard> createState() => _PrimaryCardState();
}

class _PrimaryCardState extends State<_PrimaryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _hovered ? widget.color.withOpacity(0.06) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered
                  ? widget.color.withOpacity(0.5)
                  : Colors.grey.shade200,
              width: _hovered ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? widget.color.withOpacity(0.12)
                    : Colors.black.withOpacity(0.04),
                blurRadius: _hovered ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.color, widget.color.withOpacity(0.75)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: widget.color.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: widget.color)),
                    const SizedBox(height: 4),
                    Text(widget.subtitle,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            height: 1.4)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: _hovered ? widget.color : Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Step pill indicator ──────────────────────────────────────────────────────

class _StepPill extends StatelessWidget {
  final int current;
  final int total;
  const _StepPill({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(
        'Step $current of $total',
        style: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
