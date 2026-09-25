enum FollowupPriority {
  low,
  med,
  high,
  urgent;

  static FollowupPriority fromWire(String? v) => switch (v?.toLowerCase()) {
        'urgent' => FollowupPriority.urgent,
        'high' => FollowupPriority.high,
        'low' => FollowupPriority.low,
        _ => FollowupPriority.med,
      };

  String get label => switch (this) {
        FollowupPriority.urgent => 'Urgent',
        FollowupPriority.high => 'High',
        FollowupPriority.med => 'Med',
        FollowupPriority.low => 'Low',
      };
}

enum FollowupStatus {
  pending,
  done,
  dismissed;

  static FollowupStatus fromWire(String? v) => switch (v?.toUpperCase()) {
        'DONE' => FollowupStatus.done,
        'DISMISSED' => FollowupStatus.dismissed,
        _ => FollowupStatus.pending,
      };
}

/// A cross-department follow-up assignment given to a worker.
class FollowupAssignment {
  const FollowupAssignment({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.priority,
    required this.status,
    this.reason = '',
    this.assignedBy = '',
    this.assignedAtLabel = '',
    this.lastOutcome = '',
    this.lastOutcomeAt = '',
  });

  final String id;
  final String memberId;
  final String memberName;
  final FollowupPriority priority;
  final FollowupStatus status;
  final String reason;
  final String assignedBy;
  final String assignedAtLabel;
  final String lastOutcome;
  final String lastOutcomeAt;

  factory FollowupAssignment.fromMap(String id, Map<String, dynamic> m) {
    return FollowupAssignment(
      id: id,
      memberId: (m['member_id'] ?? '') as String,
      memberName: (m['member_name'] ?? '') as String,
      priority: FollowupPriority.fromWire(m['priority'] as String?),
      status: FollowupStatus.fromWire(m['status'] as String?),
      reason: (m['reason'] ?? '') as String,
      assignedBy: (m['assigned_by'] ?? '') as String,
      assignedAtLabel: (m['assigned_at_label'] ?? '') as String,
      lastOutcome: (m['last_outcome'] ?? '') as String,
      lastOutcomeAt: (m['last_outcome_at'] ?? '') as String,
    );
  }
}
