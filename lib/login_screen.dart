// lib/login_screen.dart
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// NDMU LibTour — Login Screen  (Professional Glassmorphism Edition)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/responsive_helper.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kGreen = Color(0xFF1B5E20);
const _kGreenMid = Color(0xFF2E7D32);
const _kGreenDeep = Color(0xFF0D3F0F);
const _kGreenDark = Color(0xFF071A08);
const _kGold = Color(0xFFFFD700);
const _kGoldDeep = Color(0xFFF9A825);

// ══════════════════════════════════════════════════════════════════════════════
// LoginScreen
// ══════════════════════════════════════════════════════════════════════════════
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Animations
  late AnimationController _bgCtrl;
  late AnimationController _orb2Ctrl;
  late AnimationController _orb3Ctrl;
  late AnimationController _cardCtrl;
  late AnimationController _shimmerCtrl;

  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();

    _bgCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 14))
          ..repeat(reverse: true);
    _orb2Ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
          ..repeat(reverse: true);
    _orb3Ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 26))
          ..repeat(reverse: true);

    _shimmerCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();

    _cardCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _cardFade = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));

    _cardCtrl.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _bgCtrl.dispose();
    _orb2Ctrl.dispose();
    _orb3Ctrl.dispose();
    _shimmerCtrl.dispose();
    _cardCtrl.dispose();
    super.dispose();
  }

  // ── Auth (unchanged logic) ─────────────────────────────────────────────────

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthService>(context, listen: false);
    final result = await auth.signIn(
      _usernameController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;
    if (result['success']) {
      final role = result['role'] ?? '';
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else if (role == 'director') {
        Navigator.pushReplacementNamed(context, '/director');
      } else {
        _snack('Unrecognised account role. Contact your administrator.',
            isError: true);
      }
    } else {
      _snack(result['message'] ?? 'An error occurred', isError: true);
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_usernameController.text.trim().isEmpty) {
      _snack('Please enter your username first.');
      return;
    }
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      await auth.resetPassword(_usernameController.text.trim());
      if (!mounted) return;
      _snack('Password reset email sent. Check your inbox.', isSuccess: true);
    } catch (e) {
      if (!mounted) return;
      _snack('Error: ${e.toString()}', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false, bool isSuccess = false}) {
    final color = isError
        ? const Color(0xFFB71C1C)
        : isSuccess
            ? _kGreenMid
            : const Color(0xFF37474F);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          isError
              ? Icons.error_outline_rounded
              : isSuccess
                  ? Icons.check_circle_outline_rounded
                  : Icons.info_outline_rounded,
          color: Colors.white,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13.5))),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      backgroundColor: _kGreenDark,
      body: Stack(children: [
        // Animated background
        _Background(bg: _bgCtrl, orb2: _orb2Ctrl, orb3: _orb3Ctrl),

        // Login card
        Center(
          child: FadeTransition(
            opacity: _cardFade,
            child: SlideTransition(
              position: _cardSlide,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 0,
                  vertical: 40,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: _buildCard(isMobile),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Glass card ─────────────────────────────────────────────────────────────

  Widget _buildCard(bool isMobile) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 28 : 40,
            isMobile ? 36 : 44,
            isMobile ? 28 : 40,
            isMobile ? 32 : 40,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.10),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.14),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.40),
                blurRadius: 56,
                offset: const Offset(0, 20),
              ),
              BoxShadow(
                color: _kGold.withOpacity(0.05),
                blurRadius: 80,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 36),
                _buildFieldLabel('Username'),
                const SizedBox(height: 8),
                _buildUsernameField(),
                const SizedBox(height: 20),
                _buildFieldLabel('Password'),
                const SizedBox(height: 8),
                _buildPasswordField(),
                const SizedBox(height: 10),
                _buildForgotLink(),
                const SizedBox(height: 32),
                _buildLoginButton(),
                const SizedBox(height: 32),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(children: [
      // Shimmer logo ring
      AnimatedBuilder(
        animation: _shimmerCtrl,
        builder: (_, child) => Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              transform: GradientRotation(_shimmerCtrl.value * math.pi * 2),
              colors: const [
                _kGold,
                _kGoldDeep,
                Color(0xFFFFF9C4),
                Colors.transparent,
                Colors.transparent,
                _kGold,
              ],
              stops: const [0.0, 0.15, 0.28, 0.42, 0.82, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                  color: _kGold.withOpacity(0.28),
                  blurRadius: 14,
                  spreadRadius: 1)
            ],
          ),
          padding: const EdgeInsets.all(2.5),
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: _kGreenDeep.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: ClipOval(
            child: Image.asset(
              'assets/images/ndmu_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.school_rounded,
                size: 28,
                color: _kGreen,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 18),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'NDMU LibTour',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: _kGold.withOpacity(0.13),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _kGold.withOpacity(0.35), width: 1),
              ),
              child: const Text(
                'STAFF PORTAL',
                style: TextStyle(
                  color: _kGold,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  // ── Field label ────────────────────────────────────────────────────────────

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.60),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }

  // ── Input fields ───────────────────────────────────────────────────────────

  Widget _buildUsernameField() {
    return _GlassField(
      controller: _usernameController,
      hint: 'Enter your username',
      icon: Icons.person_outline_rounded,
      keyboardType: TextInputType.text,
      autocorrect: false,
      textInputAction: TextInputAction.next,
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Please enter your username' : null,
    );
  }

  Widget _buildPasswordField() {
    return _GlassField(
      controller: _passwordController,
      hint: 'Enter your password',
      icon: Icons.lock_outline_rounded,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _handleSignIn(),
      suffixIcon: GestureDetector(
        onTap: () => setState(() => _obscurePassword = !_obscurePassword),
        child: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Colors.white38,
            size: 19,
          ),
        ),
      ),
      validator: (v) =>
          (v == null || v.isEmpty) ? 'Please enter your password' : null,
    );
  }

  Widget _buildForgotLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: _handleForgotPassword,
        child: Text(
          'Forgot password?',
          style: TextStyle(
            color: _kGold.withOpacity(0.70),
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.underline,
            decorationColor: _kGold.withOpacity(0.35),
          ),
        ),
      ),
    );
  }

  // ── Login button ───────────────────────────────────────────────────────────

  Widget _buildLoginButton() {
    final auth = Provider.of<AuthService>(context);
    return _LoginButton(
      loading: auth.isLoading,
      onPressed: auth.isLoading ? null : _handleSignIn,
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Column(children: [
      Divider(color: Colors.white.withOpacity(0.10), height: 1),
      const SizedBox(height: 16),
      Text(
        '© 2026 Notre Dame of Marbel University',
        style: TextStyle(
          color: Colors.white.withOpacity(0.28),
          fontSize: 11,
          letterSpacing: 0.2,
        ),
        textAlign: TextAlign.center,
      ),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Glass input field
// ══════════════════════════════════════════════════════════════════════════════
class _GlassField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool autocorrect;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _GlassField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.autocorrect = true,
    this.obscureText = false,
    this.textInputAction,
    this.onFieldSubmitted,
    this.suffixIcon,
    this.validator,
  });

  @override
  State<_GlassField> createState() => _GlassFieldState();
}

class _GlassFieldState extends State<_GlassField> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode
        .addListener(() => setState(() => _focused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _focused
            ? Colors.white.withOpacity(0.11)
            : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focused
              ? _kGold.withOpacity(0.55)
              : Colors.white.withOpacity(0.13),
          width: _focused ? 1.6 : 1.2,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                    color: _kGold.withOpacity(0.10),
                    blurRadius: 12,
                    spreadRadius: 0)
              ]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: widget.keyboardType,
        autocorrect: widget.autocorrect,
        obscureText: widget.obscureText,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onFieldSubmitted,
        style:
            const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.35),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle:
              TextStyle(color: Colors.white.withOpacity(0.28), fontSize: 14),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(
              widget.icon,
              color: _focused
                  ? _kGold.withOpacity(0.8)
                  : Colors.white.withOpacity(0.35),
              size: 19,
            ),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 46, minHeight: 46),
          suffixIcon: widget.suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: widget.suffixIcon,
                )
              : null,
          suffixIconConstraints:
              const BoxConstraints(minWidth: 44, minHeight: 44),
          filled: false,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          errorStyle: TextStyle(
              color: const Color(0xFFFF8A80).withOpacity(0.9),
              fontSize: 11.5,
              height: 1.3),
          errorMaxLines: 2,
        ),
        validator: widget.validator,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Login button
// ══════════════════════════════════════════════════════════════════════════════
class _LoginButton extends StatefulWidget {
  final bool loading;
  final VoidCallback? onPressed;
  const _LoginButton({required this.loading, this.onPressed});

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  bool _hov = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.975)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onPressed != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) {
        setState(() => _hov = true);
        _ctrl.forward();
      },
      onExit: (_) {
        setState(() => _hov = false);
        _ctrl.reverse();
      },
      child: ScaleTransition(
        scale: _scale,
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.loading
                    ? [_kGold.withOpacity(0.4), _kGoldDeep.withOpacity(0.4)]
                    : _hov
                        ? [const Color(0xFFFFEC62), _kGoldDeep]
                        : [_kGold, _kGoldDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: widget.loading
                  ? []
                  : [
                      BoxShadow(
                        color: _kGold.withOpacity(_hov ? 0.40 : 0.22),
                        blurRadius: _hov ? 24 : 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
              child: widget.loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: _kGreenDark, strokeWidth: 2.5),
                    )
                  : const Text(
                      'Sign In',
                      style: TextStyle(
                        color: _kGreenDark,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Animated background
// ══════════════════════════════════════════════════════════════════════════════
class _Background extends StatelessWidget {
  final Animation<double> bg;
  final Animation<double> orb2;
  final Animation<double> orb3;

  const _Background({required this.bg, required this.orb2, required this.orb3});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([bg, orb2, orb3]),
      builder: (_, __) => CustomPaint(
        size: MediaQuery.of(context).size,
        painter: _BgPainter(
          v1: bg.value,
          v2: orb2.value,
          v3: orb3.value,
        ),
      ),
    );
  }
}

class _BgPainter extends CustomPainter {
  final double v1, v2, v3;
  const _BgPainter({required this.v1, required this.v2, required this.v3});

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;

    // Deep forest base gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF071A08), Color(0xFF0D3F0F), Color(0xFF071810)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Orb 1 — large emerald glow top-left
    _orb(canvas, Offset(w * 0.08 + v1 * w * 0.07, h * 0.12 + v1 * h * 0.10),
        w * 0.52, const Color(0xFF1B5E20).withOpacity(0.22));

    // Orb 2 — muted gold bottom-right
    _orb(canvas, Offset(w * 0.82 - v2 * w * 0.08, h * 0.76 + v2 * h * 0.06),
        w * 0.38, const Color(0xFFFFD700).withOpacity(0.05));

    // Orb 3 — secondary green centre
    _orb(canvas, Offset(w * 0.52 + v3 * w * 0.05, h * 0.38 - v3 * h * 0.08),
        w * 0.30, const Color(0xFF2E7D32).withOpacity(0.14));

    // Subtle grid overlay
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.016)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;
    const step = 52.0;
    for (double x = 0; x < w; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y < h; y += step) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Diagonal gold accent lines
    final accentPaint = Paint()
      ..shader = LinearGradient(colors: [
        Colors.transparent,
        const Color(0xFFFFD700).withOpacity(0.10),
        Colors.transparent,
      ]).createShader(Rect.fromLTWH(0, 0, w, h))
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, h * 0.38), Offset(w * 0.42, 0), accentPaint);
    canvas.drawLine(Offset(w * 0.58, h), Offset(w, h * 0.60), accentPaint);
  }

  void _orb(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color, Colors.transparent],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_BgPainter o) => o.v1 != v1 || o.v2 != v2 || o.v3 != v3;
}
