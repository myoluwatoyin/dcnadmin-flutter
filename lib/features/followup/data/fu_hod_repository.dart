import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/department.dart';
import '../../../models/sms.dart';

/// Follow-Up HOD powers: cross-department follow-up assignment and the SMS
/// engine (config + log). Authorized by FOLLOWUP-dept claims / Pastor.
class FuHodRepository {
  FuHodRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Assign each picked member to each picked worker (may be cross-department).
  /// Writes a followup_assignment the target worker sees in their dashboard.
  Future<void> assignFollowup({
    required List<({String id, String name})> members,
    required List<String> workerUids,
    required String priority,
    required String reason,
    required String assignedBy,
  }) async {
    final batch = _db.batch();
    for (final w in workerUids) {
      for (final m in members) {
        final ref = _db.collection('followup_assignments').doc();
        batch.set(ref, {
          'worker_uid': w,
          'member_id': m.id,
          'member_name': m.name,
          'priority': priority,
          'reason': reason.trim(),
          'status': 'PENDING',
          'assigned_by': assignedBy,
          'assigned_at_label': 'Just now',
          'created_at': FieldValue.serverTimestamp(),
        });
      }
    }
    await batch.commit();
  }

  /// All approved workers (from the public directory) for cross-dept assignment.
  Stream<List<WorkerRef>> watchAllWorkers() {
    return _db
        .collection('worker_directory')
        .where('status', isEqualTo: 'APPROVED')
        .snapshots()
        .map((s) {
      final list = s.docs.map((d) => WorkerRef.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  Stream<List<SmsTemplate>> watchTemplates() {
    return _db.collection('sms_templates').snapshots().map(
          (s) => s.docs.map((d) => SmsTemplate.fromMap(d.id, d.data())).toList(),
        );
  }

  Stream<List<SmsRule>> watchRules() {
    return _db.collection('sms_rules').snapshots().map((s) {
      final list = s.docs.map((d) => SmsRule.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => a.threshold.compareTo(b.threshold));
      return list;
    });
  }

  Stream<List<SmsLogEntry>> watchLog() {
    return _db.collection('sms_log').snapshots().map((s) {
      final list = s.docs.map((d) => SmsLogEntry.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => b.sortKey.compareTo(a.sortKey));
      return list;
    });
  }
}
