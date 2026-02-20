import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

// ─── Icon Name Map ────────────────────────────────────────────────────────────
// Firestore stores icon names as strings. Use this map to convert them back
// to IconData on the user side.
// To add new icons: add an entry here and reference the string in the Admin UI.

import 'package:flutter/material.dart';

const Map<String, IconData> kIconNameMap = {
  'access_time': Icons.access_time,
  'book': Icons.book,
  'computer': Icons.computer,
  'groups': Icons.groups,
  'meeting_room': Icons.meeting_room,
  'warning_amber_rounded': Icons.warning_amber_rounded,
  'info_outline': Icons.info_outline,
  'local_library': Icons.local_library,
  'wifi': Icons.wifi,
  'print': Icons.print,
  'no_food': Icons.no_food,
  'volume_off': Icons.volume_off,
  'badge': Icons.badge,
  'school': Icons.school,
  'rule': Icons.rule,
};

IconData iconFromName(String name) =>
    kIconNameMap[name] ?? Icons.article_outlined;

// ─── PolicyItem ───────────────────────────────────────────────────────────────

class PolicyItem {
  final String id;
  final String title;
  final String iconName; // stored as string, e.g. "access_time"
  final String contentJson; // Flutter Quill delta JSON
  final int order;
  final DateTime updatedAt;

  PolicyItem({
    required this.id,
    required this.title,
    required this.iconName,
    required this.contentJson,
    required this.order,
    required this.updatedAt,
  });

  IconData get icon => iconFromName(iconName);

  /// Safe parse of Quill delta JSON
  List<dynamic> get deltaJson {
    try {
      if (contentJson.isEmpty)
        return [
          {'insert': '\n'}
        ];
      final decoded = jsonDecode(contentJson);
      return decoded is List
          ? decoded
          : [
              {'insert': '\n'}
            ];
    } catch (_) {
      return [
        {'insert': contentJson.isEmpty ? '\n' : contentJson}
      ];
    }
  }

  /// Plain text preview (for admin list tiles)
  String get plainText {
    try {
      return deltaJson
          .where((op) => op['insert'] is String)
          .map((op) => op['insert'] as String)
          .join('')
          .trim();
    } catch (_) {
      return '';
    }
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'iconName': iconName,
        'contentJson': contentJson,
        'order': order,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory PolicyItem.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return PolicyItem(
      id: id,
      title: map['title'] ?? '',
      iconName: map['iconName'] ?? 'article_outlined',
      contentJson: map['contentJson'] ?? '',
      order: map['order'] ?? 0,
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  PolicyItem copyWith({
    String? id,
    String? title,
    String? iconName,
    String? contentJson,
    int? order,
    DateTime? updatedAt,
  }) =>
      PolicyItem(
        id: id ?? this.id,
        title: title ?? this.title,
        iconName: iconName ?? this.iconName,
        contentJson: contentJson ?? this.contentJson,
        order: order ?? this.order,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

// ─── StaffMember ──────────────────────────────────────────────────────────────

class StaffMember {
  final String id;
  final String name;
  final String position;
  final String? imageUrl; // from ImgBB
  final int order;
  final DateTime updatedAt;

  StaffMember({
    required this.id,
    required this.name,
    required this.position,
    this.imageUrl,
    required this.order,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'position': position,
        'imageUrl': imageUrl,
        'order': order,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory StaffMember.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return StaffMember(
      id: id,
      name: map['name'] ?? '',
      position: map['position'] ?? '',
      imageUrl: map['imageUrl'],
      order: map['order'] ?? 0,
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  StaffMember copyWith({
    String? id,
    String? name,
    String? position,
    String? imageUrl,
    int? order,
    DateTime? updatedAt,
  }) =>
      StaffMember(
        id: id ?? this.id,
        name: name ?? this.name,
        position: position ?? this.position,
        imageUrl: imageUrl ?? this.imageUrl,
        order: order ?? this.order,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

// ─── AboutData ────────────────────────────────────────────────────────────────
// Single-document model stored at content/about/info

class AboutData {
  final String missionJson; // Quill delta JSON
  final String historyJson; // Quill delta JSON
  final DateTime updatedAt;

  AboutData({
    required this.missionJson,
    required this.historyJson,
    required this.updatedAt,
  });

  List<dynamic> get missionDelta {
    try {
      if (missionJson.isEmpty)
        return [
          {'insert': '\n'}
        ];
      final d = jsonDecode(missionJson);
      return d is List
          ? d
          : [
              {'insert': '\n'}
            ];
    } catch (_) {
      return [
        {'insert': '\n'}
      ];
    }
  }

  List<dynamic> get historyDelta {
    try {
      if (historyJson.isEmpty)
        return [
          {'insert': '\n'}
        ];
      final d = jsonDecode(historyJson);
      return d is List
          ? d
          : [
              {'insert': '\n'}
            ];
    } catch (_) {
      return [
        {'insert': '\n'}
      ];
    }
  }

  Map<String, dynamic> toMap() => {
        'missionJson': missionJson,
        'historyJson': historyJson,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory AboutData.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return AboutData(
      missionJson: map['missionJson'] ?? '',
      historyJson: map['historyJson'] ?? '',
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  static AboutData empty() => AboutData(
        missionJson: '',
        historyJson: '',
        updatedAt: DateTime.now(),
      );
}
