import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/accountability.dart';
import '../../../models/app_notification.dart';
import '../../../models/followup_assignment.dart';
import '../../../models/life_update.dart';
import '../../../models/meeting.dart';
import '../../../models/member.dart';
import '../../../models/scorecard.dart';
import '../../../models/task.dart';
import '../../../models/weekly_report.dart';

/// Live, uid-scoped reads for the worker dashboards. Queries use equality-only
/// filters and sort client-side, so no composite indexes are required.
class WorkerRepository {
  WorkerRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<Task>> watchTasks(String uid) {
    return _db
        .collection('tasks')
        .where('assignee_uid', isEqualTo: uid)
        .snapshots()
        .map((s) => s.docs.map((d) => Task.fromMap(d.id, d.data())).toList());
  }

  Stream<List<Meeting>> watchMeetings(String uid) {
    return _db
        .collection('meetings')
        .where('audience_uids', arrayContains: uid)
        .snapshots()
        .map((s) {
      final list = s.docs.map((d) => Meeting.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => (a.startAt ?? DateTime(2100))
          .compareTo(b.startAt ?? DateTime(2100)));
      return list;
    });
  }

  Stream<List<WeeklyReport>> watchReports(String uid) {
    return _db
        .collection('reports')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((s) {
      final list =
          s.docs.map((d) => WeeklyReport.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => (b.weekNumber ?? 0).compareTo(a.weekNumber ?? 0));
      return list;
    });
  }

  Stream<List<FollowupAssignment>> watchFollowups(String uid) {
    return _db
        .collection('followup_assignments')
        .where('worker_uid', isEqualTo: uid)
        .snapshots()
        .map((s) => s.docs
            .map((d) => FollowupAssignment.fromMap(d.id, d.data()))
            .toList());
  }

  Stream<List<AppNotification>> watchNotifications(String uid) {
    return _db
        .collection('notifications')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((s) {
      final list =
          s.docs.map((d) => AppNotification.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => (b.createdAt ?? DateTime(1970))
          .compareTo(a.createdAt ?? DateTime(1970)));
      return list;
    });
  }

  Stream<List<Scorecard>> watchScorecards(String uid) {
    return _db
        .collection('scorecards')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((s) {
      final list = s.docs.map((d) => Scorecard.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => b.sortKey.compareTo(a.sortKey));
      return list;
    });
  }

  Stream<List<LifeUpdate>> watchLifeUpdates(String uid) {
    return _db
        .collection('life_updates')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((s) {
      final list = s.docs.map((d) => LifeUpdate.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => (b.createdAt ?? DateTime(1970))
          .compareTo(a.createdAt ?? DateTime(1970)));
      return list;
    });
  }

  Stream<Accountability?> watchAccountability(String uid) {
    return _db
        .collection('accountability')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isEmpty
            ? null
            : Accountability.fromMap(s.docs.first.data()));
  }

  Future<Member?> getMember(String id) async {
    final doc = await _db.collection('members').doc(id).get();
    if (!doc.exists) return null;
    return Member.fromMap(doc.id, doc.data()!);
  }

  // ── Writes ──────────────────────────────────────────────────

  /// Submit (or update) the worker's weekly Bible/prayer report.
  Future<void> submitReport(
    String uid, {
    required String reportId,
    required int weekNumber,
    required String weekLabel,
    required String bible,
    required String prayer,
  }) {
    return _db.collection('reports').doc(reportId).set({
      'uid': uid,
      'week_number': weekNumber,
      'week_label': weekLabel,
      'bible': bible.trim(),
      'prayer': prayer.trim(),
      'submitted': true,
      'created_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Acknowledge or dispute a scorecard. Rules restrict the writable fields.
  Future<void> setScorecardAck(
    String scorecardId,
    AckStatus status, {
    String? disputeText,
  }) {
    return _db.collection('scorecards').doc(scorecardId).update({
      'ack_status': status == AckStatus.acknowledged ? 'ACK' : 'DISPUTE',
      if (disputeText != null) 'dispute_text': disputeText.trim(),
      'ack_at': FieldValue.serverTimestamp(),
    });
  }

  Future<String> createLifeUpdate(
    String uid, {
    required String type,
    required String body,
    required String sharedWith,
    String? departmentCode,
  }) async {
    final ref = await _db.collection('life_updates').add({
      'uid': uid,
      'type': type,
      'body': body.trim(),
      'shared_with': sharedWith,
      'department_code': departmentCode,
      'status': 'SEEN',
      'response': null,
      'created_at': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Log a contact outcome on a follow-up assignment and mark it done.
  Future<void> logFollowupOutcome(
    String assignmentId, {
    required String outcome,
    String? note,
  }) {
    return _db.collection('followup_assignments').doc(assignmentId).update({
      'status': 'DONE',
      'last_outcome': outcome,
      if (note != null && note.trim().isNotEmpty) 'last_note': note.trim(),
      'last_outcome_at': FieldValue.serverTimestamp(),
    });
  }

  /// Move a task to [status]; optionally record the worker's submission note.
  /// Guarded by security rules to the task's own assignee.
  Future<void> updateTaskStatus(
    String taskId,
    TaskStatus status, {
    String? note,
  }) {
    return _db.collection('tasks').doc(taskId).update({
      'status': _taskStatusWire(status),
      if (note != null && note.trim().isNotEmpty) 'submission_note': note.trim(),
      if (status == TaskStatus.submitted)
        'submitted_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markNotificationRead(String id) {
    return _db.collection('notifications').doc(id).update({'read': true});
  }

  Future<void> markAllNotificationsRead(Iterable<String> ids) async {
    final batch = _db.batch();
    for (final id in ids) {
      batch.update(_db.collection('notifications').doc(id), {'read': true});
    }
    await batch.commit();
  }

  static String _taskStatusWire(TaskStatus s) => switch (s) {
        TaskStatus.assigned => 'ASSIGNED',
        TaskStatus.inProgress => 'IN_PROGRESS',
        TaskStatus.submitted => 'SUBMITTED',
        TaskStatus.underReview => 'UNDER_REVIEW',
        TaskStatus.approved => 'APPROVED',
        TaskStatus.rejected => 'REJECTED',
        TaskStatus.overdue => 'OVERDUE',
      };
}
