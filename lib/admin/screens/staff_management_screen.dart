// lib/admin/screens/staff_management_screen.dart
//
// Redesigned with NDMU glassmorphism theme using admin_ui_kit.dart
// All password-strength logic, username logic, and AuthService calls preserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ndmu_libtour/services/auth_service.dart';
import '../admin_ui_kit.dart';

// ── Password strength utilities (unchanged from original) ──────────────────────

int evalPasswordScore(String password) {
  if (password.isEmpty) return 0;
  int score = 0;
  if (password.length >= 8) score++;
  if (password.contains(RegExp(r'[A-Z]'))) score++;
  if (password.contains(RegExp(r'[a-z]'))) score++;
  if (password.contains(RegExp(r'[0-9]'))) score++;
  if (password.contains(RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;'/`~]''')))
    score++;
  return score;
}

Color _scoreColor(int s) => switch (s) {
      1 => Colors.red,
      2 => Colors.orange,
      3 => Colors.amber,
      4 || 5 => kAdmGreen,
      _ => Colors.transparent,
    };

String _scoreLabel(int s) => switch (s) {
      1 => 'Weak',
      2 => 'Fair',
      3 => 'Good',
      4 || 5 => 'Strong',
      _ => '',
    };

// ═════════════════════════════════════════════════════════════════════════════
// STAFF MANAGEMENT PAGE
// ═════════════════════════════════════════════════════════════════════════════

class StaffManagementPage extends StatefulWidget {
  const StaffManagementPage({super.key});

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();

  String _selectedRole = 'director';
  bool _obscurePw = true;
  bool _obscureConfirm = true;
  int _pwScore = 0;

  @override
  void initState() {
    super.initState();
    _pwCtrl.addListener(() {
      final s = evalPasswordScore(_pwCtrl.text);
      if (s != _pwScore) setState(() => _pwScore = s);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _pwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthService>(context, listen: false);

    final result = await auth.createAccount(
      _usernameCtrl.text.trim(),
      _pwCtrl.text,
      _nameCtrl.text.trim(),
      _selectedRole,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final role = _selectedRole;
      _formKey.currentState!.reset();
      _nameCtrl.clear();
      _usernameCtrl.clear();
      _pwCtrl.clear();
      _confirmPwCtrl.clear();
      setState(() {
        _selectedRole = 'director';
        _pwScore = 0;
      });
      admSnack(context,
          '${role == 'admin' ? 'Admin' : 'Director'} account created successfully!');
    } else {
      admSnack(context, result['message'] ?? 'An error occurred.',
          success: false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Container(
      color: kAdmBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                AdmPageHeader(
                  title: 'Staff Management',
                  subtitle: 'Create and manage admin and director accounts',
                  icon: Icons.manage_accounts_rounded,
                ),
                const SizedBox(height: 20),

                // Info banner
                AdmGlass(
                  subtle: true,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kAdmGold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.shield_rounded,
                          size: 18, color: kAdmGoldDeep),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(
                      'Only logged-in administrators can create staff accounts. '
                      'This section is not accessible to the public or Directors.',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: kAdmGoldDeep.withOpacity(0.85),
                          height: 1.4),
                    )),
                  ]),
                ),
                const SizedBox(height: 20),

                // Form card
                AdmSectionCard(
                  title: 'Create Staff Account',
                  icon: Icons.person_add_rounded,
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Full name
                            TextFormField(
                              controller: _nameCtrl,
                              style: const TextStyle(
                                  fontSize: 14, color: kAdmText),
                              decoration: admInput(
                                  label: 'Full Name',
                                  hint: 'e.g., Juan Dela Cruz',
                                  prefixIcon: Icons.badge_rounded),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty)
                                  return 'Required';
                                if (v.trim().length < 2)
                                  return 'At least 2 characters';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Username
                            TextFormField(
                              controller: _usernameCtrl,
                              keyboardType: TextInputType.text,
                              autocorrect: false,
                              enableSuggestions: false,
                              style: const TextStyle(
                                  fontSize: 14, color: kAdmText),
                              decoration: admInput(
                                label: 'Username',
                                hint: 'e.g. admin_juan  (no @ or spaces)',
                                prefixIcon: Icons.alternate_email_rounded,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty)
                                  return 'Required';
                                if (v.trim().contains(' '))
                                  return 'Username cannot contain spaces';
                                if (v.trim().contains('@'))
                                  return 'Username must not include @';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Password
                            TextFormField(
                              controller: _pwCtrl,
                              obscureText: _obscurePw,
                              style: const TextStyle(
                                  fontSize: 14, color: kAdmText),
                              decoration: admInput(
                                label: 'Password',
                                prefixIcon: Icons.lock_rounded,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                      _obscurePw
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      size: 18,
                                      color: kAdmMuted),
                                  onPressed: () =>
                                      setState(() => _obscurePw = !_obscurePw),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                if (v.length < 6) return 'Minimum 6 characters';
                                return null;
                              },
                            ),

                            // Password strength meter
                            if (_pwScore > 0) ...[
                              const SizedBox(height: 8),
                              _StrengthMeter(score: _pwScore),
                            ],
                            const SizedBox(height: 14),

                            // Confirm password
                            TextFormField(
                              controller: _confirmPwCtrl,
                              obscureText: _obscureConfirm,
                              style: const TextStyle(
                                  fontSize: 14, color: kAdmText),
                              decoration: admInput(
                                label: 'Confirm Password',
                                prefixIcon: Icons.lock_outline_rounded,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      size: 18,
                                      color: kAdmMuted),
                                  onPressed: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                if (v != _pwCtrl.text)
                                  return 'Passwords do not match';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Role dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedRole,
                              style: const TextStyle(
                                  fontSize: 14, color: kAdmText),
                              decoration: InputDecoration(
                                labelText: 'Assign Role',
                                labelStyle: const TextStyle(
                                    color: kAdmMuted, fontSize: 13.5),
                                prefixIcon: const Icon(
                                    Icons.admin_panel_settings_rounded,
                                    color: kAdmGreen,
                                    size: 18),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.75),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 14),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                        color: kAdmGreen.withOpacity(0.18))),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: kAdmGreen, width: 2)),
                              ),
                              dropdownColor: Colors.white,
                              items: const [
                                DropdownMenuItem(
                                    value: 'director',
                                    child: Row(children: [
                                      Icon(Icons.supervisor_account_rounded,
                                          size: 16, color: kAdmGreen),
                                      SizedBox(width: 8),
                                      Text('Director'),
                                    ])),
                                DropdownMenuItem(
                                    value: 'admin',
                                    child: Row(children: [
                                      Icon(Icons.admin_panel_settings_rounded,
                                          size: 16, color: kAdmGreen),
                                      SizedBox(width: 8),
                                      Text('Administrator'),
                                    ])),
                              ],
                              onChanged: (v) {
                                if (v != null)
                                  setState(() => _selectedRole = v);
                              },
                            ),
                            const SizedBox(height: 24),

                            // Role info chips
                            _RoleInfoCards(selectedRole: _selectedRole),
                            const SizedBox(height: 24),

                            // Submit
                            SizedBox(
                              width: double.infinity,
                              child: AdmPrimaryBtn(
                                label: 'Create Account',
                                icon: Icons.person_add_rounded,
                                loading: auth.isLoading,
                                onPressed: _handleCreate,
                              ),
                            ),
                          ]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Password strength meter ────────────────────────────────────────────────────

class _StrengthMeter extends StatelessWidget {
  final int score;
  const _StrengthMeter({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(score);
    final label = _scoreLabel(score);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: (score / 5).clamp(0.0, 1.0),
          minHeight: 5,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
      const SizedBox(height: 5),
      Row(children: [
        Text('Strength: $label',
            style: TextStyle(
                fontSize: 11.5, color: color, fontWeight: FontWeight.w600)),
        const Spacer(),
        _Dot(met: score >= 1, tooltip: '≥8 chars', color: color),
        _Dot(met: score >= 2, tooltip: 'Uppercase', color: color),
        _Dot(met: score >= 3, tooltip: 'Lowercase', color: color),
        _Dot(met: score >= 4, tooltip: 'Number', color: color),
        _Dot(met: score >= 5, tooltip: 'Special', color: color),
      ]),
    ]);
  }
}

class _Dot extends StatelessWidget {
  final bool met;
  final String tooltip;
  final Color color;
  const _Dot({required this.met, required this.tooltip, required this.color});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: met ? color : Colors.grey[300]),
        ),
      ),
    );
  }
}

// ── Role info cards ────────────────────────────────────────────────────────────

class _RoleInfoCards extends StatelessWidget {
  final String selectedRole;
  const _RoleInfoCards({required this.selectedRole});

  @override
  Widget build(BuildContext context) {
    final isAdmin = selectedRole == 'admin';
    final entries = isAdmin
        ? const [
            ('Full system access', Icons.check_circle_rounded, kAdmGreen),
            (
              'Manage all content & staff',
              Icons.check_circle_rounded,
              kAdmGreen
            ),
            ('View analytics & reports', Icons.check_circle_rounded, kAdmGreen),
          ]
        : const [
            ('Read-only access', Icons.info_rounded, Color(0xFF0277BD)),
            ('View content & feedback', Icons.info_rounded, Color(0xFF0277BD)),
            (
              'Cannot modify or delete content',
              Icons.cancel_rounded,
              Colors.red
            ),
          ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            (isAdmin ? kAdmGreen : const Color(0xFF0277BD)).withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: (isAdmin ? kAdmGreen : const Color(0xFF0277BD))
                .withOpacity(0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(isAdmin ? 'Administrator Permissions' : 'Director Permissions',
            style: const TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.bold, color: kAdmText)),
        const SizedBox(height: 8),
        ...entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                Icon(e.$2, size: 14, color: e.$3),
                const SizedBox(width: 6),
                Text(e.$1,
                    style: const TextStyle(fontSize: 12, color: kAdmMuted)),
              ]),
            )),
      ]),
    );
  }
}
