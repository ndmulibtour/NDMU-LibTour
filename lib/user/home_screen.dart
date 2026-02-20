import 'package:flutter/material.dart';
import 'dart:async';
import 'package:ndmu_libtour/admin/services/system_settings_service.dart';
import 'package:ndmu_libtour/user/widgets/bottom_bar.dart';
import 'package:ndmu_libtour/user/widgets/top_bar.dart';
import '../utils/responsive_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  late Timer _timer;

  final _settingsService = SystemSettingsService();

  final List<String> _carouselImages = [
    'assets/images/homepage/random2.jpg',
    'assets/images/homepage/random3.jpg',
    'assets/images/homepage/random4.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < _carouselImages.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch system settings in real-time
    return StreamBuilder<SystemSettings>(
      stream: _settingsService.watchSettings(),
      builder: (context, snap) {
        final settings = snap.data ?? SystemSettings.defaults();

        // ── Maintenance Mode ───────────────────────────────────────────────
        if (settings.isMaintenanceMode) {
          return const _MaintenanceScreen();
        }

        // ── Normal Home ────────────────────────────────────────────────────
        return Scaffold(
          backgroundColor: const Color(0xFFF2F2F2),
          appBar: const TopBar(),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Announcement banner — only shown when active
                if (settings.hasAnnouncement)
                  _AnnouncementBanner(text: settings.globalAnnouncement),

                _buildHeroSection(context),
                _buildContentSection(context),
                const BottomBar(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return SizedBox(
      height: isMobile ? 550 : 750,
      width: double.infinity,
      child: Stack(
        children: [
          // 1. Sliding Background Carousel
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _carouselImages.length,
              itemBuilder: (context, index) {
                return Image.asset(
                  _carouselImages[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    color: const Color(0xFF1B5E20),
                    child: const Center(
                      child:
                          Icon(Icons.image, color: Colors.white24, size: 100),
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1B5E20).withOpacity(0.85),
                    const Color(0xFF1B5E20).withOpacity(0.6),
                    const Color(0xFF1B5E20).withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ),

          // 3. Hero Content
          Padding(
            padding: ResponsiveHelper.padding(
              context,
              mobile: const EdgeInsets.symmetric(horizontal: 24),
              desktop: const EdgeInsets.symmetric(horizontal: 80),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Image.asset('assets/images/ndmu_logo.png',
                        height: isMobile ? 60 : 100),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'NOTRE DAME OF MARBEL UNIVERSITY',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      letterSpacing: 4,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 800,
                    child: Text(
                      'Step Into the Future of Learning',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.fontSize(context,
                            mobile: 36, desktop: 64),
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                        shadows: const [
                          Shadow(
                              color: Colors.black38,
                              offset: Offset(2, 2),
                              blurRadius: 10)
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(
                    width: 700,
                    child: Text(
                      'Explore our world-class library collections and facilities\nthrough an immersive 360° virtual experience.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.6,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFC107)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(
                          context, '/virtual-tour',
                          arguments: {'source': 'home'}),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: const Color(0xFF1B5E20),
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 48, vertical: 24),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        'START VIRTUAL TOUR',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 60, height: 3, color: const Color(0xFFFFD700)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "UNIVERSITY SECTIONS",
                  style: TextStyle(
                    color: Color(0xFF1B5E20),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(width: 60, height: 3, color: const Color(0xFFFFD700)),
            ],
          ),
          const SizedBox(height: 60),
          const Wrap(
            spacing: 30,
            runSpacing: 30,
            children: [],
          ),
        ],
      ),
    );
  }
}

// ─── Announcement Banner ───────────────────────────────────────────────────────

class _AnnouncementBanner extends StatefulWidget {
  final String text;
  const _AnnouncementBanner({required this.text});

  @override
  State<_AnnouncementBanner> createState() => _AnnouncementBannerState();
}

class _AnnouncementBannerState extends State<_AnnouncementBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFC107)],
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign, color: Color(0xFF1B5E20), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.text,
              style: const TextStyle(
                color: Color(0xFF1B5E20),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.close, size: 18, color: Color(0xFF1B5E20)),
            onPressed: () => setState(() => _dismissed = true),
          ),
        ],
      ),
    );
  }
}

// ─── Maintenance Screen ────────────────────────────────────────────────────────

class _MaintenanceScreen extends StatelessWidget {
  const _MaintenanceScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/images/ndmu_logo.png',
                  height: 100,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.school,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Wrench icon
              const Icon(Icons.construction,
                  color: Color(0xFFFFD700), size: 64),
              const SizedBox(height: 24),

              // Title
              const Text(
                'System Under Maintenance',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Subtitle
              const Text(
                'We\'re making improvements to bring you\na better experience. Please check back soon.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),

              // Gold divider
              Container(
                width: 80,
                height: 3,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Footer
              const Text(
                'NDMU LibTour — Notre Dame of Marbel University',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
