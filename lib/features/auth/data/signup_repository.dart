import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/department.dart';

/// Result of validating an invite code against the backend.
class InviteValidation {
  const InviteValidation({required this.valid, this.reason});
  final bool valid;
  final String? reason;
}

/// Backend data + submission for the signup application flow. All lookups are
/// real (departments, sub-units, inviter search, invite-code validation) — no
/// hardcoded prototype arrays, per the product brief.
abstract class SignupRepository {
  Future<List<Department>> fetchDepartments();

  /// Search approved workers by name for the "Who invited you?" field.
  Future<List<WorkerRef>> searchWorkers(String query);

  /// Validate an invite code, optionally scoped to a department code.
  Future<InviteValidation> validateInviteCode({
    required String code,
    String? departmentCode,
  });

  /// Submit the completed application. Returns the created application id.
  Future<String> submitApplication(Map<String, dynamic> payload);
}

class FirebaseSignupRepository implements SignupRepository {
  FirebaseSignupRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<List<Department>> fetchDepartments() async {
    final snap = await _db.collection('departments').orderBy('name').get();
    return snap.docs.map((d) => Department.fromMap(d.id, d.data())).toList();
  }

  @override
  Future<List<WorkerRef>> searchWorkers(String query) async {
    final q = query.trim();
    if (q.length < 2) return [];
    // Prefix search on a lowercased search field, scoped to approved workers.
    final lower = q.toLowerCase();
    // Reads the public, non-PII approved-worker projection (not `users`).
    final snap = await _db
        .collection('worker_directory')
        .where('status', isEqualTo: 'APPROVED')
        .where('search_name', isGreaterThanOrEqualTo: lower)
        .where('search_name', isLessThan: '$lower')
        .limit(10)
        .get();
    return snap.docs.map((d) => WorkerRef.fromMap(d.id, d.data())).toList();
  }

  @override
  Future<InviteValidation> validateInviteCode({
    required String code,
    String? departmentCode,
  }) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      return const InviteValidation(valid: false, reason: 'Enter an invite code.');
    }
    final snap = await _db
        .collection('invite_codes')
        .where('code', isEqualTo: trimmed)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) {
      return const InviteValidation(valid: false, reason: 'Invalid invite code.');
    }
    final data = snap.docs.first.data();
    final active = (data['active'] ?? true) as bool;
    if (!active) {
      return const InviteValidation(valid: false, reason: 'This code has expired.');
    }
    final maxUses = data['max_uses'] as int?;
    final uses = (data['uses'] ?? 0) as int;
    if (maxUses != null && uses >= maxUses) {
      return const InviteValidation(valid: false, reason: 'This code has reached its max uses.');
    }
    final codeDept = (data['department_code'] as String?)?.toUpperCase();
    if (departmentCode != null &&
        codeDept != null &&
        codeDept != departmentCode.toUpperCase()) {
      return const InviteValidation(
        valid: false,
        reason: 'This code is for a different department.',
      );
    }
    return const InviteValidation(valid: true);
  }

  @override
  Future<String> submitApplication(Map<String, dynamic> payload) async {
    final ref = await _db.collection('applications').add({
      ...payload,
      'status': 'PENDING',
      'created_at': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }
}
