import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:ndmu_libtour/user/widgets/top_bar.dart';
import 'package:ndmu_libtour/user/widgets/bottom_bar.dart';
import 'package:ndmu_libtour/utils/responsive_helper.dart';

class PoliciesScreen extends StatelessWidget {
  const PoliciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const TopBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(isMobile),
            _buildMainContent(isMobile),
            const BottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 40 : 60),
      decoration: const BoxDecoration(
        color: Color(0xFF1B5E20),
        image: DecorationImage(
          image: AssetImage('assets/images/school.jpg'),
          fit: BoxFit.cover,
          opacity: 0.2,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Library Policies',
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 32 : 42,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rules and Guidelines for Library Use',
            style: TextStyle(
              color: const Color(0xFFFFD700),
              fontSize: isMobile ? 16 : 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(bool isMobile) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      child: MaxWidthContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPolicyCard(
              icon: Icons.access_time,
              title: "Library Hours",
              content:
                  "The library is open Monday to Friday from 8:00 AM to 5:00 PM, and Saturday from 9:00 AM to 3:00 PM. The library is closed on Sundays and official university holidays... [Content Placeholder]",
              isMobile: isMobile,
            ),
            const SizedBox(height: 20),
            _buildPolicyCard(
              icon: Icons.book,
              title: "Borrowing Policies",
              content:
                  "Students and faculty members may borrow books using their valid university ID. The loan period is 7 days for students and 14 days for faculty members. Late returns are subject to fines... [Content Placeholder]",
              isMobile: isMobile,
            ),
            const SizedBox(height: 20),
            _buildPolicyCard(
              icon: Icons.computer,
              title: "Computer & Internet Use",
              content:
                  "Internet access is available for academic purposes only. Users must log in with their university credentials. Gaming, streaming, and downloading of large files are prohibited... [Content Placeholder]",
              isMobile: isMobile,
            ),
            const SizedBox(height: 20),
            _buildPolicyCard(
              icon: Icons.groups,
              title: "Conduct & Behavior",
              content:
                  "The library is a quiet study area. Please maintain silence in all reading rooms. Food and drinks are not allowed except in designated areas. Mobile phones must be on silent mode... [Content Placeholder]",
              isMobile: isMobile,
            ),
            const SizedBox(height: 20),
            _buildPolicyCard(
              icon: Icons.meeting_room,
              title: "Reservations & Study Rooms",
              content:
                  "Group study rooms can be reserved in advance through the library website or front desk. Maximum reservation time is 2 hours per group per day... [Content Placeholder]",
              isMobile: isMobile,
            ),
            const SizedBox(height: 20),
            _buildPolicyCard(
              icon: Icons.warning_amber_rounded,
              title: "Lost or Damaged Materials",
              content:
                  "Users are responsible for all materials borrowed. Lost or damaged items must be replaced or paid for at current market value plus processing fees... [Content Placeholder]",
              isMobile: isMobile,
            ),
            const SizedBox(height: 40),

            // Important Notice Box with Glassmorphism
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 24 : 32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFFFF3CD).withOpacity(0.9),
                        const Color(0xFFFFE082).withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        child: const Icon(
                          Icons.info_outline,
                          color: Color(0xFFFFD700),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Important Notice',
                              style: TextStyle(
                                fontSize: isMobile ? 18 : 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1B5E20),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Violation of library policies may result in suspension of library privileges. For complete policy details, please contact the library administration.',
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                color: const Color(0xFF5D4037),
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyCard({
    required IconData icon,
    required String title,
    required String content,
    required bool isMobile,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 24 : 28),
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
                      icon,
                      color: const Color(0xFFFFD700),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 16),
              Text(
                content,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  height: 1.6,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MaxWidthContainer extends StatelessWidget {
  final Widget child;
  const MaxWidthContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: child,
        ),
      );
}
