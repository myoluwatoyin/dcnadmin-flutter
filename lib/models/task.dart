import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus {
  assigned,
  inProgress,
  submitted,
  underReview,
  approved,
  rejected,
  overdue;

  static TaskStatus fromWire(String? v) => switch (v?.toUpperCase()) {
        'IN_PROGRESS' => TaskStatus.inProgress,
        'SUBMITTED' => TaskStatus.submitted,
        'UNDER_REVIEW' => TaskStatus.underReview,
        'APPROVED' => TaskStatus.approved,
        'REJECTED' => TaskStatus.rejected,
        'OVERDUE' => TaskStatus.overdue,
        _ => TaskStatus.assigned,
      };

  String get label => switch (this) {
        TaskStatus.assigned => 'Assigned',
        TaskStatus.inProgress => 'In progress',
        TaskStatus.submitted => 'Submitted',
        TaskStatus.underReview => 'Under review',
        TaskStatus.approved => 'Approved',
        TaskStatus.rejected => 'Rejected',
        TaskStatus.overdue => 'Overdue',
      };
}

enum TaskPriority {
  high,
  medium,
  low;

  static TaskPriority fromWire(String? v) => switch (v?.toUpperCase()) {
        'HIGH' => TaskPriority.high,
        'LOW' => TaskPriority.low,
        _ => TaskPriority.medium,
      };
}

/// A task assigned to a worker.
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    this.description = '',
    this.dueDate = '',
    this.assignedBy = '',
    this.dueAt,
    this.assigneeName = '',
    this.submissionNote = '',
    this.attachments = 0,
    this.submittedAtLabel = '',
  });

  final String id;
  final String title;
  final TaskStatus status;
  final TaskPriority priority;
  final String description;
  final String dueDate;
  final String assignedBy;
  final DateTime? dueAt;
  // HOD review context (present on submitted tasks).
  final String assigneeName;
  final String submissionNote;
  final int attachments;
  final String submittedAtLabel;

  bool get isActive => status == TaskStatus.assigned ||
      status == TaskStatus.inProgress ||
      status == TaskStatus.overdue;

  factory Task.fromMap(String id, Map<String, dynamic> m) {
    final ts = m['due_at'];
    return Task(
      id: id,
      title: (m['title'] ?? '') as String,
      status: TaskStatus.fromWire(m['status'] as String?),
      priority: TaskPriority.fromWire(m['priority'] as String?),
      description: (m['description'] ?? '') as String,
      dueDate: (m['due_date'] ?? '') as String,
      assignedBy: (m['assigned_by'] ?? '') as String,
      dueAt: ts is Timestamp ? ts.toDate() : null,
      assigneeName: (m['assignee_name'] ?? '') as String,
      submissionNote: (m['submission_note'] ?? '') as String,
      attachments: (m['attachments'] ?? 0) as int,
      submittedAtLabel: (m['submitted_at_label'] ?? '') as String,
    );
  }
}
