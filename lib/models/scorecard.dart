import 'package:cloud_firestore/cloud_firestore.dart';

enum AckStatus { none, acknowledged, disputed }

class ScorecardCategory {
  const ScorecardCategory({
    required this.label,
    required this.score,
    required this.max,
    this.critical = false,
  });

  final String label;
  final int score;
  final int max;
  final bool critical;

  double get pct => max == 0 ? 0 : (score / max) * 100;

  factory ScorecardCategory.fromMap(Map<String, dynamic> m) => ScorecardCategory(
        label: (m['label'] ?? '') as String,
        score: (m['score'] ?? 0) as int,
        max: (m['max'] ?? 0) as int,
        critical: (m['critical'] ?? false) as bool,
      );
}

/// A worker's quarterly assessment. Scores/notes come from the HOD; the worker
/// may acknowledge or dispute.
class Scorecard {
  const Scorecard({
    required this.id,
    required this.quarter,
    required this.year,
    required this.total,
    required this.pass,
    this.uid = '',
    this.workerName = '',
    this.statusWire = '',
    this.categories = const [],
    this.hodName = '',
    this.hodNote = '',
    this.assessedAt = '',
    this.ackStatus = AckStatus.none,
    this.sortKey = 0,
  });

  final String id;
  final String uid;
  final String workerName;
  final String statusWire;
  final String quarter; // e.g. "Q2"
  final int year;
  final int total; // out of 100
  final bool pass;
  final List<ScorecardCategory> categories;
  final String hodName;
  final String hodNote;
  final String assessedAt;
  final AckStatus ackStatus;
  final int sortKey; // year*10 + quarter number, for ordering

  String get label => '$quarter $year';
  bool get hasDetail => categories.isNotEmpty;

  static AckStatus _ack(String? v) => switch (v?.toUpperCase()) {
        'ACK' || 'ACKNOWLEDGED' => AckStatus.acknowledged,
        'DISPUTE' || 'DISPUTED' => AckStatus.disputed,
        _ => AckStatus.none,
      };

  factory Scorecard.fromMap(String id, Map<String, dynamic> m) {
    final q = (m['quarter'] ?? 'Q1') as String;
    final year = (m['year'] ?? 0) as int;
    final qNum = int.tryParse(q.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final ts = m['assessed_at'];
    return Scorecard(
      id: id,
      uid: (m['uid'] ?? '') as String,
      workerName: (m['worker_name'] ?? '') as String,
      statusWire: (m['status'] ?? '') as String,
      quarter: q,
      year: year,
      total: (m['total'] ?? 0) as int,
      pass: (m['pass'] ?? false) as bool,
      categories: ((m['categories'] as List?) ?? const [])
          .whereType<Map>()
          .map((c) => ScorecardCategory.fromMap(Map<String, dynamic>.from(c)))
          .toList(),
      hodName: (m['hod_name'] ?? '') as String,
      hodNote: (m['hod_note'] ?? '') as String,
      assessedAt: ts is Timestamp
          ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}'
          : (m['assessed_at_label'] ?? '') as String,
      ackStatus: _ack(m['ack_status'] as String?),
      sortKey: year * 10 + qNum,
    );
  }
}
