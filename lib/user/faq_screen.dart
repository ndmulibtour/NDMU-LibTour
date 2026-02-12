import 'package:flutter/material.dart';
import 'package:ndmu_libtour/admin/models/faq_model.dart';
import 'package:ndmu_libtour/admin/services/faq_service.dart';
import 'package:ndmu_libtour/user/widgets/bottom_bar.dart';
import 'package:ndmu_libtour/user/widgets/top_bar.dart';
import 'package:ndmu_libtour/utils/responsive_helper.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final FAQService _faqService = FAQService();
  final Map<String, bool> _expandedStates = {};

  // 1. Declare the stream variable
  late Stream<List<FAQ>> _faqStream;

  @override
  void initState() {
    super.initState();
    // 2. Initialize the stream once so it doesn't restart on every rebuild
    _faqStream = _faqService.getFAQs();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const TopBar(),
      body: StreamBuilder<List<FAQ>>(
        stream: _faqStream, // 3. Use the persistent stream
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
                // Header Section
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: isMobile ? 10 : 20,
                    horizontal: isMobile ? 24 : 40,
                  ),
                  color: Colors.white,
                  child: Column(
                    children: [
                      Text(
                        'Frequently Asked Questions',
                        style: TextStyle(
                          fontSize: isMobile ? 28 : 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Find answers to common questions',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // FAQ Content
                Container(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  padding: EdgeInsets.all(isMobile ? 10 : 30),
                  child: Column(
                    children: faqList.map((faq) {
                      return FAQItem(
                        key: ValueKey(faq.id),
                        faq: faq,
                        // Maintain expansion state using the map
                        isExpanded: _expandedStates[faq.id] ?? false,
                        isMobile: isMobile,
                        onTap: () {
                          setState(() {
                            _expandedStates[faq.id] =
                                !(_expandedStates[faq.id] ?? false);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),

                // Contact Section
                _buildContactSection(isMobile),
                const BottomBar(),
              ],
            ),
          );
        },
      ),
    );
  }

  // Refactored Contact Section for cleaner code
  Widget _buildContactSection(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 40 : 60),
      color: Colors.grey[200],
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: EdgeInsets.all(isMobile ? 32 : 48),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Still have questions?',
                style: TextStyle(
                  fontSize: isMobile ? 22 : 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Contact Us'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen(bool isMobile) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: isMobile ? 60 : 100,
              horizontal: isMobile ? 24 : 40,
            ),
            color: Colors.white,
            child: Column(
              children: [
                Text(
                  'Frequently Asked Questions',
                  style: TextStyle(
                    fontSize: isMobile ? 28 : 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Find answers to common questions',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Container(
            constraints: const BoxConstraints(maxWidth: 1100),
            padding: EdgeInsets.all(isMobile ? 60 : 100),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1B5E20),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 40),
            color: Colors.white,
            child: Column(
              children: [
                Text(
                  'Frequently Asked Questions',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Find answers to common questions',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(60),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error loading FAQs',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFAQs() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1100),
      padding: const EdgeInsets.all(60),
      child: Column(
        children: [
          Icon(
            Icons.question_answer_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No FAQs available yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for updates',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

// FAQ Item Widget - Uses AnimatedSize for smooth expansion
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isExpanded
              ? const Color(0xFF1B5E20).withOpacity(0.3)
              : Colors.grey[300]!,
          width: widget.isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isExpanded ? 0.06 : 0.03),
            blurRadius: widget.isExpanded ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: const Color(0xFF1B5E20).withOpacity(0.1),
          highlightColor: const Color(0xFF1B5E20).withOpacity(0.05),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: Padding(
              padding: EdgeInsets.all(widget.isMobile ? 20 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.faq.question,
                          style: TextStyle(
                            fontSize: widget.isMobile ? 16 : 17,
                            fontWeight: FontWeight.w600,
                            color: widget.isExpanded
                                ? const Color(0xFF1B5E20)
                                : Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      AnimatedRotation(
                        turns: widget.isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 250),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: widget.isExpanded
                              ? const Color(0xFF1B5E20)
                              : Colors.black54,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  if (widget.isExpanded) ...[
                    const SizedBox(height: 16),
                    Text(
                      widget.faq.answer,
                      style: TextStyle(
                        fontSize: widget.isMobile ? 14 : 15,
                        color: Colors.grey[700],
                        height: 1.6,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
