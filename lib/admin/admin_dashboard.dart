// lib/admin/admin_dashboard.dart
//
// Task 5 changes:
//   • Removed "Content Management" section from _sections list
//   • Removed ContentManagement widget class entirely
//   • Added "About Management" section → AboutManagementScreen()
//   • Added "Policy Management" section → PolicyManagementScreen()
//   • StaffManagementPage now imported from its own file (Task 4)
//   • Unused import of create_account_screen.dart removed

import 'package:flutter/material.dart';
import 'package:ndmu_libtour/admin/screens/about_management_screen.dart';
import 'package:ndmu_libtour/admin/screens/contact_management_screen.dart';
import 'package:ndmu_libtour/admin/screens/feedback_management_screen.dart';
import 'package:ndmu_libtour/admin/screens/policy_management_screen.dart';
import 'package:ndmu_libtour/admin/screens/section_management_screen.dart';
import 'package:ndmu_libtour/admin/screens/settings_page.dart';
// Task 4 — StaffManagementPage moved to its own file
import 'package:ndmu_libtour/admin/screens/staff_management_screen.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'screens/faq_management_screen.dart';

// ── Breakpoint matching ResponsiveHelper.isDesktop (>= 1024) ────────────────
const double _kSidebarBreakpoint = 1024.0;
const double _kSidebarWidth = 280.0;

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  // ── Task 5 — sidebar section list ─────────────────────────────────────────
  // • "Content Management" section REMOVED (and its widget class deleted)
  // • "About Management"  ADDED  → AboutManagementScreen()  Icons.info_outline
  // • "Policy Management" ADDED  → PolicyManagementScreen() Icons.policy
  // • "Staff Management"  still present, now imported from staff_management_screen.dart
  final List<DashboardSection> _sections = [
    DashboardSection(
      title: 'Dashboard',
      icon: Icons.dashboard,
      widget: const DashboardOverview(),
    ),
    // ── New direct content screens (Task 5) ──────────────────────────────────
    DashboardSection(
      title: 'About Management',
      icon: Icons.info_outline,
      widget: const AboutManagementScreen(),
    ),
    DashboardSection(
      title: 'Policy Management',
      icon: Icons.policy,
      widget: const PolicyManagementScreen(),
    ),
    // ── Unchanged sections ───────────────────────────────────────────────────
    DashboardSection(
      title: 'Section Management',
      icon: Icons.library_books,
      widget: const SectionManagementScreen(),
    ),
    DashboardSection(
      title: 'FAQ Management',
      icon: Icons.question_answer,
      widget: const FAQManagementScreen(),
    ),
    DashboardSection(
      title: 'Feedback Management',
      icon: Icons.feedback,
      widget: const FeedbackManagementScreen(),
    ),
    DashboardSection(
      title: 'Contact Management',
      icon: Icons.contact_mail,
      widget: const ContactManagementScreen(),
    ),
    DashboardSection(
      title: 'Analytics & Reports',
      icon: Icons.analytics,
      widget: const AnalyticsReports(),
    ),
    // Task 4 — StaffManagementPage now comes from staff_management_screen.dart
    DashboardSection(
      title: 'Staff Management',
      icon: Icons.manage_accounts,
      widget: const StaffManagementPage(),
    ),
    DashboardSection(
      title: 'Settings',
      icon: Icons.settings,
      widget: const SettingsPage(),
    ),
  ];

  // ── Selects a section and closes the drawer on mobile ────────────────────
  void _selectSection(int index) {
    setState(() => _selectedIndex = index);
    final scaffoldState = Scaffold.maybeOf(context);
    if (scaffoldState != null && scaffoldState.isDrawerOpen) {
      scaffoldState.closeDrawer();
    }
  }

  // ── Sidebar content — shared between Drawer and permanent column ──────────
  Widget _buildSidebarContent(AuthService authService) {
    final user = authService.user;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/images/ndmu_logo.png',
                    height: 60,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.school, size: 48, color: Colors.white),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'NDMU Libtour',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                user?.displayName ?? 'Admin Name',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Library Administrator',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),

        const Divider(color: Colors.white24),

        // Menu items
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _sections.length,
            itemBuilder: (context, index) {
              final section = _sections[index];
              final isSelected = _selectedIndex == index;
              final isStaffSection = section.title == 'Staff Management';

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white24 : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isStaffSection
                      ? Border.all(
                          color: const Color(0xFFFFD700).withOpacity(0.4),
                          width: 1,
                        )
                      : null,
                ),
                child: ListTile(
                  leading: Icon(
                    section.icon,
                    color:
                        isStaffSection ? const Color(0xFFFFD700) : Colors.white,
                  ),
                  title: Text(
                    section.title,
                    style: TextStyle(
                      color: isStaffSection
                          ? const Color(0xFFFFD700)
                          : Colors.white,
                      fontWeight:
                          isStaffSection ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  onTap: () => _selectSection(index),
                ),
              );
            },
          ),
        ),

        const Divider(color: Colors.white24),

        // Logout
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.white),
          title: const Text('Logout', style: TextStyle(color: Colors.white)),
          onTap: () async {
            await authService.signOut();
            if (!mounted) return;
            Navigator.pushReplacementNamed(context, '/');
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= _kSidebarBreakpoint;

    final sidebar = Container(
      width: _kSidebarWidth,
      color: const Color(0xFF1B5E20),
      child: _buildSidebarContent(authService),
    );

    if (isDesktop) {
      // Desktop: permanent sidebar
      return Scaffold(
        body: Row(
          children: [
            sidebar,
            Expanded(
              child: _sections[_selectedIndex].widget,
            ),
          ],
        ),
      );
    }

    // Mobile/Tablet: AppBar + Drawer
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _sections[_selectedIndex].title,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              await authService.signOut();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: const Color(0xFF1B5E20),
          child: _buildSidebarContent(authService),
        ),
      ),
      body: _sections[_selectedIndex].widget,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class DashboardSection {
  final String title;
  final IconData icon;
  final Widget widget;
  DashboardSection(
      {required this.title, required this.icon, required this.widget});
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTE (Task 5): ContentManagement class has been DELETED from this file.
//   It was the "hub" widget that offered cards linking to About, Policies,
//   FAQ, Contact, and Sections.  Those screens are now reachable directly
//   from the sidebar, so the hub is no longer needed.
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// NOTE (Task 4): StaffManagementPage and _StaffManagementPageState have been
//   moved to lib/admin/screens/staff_management_screen.dart and are imported
//   at the top of this file.
// ─────────────────────────────────────────────────────────────────────────────

class DashboardOverview extends StatelessWidget {
  const DashboardOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dashboard Overview',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildStatCard('Total Visits', '0', Icons.visibility),
              _buildStatCard('New Feedback', '0', Icons.feedback),
              _buildStatCard('Avg. Time Spent', '0 min', Icons.timer),
              _buildStatCard('Tour Completion', '0%', Icons.check_circle),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildChartCard('Weekly Visitor Trends')),
                const SizedBox(width: 16),
                Expanded(child: _buildChartCard('Most Visited Sections')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Recent Feedback',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  Center(child: Text('No feedback yet')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF1B5E20), size: 32),
            const SizedBox(height: 12),
            Text(value,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title,
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(String title) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child:
                    Icon(Icons.bar_chart, size: 100, color: Colors.grey[300]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class AnalyticsReports extends StatelessWidget {
  const AnalyticsReports({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Analytics & Reports',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          Expanded(
            child: Center(
              child: Text('Analytics visualization coming soon',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            ),
          ),
        ],
      ),
    );
  }
}
