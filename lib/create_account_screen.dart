import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/responsive_helper.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'admin';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateAccount() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);

    final result = await authService.createAccount(
      _emailController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
      _selectedRole,
    );

    if (!mounted) return;

    if (result['success']) {
      String role = result['role'] ?? 'admin';

      // Navigate to appropriate dashboard based on role
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else if (role == 'director') {
        Navigator.pushReplacementNamed(context, '/director');
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Account created successfully!'),
            ],
          ),
          backgroundColor: Color(0xFF1B5E20),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(result['message'] ?? 'An error occurred'),
              ),
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
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      body: isMobile
          ? Center(
              child: SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.all(32),
                  child: _buildCreateAccountCard(authService),
                ),
              ),
            )
          : Center(
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 500,
                  maxHeight: 800,
                ),
                child: _buildCreateAccountCard(authService),
              ),
            ),
    );
  }

  Widget _buildCreateAccountCard(AuthService authService) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
          // Logo
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/images/ndmu_logo.png',
              height: 40,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.school, size: 40, color: Colors.white);
              },
            ),
          ),
          const SizedBox(height: 24),

          // Title
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
            'Create Admin Account',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),

          // Full Name Field
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              hintText: 'Enter your full name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your name';
              }
              if (value.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Email Field
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Confirm Password Field
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              hintText: 'Re-enter your password',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Role Selection
          DropdownButtonFormField<String>(
            value: _selectedRole,
            decoration: InputDecoration(
              labelText: 'Role',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.admin_panel_settings),
            ),
            items: const [
              DropdownMenuItem(
                value: 'admin',
                child: Text('Library Administrator'),
              ),
              DropdownMenuItem(
                value: 'director',
                child: Text('Library Director'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedRole = value ?? 'admin';
              });
            },
          ),
          const SizedBox(height: 24),

          // Create Account Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: authService.isLoading ? null : _handleCreateAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: authService.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'CREATE ACCOUNT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Back to Login
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Already have an account? Login',
              style: TextStyle(
                color: Color(0xFF1B5E20),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'NDMU Library © 2025',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
