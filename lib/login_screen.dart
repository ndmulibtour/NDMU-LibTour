import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/responsive_helper.dart';
// CreateAccountScreen is intentionally NOT imported here.
// Account creation is exclusively accessible from AdminDashboard → Staff Management.

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Task 2 — renamed from _emailController to _usernameController ─────────
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);

    // Task 2 — pass the plain username; auth_service._toEmail() appends
    // '@ndmu.local' before calling signInWithEmailAndPassword.
    final result = await authService.signIn(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (result['success']) {
      final String role = result['role'] ?? '';
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else if (role == 'director') {
        Navigator.pushReplacementNamed(context, '/director');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Unrecognised account role. Contact your administrator.'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  // Task 2 — uses the username field; auth_service.resetPassword() converts
  // it to the hidden email format before calling sendPasswordResetEmail.
  Future<void> _handleForgotPassword() async {
    if (_usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your username first.')),
      );
      return;
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.resetPassword(_usernameController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent. Check your inbox.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      body: isMobile
          ? Center(
              child: SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.all(32),
                  child: _buildLoginCard(authService),
                ),
              ),
            )
          : Center(
              child: Container(
                constraints:
                    const BoxConstraints(maxWidth: 500, maxHeight: 620),
                child: _buildLoginCard(authService),
              ),
            ),
    );
  }

  Widget _buildLoginCard(AuthService authService) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: isMobile
          ? Padding(
              padding: const EdgeInsets.all(32),
              child: _buildFormContent(authService),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: _buildFormContent(authService),
                ),
              ),
            ),
    );
  }

  Widget _buildFormContent(AuthService authService) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Logo ──────────────────────────────────────────────────────────
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/ndmu_logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.school,
                    size: 40, color: Color(0xFF1B5E20)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Title ─────────────────────────────────────────────────────────
          const Text(
            'NDMU Libtour',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Staff Portal',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          // ── Username ─────────────────────────────────────────────────────
          // Task 2 — was "Email" TextFormField with email keyboard and @
          //          validation. Now a plain "Username" field.
          TextFormField(
            controller: _usernameController,
            // Username has no special keyboard type; use plain text.
            keyboardType: TextInputType.text,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Username',
              hintText: 'Enter your username',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              // person icon is more appropriate than email for a username
              prefixIcon: const Icon(Icons.person),
            ),
            validator: (value) {
              // Task 2 — removed @ and . validation; only require non-empty.
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your username';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // ── Password ──────────────────────────────────────────────────────
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleSignIn(),
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // ── Remember Me ───────────────────────────────────────────────────
          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                activeColor: const Color(0xFF1B5E20),
                onChanged: (v) => setState(() => _rememberMe = v ?? false),
              ),
              const Text('Remember me'),
            ],
          ),
          const SizedBox(height: 24),

          // ── Login Button ──────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: authService.isLoading ? null : _handleSignIn,
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
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'LOGIN',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),

          // ── Forgot Password ───────────────────────────────────────────────
          const SizedBox(height: 16),
          TextButton(
            onPressed: _handleForgotPassword,
            child: const Text(
              'Forgot Password?',
              style: TextStyle(
                  color: Color(0xFF1B5E20),
                  decoration: TextDecoration.underline),
            ),
          ),

          const SizedBox(height: 16),

          // ── Copyright ─────────────────────────────────────────────────────
          Text(
            'NDMU Library © 2025',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),

          // NOTE: "Create new account" button has been intentionally removed.
          // Account creation is only available inside the Admin Dashboard
          // under: Staff Management → Create Staff Account.
        ],
      ),
    );
  }
}
