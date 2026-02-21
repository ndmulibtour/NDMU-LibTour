// lib/admin/services/analytics_data_service.dart
//
// Reads from Firestore analytics collections for the admin dashboard.
//
// Collections:
//   analytics/events/items/{auto}            ← raw event log
//   analytics/daily/dates/{YYYY-MM-DD}       ← pre-aggregated daily counters

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AnalyticsDataService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _events =>
      _db.collection('analytics').doc('events').collection('items');

  DocumentReference _daily(String date) =>
      _db.collection('analytics').doc('daily').collection('dates').doc(date);

  // ── Date helpers ───────────────────────────────────────────────────────────

  static String dateStr(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  // ── Single-day summary (real-time stream) ─────────────────────────────────

  Stream<Map<String, dynamic>> getDailySummary(String date) {
    return _daily(date).snapshots().map((snap) {
      return snap.exists ? (snap.data() as Map<String, dynamic>) : {};
    });
  }

  // ── Date-range summary (reads daily docs — cheap) ─────────────────────────

  Future<List<Map<String, dynamic>>> getDateRangeSummary(
      DateTime from, DateTime to) async {
    final results = <Map<String, dynamic>>[];
    var current = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);

    while (!current.isAfter(end)) {
      try {
        final snap = await _daily(dateStr(current)).get();
        final data = snap.exists
            ? (snap.data() as Map<String, dynamic>)
            : <String, dynamic>{};
        results.add({
          'date': dateStr(current),
          ...data,
        });
      } catch (e) {
        debugPrint('getDateRangeSummary error for ${dateStr(current)}: $e');
        results.add({'date': dateStr(current)});
      }
      current = current.add(const Duration(days: 1));
    }
    return results;
  }

  // ── Total KPI values across a date range ──────────────────────────────────

  Future<Map<String, int>> getRangeTotals(DateTime from, DateTime to) async {
    final days = await getDateRangeSummary(from, to);
    final totals = <String, int>{};

    for (final day in days) {
      day.forEach((key, value) {
        if (key == 'date') return;
        if (value is int) {
          totals[key] = (totals[key] ?? 0) + value;
        }
      });
    }
    return totals;
  }

  // ── Recent events stream (live-updating) ──────────────────────────────────

  Stream<List<Map<String, dynamic>>> getRecentEvents({int limit = 20}) {
    return _events
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
            .toList());
  }

  // ── Section view counts across a date range ───────────────────────────────
  // Reads from daily aggregated docs to avoid expensive collection scans.

  Future<Map<String, int>> getSectionViewCounts(
      DateTime from, DateTime to) async {
    final days = await getDateRangeSummary(from, to);
    final counts = <String, int>{};

    for (final day in days) {
      day.forEach((key, value) {
        if (key.startsWith('sectionViews_') && value is int) {
          final sectionId = key.replaceFirst('sectionViews_', '');
          counts[sectionId] = (counts[sectionId] ?? 0) + value;
        }
      });
    }
    return counts;
  }

  // ── Hourly distribution (peak hours) ──────────────────────────────────────

  Future<Map<int, int>> getHourlyDistribution(
      DateTime from, DateTime to) async {
    final days = await getDateRangeSummary(from, to);
    final counts = <int, int>{for (var h = 0; h < 24; h++) h: 0};

    for (final day in days) {
      day.forEach((key, value) {
        if (key.startsWith('hourly_') && value is int) {
          final hour = int.tryParse(key.replaceFirst('hourly_', ''));
          if (hour != null) {
            counts[hour] = (counts[hour] ?? 0) + value;
          }
        }
      });
    }
    return counts;
  }

  // ── User type / subtype breakdown ─────────────────────────────────────────

  Future<Map<String, int>> getUserTypeBreakdown(
      DateTime from, DateTime to) async {
    final totals = await getRangeTotals(from, to);
    final result = <String, int>{};

    final subtypes = [
      'Student',
      'Faculty',
      'Staff',
      'Researcher',
      'Visitor',
      'Other Institution'
    ];

    for (final sub in subtypes) {
      final key = 'userSubtype_$sub';
      if (totals.containsKey(key)) {
        result[sub] = totals[key]!;
      }
    }
    return result;
  }

  // ── Virtual tour scene visit counts ───────────────────────────────────────

  Future<Map<String, int>> getTourSceneCounts(
      DateTime from, DateTime to) async {
    final days = await getDateRangeSummary(from, to);
    final counts = <String, int>{};

    for (final day in days) {
      day.forEach((key, value) {
        if (key.startsWith('tourScene_') && value is int) {
          final sceneId = key.replaceFirst('tourScene_', '');
          counts[sceneId] = (counts[sceneId] ?? 0) + value;
        }
      });
    }
    return counts;
  }
}
