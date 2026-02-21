// lib/admin/screens/analytics_screen.dart
//
// Admin Analytics Dashboard
// ─────────────────────────
// Sections:
//   1. Date-range selector (Today / This Week / This Month / Custom)
//   2. KPI row — Total Visits, Internal/External ratio, Most-viewed Section, Tour entry rate
//   3. Line chart (daily visits by user type) + Bar chart (peak hours)
//   4. Section popularity table + User-type donut chart
//   5. Virtual tour scene heatmap + Live event feed

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ndmu_libtour/admin/services/analytics_data_service.dart';
import 'package:ndmu_libtour/admin/services/section_service.dart';
import 'package:ndmu_libtour/admin/models/section_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ── Brand colours ─────────────────────────────────────────────────────────────
const _kGreen = Color(0xFF1B5E20);
const _kDarkGreen = Color(0xFF0D3F0F);
const _kGold = Color(0xFFFFD700);
const _kGoldLight = Color(0xFFFFC107);
const _kBg = Color(0xFFF4F6F0);

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final AnalyticsDataService _svc = AnalyticsDataService();
  final SectionService _sectionSvc = SectionService();

  // ── Date range ─────────────────────────────────────────────────────────────
  _DateRange _range = _DateRange.today;
  DateTime _customFrom = DateTime.now().subtract(const Duration(days: 7));
  DateTime _customTo = DateTime.now();

  // ── Loaded data ────────────────────────────────────────────────────────────
  bool _loading = true;
  Map<String, int> _totals = {};
  List<Map<String, dynamic>> _dailyData = [];
  Map<int, int> _hourly = {};
  Map<String, int> _sectionCounts = {};
  Map<String, int> _userSubtypes = {};
  Map<String, int> _sceneCounts = {};
  List<LibrarySection> _sections = [];

  @override
  void initState() {
    super.initState();
    _load();
    // Pre-load sections for name resolution
    _sectionSvc.getSections().first.then((s) {
      if (mounted) setState(() => _sections = s);
    });
  }

  DateTime get _from {
    final now = DateTime.now();
    switch (_range) {
      case _DateRange.today:
        return DateTime(now.year, now.month, now.day);
      case _DateRange.week:
        return now.subtract(Duration(days: now.weekday - 1));
      case _DateRange.month:
        return DateTime(now.year, now.month, 1);
      case _DateRange.custom:
        return _customFrom;
    }
  }

  DateTime get _to => _range == _DateRange.custom ? _customTo : DateTime.now();

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _svc.getRangeTotals(_from, _to),
        _svc.getDateRangeSummary(_from, _to),
        _svc.getHourlyDistribution(_from, _to),
        _svc.getSectionViewCounts(_from, _to),
        _svc.getUserTypeBreakdown(_from, _to),
        _svc.getTourSceneCounts(_from, _to),
      ]);

      if (!mounted) return;
      setState(() {
        _totals = results[0] as Map<String, int>;
        _dailyData = results[1] as List<Map<String, dynamic>>;
        _hourly = results[2] as Map<int, int>;
        _sectionCounts = results[3] as Map<String, int>;
        _userSubtypes = results[4] as Map<String, int>;
        _sceneCounts = results[5] as Map<String, int>;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      debugPrint('Analytics load error: $e');
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      child: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _kGreen))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── KPI row ──────────────────────────────────────
                        _buildKpiRow(),
                        const SizedBox(height: 24),

                        // ── Charts row ───────────────────────────────────
                        _buildSectionTitle('Visitor Trends'),
                        const SizedBox(height: 12),
                        _ResponsiveRow(children: [
                          _buildLineChart(),
                          _buildHourlyBarChart(),
                        ]),
                        const SizedBox(height: 24),

                        // ── Sections + donut ─────────────────────────────
                        _buildSectionTitle('Content Engagement'),
                        const SizedBox(height: 12),
                        _ResponsiveRow(children: [
                          _buildSectionTable(),
                          _buildUserDonut(),
                        ]),
                        const SizedBox(height: 24),

                        // ── Tour heatmap + live feed ─────────────────────
                        _buildSectionTitle('Virtual Tour & Live Activity'),
                        const SizedBox(height: 12),
                        _ResponsiveRow(children: [
                          _buildTourHeatmap(),
                          _buildLiveFeed(),
                        ]),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Row(
        children: [
          // Title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Analytics & Reports',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _kGreen)),
              Text(
                'Data from ${_fmtDate(_from)} to ${_fmtDate(_to)}',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          const Spacer(),

          // Date-range pills
          Wrap(
            spacing: 8,
            children: _DateRange.values.map((r) {
              final selected = _range == r;
              return GestureDetector(
                onTap: () async {
                  if (r == _DateRange.custom) {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                      initialDateRange:
                          DateTimeRange(start: _customFrom, end: _customTo),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: _kGreen, secondary: _kGold),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked == null) return;
                    _customFrom = picked.start;
                    _customTo = picked.end;
                  }
                  setState(() => _range = r);
                  _load();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? _kGreen : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: selected ? _kGreen : Colors.grey.shade300),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                                color: _kGreen.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ]
                        : [],
                  ),
                  child: Text(r.label,
                      style: TextStyle(
                          color: selected ? Colors.white : Colors.grey[700],
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ),
              );
            }).toList(),
          ),

          const SizedBox(width: 12),
          // Refresh button
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, color: _kGreen),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  // ── KPI cards ──────────────────────────────────────────────────────────────

  Widget _buildKpiRow() {
    final totalVisits = _totals['totalVisits'] ?? 0;
    final internal = _totals['internalVisits'] ?? 0;
    final external = _totals['externalVisits'] ?? 0;
    final tourEntries = _totals['tourEntries'] ?? 0;
    final entryRate = totalVisits > 0 ? (tourEntries / totalVisits * 100) : 0.0;

    // Most viewed section
    String topSectionName = '—';
    int topSectionCount = 0;
    if (_sectionCounts.isNotEmpty) {
      final topId = _sectionCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      topSectionCount = _sectionCounts[topId] ?? 0;
      topSectionName = _sections
          .firstWhere((s) => s.id == topId,
              orElse: () => LibrarySection(
                  id: '',
                  name: topId,
                  description: '',
                  floor: '',
                  order: 0,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now()))
          .name;
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _KpiCard(
          title: 'Total Visits',
          value: totalVisits.toString(),
          icon: Icons.people_rounded,
          color: _kGreen,
          subtitle: 'This period',
        ),
        _KpiCard(
          title: 'Internal / External',
          value: '$internal / $external',
          icon: Icons.compare_arrows_rounded,
          color: const Color(0xFF1565C0),
          subtitle: 'User type split',
          badge: totalVisits > 0
              ? '${(internal / totalVisits * 100).toStringAsFixed(0)}% int.'
              : null,
        ),
        _KpiCard(
          title: 'Top Section',
          value: topSectionName,
          icon: Icons.library_books_rounded,
          color: const Color(0xFF7B1FA2),
          subtitle: '$topSectionCount views',
          smallValue: true,
        ),
        _KpiCard(
          title: 'Tour Entry Rate',
          value: '${entryRate.toStringAsFixed(1)}%',
          icon: Icons.vrpano_rounded,
          color: const Color(0xFFE65100),
          subtitle: '$tourEntries entries',
        ),
      ],
    );
  }

  // ── Line chart — daily visits ──────────────────────────────────────────────

  Widget _buildLineChart() {
    return _ChartCard(
      title: 'Daily Visits by User Type',
      icon: Icons.show_chart_rounded,
      child: _dailyData.isEmpty
          ? _emptyChart('No visit data for this period')
          : _SimpleLineChart(
              days: _dailyData,
              internalKey: 'internalVisits',
              externalKey: 'externalVisits',
            ),
    );
  }

  // ── Bar chart — peak hours ─────────────────────────────────────────────────

  Widget _buildHourlyBarChart() {
    return _ChartCard(
      title: 'Peak Usage Hours',
      icon: Icons.bar_chart_rounded,
      child: _hourly.values.every((v) => v == 0)
          ? _emptyChart('No hourly data yet')
          : _SimpleBarChart(data: _hourly),
    );
  }

  // ── Section popularity table ───────────────────────────────────────────────

  Widget _buildSectionTable() {
    final sorted = _sectionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxCount = sorted.isEmpty ? 1 : sorted.first.value.clamp(1, 999999);

    return _ChartCard(
      title: 'Section Popularity',
      icon: Icons.leaderboard_rounded,
      child: sorted.isEmpty
          ? _emptyChart('No section views recorded')
          : Column(
              children: sorted.take(8).map((entry) {
                final section = _sections.firstWhere((s) => s.id == entry.key,
                    orElse: () => LibrarySection(
                        id: entry.key,
                        name: entry.key,
                        description: '',
                        floor: '?',
                        order: 0,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now()));
                final pct = entry.value / maxCount;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(section.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13),
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          Text('${entry.value}',
                              style: const TextStyle(
                                  color: _kGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct.toDouble(),
                          minHeight: 8,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation(_kGreen),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  // ── User type donut chart ──────────────────────────────────────────────────

  Widget _buildUserDonut() {
    return _ChartCard(
      title: 'User Roles',
      icon: Icons.donut_large_rounded,
      child: _userSubtypes.isEmpty || _userSubtypes.values.every((v) => v == 0)
          ? _emptyChart('No user classifications yet')
          : _DonutChart(data: _userSubtypes),
    );
  }

  // ── Tour scene heatmap ─────────────────────────────────────────────────────

  Widget _buildTourHeatmap() {
    final sorted = _sceneCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxV = sorted.isEmpty ? 1 : sorted.first.value.clamp(1, 999999);

    return _ChartCard(
      title: 'Virtual Tour Scenes',
      icon: Icons.vrpano_rounded,
      child: sorted.isEmpty
          ? _emptyChart('No tour scene data')
          : Column(
              children: sorted.take(8).map((entry) {
                final pct = entry.value / maxV;
                final warmth = (pct * 255).toInt();
                final barColor = Color.fromARGB(
                    255, warmth, (255 - warmth ~/ 2).clamp(0, 255), 0);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                                color: barColor, shape: BoxShape.circle),
                          ),
                          Expanded(
                            child: Text(entry.key,
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text('${entry.value}',
                              style: TextStyle(
                                  color: barColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct.toDouble(),
                          minHeight: 6,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation(barColor),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  // ── Live event feed ────────────────────────────────────────────────────────

  Widget _buildLiveFeed() {
    return _ChartCard(
      title: 'Live Activity Feed',
      icon: Icons.rss_feed_rounded,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 8, color: Colors.white),
            SizedBox(width: 4),
            Text('LIVE',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _svc.getRecentEvents(limit: 15),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: _kGreen),
            ));
          }
          final events = snap.data ?? [];
          if (events.isEmpty) {
            return _emptyChart('No events yet');
          }
          return Column(
            children: events.map((e) => _EventTile(event: e)).toList(),
          );
        },
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _emptyChart(String msg) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.bar_chart_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(msg,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
            width: 4,
            height: 20,
            color: _kGold,
            margin: const EdgeInsets.only(right: 10)),
        Text(title,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold, color: _kGreen)),
      ],
    );
  }

  static String _fmtDate(DateTime dt) => '${dt.month}/${dt.day}/${dt.year}';
}

// ─── Date range enum ──────────────────────────────────────────────────────────

enum _DateRange { today, week, month, custom }

extension _DateRangeExt on _DateRange {
  String get label {
    switch (this) {
      case _DateRange.today:
        return 'Today';
      case _DateRange.week:
        return 'This Week';
      case _DateRange.month:
        return 'This Month';
      case _DateRange.custom:
        return 'Custom';
    }
  }
}

// ─── KPI Card ─────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;
  final String? badge;
  final bool smallValue;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
    this.badge,
    this.smallValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(badge!,
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
                fontSize: smallValue ? 16 : 26,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900]),
            maxLines: smallValue ? 2 : 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(title,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey[400])),
        ],
      ),
    );
  }
}

// ─── Chart card wrapper ───────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _ChartCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: _kGreen, size: 18),
                ),
                const SizedBox(width: 10),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _kGreen)),
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ─── Simple line chart (custom painted — no fl_chart dep needed) ──────────────

class _SimpleLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> days;
  final String internalKey;
  final String externalKey;

  const _SimpleLineChart({
    required this.days,
    required this.internalKey,
    required this.externalKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        Row(
          children: [
            _LegendDot(color: _kGreen, label: 'Internal'),
            const SizedBox(width: 16),
            _LegendDot(color: _kGold, label: 'External'),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: CustomPaint(
            painter: _LineChartPainter(
              days: days,
              internalKey: internalKey,
              externalKey: externalKey,
            ),
            size: Size.infinite,
          ),
        ),
        const SizedBox(height: 8),
        // X labels — show first, middle, last
        if (days.length >= 2)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _axisLabel(days.first['date'] as String? ?? ''),
              if (days.length > 2)
                _axisLabel(days[days.length ~/ 2]['date'] as String? ?? ''),
              _axisLabel(days.last['date'] as String? ?? ''),
            ],
          ),
      ],
    );
  }

  Widget _axisLabel(String date) {
    final parts = date.split('-');
    final label = parts.length >= 3 ? '${parts[1]}/${parts[2]}' : date;
    return Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500]));
  }
}

class _LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> days;
  final String internalKey;
  final String externalKey;

  _LineChartPainter({
    required this.days,
    required this.internalKey,
    required this.externalKey,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (days.isEmpty) return;

    int _val(Map m, String key) {
      final v = m[key];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return 0;
    }

    final maxVal = days
        .map((d) => math.max(_val(d, internalKey), _val(d, externalKey)))
        .reduce(math.max)
        .clamp(1, 999999);

    final gridPaint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 1;

    // Horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final y = size.height - (i / 4) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    void drawLine(String key, Color color) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      for (int i = 0; i < days.length; i++) {
        final x = i / (days.length - 1).clamp(1, 999999) * size.width;
        final y = size.height - (_val(days[i], key) / maxVal * size.height);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);

      // Dots
      final dotPaint = Paint()..color = color;
      for (int i = 0; i < days.length; i++) {
        if (days.length > 14 && i % 3 != 0)
          continue; // Skip dots for dense charts
        final x = i / (days.length - 1).clamp(1, 999999) * size.width;
        final y = size.height - (_val(days[i], key) / maxVal * size.height);
        canvas.drawCircle(Offset(x, y), 3, dotPaint);
      }
    }

    drawLine(externalKey, _kGold);
    drawLine(internalKey, _kGreen);
  }

  @override
  bool shouldRepaint(_LineChartPainter old) => old.days != days;
}

// ─── Simple bar chart (custom painted) ───────────────────────────────────────

class _SimpleBarChart extends StatelessWidget {
  final Map<int, int> data;
  const _SimpleBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 160,
          child: CustomPaint(
            painter: _BarChartPainter(data: data),
            size: Size.infinite,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [0, 6, 12, 18, 23]
              .map((h) => Text('${h}h',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500])))
              .toList(),
        ),
      ],
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final Map<int, int> data;
  const _BarChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = data.values.reduce(math.max).clamp(1, 999999);
    const barCount = 24;
    final barWidth = size.width / barCount - 2;

    for (int h = 0; h < barCount; h++) {
      final count = data[h] ?? 0;
      final barHeight = (count / maxVal) * size.height;
      final x = h / barCount * size.width + 1;
      final y = size.height - barHeight;

      // colour gradient: low = light green, high = gold
      final ratio = count / maxVal;
      final barColor = Color.lerp(_kGreen.withOpacity(0.3), _kGold, ratio)!;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(3),
        ),
        Paint()..color = barColor,
      );
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) => old.data != data;
}

// ─── Donut chart (custom painted) ────────────────────────────────────────────

class _DonutChart extends StatelessWidget {
  final Map<String, int> data;
  const _DonutChart({required this.data});

  static const _colors = [
    Color(0xFF1B5E20),
    Color(0xFFFFD700),
    Color(0xFF1565C0),
    Color(0xFF7B1FA2),
    Color(0xFFE65100),
    Color(0xFF00838F),
  ];

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold(0, (a, b) => a + b).clamp(1, 999999);
    final entries = data.entries.toList();

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: CustomPaint(
            painter: _DonutPainter(data: data, colors: _colors),
            size: Size.infinite,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: entries.asMap().entries.map((e) {
            final color = _colors[e.key % _colors.length];
            final pct = (e.value.value / total * 100).toStringAsFixed(0);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: color, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 4),
                Text('${e.value.key} ($pct%)',
                    style: const TextStyle(fontSize: 11)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final Map<String, int> data;
  final List<Color> colors;
  const _DonutPainter({required this.data, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.values.fold(0, (a, b) => a + b).clamp(1, 999999);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    var startAngle = -math.pi / 2;
    int i = 0;

    for (final entry in data.entries) {
      if (entry.value == 0) {
        i++;
        continue;
      }
      final sweep = entry.value / total * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        Paint()
          ..color = colors[i % colors.length]
          ..strokeWidth = 28
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.butt,
      );
      // Small gap
      startAngle += sweep + 0.03;
      i++;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.data != data;
}

// ─── Live event tile ──────────────────────────────────────────────────────────

class _EventTile extends StatelessWidget {
  final Map<String, dynamic> event;
  const _EventTile({required this.event});

  static const _eventIcons = {
    'page_view': Icons.pageview_rounded,
    'section_view': Icons.library_books_rounded,
    'tour_entry': Icons.vrpano_rounded,
    'tour_scene': Icons.place_rounded,
    'user_classified': Icons.person_rounded,
    'visit': Icons.login_rounded,
  };

  static const _eventColors = {
    'page_view': Color(0xFF1565C0),
    'section_view': _kGreen,
    'tour_entry': Color(0xFFE65100),
    'tour_scene': Color(0xFF7B1FA2),
    'user_classified': _kGold,
    'visit': Color(0xFF00838F),
  };

  @override
  Widget build(BuildContext context) {
    final type = event['eventType'] as String? ?? 'unknown';
    final userType = event['userType'] as String? ?? 'unknown';
    final icon = _eventIcons[type] ?? Icons.circle_rounded;
    final color = _eventColors[type] ?? Colors.grey;

    String label = type.replaceAll('_', ' ');
    if (type == 'section_view') {
      label = event['sectionName'] as String? ?? label;
    } else if (type == 'tour_scene') {
      label = event['sceneName'] as String? ?? label;
    } else if (type == 'page_view') {
      label = 'Viewed: ${event['pageName'] ?? ''}';
    }

    final ts = event['timestamp'];
    String timeAgo = '';
    if (ts is Timestamp) {
      final diff = DateTime.now().difference(ts.toDate());
      if (diff.inSeconds < 60) {
        timeAgo = '${diff.inSeconds}s ago';
      } else if (diff.inMinutes < 60) {
        timeAgo = '${diff.inMinutes}m ago';
      } else {
        timeAgo = '${diff.inHours}h ago';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                Row(
                  children: [
                    _UserBadge(userType: userType),
                    const SizedBox(width: 6),
                    Text(timeAgo,
                        style:
                            TextStyle(fontSize: 10, color: Colors.grey[500])),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserBadge extends StatelessWidget {
  final String userType;
  const _UserBadge({required this.userType});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (userType) {
      'internal' => (const Color(0xFF1B5E20), 'Internal'),
      'external' => (const Color(0xFF1565C0), 'External'),
      _ => (Colors.grey, 'Unknown'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}

// ─── Legend dot ───────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
      ],
    );
  }
}

// ─── Responsive two-column row ────────────────────────────────────────────────

class _ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  const _ResponsiveRow({required this.children});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1200) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children
            .map((c) => Expanded(child: c))
            .toList()
            .expand((w) => [w, const SizedBox(width: 16)])
            .toList()
          ..removeLast(),
      );
    }
    return Column(
      children: children.expand((c) => [c, const SizedBox(height: 16)]).toList()
        ..removeLast(),
    );
  }
}
