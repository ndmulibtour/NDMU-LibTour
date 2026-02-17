import 'package:flutter/material.dart';
import 'package:ndmu_libtour/user/widgets/top_bar.dart';
import 'package:ndmu_libtour/user/widgets/bottom_bar.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildMainContent(),
            const BottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: const BoxDecoration(
        color: Color(0xFF1B5E20),
        image: DecorationImage(
          image: AssetImage('assets/images/school.jpg'), // Optional background
          fit: BoxFit.cover,
          opacity: 0.2,
        ),
      ),
      child: const Column(
        children: [
          Text(
            'About the Library',
            style: TextStyle(
                color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Excellence in Information Service since 1954',
            style: TextStyle(color: Color(0xFFFFD700), fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: MaxWidthContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section("Mission & Vision",
                "To provide quality library services and resources that support the university's mission of academic excellence and spiritual growth... [Content Placeholder]"),
            const SizedBox(height: 40),
            _section("Historical Background",
                "The NDMU Library has evolved from a small collection of books to a modern information center... [Content Placeholder]"),
            const SizedBox(height: 40),
            const Text("Library Staff",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20))),
            const SizedBox(height: 20),
            // Placeholder for staff grid
            const Placeholder(fallbackHeight: 200, color: Color(0xFFE0E0E0)),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20))),
        const Divider(color: Color(0xFFFFD700), thickness: 2, endIndent: 100),
        const SizedBox(height: 16),
        Text(content, style: const TextStyle(fontSize: 16, height: 1.6)),
      ],
    );
  }
}

class MaxWidthContainer extends StatelessWidget {
  final Widget child;
  const MaxWidthContainer({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Center(
      child: Container(
          constraints: const BoxConstraints(maxWidth: 1000), child: child));
}
