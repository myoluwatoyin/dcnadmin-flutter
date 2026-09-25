import 'package:cloud_firestore/cloud_firestore.dart';

/// A worker's weekly Bible + prayer report entry.
class WeeklyReport {
  const WeeklyReport({
    required this.id,
    required this.weekLabel,
    required this.submitted,
    this.bible = '',
    this.prayer = '',
    this.weekNumber,
    this.createdAt,
  });

  final String id;
  final String weekLabel;
  final bool submitted;
  final String bible;
  final String prayer;
  final int? weekNumber;
  final DateTime? createdAt;

  factory WeeklyReport.fromMap(String id, Map<String, dynamic> m) {
    final ts = m['created_at'];
    return WeeklyReport(
      id: id,
      weekLabel: (m['week_label'] ?? '') as String,
      submitted: (m['submitted'] ?? false) as bool,
      bible: (m['bible'] ?? '') as String,
      prayer: (m['prayer'] ?? '') as String,
      weekNumber: m['week_number'] as int?,
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
