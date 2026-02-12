import 'package:flutter/material.dart';
import 'package:ndmu_libtour/user/widgets/bottom_bar.dart';
import 'package:ndmu_libtour/user/widgets/top_bar.dart';
import 'virtual_tour_screen.dart';
import '../utils/responsive_helper.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: const TopBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(context),
            _buildContentSection(context),
            const BottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.padding(
        context,
        mobile: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
        desktop: const EdgeInsets.symmetric(vertical: 120, horizontal: 24),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[200]!,
            Colors.grey[100]!,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // NDMU Logo with animation effect
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/ndmu_logo.png',
              height: ResponsiveHelper.responsive<double>(
                context,
                mobile: 80,
                desktop: 120,
              ),
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.school,
                  size: ResponsiveHelper.responsive<double>(
                    context,
                    mobile: 80,
                    desktop: 120,
                  ),
                  color: const Color(0xFF1B5E20),
                );
              },
            ),
          ),
          SizedBox(
            height: ResponsiveHelper.spacing(
              context,
              mobile: 32,
              desktop: 40,
            ),
          ),
          Text(
            'Welcome to NDMU Library',
            style: TextStyle(
              fontSize: ResponsiveHelper.fontSize(
                context,
                mobile: 28,
                desktop: 42,
              ),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Explore our virtual tour and discover library services',
            style: TextStyle(
              fontSize: ResponsiveHelper.fontSize(
                context,
                mobile: 14,
                desktop: 18,
              ),
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/virtual-tour');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              padding: ResponsiveHelper.padding(
                context,
                mobile:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                desktop:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_circle_outline, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Start Virtual Tour',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.fontSize(
                      context,
                      mobile: 16,
                      desktop: 18,
                    ),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Container(
      padding: ResponsiveHelper.padding(
        context,
        mobile: const EdgeInsets.all(24),
        desktop: const EdgeInsets.all(80),
      ),
      child: Column(
        children: [
          // Section Title
          Text(
            'Experience Notre Dame of Marbel University Library',
            style: TextStyle(
              fontSize: ResponsiveHelper.fontSize(
                context,
                mobile: 24,
                desktop: 36,
              ),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1B5E20),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Text(
              'Navigate through our comprehensive library facilities with our interactive 360° virtual tour. Discover our collections, study areas, and resources from anywhere, at any time.',
              style: TextStyle(
                fontSize: ResponsiveHelper.fontSize(
                  context,
                  mobile: 14,
                  desktop: 16,
                ),
                color: Colors.black87,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 48),

          // Feature Cards
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _buildFeatureCard(
                context,
                Icons.threed_rotation,
                '360° Virtual Tour',
                'Explore every corner of our library with immersive panoramic views',
                isMobile,
              ),
              _buildFeatureCard(
                context,
                Icons.menu_book,
                'Library Sections',
                'Navigate through different sections and discover our collections',
                isMobile,
              ),
              _buildFeatureCard(
                context,
                Icons.info_outline,
                'Resources & Services',
                'Learn about available resources, policies, and library services',
                isMobile,
              ),
            ],
          ),
          const SizedBox(height: 48),

          // Image Placeholder
          Container(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : 1000,
            ),
            width: double.infinity,
            height: isMobile ? 200 : 400,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image,
                  size: isMobile ? 60 : 100,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Library Preview Image',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    bool isMobile,
  ) {
    return Container(
      width: isMobile ? double.infinity : 300,
      padding: const EdgeInsets.all(24),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 40,
              color: const Color(0xFF1B5E20),
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
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
