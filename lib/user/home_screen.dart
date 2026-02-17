import 'package:flutter/material.dart';
import 'dart:async';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
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
    final isMobile = ResponsiveHelper.isMobile(context);

    return SizedBox(
      height: isMobile ? 550 : 750,
      width: double.infinity,
      child: Stack(
        children: [
          // 1. Sliding Background Carousel (Full Width)
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

          // 2. Centered Linear Gradient Overlay (Translucent Green)
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

          // 3. Centered Hero Text & UI Elements
          Padding(
            padding: ResponsiveHelper.padding(
              context,
              mobile: const EdgeInsets.symmetric(horizontal: 24),
              desktop: const EdgeInsets.symmetric(horizontal: 80),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment
                    .center, // Centered vertically and horizontally
                children: [
                  // Centered Logo
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
                  // Centered Gold Button
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
                      onPressed: () =>
                          Navigator.pushNamed(context, '/virtual-tour'),
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
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
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
