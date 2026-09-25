import 'package:cloud_firestore/cloud_firestore.dart';

enum LifeUpdateType {
  testimony,
  prayerNeed,
  struggle,
  milestone;

  String get label => switch (this) {
        LifeUpdateType.testimony => 'Testimony',
        LifeUpdateType.prayerNeed => 'Prayer need',
        LifeUpdateType.struggle => 'Struggle',
        LifeUpdateType.milestone => 'Milestone',
      };

  static LifeUpdateType fromWire(String? v) => switch (v) {
        'Prayer need' => LifeUpdateType.prayerNeed,
        'Struggle' => LifeUpdateType.struggle,
        'Milestone' => LifeUpdateType.milestone,
        _ => LifeUpdateType.testimony,
      };
}

class LeaderResponse {
  const LeaderResponse({required this.by, required this.at, required this.body});
  final String by;
  final String at;
  final String body;

  factory LeaderResponse.fromMap(Map<String, dynamic> m) => LeaderResponse(
        by: (m['by'] ?? '') as String,
        at: (m['at'] ?? '') as String,
        body: (m['body'] ?? '') as String,
      );
}

/// A worker's life update shared with their leaders.
class LifeUpdate {
  const LifeUpdate({
    required this.id,
    required this.type,
    required this.body,
    required this.sharedWith,
    required this.responded,
    this.atLabel = '',
    this.workerName = '',
    this.response,
    this.createdAt,
  });

  final String id;
  final LifeUpdateType type;
  final String body;
  final String sharedWith;
  final bool responded;
  final String atLabel;
  final String workerName;
  final LeaderResponse? response;
  final DateTime? createdAt;

  factory LifeUpdate.fromMap(String id, Map<String, dynamic> m) {
    final ts = m['created_at'];
    final resp = m['response'];
    return LifeUpdate(
      id: id,
      type: LifeUpdateType.fromWire(m['type'] as String?),
      body: (m['body'] ?? '') as String,
      sharedWith: (m['shared_with'] ?? '') as String,
      responded: (m['status'] as String?)?.toUpperCase() == 'RESPONDED',
      atLabel: (m['at'] ?? '') as String,
      workerName: (m['worker_name'] ?? '') as String,
      response: resp is Map
          ? LeaderResponse.fromMap(Map<String, dynamic>.from(resp))
          : null,
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
