import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:ndmu_libtour/admin/models/faq_model.dart';
import 'package:ndmu_libtour/admin/services/faq_service.dart';
import 'package:ndmu_libtour/user/widgets/bottom_bar.dart';
import 'package:ndmu_libtour/user/widgets/top_bar.dart';
import 'package:ndmu_libtour/utils/responsive_helper.dart';
import 'package:ndmu_libtour/main.dart'; // For NavigationProvider
import 'package:ndmu_libtour/user/contact_feedback_screen.dart'; // For scroll flag

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final FAQService _faqService = FAQService();
  final Map<String, bool> _expandedStates = {};

  late Stream<List<FAQ>> _faqStream;

  @override
  void initState() {
    super.initState();
    _faqStream = _faqService.getFAQs();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const TopBar(),
      body: StreamBuilder<List<FAQ>>(
        stream: _faqStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return _buildLoadingScreen(isMobile);
          }

          if (snapshot.hasError) {
            return _buildErrorScreen();
          }

          final faqList = snapshot.data ?? [];

          if (faqList.isEmpty) {
            return _buildEmptyFAQs();
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(isMobile),
                _buildFAQContent(faqList, isMobile),
                _buildContactSection(isMobile),
                const BottomBar(),
              ],
            ),
          );
        },
      ),
    );
  }

  // Enhanced Header with NDMU Theme
  Widget _buildHeader(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 60,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1B5E20),
        image: DecorationImage(
          image: AssetImage('assets/images/school.jpg'),
          fit: BoxFit.cover,
          opacity: 0.2,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: isMobile ? 32 : 42,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Find answers to common questions',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              color: const Color(0xFFFFD700),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // FAQ Content with Glass Cards
  Widget _buildFAQContent(List<FAQ> faqList, bool isMobile) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1100),
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      child: Column(
        children: faqList.map((faq) {
          return FAQItem(
            key: ValueKey(faq.id),
            faq: faq,
            isExpanded: _expandedStates[faq.id] ?? false,
            isMobile: isMobile,
            onTap: () {
              setState(() {
                _expandedStates[faq.id] = !(_expandedStates[faq.id] ?? false);
              });
            },
          );
        }).toList(),
      ),
    );
  }

  // Enhanced Contact Section with Glassmorphism
  Widget _buildContactSection(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 40 : 60),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1B5E20).withOpacity(0.05),
            const Color(0xFFFFD700).withOpacity(0.05),
          ],
        ),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: EdgeInsets.all(isMobile ? 32 : 48),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF1B5E20).withOpacity(0.2),
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
                    // Icon with gradient background
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
                      child: const Icon(
                        Icons.contact_support,
                        color: Color(0xFFFFD700),
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Still have questions?',
                      style: TextStyle(
                        fontSize: isMobile ? 24 : 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B5E20),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Our team is here to help you',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFC107)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          // Set flag to trigger scroll
                          ContactFeedbackScreen.shouldScrollToForm = true;

                          // Navigate to contact page (index 4)
                          final navProvider = Provider.of<NavigationProvider>(
                            context,
                            listen: false,
                          );
                          navProvider.navigateTo(4);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: const Color(0xFF1B5E20),
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.email_outlined, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'Contact Us',
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen(bool isMobile) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(isMobile),
          Container(
            constraints: const BoxConstraints(maxWidth: 1100),
            padding: EdgeInsets.all(isMobile ? 60 : 100),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1B5E20),
                strokeWidth: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(false),
          Container(
            padding: const EdgeInsets.all(60),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[400],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Error loading FAQs',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please try again later',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFAQs() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(false),
          Container(
            constraints: const BoxConstraints(maxWidth: 1100),
            padding: const EdgeInsets.all(60),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.question_answer_outlined,
                    size: 64,
                    color: const Color(0xFF1B5E20).withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No FAQs available yet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back later for updates',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Simplified FAQ Item - Fast and smooth
class FAQItem extends StatefulWidget {
  final FAQ faq;
  final bool isExpanded;
  final bool isMobile;
  final VoidCallback onTap;

  const FAQItem({
    super.key,
    required this.faq,
    required this.isExpanded,
    required this.isMobile,
    required this.onTap,
  });

  @override
  State<FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<FAQItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
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
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isExpanded
                    ? const Color(0xFFFFD700).withOpacity(0.6)
                    : const Color(0xFF1B5E20).withOpacity(0.15),
                width: widget.isExpanded ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.isExpanded
                      ? const Color(0xFF1B5E20).withOpacity(0.12)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: widget.isExpanded ? 16 : 8,
                  offset: Offset(0, widget.isExpanded ? 6 : 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(16),
                splashColor: const Color(0xFF1B5E20).withOpacity(0.1),
                highlightColor: const Color(0xFFFFD700).withOpacity(0.05),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: Padding(
                    padding: EdgeInsets.all(widget.isMobile ? 20 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.help_outline,
                              size: 22,
                              color: widget.isExpanded
                                  ? const Color(0xFF1B5E20)
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                widget.faq.question,
                                style: TextStyle(
                                  fontSize: widget.isMobile ? 16 : 18,
                                  fontWeight: FontWeight.w600,
                                  color: widget.isExpanded
                                      ? const Color(0xFF1B5E20)
                                      : Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            AnimatedRotation(
                              turns: widget.isExpanded ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: widget.isExpanded
                                    ? const Color(0xFF1B5E20)
                                    : Colors.grey[600],
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                        if (widget.isExpanded) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: EdgeInsets.all(widget.isMobile ? 16 : 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFFD700).withOpacity(0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1B5E20),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.lightbulb,
                                    color: Color(0xFFFFD700),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    widget.faq.answer,
                                    style: TextStyle(
                                      fontSize: widget.isMobile ? 15 : 16,
                                      color: Colors.black87,
                                      height: 1.6,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
