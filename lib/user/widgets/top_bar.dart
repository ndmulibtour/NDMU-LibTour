import 'package:flutter/material.dart';
import 'package:ndmu_libtour/utils/responsive_helper.dart';

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

    return AppBar(
      backgroundColor: const Color(0xFF1B5E20),
      elevation: 2,
      toolbarHeight: 80,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // NDMU Logo
          Container(
            padding: const EdgeInsets.all(8),
            child: Image.asset(
              'assets/images/ndmu_logo.png',
              height: 50,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.school,
                  size: 50,
                  color: Colors.white,
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // Title
          const Text(
            'NDMU LibTour',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: isMobile
          ? [
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                onPressed: onMenuPressed ?? () => _showMobileMenu(context),
              ),
            ]
          : _buildDesktopMenu(context),
    );
  }

  List<Widget> _buildDesktopMenu(BuildContext context) {
    return [
      _buildNavButton(context, 'Home', () {
        if (ModalRoute.of(context)?.settings.name != '/') {
          Navigator.pushReplacementNamed(context, '/');
        }
      }),
      _buildNavButton(context, 'Sections', () {
        if (ModalRoute.of(context)?.settings.name != '/sections') {
          Navigator.pushReplacementNamed(context, '/sections');
        }
      }),
      _buildNavButton(context, 'Policies', () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Policies page coming soon!')),
        );
      }),
      _buildNavButton(context, 'Services', () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Services page coming soon!')),
        );
      }),
      _buildNavButton(context, 'FAQ', () {
        if (ModalRoute.of(context)?.settings.name != '/faq') {
          Navigator.pushReplacementNamed(context, '/faq');
        }
      }),
      _buildNavButton(context, 'Contact', () {
        if (ModalRoute.of(context)?.settings.name != '/contact') {
          Navigator.pushReplacementNamed(context, '/contact');
        }
      }),
      const SizedBox(width: 16),
    ];
  }

  Widget _buildNavButton(
      BuildContext context, String label, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1B5E20),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white54,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            _buildMobileMenuItem(context, Icons.home, 'Home', () {
              Navigator.pop(context);
              if (ModalRoute.of(context)?.settings.name != '/') {
                Navigator.pushReplacementNamed(context, '/');
              }
            }),
            _buildMobileMenuItem(context, Icons.library_books, 'Sections', () {
              Navigator.pop(context);
              if (ModalRoute.of(context)?.settings.name != '/sections') {
                Navigator.pushReplacementNamed(context, '/sections');
              }
            }),
            _buildMobileMenuItem(context, Icons.policy, 'Policies', () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Policies page coming soon!')),
              );
            }),
            _buildMobileMenuItem(context, Icons.room_service, 'Services', () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Services page coming soon!')),
              );
            }),
            _buildMobileMenuItem(context, Icons.help, 'FAQ', () {
              Navigator.pop(context);
              if (ModalRoute.of(context)?.settings.name != '/faq') {
                Navigator.pushReplacementNamed(context, '/faq');
              }
            }),
            _buildMobileMenuItem(context, Icons.contact_mail, 'Contact', () {
              Navigator.pop(context);
              if (ModalRoute.of(context)?.settings.name != '/contact') {
                Navigator.pushReplacementNamed(context, '/contact');
              }
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileMenuItem(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
