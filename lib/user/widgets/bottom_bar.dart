import 'package:flutter/material.dart';
import 'package:ndmu_libtour/utils/responsive_helper.dart';

class BottomBar extends StatelessWidget {
  const BottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1B5E20),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: isMobile ? _buildMobileFooter() : _buildDesktopFooter(),
    );
  }

  Widget _buildMobileFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo and Campus Info
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/ndmu_logo.png',
                height: 50,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.school,
                      size: 50, color: Colors.white);
                },
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NDMU Main Campus',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Alunan Avenue, Brgy. Zone 3,\nCity of Koronadal, South Cotabato',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Contact Section
          const Text(
            'Contact Us',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '(###) ### ####',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Social Icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.facebook, color: Colors.white),
                onPressed: () {},
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.email, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Copyright
          const Divider(color: Colors.white24, thickness: 1),
          const SizedBox(height: 16),
          const Text(
            'NDMU Library © 2025. All Rights Reserved.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 80),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Menu Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Menu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFooterLink('Home'),
                    _buildFooterLink('Sections'),
                    _buildFooterLink('Policies'),
                    _buildFooterLink('Services'),
                    _buildFooterLink('FAQ'),
                  ],
                ),
              ),

              // Campus Info Section
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/ndmu_logo.png',
                          height: 60,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.school,
                                size: 60, color: Colors.white);
                          },
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NDMU Main Campus',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Alunan Avenue, Brgy. Zone 3,\nCity of Koronadal, South Cotabato, Philippines',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.start,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'NDMU Library © 2025. All Rights Reserved.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Contact Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Contact Us',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '(###) ### ####',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.facebook, color: Colors.white),
                          onPressed: () {},
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.email, color: Colors.white),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {},
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
