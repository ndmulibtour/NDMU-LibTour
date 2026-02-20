// lib/admin/screens/staff_management_screen.dart
//
// Extracted from admin_dashboard.dart (Task 4).
// Changes applied on top of the extracted code:
//   • Task 2 — Email field replaced with Username field.
//              AuthService._toEmail() handles the @ndmu.local conversion.
//   • Task 3 — Password Strength Meter added below the Password field.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ndmu_libtour/services/auth_service.dart';

// ═════════════════════════════════════════════════════════════════════════════
// TASK 3 — Password strength utilities
// ═════════════════════════════════════════════════════════════════════════════

/// Evaluates [password] against five criteria and returns a score 0-5:
///   1. Length >= 8
///   2. Contains uppercase letter
///   3. Contains lowercase letter
///   4. Contains digit
///   5. Contains special character
///
/// Score 0 → nothing typed (meter hidden)
/// Score 1 → Weak    (red)
/// Score 2 → Fair    (orange)
/// Score 3 → Good    (amber)
/// Score 4-5 → Strong (green)
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

Color _scoreColor(int score) {
  switch (score) {
    case 1:
      return Colors.red;
    case 2:
      return Colors.orange;
    case 3:
      return Colors.amber[700]!;
    case 4:
    case 5:
      return Colors.green;
    default:
      return Colors.transparent;
  }
}

String _scoreLabel(int score) {
  switch (score) {
    case 1:
      return 'Weak';
    case 2:
      return 'Fair';
    case 3:
      return 'Good';
    case 4:
    case 5:
      return 'Strong';
    default:
      return '';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Password Strength Meter widget
// ─────────────────────────────────────────────────────────────────────────────

/// Renders a coloured [LinearProgressIndicator] plus a label and five
/// criterion dots that fill as the password meets more requirements.
/// Hidden entirely while [score] == 0 (no input yet).
class _PasswordStrengthMeter extends StatelessWidget {
  final int score;
  const _PasswordStrengthMeter({required this.score});

  @override
  Widget build(BuildContext context) {
    if (score == 0) return const SizedBox.shrink();

    final color = _scoreColor(score);
    final label = _scoreLabel(score);
    final value = (score / 5).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coloured progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 6),
          // Label + five criterion dots
          Row(
            children: [
              Text(
                'Password strength: $label',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _CriterionDot(
                  met: score >= 1, tooltip: '≥8 characters', color: color),
              _CriterionDot(
                  met: score >= 2, tooltip: 'Uppercase', color: color),
              _CriterionDot(
                  met: score >= 3, tooltip: 'Lowercase', color: color),
              _CriterionDot(met: score >= 4, tooltip: 'Number', color: color),
              _CriterionDot(
                  met: score >= 5, tooltip: 'Special char', color: color),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small animated dot representing one password criterion.
class _CriterionDot extends StatelessWidget {
  final bool met;
  final String tooltip;
  final Color color;
  const _CriterionDot({
    required this.met,
    required this.tooltip,
    required this.color,
  });

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
            shape: BoxShape.circle,
            color: met ? color : Colors.grey[300],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// STAFF MANAGEMENT PAGE  (Tasks 2, 3, 4)
// ═════════════════════════════════════════════════════════════════════════════

class StaffManagementPage extends StatefulWidget {
  const StaffManagementPage({super.key});

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  // Task 2 — renamed _emailController → _usernameController
  final _usernameController = TextEditingController();

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'director';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Task 3 — reactive password score that drives the strength meter
  int _pwScore = 0;

  @override
  void initState() {
    super.initState();
    // Recompute strength every time the password field changes
    _passwordController.addListener(() {
      final newScore = evalPasswordScore(_passwordController.text);
      if (newScore != _pwScore) setState(() => _pwScore = newScore);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;
    final authService = Provider.of<AuthService>(context, listen: false);

    // Task 2 — pass plain username; AuthService._toEmail() appends @ndmu.local
    final result = await authService.createAccount(
      _usernameController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
      _selectedRole,
    );

    if (!mounted) return;

    if (result['success']) {
      final createdRole = _selectedRole; // capture before reset
      _formKey.currentState!.reset();
      _nameController.clear();
      _usernameController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      setState(() {
        _selectedRole = 'director';
        _pwScore = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                '${createdRole == 'admin' ? 'Admin' : 'Director'} '
                'account created successfully!',
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1B5E20),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(result['message'] ?? 'An error occurred')),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    return Container(
      color: Colors.grey[100],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page header ───────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.manage_accounts,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Staff Management',
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold)),
                    Text('Create and manage staff accounts',
                        style: TextStyle(fontSize: 14, color: Colors.black54)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Info banner ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Only logged-in administrators can create staff '
                      'accounts. This section is not accessible to the '
                      'public or Directors.',
                      style: TextStyle(fontSize: 13, color: Colors.amber[900]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Form card ─────────────────────────────────────────────────
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Create Staff Account',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),

                        // ── Full Name ────────────────────────────────────
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.badge),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Required';
                            if (v.trim().length < 2)
                              return 'At least 2 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // ── Username (Task 2) ─────────────────────────────
                        // Replaces the old "Email" field.
                        // No email keyboard, no @ validation.
                        TextFormField(
                          controller: _usernameController,
                          keyboardType: TextInputType.text,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            hintText: 'e.g. admin_juan  (no @ or spaces)',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.person_outline),
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
                        const SizedBox(height: 16),

                        // ── Password ─────────────────────────────────────
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (v.length < 6) return 'Minimum 6 characters';
                            return null;
                          },
                        ),

                        // ── Task 3: Password Strength Meter ───────────────
                        // Appears immediately below the Password field.
                        // Updates in real-time via the addListener above.
                        _PasswordStrengthMeter(score: _pwScore),

                        const SizedBox(height: 16),

                        // ── Confirm Password ──────────────────────────────
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(() =>
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (v != _passwordController.text)
                              return 'Passwords do not match';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // ── Role dropdown ─────────────────────────────────
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          decoration: InputDecoration(
                            labelText: 'Assign Role',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.admin_panel_settings),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'director',
                              child: Row(
                                children: [
                                  Icon(Icons.supervisor_account,
                                      size: 18, color: Color(0xFF1B5E20)),
                                  SizedBox(width: 8),
                                  Text('Director'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Row(
                                children: [
                                  Icon(Icons.admin_panel_settings,
                                      size: 18, color: Color(0xFF1B5E20)),
                                  SizedBox(width: 8),
                                  Text('Administrator'),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedRole = v);
                          },
                        ),
                        const SizedBox(height: 32),

                        // ── Submit button ─────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed:
                                authService.isLoading ? null : _handleCreate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B5E20),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: authService.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Text('Create Account',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
