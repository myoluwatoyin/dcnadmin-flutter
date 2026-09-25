import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thin wrapper over the callable Cloud Functions that run the signup +
/// approval workflow. Functions live in europe-west1 (next to Firestore).
class FunctionsService {
  FunctionsService({FirebaseFunctions? functions})
      : _fns = functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseFunctions _fns;

  /// Files a signup application. The function validates the invite code,
  /// creates a disabled auth account with [password], and returns the
  /// application id. Throws [FunctionsException] with a user-safe message.
  Future<String> submitApplication(Map<String, dynamic> payload) async {
    try {
      final res = await _fns.httpsCallable('submitApplication').call(payload);
      return (res.data as Map)['application_id'] as String;
    } on FirebaseFunctionsException catch (e) {
      throw FunctionsException(e.message ?? 'Could not submit your application.');
    }
  }

  Future<({String status, String? memberId, String? reason})> checkApplicationStatus(String appId) async {
    try {
      final res = await _fns.httpsCallable('checkApplicationStatus').call({'application_id': appId});
      final d = res.data as Map;
      return (status: d['status'] as String, memberId: d['member_id'] as String?, reason: d['reason'] as String?);
    } on FirebaseFunctionsException catch (e) {
      throw FunctionsException(e.message ?? 'Could not check your status.');
    }
  }

  /// Approve or reject an application (HOD/Pastor). Returns the minted member
  /// id on approval.
  Future<({String status, String? memberId})> decideApplication(
    String appId, {
    required bool approve,
    String? reason,
  }) async {
    try {
      final res = await _fns.httpsCallable('decideApplication').call({
        'application_id': appId,
        'approve': approve,
        if (reason != null) 'reason': reason,
      });
      final d = res.data as Map;
      return (status: d['status'] as String, memberId: d['member_id'] as String?);
    } on FirebaseFunctionsException catch (e) {
      throw FunctionsException(e.message ?? 'Could not complete the decision.');
    }
  }
}

class FunctionsException implements Exception {
  const FunctionsException(this.message);
  final String message;
  @override
  String toString() => message;
}

final functionsServiceProvider = Provider<FunctionsService>((ref) => FunctionsService());
