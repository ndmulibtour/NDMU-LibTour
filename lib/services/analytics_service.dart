// lib/services/analytics_service.dart
//
// Fire-and-forget analytics sink.
// All public methods are unawaited — they NEVER block the UI.
//
// Firestore layout:
//   analytics/events/items/{auto}          ← raw event log
//   analytics/daily/dates/{YYYY-MM-DD}     ← pre-aggregated daily counters
//
// ── Permission model ──────────────────────────────────────────────────────────
// Public visitors are unauthenticated. Firestore rules grant:
//   analytics/events/items   → allow create: if true   (anyone can log)
//   analytics/daily/dates    → allow create, update: if true
//   reads                    → isStaff() only  (admin dashboard)
// See firestore.rules.

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class AnalyticsService {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  // ── Firestore refs ─────────────────────────────────────────────────────────
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _events =>
      _db.collection('analytics').doc('events').collection('items');

  DocumentReference _daily(String date) =>
      _db.collection('analytics').doc('daily').collection('dates').doc(date);

  // ── Session / user-type helpers ────────────────────────────────────────────

  String get _sessionId {
    const key = 'ndmu_session_id';
    var id = html.window.sessionStorage[key];
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      html.window.sessionStorage[key] = id;
    }
    return id;
  }

  String get _userType =>
      html.window.localStorage['ndmu_user_type'] ?? 'unknown';

  String? get _userSubtype => html.window.localStorage['ndmu_user_subtype'];

  // ── Date helpers ───────────────────────────────────────────────────────────

  String _dateString(DateTime dt) => '${dt.year}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  // ── Base event document builder ────────────────────────────────────────────

  Map<String, dynamic> _baseEvent(String eventType) {
    final now = DateTime.now();
    return {
      'eventType': eventType,
      'userType': _userType,
      'userSubtype': _userSubtype,
      'sessionId': _sessionId,
      'timestamp': Timestamp.fromDate(now),
      'date': _dateString(now),
      'hour': now.hour,
    };
  }

  // ── Safe fire-and-forget wrappers ──────────────────────────────────────────
  //
  // FIX 1 — catchError return-type mismatch:
  //
  //   _events.add()  → Future<DocumentReference>
  //     The catchError handler MUST return DocumentReference (not void).
  //     We return _events.doc() — a valid stub ref — as the fallback.
  //
  //   _daily().set() → Future<void>
  //     The catchError handler must be void. We use an explicit typed
  //     parameter `(Object e)` so Dart does not infer a non-void return
  //     from debugPrint's void return — no return statement after the
  //     print keeps the handler correctly void-typed.

  void _addEvent(Map<String, dynamic> event, String tag) {
    _events.add(event).catchError((Object e) {
      if (kDebugMode) debugPrint('$tag error: $e'); // L-2: stripped in release
      return _events.doc();
    });
  }

  void _incrementDaily(String date, Map<String, dynamic> increments) {
    _daily(date)
        .set(increments, SetOptions(merge: true))
        .catchError((Object e) {
      if (kDebugMode) debugPrint('Analytics daily increment error: $e'); // L-2
    });
  }

  // ── Public tracking API ────────────────────────────────────────────────────

  /// Called in initState() of every user-facing screen.
  void logPageView(String pageName) {
    final now = DateTime.now();
    final date = _dateString(now);
    final ut = _userType;

    _addEvent(
      _baseEvent('page_view')..['pageName'] = pageName,
      'logPageView',
    );

    _incrementDaily(date, {
      'totalPageViews': FieldValue.increment(1),
      if (ut == 'internal') 'internalPageViews': FieldValue.increment(1),
      if (ut == 'external') 'externalPageViews': FieldValue.increment(1),
      if (ut == 'unknown') 'unknownPageViews': FieldValue.increment(1),
      'pageViews_$pageName': FieldValue.increment(1),
    });
  }

  /// Called when a user taps a section in the sections screen.
  void logSectionView(String sectionId, String sectionName) {
    final now = DateTime.now();
    final date = _dateString(now);
    final ut = _userType;

    _addEvent(
      _baseEvent('section_view')
        ..['sectionId'] = sectionId
        ..['sectionName'] = sectionName,
      'logSectionView',
    );

    _incrementDaily(date, {
      'totalSectionViews': FieldValue.increment(1),
      'sectionViews_$sectionId': FieldValue.increment(1),
      if (ut == 'internal')
        'internal_sectionViews_$sectionId': FieldValue.increment(1),
      if (ut == 'external')
        'external_sectionViews_$sectionId': FieldValue.increment(1),
    });
  }

  /// Called in initState() of VirtualTourScreen.
  void logVirtualTourEntry({String? sceneId, String? source}) {
    final now = DateTime.now();
    final date = _dateString(now);
    final ut = _userType;

    _addEvent(
      _baseEvent('tour_entry')
        ..['sceneId'] = sceneId ?? ''
        ..['source'] = source ?? 'unknown',
      'logVirtualTourEntry',
    );

    _incrementDaily(date, {
      'tourEntries': FieldValue.increment(1),
      'totalVisits': FieldValue.increment(1),
      if (ut == 'internal') 'internalVisits': FieldValue.increment(1),
      if (ut == 'external') 'externalVisits': FieldValue.increment(1),
      if (ut == 'unknown') 'unknownVisits': FieldValue.increment(1),
    });
  }

  /// Called inside the navigationStarted postMessage handler in VirtualTourScreen.
  void logVirtualTourSceneChange(String sceneId, String sceneName) {
    final now = DateTime.now();
    final date = _dateString(now);

    _addEvent(
      _baseEvent('tour_scene')
        ..['sceneId'] = sceneId
        ..['sceneName'] = sceneName,
      'logTourSceneChange',
    );

    _incrementDaily(date, {
      'tourSceneChanges': FieldValue.increment(1),
      'tourScene_$sceneId': FieldValue.increment(1),
    });
  }

  /// Called once from UserTypeDialog after the user makes their choice.
  void logUserClassified(String type, String subtype) {
    final now = DateTime.now();
    final date = _dateString(now);

    _addEvent(
      _baseEvent('user_classified')
        ..['classifiedType'] = type
        ..['classifiedSubtype'] = subtype,
      'logUserClassified',
    );

    _incrementDaily(date, {
      'userClassifications': FieldValue.increment(1),
      'userType_$type': FieldValue.increment(1),
      'userSubtype_$subtype': FieldValue.increment(1),
    });
  }

  /// Called once from HomeScreen to count a unique visit per session.
  void logUniqueVisit() {
    final now = DateTime.now();
    final date = _dateString(now);
    final ut = _userType;

    _addEvent(_baseEvent('visit'), 'logUniqueVisit');

    _incrementDaily(date, {
      'totalVisits': FieldValue.increment(1),
      if (ut == 'internal') 'internalVisits': FieldValue.increment(1),
      if (ut == 'external') 'externalVisits': FieldValue.increment(1),
      if (ut == 'unknown') 'unknownVisits': FieldValue.increment(1),
      'hourly_${now.hour}': FieldValue.increment(1),
    });
  }
}
