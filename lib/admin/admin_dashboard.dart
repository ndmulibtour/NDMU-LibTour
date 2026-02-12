import 'package:flutter/material.dart';
import 'package:ndmu_libtour/admin/screens/contact_management_screen.dart';
import 'package:ndmu_libtour/admin/screens/feedback_management_screen.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'screens/faq_management_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<DashboardSection> _sections = [
    DashboardSection(
      title: 'Dashboard',
      icon: Icons.dashboard,
      widget: const DashboardOverview(),
    ),
    DashboardSection(
      title: 'Content Management',
      icon: Icons.edit,
      widget: const ContentManagement(),
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
    DashboardSection(
      title: 'Settings',
      icon: Icons.settings,
      widget: const SettingsPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            color: const Color(0xFF1B5E20),
            child: Column(
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
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.school,
                                  size: 48, color: Colors.white);
                            },
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
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white24,
                        child: const Icon(Icons.person,
                            size: 40, color: Colors.white),
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
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(color: Colors.white24),

                // Menu Items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _sections.length,
                    itemBuilder: (context, index) {
                      final section = _sections[index];
                      final isSelected = _selectedIndex == index;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? Colors.white24 : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: Icon(
                            section.icon,
                            color: Colors.white,
                          ),
                          title: Text(
                            section.title,
                            style: const TextStyle(color: Colors.white),
                          ),
                          selected: isSelected,
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),

                const Divider(color: Colors.white24),

                // Logout Button
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    await authService.signOut();
                    if (!mounted) return;
                    Navigator.pushReplacementNamed(context, '/');
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: _sections[_selectedIndex].widget,
          ),
        ],
      ),
    );
  }
}

class DashboardSection {
  final String title;
  final IconData icon;
  final Widget widget;

  DashboardSection({
    required this.title,
    required this.icon,
    required this.widget,
  });
}

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
          const Text(
            'Dashboard Overview',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),

          // Stats Cards
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

          // Charts
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildChartCard('Weekly Visitor Trends'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildChartCard('Most Visited Sections'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Recent Feedback
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Feedback',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('[List of recent feedbacks]'),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black87,
                      ),
                      child: const Text('View all feedbacks'),
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

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Icon(icon, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Icon(
                  Icons.bar_chart,
                  size: 100,
                  color: Colors.grey[300],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContentManagement extends StatelessWidget {
  const ContentManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Content Management',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
              'Manage library policies, services, FAQ, and multimedia content'),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildContentCard('Library Policies', Icons.policy),
                _buildContentCard('Library Services', Icons.room_service),
                _buildContentCard('FAQ Management', Icons.question_answer),
                _buildContentCard('360° Tour Settings', Icons.threed_rotation),
                _buildContentCard('Contact Information', Icons.contact_mail),
                _buildContentCard('Media Gallery', Icons.photo_library),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(String title, IconData icon) {
    return Card(
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: const Color(0xFF1B5E20)),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeedbackManagement extends StatelessWidget {
  const FeedbackManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Feedback Management',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search feedback...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.filter_list),
                          label: const Text('Filter'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Expanded(
                      child: Center(
                        child: Text('No feedback yet'),
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
          const Text(
            'Analytics & Reports',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Center(
              child: Text(
                'Analytics visualization coming soon',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile Settings'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Security'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
