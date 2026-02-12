import 'package:flutter/material.dart';
import 'package:ndmu_libtour/user/widgets/bottom_bar.dart';
import 'package:ndmu_libtour/user/widgets/top_bar.dart';
import 'package:ndmu_libtour/utils/responsive_helper.dart';
import 'dart:ui' as ui;
import '../admin/services/feedback_service.dart';
import '../admin/services/contact_service.dart';

class ContactFeedbackScreen extends StatefulWidget {
  const ContactFeedbackScreen({super.key});

  @override
  State<ContactFeedbackScreen> createState() => _ContactFeedbackScreenState();
}

class _ContactFeedbackScreenState extends State<ContactFeedbackScreen> {
  final FeedbackService _feedbackService = FeedbackService();
  final ContactService _contactService = ContactService();

  // NDMU Color Palette
  static const Color ndmuGreen = Color(0xFF1B5E20);
  static const Color ndmuLightGreen = Color(0xFF2E7D32);
  static const Color ndmuGold = Color(0xFFD4AF37);
  static const Color ndmuDarkGreen = Color(0xFF0D3F0F);

  // Feedback form controllers
  final _feedbackFormKey = GlobalKey<FormState>();
  final _feedbackNameController = TextEditingController();
  final _feedbackEmailController = TextEditingController();
  final _feedbackMessageController = TextEditingController();
  int _selectedRating = 0;
  bool _isSubmittingFeedback = false;

  // Contact form controllers
  final _contactFormKey = GlobalKey<FormState>();
  final _contactNameController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactMessageController = TextEditingController();
  bool _isSubmittingContact = false;

  @override
  void dispose() {
    _feedbackNameController.dispose();
    _feedbackEmailController.dispose();
    _feedbackMessageController.dispose();
    _contactNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _contactMessageController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_feedbackFormKey.currentState!.validate()) return;
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Please select a rating'),
            ],
          ),
          backgroundColor: ndmuGold,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Thank you for your feedback! We appreciate your input.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: ndmuGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Failed to submit feedback. Please try again.'),
            ],
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Message sent successfully! We\'ll respond to you shortly.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: ndmuGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Failed to send message. Please try again.'),
            ],
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const TopBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section with Contact Info and Map
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage(
                    'assets/images/school.jpg',
                  ),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    ndmuDarkGreen.withOpacity(0.85),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: ndmuDarkGreen.withOpacity(0.3),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 40,
                      vertical: isMobile ? 40 : 80,
                    ),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: Column(
                        children: [
                          // Page Title
                          Text(
                            'Contact Us',
                            style: TextStyle(
                              fontSize: isMobile ? 32 : 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Notre Dame of Marbel University Library',
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 20,
                              color: ndmuGold,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 60),

                          // Contact Info and Map
                          isMobile
                              ? Column(
                                  children: [
                                    _buildContactInfo(isMobile),
                                    const SizedBox(height: 30),
                                    _buildMapSection(isMobile),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: _buildContactInfo(isMobile),
                                    ),
                                    const SizedBox(width: 40),
                                    Expanded(
                                      flex: 3,
                                      child: _buildMapSection(isMobile),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Forms Section
            Container(
              width: double.infinity,
              color: Colors.grey[50],
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 40,
                vertical: isMobile ? 40 : 80,
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: Column(
                  children: [
                    // Section Header
                    Text(
                      'Get in Touch',
                      style: TextStyle(
                        fontSize: isMobile ? 28 : 36,
                        fontWeight: FontWeight.bold,
                        color: ndmuDarkGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We value your feedback and inquiries',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 50),

                    // Forms
                    isMobile
                        ? Column(
                            children: [
                              _buildFeedbackForm(isMobile),
                              const SizedBox(height: 30),
                              _buildContactForm(isMobile),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildFeedbackForm(isMobile)),
                              const SizedBox(width: 40),
                              Expanded(child: _buildContactForm(isMobile)),
                            ],
                          ),
                  ],
                ),
              ),
            ),

            const BottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 30 : 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: ndmuDarkGreen,
            ),
          ),
          const SizedBox(height: 30),
          _buildInfoRow(
            Icons.business,
            'Institution',
            'NDMU Library',
          ),
          const SizedBox(height: 24),
          _buildInfoRow(
            Icons.account_balance,
            'University',
            'Notre Dame of Marbel University',
          ),
          const SizedBox(height: 24),
          _buildInfoRow(
            Icons.location_on,
            'Address',
            'Alunan Avenue, Brgy. Zone 3\nCity of Koronadal, South Cotabato\nPhilippines',
          ),
          const SizedBox(height: 24),
          _buildInfoRow(
            Icons.phone,
            'Phone',
            '(xxx) ### ####',
          ),
          const SizedBox(height: 40),
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildSocialButton(Icons.facebook, () {}),
              const SizedBox(width: 16),
              _buildSocialButton(Icons.email, () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: ndmuGreen,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ndmuGreen,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildMapSection(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ndmuGreen,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'LOCATION',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 500,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: const HtmlElementView(
              viewType: 'google-maps-embed',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackForm(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 30 : 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _feedbackFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share Your Feedback',
              style: TextStyle(
                fontSize: isMobile ? 22 : 26,
                fontWeight: FontWeight.bold,
                color: ndmuDarkGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Help us improve our services',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),

            // Rating
            Text(
              'Rate Your Experience',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: ndmuDarkGreen,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(
                5,
                (index) => InkWell(
                  onTap: () => setState(() => _selectedRating = index + 1),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      _selectedRating > index ? Icons.star : Icons.star_border,
                      color:
                          _selectedRating > index ? ndmuGold : Colors.grey[400],
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildFormField(
              label: 'Name',
              controller: _feedbackNameController,
              hint: 'Enter your name',
              icon: Icons.person,
            ),
            const SizedBox(height: 20),
            _buildFormField(
              label: 'Email',
              controller: _feedbackEmailController,
              hint: 'your.email@example.com',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            _buildFormField(
              label: 'Feedback',
              controller: _feedbackMessageController,
              hint: 'Share your thoughts...',
              icon: Icons.message,
              maxLines: 5,
            ),
            const SizedBox(height: 32),
            _buildSubmitButton(
              label: 'Submit Feedback',
              isLoading: _isSubmittingFeedback,
              onPressed: _submitFeedback,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactForm(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 30 : 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _contactFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Us',
              style: TextStyle(
                fontSize: isMobile ? 22 : 26,
                fontWeight: FontWeight.bold,
                color: ndmuDarkGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get in touch with our team',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            _buildFormField(
              label: 'Full Name',
              controller: _contactNameController,
              hint: 'Enter your full name',
              icon: Icons.person,
            ),
            const SizedBox(height: 20),
            _buildFormField(
              label: 'Email',
              controller: _contactEmailController,
              hint: 'your.email@example.com',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            _buildFormField(
              label: 'Phone Number',
              controller: _contactPhoneController,
              hint: '+63 XXX XXX XXXX',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            _buildFormField(
              label: 'Message',
              controller: _contactMessageController,
              hint: 'How can we help you?',
              icon: Icons.message,
              maxLines: 5,
            ),
            const SizedBox(height: 32),
            _buildSubmitButton(
              label: 'Send Message',
              isLoading: _isSubmittingContact,
              onPressed: _submitContact,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: ndmuDarkGreen,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(icon, color: ndmuGreen, size: 20),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: ndmuGreen, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
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
            if (label.contains('Email') &&
                (!value.contains('@') || !value.contains('.'))) {
              return 'Please enter a valid email address';
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
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: ndmuGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
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
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}
