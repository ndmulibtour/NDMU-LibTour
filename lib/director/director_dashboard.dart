import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class DirectorDashboard extends StatefulWidget {
  const DirectorDashboard({super.key});

  @override
  State<DirectorDashboard> createState() => _DirectorDashboardState();
}

class _DirectorDashboardState extends State<DirectorDashboard> {
  int _selectedIndex = 0;

  final List<DirectorSection> _sections = [
    DirectorSection(
      title: 'Dashboard',
      icon: Icons.dashboard,
      widget: const DirectorOverview(),
    ),
    DirectorSection(
      title: 'View Feedbacks',
      icon: Icons.feedback,
      widget: const ViewFeedbacks(),
    ),
    DirectorSection(
      title: 'View Analytics',
      icon: Icons.analytics,
      widget: const ViewAnalytics(),
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
                        user?.displayName ?? 'Director Name',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Library Director',
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

class DirectorSection {
  final String title;
  final IconData icon;
  final Widget widget;

  DirectorSection({
    required this.title,
    required this.icon,
    required this.widget,
  });
}

class DirectorOverview extends StatelessWidget {
  const DirectorOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Dashboard Overview',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 6),
                    Text(
                      'Read-Only Access',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
              _buildStatCard(
                  'Satisfaction Rate', '0%', Icons.sentiment_satisfied),
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
                  child: _buildChartCard('User Satisfaction Ratings'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildChartCard('Performance Summary'),
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

class ViewFeedbacks extends StatelessWidget {
  const ViewFeedbacks({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'View Feedbacks',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 6),
                    Text(
                      'Read-Only',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'View user feedback and suggestions (Read-only access)',
            style: TextStyle(color: Colors.black54),
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
                              enabled: false,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.filter_list),
                          label: const Text('Filter'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.feedback_outlined,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No feedback yet',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
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
        ],
      ),
    );
  }
}

class ViewAnalytics extends StatelessWidget {
  const ViewAnalytics({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'View Analytics',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 6),
                    Text(
                      'Read-Only',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'View system analytics and user engagement data (Read-only access)',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 32),

          // Analytics Summary Cards
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildMetricCard('Page Views', '0', Icons.pageview, Colors.blue),
              _buildMetricCard(
                  'Unique Visitors', '0', Icons.people, Colors.green),
              _buildMetricCard(
                  'Avg. Session', '0:00', Icons.timer, Colors.orange),
              _buildMetricCard(
                  'Bounce Rate', '0%', Icons.exit_to_app, Colors.red),
            ],
          ),

          const SizedBox(height: 32),

          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Traffic Overview',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: Center(
                              child: Icon(
                                Icons.show_chart,
                                size: 100,
                                color: Colors.grey[300],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Top Pages',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: ListView(
                              children: const [
                                ListTile(
                                  leading: Icon(Icons.home),
                                  title: Text('Home'),
                                  trailing: Text('0 views'),
                                ),
                                ListTile(
                                  leading: Icon(Icons.threed_rotation),
                                  title: Text('Virtual Tour'),
                                  trailing: Text('0 views'),
                                ),
                                ListTile(
                                  leading: Icon(Icons.policy),
                                  title: Text('Policies'),
                                  trailing: Text('0 views'),
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
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
