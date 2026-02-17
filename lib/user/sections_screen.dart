import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:ndmu_libtour/user/widgets/bottom_bar.dart';
import 'package:ndmu_libtour/user/widgets/top_bar.dart';
import '../utils/responsive_helper.dart';

class LibrarySectionsScreen extends StatefulWidget {
  const LibrarySectionsScreen({super.key});

  @override
  State<LibrarySectionsScreen> createState() => _LibrarySectionsScreenState();
}

class _LibrarySectionsScreenState extends State<LibrarySectionsScreen> {
  String selectedSection = 'Entrance';

  final List<SectionItem> sections = [
    SectionItem(
      label: 'Entrance',
      floor: '1F',
      icon: Icons.door_front_door,
      description:
          'Main entrance lobby with information desk and security checkpoint. First point of contact for all library visitors.',
    ),
    SectionItem(
      label: 'CSCAM',
      floor: '1F',
      icon: Icons.computer,
      description:
          'Computer Science, Computer Applications, and Mathematics section with specialized resources and study materials.',
    ),
    SectionItem(
      label: 'Law Library',
      floor: '1F',
      icon: Icons.gavel,
      description:
          'Comprehensive collection of legal resources, law journals, and jurisprudence materials for law students and researchers.',
    ),
    SectionItem(
      label: 'Graduate School',
      floor: '1F',
      icon: Icons.school,
      description:
          'Dedicated section for graduate students with research materials, thesis resources, and quiet study areas.',
    ),
    SectionItem(
      label: 'EMC',
      floor: '1F',
      icon: Icons.eco,
      description:
          'Environmental Management and Conservation section featuring ecological and environmental science resources.',
    ),
    SectionItem(
      label: 'Filipiniana',
      floor: '2F',
      icon: Icons.history_edu,
      description:
          'Special collection of Philippine history, culture, and heritage materials including rare books and archives.',
    ),
    SectionItem(
      label: 'Internet Section',
      floor: '2F',
      icon: Icons.wifi,
      description:
          'High-speed internet access area with computer workstations for online research and digital resources.',
    ),
    SectionItem(
      label: 'Technical Section',
      floor: '2F',
      icon: Icons.build,
      description:
          'Engineering and technical resources including manuals, specifications, and technical journals.',
    ),
    SectionItem(
      label: 'Director\'s Office',
      floor: '2F',
      icon: Icons.business_center,
      description:
          'Library administration office. For inquiries, complaints, and administrative concerns.',
    ),
    SectionItem(
      label: 'Main Section',
      floor: '3F',
      icon: Icons.menu_book,
      description:
          'General circulation and main collection area with diverse academic resources across all disciplines.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const TopBar(),
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Simple Header for Mobile
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'Library Sections',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Sections Grid
          _buildMobileSectionsGrid(),

          // Selected Section Detail
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildSectionDetail(true),
          ),

          const BottomBar(),
        ],
      ),
    );
  }

  Widget _buildMobileSectionsGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final section = sections[index];
          final isSelected = selectedSection == section.label;

          return _buildSectionCard(section, isSelected, true);
        },
      ),
    );
  }

  Widget _buildSectionCard(
      SectionItem section, bool isSelected, bool isMobile) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSection = section.label;
        });
        if (isMobile) {
          // Scroll to detail section on mobile
          Future.delayed(const Duration(milliseconds: 100), () {
            // You can add scroll logic here if needed
          });
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isSelected
                    ? [
                        const Color(0xFF1B5E20).withOpacity(0.15),
                        Colors.white.withOpacity(0.95),
                      ]
                    : [
                        Colors.white.withOpacity(0.95),
                        Colors.white.withOpacity(0.85),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFFD700).withOpacity(0.6)
                    : const Color(0xFF1B5E20).withOpacity(0.15),
                width: isSelected ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? const Color(0xFF1B5E20).withOpacity(0.12)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: isSelected ? 12 : 8,
                  offset: Offset(0, isSelected ? 4 : 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                          )
                        : LinearGradient(
                            colors: [
                              const Color(0xFF1B5E20).withOpacity(0.1),
                              const Color(0xFF1B5E20).withOpacity(0.05),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    section.icon,
                    color: isSelected
                        ? const Color(0xFFFFD700)
                        : const Color(0xFF1B5E20),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  section.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        isSelected ? const Color(0xFF1B5E20) : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFFD700).withOpacity(0.2)
                        : const Color(0xFF1B5E20).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    section.floor,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color:
                          isSelected ? const Color(0xFF1B5E20) : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left Sidebar - Sections List with Title
        Container(
          width: 320,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1B5E20),
                Color(0xFF0D3F0F),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Title in Sidebar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFFFFD700).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Library Sections',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select a section to view details',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Sections List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sections.length,
                  itemBuilder: (context, index) {
                    final section = sections[index];
                    final isSelected = selectedSection == section.label;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFFFD700).withOpacity(0.5)
                                    : Colors.white.withOpacity(0.1),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedSection = section.label;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          gradient: isSelected
                                              ? const LinearGradient(
                                                  colors: [
                                                    Color(0xFFFFD700),
                                                    Color(0xFFFFC107)
                                                  ],
                                                )
                                              : LinearGradient(
                                                  colors: [
                                                    Colors.white
                                                        .withOpacity(0.2),
                                                    Colors.white
                                                        .withOpacity(0.1),
                                                  ],
                                                ),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          section.icon,
                                          color: isSelected
                                              ? const Color(0xFF1B5E20)
                                              : Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              section.label,
                                              style: TextStyle(
                                                color: isSelected
                                                    ? const Color(0xFFFFD700)
                                                    : Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                section.floor,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: isSelected
                                            ? const Color(0xFFFFD700)
                                            : Colors.white54,
                                        size: 16,
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
                  },
                ),
              ),
            ],
          ),
        ),

        // Right Content - Section Detail
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: _buildSectionDetail(false),
                ),
                const BottomBar(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionDetail(bool isMobile) {
    final section = sections.firstWhere(
      (s) => s.label == selectedSection,
      orElse: () => sections[0],
    );

    return Container(
      constraints: const BoxConstraints(maxWidth: 900),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Virtual Tour Image with Glassmorphism
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: double.infinity,
                height: ResponsiveHelper.responsive(
                  context,
                  mobile: 250.0,
                  desktop: 500.0,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey[200]!,
                      Colors.grey[100]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF1B5E20).withOpacity(0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B5E20).withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.panorama,
                      size: ResponsiveHelper.responsive(
                        context,
                        mobile: 80.0,
                        desktop: 120.0,
                      ),
                      color: const Color(0xFF1B5E20).withOpacity(0.3),
                    ),
                    Positioned(
                      bottom: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1B5E20).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.touch_app,
                              color: Color(0xFFFFD700),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tap to view in virtual tour',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: ResponsiveHelper.responsive(
                                  context,
                                  mobile: 12.0,
                                  desktop: 14.0,
                                ),
                                fontWeight: FontWeight.w600,
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
          const SizedBox(height: 32),

          // Section Info Card
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
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
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF1B5E20).withOpacity(0.15),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
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
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1B5E20).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            section.icon,
                            color: const Color(0xFFFFD700),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                section.label,
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.responsive(
                                    context,
                                    mobile: 24.0,
                                    desktop: 32.0,
                                  ),
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1B5E20),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFFFD700).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFFFD700)
                                        .withOpacity(0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Floor ${section.floor}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 3,
                      width: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFC107)],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      section.description,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.responsive(
                          context,
                          mobile: 14.0,
                          desktop: 16.0,
                        ),
                        color: Colors.black87,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionItem {
  final String label;
  final String floor;
  final IconData icon;
  final String description;

  SectionItem({
    required this.label,
    required this.floor,
    required this.icon,
    required this.description,
  });
}
