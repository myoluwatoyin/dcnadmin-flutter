import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/member.dart';

/// Reads/writes for the Follow-Up worker: their assigned members, call logging,
/// intake, and attendance sheets. Scoped to the signed-in worker by the rules.
class FuRepository {
  FuRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<Member>> watchMyMembers(String uid) {
    return _db
        .collection('members')
        .where('assigned_worker_uid', isEqualTo: uid)
        .snapshots()
        .map((s) {
      final list = s.docs.map((d) => Member.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  /// All members (Follow-Up HOD oversight).
  Stream<List<Member>> watchAllMembers() {
    return _db.collection('members').snapshots().map((s) {
      final list = s.docs.map((d) => Member.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  /// A single member, live (so detail reflects logged calls immediately).
  Stream<Member?> watchMember(String id) {
    return _db.collection('members').doc(id).snapshots().map(
          (d) => d.exists ? Member.fromMap(d.id, d.data()!) : null,
        );
  }

  /// Log a contact outcome on a member: append a note, record the outcome and
  /// mark the queue item done.
  Future<void> logContact(
    String memberId, {
    required String outcome,
    required String workerName,
    String? note,
  }) {
    final body = (note != null && note.trim().isNotEmpty)
        ? '$outcome — ${note.trim()}'
        : '$outcome — logged.';
    return _db.collection('members').doc(memberId).update({
      'follow_up_notes': FieldValue.arrayUnion([followUpNoteData(workerName, body)]),
      'last_outcome': outcome,
      'queue_status': 'DONE',
      'last_outcome_at': FieldValue.serverTimestamp(),
    });
  }

  /// Create a member record assigned to this worker.
  Future<String> addMember(String uid, Map<String, dynamic> data) async {
    final ref = await _db.collection('members').add({
      ...data,
      'assigned_worker_uid': uid,
      'created_at': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<Map<String, String>> watchAttendance(String uid, String serviceId) {
    return _db.collection('attendance').doc('${uid}_$serviceId').snapshots().map((d) {
      final marks = (d.data()?['marks'] as Map?) ?? const {};
      return marks.map((k, v) => MapEntry(k as String, v as String));
    });
  }

  Future<void> saveAttendance(
    String uid,
    String serviceId, {
    required String serviceName,
    required String date,
    required Map<String, String> marks,
  }) {
    return _db.collection('attendance').doc('${uid}_$serviceId').set({
      'worker_uid': uid,
      'service_id': serviceId,
      'service_name': serviceName,
      'date': date,
      'marks': marks,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
