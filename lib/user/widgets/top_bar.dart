import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:ndmu_libtour/utils/responsive_helper.dart';
import 'package:provider/provider.dart';
import 'package:ndmu_libtour/main.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuPressed;

  const TopBar({
    super.key,
    this.onMenuPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final navProvider = Provider.of<NavigationProvider>(context);

    return AppBar(
      backgroundColor: const Color(0xFF1B5E20).withValues(alpha: 0.95),
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFFFD700), width: 3),
          ),
        ),
      ),
      toolbarHeight: 80,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
            ),
            child: Image.asset(
              'assets/images/ndmu_logo.png',
              height: 45,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.school, size: 40, color: Color(0xFF1B5E20)),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'NDMU LibTour',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: isMobile
          ? [
              IconButton(
                icon:
                    const Icon(Icons.menu, color: Color(0xFFFFD700), size: 30),
                onPressed: onMenuPressed ?? () => _showMobileMenu(context),
              ),
            ]
          : _buildDesktopMenu(context, navProvider),
    );
  }

  List<Widget> _buildDesktopMenu(
      BuildContext context, NavigationProvider navProvider) {
    return [
      _buildNavButton(context, 'Home', 0, navProvider),
      _buildNavButton(context, 'Sections', 1, navProvider),
      _buildNavButton(context, 'Policies', 2, navProvider),
      _buildNavButton(context, 'FAQ', 3, navProvider),
      _buildNavButton(context, 'Contact', 4, navProvider),
      _buildNavButton(context, 'About', 5, navProvider),
      const SizedBox(width: 20),
    ];
  }

  Widget _buildNavButton(
    BuildContext context,
    String label,
    int index,
    NavigationProvider navProvider,
  ) {
    final bool isActive = navProvider.currentIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        onPressed: () => navProvider.navigateTo(index),
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w400,
                color: isActive ? const Color(0xFFFFD700) : Colors.white,
              ),
            ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 2,
                width: 20,
                color: const Color(0xFFFFD700),
              )
          ],
        ),
      ),
    );
  }

  void _showMobileMenu(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1B5E20).withValues(alpha: 0.60),
                  const Color(0xFF0D3F0F).withValues(alpha: 0.60),
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(0)),
              border: Border(
                top: BorderSide(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  const SizedBox(height: 16),
                  Container(
                    width: 50,
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFC107)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Menu Items
                  _buildEnhancedMenuItem(
                    context,
                    Icons.home_rounded,
                    'Home',
                    navProvider.currentIndex == 0,
                    () {
                      Navigator.pop(context);
                      navProvider.navigateTo(0);
                    },
                  ),
                  _buildEnhancedMenuItem(
                    context,
                    Icons.library_books_rounded,
                    'Sections',
                    navProvider.currentIndex == 1,
                    () {
                      Navigator.pop(context);
                      navProvider.navigateTo(1);
                    },
                  ),
                  _buildEnhancedMenuItem(
                    context,
                    Icons.policy_rounded,
                    'Policies',
                    navProvider.currentIndex == 2,
                    () {
                      Navigator.pop(context);
                      navProvider.navigateTo(2);
                    },
                  ),
                  _buildEnhancedMenuItem(
                    context,
                    Icons.help_rounded,
                    'FAQ',
                    navProvider.currentIndex == 3,
                    () {
                      Navigator.pop(context);
                      navProvider.navigateTo(3);
                    },
                  ),
                  _buildEnhancedMenuItem(
                    context,
                    Icons.contact_mail_rounded,
                    'Contact',
                    navProvider.currentIndex == 4,
                    () {
                      Navigator.pop(context);
                      navProvider.navigateTo(4);
                    },
                  ),
                  _buildEnhancedMenuItem(
                    context,
                    Icons.info_rounded,
                    'About',
                    navProvider.currentIndex == 5,
                    () {
                      Navigator.pop(context);
                      navProvider.navigateTo(5);
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedMenuItem(
    BuildContext context,
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isActive ? const Color(0xFFFFD700) : Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isActive ? const Color(0xFFFFD700) : Colors.white,
                      fontSize: 16,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFC107)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFFFD700),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
