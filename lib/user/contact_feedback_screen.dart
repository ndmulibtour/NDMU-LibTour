import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:ndmu_libtour/user/widgets/bottom_bar.dart';
import 'package:ndmu_libtour/user/widgets/top_bar.dart';
import 'package:ndmu_libtour/utils/responsive_helper.dart';
import '../admin/services/feedback_service.dart';
import '../admin/services/contact_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactFeedbackScreen extends StatefulWidget {
  static bool shouldScrollToForm = false;

  const ContactFeedbackScreen({super.key});

  @override
  State<ContactFeedbackScreen> createState() => _ContactFeedbackScreenState();
}

class _ContactFeedbackScreenState extends State<ContactFeedbackScreen>
    with TickerProviderStateMixin {
  final FeedbackService _feedbackService = FeedbackService();
  final ContactService _contactService = ContactService();

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _contactFormSectionKey = GlobalKey();

  // Animation controllers
  late AnimationController _heroAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _heroFadeAnimation;
  late Animation<Offset> _heroSlideAnimation;

  // NDMU Color Palette
  static const Color ndmuGreen = Color(0xFF1B5E20);
  static const Color ndmuLightGreen = Color(0xFF2E7D32);
  static const Color ndmuGold = Color(0xFFFFD700);
  static const Color ndmuDarkGreen = Color(0xFF0D3F0F);

  // Form controllers
  final _feedbackFormKey = GlobalKey<FormState>();
  final _feedbackNameController = TextEditingController();
  final _feedbackEmailController = TextEditingController();
  final _feedbackMessageController = TextEditingController();
  int _selectedRating = 0;
  int _hoveredRating = 0;
  bool _isSubmittingFeedback = false;

  final _contactFormKey = GlobalKey<FormState>();
  final _contactNameController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactMessageController = TextEditingController();
  bool _isSubmittingContact = false;

  @override
  void initState() {
    super.initState();

    // Initialize animations with faster durations
    _heroAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _heroFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _heroSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _heroAnimationController,
        curve: Curves.easeOut,
      ),
    );

    // Start animations
    _heroAnimationController.forward();
    _cardAnimationController.forward();

    // Auto-scroll check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ContactFeedbackScreen.shouldScrollToForm) {
        ContactFeedbackScreen.shouldScrollToForm = false;
        _scrollToContactForm();
      }
    });
  }

  @override
  void dispose() {
    _heroAnimationController.dispose();
    _cardAnimationController.dispose();
    _feedbackNameController.dispose();
    _feedbackEmailController.dispose();
    _feedbackMessageController.dispose();
    _contactNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _contactMessageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToContactForm() {
    final context = _contactFormSectionKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  Future<void> _submitFeedback() async {
    if (!_feedbackFormKey.currentState!.validate()) return;
    if (_selectedRating == 0) {
      _showSnackBar(
        'Please select a rating',
        Icons.warning_amber_rounded,
        ndmuGold,
      );
      return;
    }

    setState(() => _isSubmittingFeedback = true);

    final success = await _feedbackService.submitFeedback(
      name: _feedbackNameController.text.trim(),
      email: _feedbackEmailController.text.trim(),
      message: _feedbackMessageController.text.trim(),
      rating: _selectedRating,
    );

    setState(() => _isSubmittingFeedback = false);

    if (!mounted) return;

    if (success) {
      _feedbackNameController.clear();
      _feedbackEmailController.clear();
      _feedbackMessageController.clear();
      setState(() => _selectedRating = 0);
      _showSnackBar(
        'Thank you for your feedback!',
        Icons.check_circle_rounded,
        ndmuGreen,
      );
    } else {
      _showSnackBar(
        'Failed to submit. Please try again.',
        Icons.error_rounded,
        Colors.red,
      );
    }
  }

  Future<void> _submitContact() async {
    if (!_contactFormKey.currentState!.validate()) return;

    setState(() => _isSubmittingContact = true);

    final success = await _contactService.submitContactMessage(
      name: _contactNameController.text.trim(),
      email: _contactEmailController.text.trim(),
      phoneNumber: _contactPhoneController.text.trim(),
      message: _contactMessageController.text.trim(),
    );

    setState(() => _isSubmittingContact = false);

    if (!mounted) return;

    if (success) {
      _contactNameController.clear();
      _contactEmailController.clear();
      _contactPhoneController.clear();
      _contactMessageController.clear();
      _showSnackBar(
        'Message sent successfully!',
        Icons.check_circle_rounded,
        ndmuGreen,
      );
    } else {
      _showSnackBar(
        'Failed to send. Please try again.',
        Icons.error_rounded,
        Colors.red,
      );
    }
  }

  void _showSnackBar(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const TopBar(),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            _buildHeroSection(isMobile),
            _buildContactInfoSection(isMobile),
            _buildFormsSection(isMobile),
            const BottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(bool isMobile) {
    return Container(
      width: double.infinity,
      height: isMobile ? 180 : 220,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/school.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1B5E20).withOpacity(0.85),
                  const Color(0xFF2E7D32).withOpacity(0.75),
                ],
              ),
            ),
            child: Center(
              child: FadeTransition(
                opacity: _heroFadeAnimation,
                child: SlideTransition(
                  position: _heroSlideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Contact & Feedback',
                        style: TextStyle(
                          fontSize: isMobile ? 24 : 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'We\'d love to hear from you',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          color: const Color(0xFFFFD700),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactInfoSection(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // Contact Info Cards - Single box for mobile, three boxes for desktop
              isMobile
                  ? _buildMobileContactInfoCard()
                  : Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            Icons.location_on,
                            'Visit Us',
                            'Alunan Avenue, Brgy. Zone 3\nCity of Koronadal, South Cotabato',
                            0,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildInfoCard(
                            Icons.phone,
                            'Call Us',
                            '(083) 228 2218\nlocal 125 / 126',
                            100,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => launchUrl(
                              Uri.parse('mailto:library@ndmu.edu.ph'),
                              mode: LaunchMode.externalApplication,
                            ),
                            child: _buildInfoCard(
                              Icons.email,
                              'Email Us',
                              'library@ndmu.edu.ph',
                              200,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => launchUrl(
                              Uri.parse('https://www.facebook.com/ndmulibrary'),
                              mode: LaunchMode.externalApplication,
                            ),
                            child: _buildInfoCard(
                              Icons.facebook,
                              'Follow Us',
                              'facebook.com/ndmulibrary',
                              300,
                            ),
                          ),
                        ),
                      ],
                    ),

              // Google Maps Embed
              const SizedBox(height: 40),
              _buildMapSection(isMobile),
            ],
          ),
        ),
      ),
    );
  }

  // New method: Mobile contact info card (all three in one)
  Widget _buildMobileContactInfoCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF1B5E20).withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B5E20).withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildContactInfoRow(
                Icons.location_on,
                'Visit Us',
                'Alunan Avenue, Brgy. Zone 3\nCity of Koronadal, South Cotabato',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Divider(
                  color: const Color(0xFF1B5E20).withOpacity(0.1),
                  thickness: 1,
                ),
              ),
              _buildContactInfoRow(
                Icons.phone,
                'Call Us',
                '(083) 228 2218, local 125 / 126',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Divider(
                  color: const Color(0xFF1B5E20).withOpacity(0.1),
                  thickness: 1,
                ),
              ),
              GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse('mailto:library@ndmu.edu.ph'),
                  mode: LaunchMode.externalApplication,
                ),
                child: _buildContactInfoRow(
                  Icons.email,
                  'Email Us',
                  'library@ndmu.edu.ph',
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Divider(
                  color: const Color(0xFF1B5E20).withOpacity(0.1),
                  thickness: 1,
                ),
              ),
              GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse('https://www.facebook.com/ndmulibrary'),
                  mode: LaunchMode.externalApplication,
                ),
                child: _buildContactInfoRow(
                  Icons.facebook,
                  'Follow Us',
                  'facebook.com/ndmulibrary',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for mobile contact info rows
  Widget _buildContactInfoRow(IconData icon, String title, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B5E20).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 24,
            color: const Color(0xFFFFD700),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapSection(bool isMobile) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF1B5E20).withOpacity(0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B5E20).withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Map Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Color(0xFF1B5E20),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Find Us Here',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'NDMU Main Campus',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Map Container
              Container(
                height: isMobile ? 300 : 450,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  child: const HtmlElementView(
                    viewType: 'google-maps-embed',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      IconData icon, String title, String content, int delay) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF1B5E20).withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B5E20).withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B5E20).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: const Color(0xFFFFD700),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                content,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormsSection(bool isMobile) {
    return Container(
      key: _contactFormSectionKey,
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF5F5F5),
            const Color(0xFF1B5E20).withOpacity(0.02),
          ],
        ),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // Section title (no animation)
              Text(
                'Send Us A Message',
                style: TextStyle(
                  fontSize: isMobile ? 28 : 36,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 4,
                width: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFC107)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 40),

              // Forms
              isMobile
                  ? Column(
                      children: [
                        _buildFeedbackForm(isMobile),
                        const SizedBox(height: 24),
                        _buildContactForm(isMobile),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildFeedbackForm(isMobile)),
                        const SizedBox(width: 24),
                        Expanded(child: _buildContactForm(isMobile)),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackForm(bool isMobile) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 24 : 32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFFFD700).withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Form(
            key: _feedbackFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFC107)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Color(0xFF1B5E20),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Leave Feedback',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          Text(
                            'Rate your experience',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Animated Star Rating
                const Text(
                  'Your Rating',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 12),
                MouseRegion(
                  onExit: (_) => setState(() => _hoveredRating = 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      final isSelected = starValue <= _selectedRating;
                      final isHovered = starValue <= _hoveredRating;

                      return MouseRegion(
                        onEnter: (_) =>
                            setState(() => _hoveredRating = starValue),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedRating = starValue),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              isSelected || isHovered
                                  ? Icons.star
                                  : Icons.star_border,
                              color: isSelected || isHovered
                                  ? const Color(0xFFFFD700)
                                  : Colors.grey[400],
                              size: 36,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 24),

                _buildAnimatedTextField(
                  controller: _feedbackNameController,
                  label: 'Name',
                  hint: 'Your name',
                  icon: Icons.person,
                  delay: 100,
                  maxLength: 100,
                ),
                const SizedBox(height: 16),
                _buildAnimatedTextField(
                  controller: _feedbackEmailController,
                  label: 'Email',
                  hint: 'your.email@example.com',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  delay: 200,
                  maxLength: 254,
                ),
                const SizedBox(height: 16),
                _buildAnimatedTextField(
                  controller: _feedbackMessageController,
                  label: 'Feedback',
                  hint: 'Share your thoughts...',
                  icon: Icons.message,
                  maxLines: 4,
                  delay: 300,
                  maxLength: 2000,
                ),
                const SizedBox(height: 24),

                _buildSubmitButton(
                  label: 'Submit Feedback',
                  isLoading: _isSubmittingFeedback,
                  onPressed: _submitFeedback,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFC107)],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactForm(bool isMobile) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 24 : 32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF1B5E20).withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B5E20).withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Form(
            key: _contactFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.contact_mail,
                        color: Color(0xFFFFD700),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contact Us',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          Text(
                            'Get in touch with our team',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildAnimatedTextField(
                  controller: _contactNameController,
                  label: 'Full Name',
                  hint: 'Your full name',
                  icon: Icons.person,
                  delay: 100,
                  maxLength: 100,
                ),
                const SizedBox(height: 16),
                _buildAnimatedTextField(
                  controller: _contactEmailController,
                  label: 'Email',
                  hint: 'your.email@example.com',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  delay: 200,
                  maxLength: 254,
                ),
                const SizedBox(height: 16),
                _buildAnimatedTextField(
                  controller: _contactPhoneController,
                  label: 'Phone Number',
                  hint: '+63 XXX XXX XXXX',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  delay: 300,
                  maxLength: 20,
                ),
                const SizedBox(height: 16),
                _buildAnimatedTextField(
                  controller: _contactMessageController,
                  label: 'Message',
                  hint: 'How can we help you?',
                  icon: Icons.message,
                  maxLines: 4,
                  delay: 400,
                  maxLength: 2000,
                ),
                const SizedBox(height: 24),
                _buildSubmitButton(
                  label: 'Send Message',
                  isLoading: _isSubmittingContact,
                  onPressed: _submitContact,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    int delay = 0,
    // M-5: explicit per-field character ceiling
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          // M-5: hard character limit enforced at the widget level
          maxLength: maxLength,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(icon, color: ndmuGreen, size: 20),
            filled: true,
            fillColor: Colors.grey[50],
            // Hide the built-in counter label to keep the UI clean; the
            // character limit is still enforced by maxLength above.
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: ndmuGreen, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red[300]!),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 16 : 0,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'This field is required';
            }
            // M-5: explicit length guard (belt-and-suspenders over maxLength)
            if (maxLength != null && value.trim().length > maxLength) {
              return 'Maximum $maxLength characters allowed';
            }
            // M-4: proper RFC-5321-friendly email regex instead of bare '@'+'.' check
            if (label.contains('Email')) {
              final emailRe = RegExp(r'^[\w.+\-]+@[\w\-]+\.[\w.]{2,}$');
              if (!emailRe.hasMatch(value.trim())) {
                return 'Please enter a valid email address';
              }
            }
            // L-3: phone — allow only digits, spaces, +, -, (, ) between 7-20 chars
            if (label.contains('Phone')) {
              final phoneRe = RegExp(r'^[\d\s+\-(). ]{7,20}$');
              if (!phoneRe.hasMatch(value.trim())) {
                return 'Enter a valid phone number (7–20 digits/symbols)';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton({
    required String label,
    required bool isLoading,
    required VoidCallback onPressed,
    required Gradient gradient,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey[300],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.send, size: 20),
                  ],
                ),
        ),
      ),
    );
  }
}
