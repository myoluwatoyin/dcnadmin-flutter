import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the id of the last submitted application so the approval-pending
/// screen can check its status (and reveal the minted member ID) even after
/// the app is closed and reopened.
class SignupDraftStore {
  const SignupDraftStore(this._storage);
  final FlutterSecureStorage _storage;

  static const _key = 'dcn_pending_application_id';

  Future<void> saveApplicationId(String id) => _storage.write(key: _key, value: id);
  Future<String?> readApplicationId() => _storage.read(key: _key);
  Future<void> clear() => _storage.delete(key: _key);
}

final signupDraftStoreProvider = Provider<SignupDraftStore>(
  (ref) => const SignupDraftStore(FlutterSecureStorage()),
);
