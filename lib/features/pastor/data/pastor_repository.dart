import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/functions_service.dart';
import '../../../models/application.dart';
import '../../../models/invite_code.dart';
import '../../../models/life_update.dart';
import '../../../models/scorecard.dart';
import '../../../models/team_worker.dart';

/// Church-wide reads/writes for the Pastor / Super-Admin. Authorized by the
/// PASTOR/SUPER_ADMIN claim (isPastor() in the rules grants access to any
/// department's data).
class PastorRepository {
  PastorRepository({FirebaseFirestore? firestore, FunctionsService? functions})
      : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FunctionsService();

  final FirebaseFirestore _db;
  final FunctionsService _functions;

  Stream<List<TeamWorker>> watchAllUsers() {
    return _db.collection('users').snapshots().map((s) {
      final list = s.docs.map((d) => TeamWorker.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  Stream<TeamWorker?> watchUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map(
          (d) => d.exists ? TeamWorker.fromMap(d.id, d.data()!) : null,
        );
  }

  Stream<List<Application>> watchAllApplications() {
    return _db.collection('applications').snapshots().map((s) => s.docs
        .map((d) => Application.fromMap(d.id, d.data()))
        .where((a) => a.status == 'PENDING')
        .toList());
  }

  Stream<List<LifeUpdate>> watchAllLifeUpdates() {
    return _db.collection('life_updates').snapshots().map((s) {
      final list = s.docs.map((d) => LifeUpdate.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => (b.createdAt ?? DateTime(1970)).compareTo(a.createdAt ?? DateTime(1970)));
      return list;
    });
  }

  Stream<List<Scorecard>> watchAllScorecards() {
    return _db.collection('scorecards').snapshots().map(
          (s) => s.docs.map((d) => Scorecard.fromMap(d.id, d.data())).toList(),
        );
  }

  Stream<Map<String, dynamic>> watchAnalytics() {
    return _db.collection('analytics').doc('church').snapshots().map(
          (d) => d.data() ?? const {},
        );
  }

  Stream<List<InviteCode>> watchInviteCodes() {
    return _db.collection('invite_codes').snapshots().map((s) {
      final list = s.docs.map((d) => InviteCode.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => a.code.compareTo(b.code));
      return list;
    });
  }

  // ── Writes ──────────────────────────────────────────────────

  /// Suspend or reinstate a worker's account.
  Future<void> setUserStatus(String uid, {required bool suspend, String? reason}) {
    return _db.collection('users').doc(uid).update({
      'status': suspend ? 'SUSPENDED' : 'APPROVED',
      if (suspend && reason != null) 'suspend_reason': reason.trim(),
      'suspended_at': suspend ? FieldValue.serverTimestamp() : null,
    });
  }

  Future<void> createInviteCode({
    required String code,
    required String role,
    required String departmentName,
    required int uses,
  }) {
    return _db.collection('invite_codes').doc(code).set({
      'code': code,
      'role': role,
      'department_name': departmentName,
      'department_code': departmentName.toUpperCase(),
      'max_uses': uses,
      'uses': 0,
      'active': true,
      'expires': '30 Jul 2026',
    });
  }

  Future<void> revokeInviteCode(String id) {
    return _db.collection('invite_codes').doc(id).update({'active': false});
  }

  /// Approve or reject a pending application church-wide. Runs server-side
  /// (Cloud Function): mints the member ID, enables the auth account, sets
  /// claims, provisions the user doc, and texts the applicant.
  Future<void> decideApplication(String id, {required bool approved, String? reason}) {
    return _functions.decideApplication(id, approve: approved, reason: reason);
  }

  Future<void> respondLifeUpdate(String id, {required String by, required String body}) {
    return _db.collection('life_updates').doc(id).update({
      'status': 'RESPONDED',
      'response': {'by': by, 'at': 'Just now', 'body': body.trim()},
      'responded_at': FieldValue.serverTimestamp(),
    });
  }
}
