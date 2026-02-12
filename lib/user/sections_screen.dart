import 'package:flutter/material.dart';
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
    SectionItem(label: 'Entrance', floor: '1F'),
    SectionItem(label: 'CSCAM', floor: '1F'),
    SectionItem(label: 'Law Library', floor: '1F'),
    SectionItem(label: 'Graduate School', floor: '1F'),
    SectionItem(label: 'EMC', floor: '1F'),
    SectionItem(label: 'Filipiniana', floor: '2F'),
    SectionItem(label: 'Internet Section', floor: '2F'),
    SectionItem(label: 'Technical Section', floor: '2F'),
    SectionItem(label: 'Director\'s Office', floor: '2F'),
    SectionItem(label: 'Main Section', floor: '3F'),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: const TopBar(),
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Sections List Header with compact buttons
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF1B5E20),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Library Sections',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Divider(
                  color: Colors.white,
                  thickness: 1,
                  height: 32,
                ),

                // Compact Section Buttons in Two Columns
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _buildCompactButton(sections[0]), // Entrance
                          const SizedBox(height: 8),
                          _buildCompactButton(sections[1]), // CSCAM
                          const SizedBox(height: 8),
                          _buildCompactButton(sections[2]), // Law Library
                          const SizedBox(height: 8),
                          _buildCompactButton(sections[3]), // Graduate School
                          const SizedBox(height: 8),
                          _buildCompactButton(sections[4]), // EMC
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          _buildCompactButton(sections[5]), // Filipiniana
                          const SizedBox(height: 8),
                          _buildCompactButton(sections[6]), // Internet Section
                          const SizedBox(height: 8),
                          _buildCompactButton(sections[7]), // Technical Section
                          const SizedBox(height: 8),
                          _buildCompactButton(sections[8]), // Director's Office
                          const SizedBox(height: 8),
                          _buildCompactButton(sections[9]), // Main Section
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Selected Section Detail
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildSectionDetail(),
          ),

          // Bottom Bar
          const BottomBar(),
        ],
      ),
    );
  }

  Widget _buildCompactButton(SectionItem section) {
    final isSelected = selectedSection == section.label;

    return InkWell(
      onTap: () {
        setState(() {
          selectedSection = section.label;
        });
      },
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.white.withOpacity(0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: Colors.white.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: Colors.white.withOpacity(0.25),
              child: Text(
                section.floor,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                section.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              // Left Sidebar - Sections List
              Container(
                width: 280,
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 0, 55, 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(2, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 15, 24, 15),
                      child: const Text(
                        'Library Sections',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 1),

                    // Sections List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        itemCount: sections.length,
                        itemBuilder: (context, index) {
                          final section = sections[index];
                          final isSelected = selectedSection == section.label;

                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white24
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.white24,
                                child: Text(
                                  section.floor,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              title: Text(
                                section.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  selectedSection = section.label;
                                });
                              },
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
                        child: _buildSectionDetail(),
                      ),
                      const BottomBar(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionDetail() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 900),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Virtual Tour Image Placeholder
          Container(
            width: double.infinity,
            height: ResponsiveHelper.responsive(
              context,
              mobile: 250.0,
              desktop: 500.0,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
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
                  color: Colors.grey[400],
                ),
                Positioned(
                  bottom: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.touch_app,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tap the image to view in virtual tour',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: ResponsiveHelper.responsive(
                              context,
                              mobile: 12.0,
                              desktop: 14.0,
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Section Title
          Text(
            'Library $selectedSection',
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
          const SizedBox(height: 16),

          // Section Description
          Text(
            '[Description text about circulation desk services and location]',
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
    );
  }
}

class SectionItem {
  final String label;
  final String floor;

  SectionItem({required this.label, required this.floor});
}
