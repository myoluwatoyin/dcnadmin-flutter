import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/functions_service.dart';
import '../../../models/application.dart';
import '../../../models/life_update.dart';
import '../../../models/meeting.dart';
import '../../../models/scorecard.dart';
import '../../../models/task.dart';
import '../../../models/team_worker.dart';

/// Department-scoped reads/writes for the HOD. Authorized by the caller's
/// custom claims ({role, dept}) via the security rules. Queries filter by a
/// single field and refine client-side to avoid composite indexes.
class HodRepository {
  HodRepository({FirebaseFirestore? firestore, FunctionsService? functions})
      : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FunctionsService();

  final FirebaseFirestore _db;
  final FunctionsService _functions;

  Stream<List<TeamWorker>> watchTeam(String dept, {String? excludeUid}) {
    return _db
        .collection('users')
        .where('department_code', isEqualTo: dept)
        .snapshots()
        .map((s) {
      final list = s.docs
          .where((d) {
            final role = (d.data()['role'] ?? '') as String;
            // Team = workers + sub-HODs (not the HOD themselves).
            return role.toUpperCase() != 'HOD' &&
                role.toUpperCase() != 'PASTOR' &&
                d.id != excludeUid;
          })
          .map((d) => TeamWorker.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  Stream<List<Task>> watchDeptTasks(String dept) {
    return _db
        .collection('tasks')
        .where('department_code', isEqualTo: dept)
        .snapshots()
        .map((s) => s.docs.map((d) => Task.fromMap(d.id, d.data())).toList());
  }

  Stream<List<Meeting>> watchDeptMeetings(String dept) {
    return _db
        .collection('meetings')
        .where('department_code', isEqualTo: dept)
        .snapshots()
        .map((s) {
      final list = s.docs.map((d) => Meeting.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => (a.startAt ?? DateTime(2100))
          .compareTo(b.startAt ?? DateTime(2100)));
      return list;
    });
  }

  Stream<List<Application>> watchApplications(String dept) {
    return _db
        .collection('applications')
        .where('department', isEqualTo: dept)
        .snapshots()
        .map((s) => s.docs
            .map((d) => Application.fromMap(d.id, d.data()))
            .where((a) => a.status == 'PENDING')
            .toList());
  }

  Stream<List<Scorecard>> watchDeptScorecards(String dept) {
    return _db
        .collection('scorecards')
        .where('department_code', isEqualTo: dept)
        .snapshots()
        .map((s) => s.docs.map((d) => Scorecard.fromMap(d.id, d.data())).toList());
  }

  Stream<List<LifeUpdate>> watchLifeInbox(String dept) {
    return _db
        .collection('life_updates')
        .where('department_code', isEqualTo: dept)
        .snapshots()
        .map((s) {
      final list = s.docs.map((d) => LifeUpdate.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => (b.createdAt ?? DateTime(1970))
          .compareTo(a.createdAt ?? DateTime(1970)));
      return list;
    });
  }

  // ── Writes ──────────────────────────────────────────────────

  /// Approve or reject a submitted task, with optional feedback to the worker.
  Future<void> reviewTask(String taskId, {required bool approved, String? feedback}) {
    return _db.collection('tasks').doc(taskId).update({
      'status': approved ? 'APPROVED' : 'REJECTED',
      if (feedback != null && feedback.trim().isNotEmpty)
        'hod_feedback': feedback.trim(),
      'reviewed_at': FieldValue.serverTimestamp(),
    });
  }

  /// Create a task for each selected assignee.
  Future<void> assignTask({
    required String dept,
    required String assignedBy,
    required String title,
    required String description,
    required String dueDate,
    required String priority,
    required List<({String uid, String name})> assignees,
  }) async {
    final batch = _db.batch();
    for (final a in assignees) {
      final ref = _db.collection('tasks').doc();
      batch.set(ref, {
        'title': title.trim(),
        'description': description.trim(),
        'status': 'ASSIGNED',
        'priority': priority,
        'due_date': dueDate.trim(),
        'department_code': dept,
        'assignee_uid': a.uid,
        'assignee_name': a.name,
        'assigned_by': assignedBy,
        'created_at': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> createMeeting({
    required String dept,
    required String title,
    required String type,
    required String date,
    required String start,
    required String end,
    required String location,
    required String agenda,
    required List<String> audienceUids,
  }) {
    return _db.collection('meetings').add({
      'title': title.trim(),
      'type': type,
      'status': 'SCHEDULED',
      'date': date.trim(),
      'start': start.trim(),
      'end': end.trim(),
      'location': location.trim(),
      'agenda': agenda.trim().isEmpty ? null : agenda.trim(),
      'department_code': dept,
      'audience_uids': audienceUids,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rescheduleMeeting(
    String id, {
    required String newDate,
    required String newStart,
    String? reason,
  }) {
    return _db.collection('meetings').doc(id).update({
      'status': 'RESCHEDULED',
      'date': newDate.trim(),
      'start': newStart.trim(),
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      'rescheduled_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelMeeting(String id, String reason) {
    return _db.collection('meetings').doc(id).update({
      'status': 'CANCELLED',
      'reason': reason.trim(),
      'cancelled_at': FieldValue.serverTimestamp(),
    });
  }

  /// Approve or reject a pending application. Runs server-side (Cloud Function):
  /// on approval it mints the member ID, enables the auth account, sets custom
  /// claims, provisions the user doc, and texts the applicant.
  Future<void> decideApplication(String id, {required bool approved, String? reason}) {
    return _functions.decideApplication(id, approve: approved, reason: reason);
  }

  /// Save a worker's quarterly scorecard (as draft or final).
  Future<void> submitScorecard({
    required String workerUid,
    required String workerName,
    required String subUnit,
    required String dept,
    required String quarter,
    required int year,
    required List<({String label, int score, int max, bool critical})> categories,
    required int total,
    required String hodName,
    required String hodNote,
    required bool draft,
  }) {
    return _db.collection('scorecards').doc('${workerUid}_${quarter.toLowerCase()}_$year').set({
      'uid': workerUid,
      'worker_name': workerName,
      'sub_unit_name': subUnit,
      'department_code': dept,
      'quarter': quarter,
      'year': year,
      'categories': [
        for (final c in categories)
          {'label': c.label, 'score': c.score, 'max': c.max, 'critical': c.critical},
      ],
      'total': total,
      'pass': total >= 50,
      'hod_name': hodName,
      'hod_note': hodNote.trim(),
      'status': draft ? 'DRAFT' : 'DONE',
      'ack_status': null,
      'assessed_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> respondLifeUpdate(String id, {required String by, required String body}) {
    return _db.collection('life_updates').doc(id).update({
      'status': 'RESPONDED',
      'response': {'by': by, 'at': 'Just now', 'body': body.trim()},
      'responded_at': FieldValue.serverTimestamp(),
    });
  }
}
