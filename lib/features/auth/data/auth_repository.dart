import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/app_user.dart';
import '../../../models/enums.dart';

/// Raised on a failed sign-in with a message safe to show inline to the user.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The outcome of a sign-in attempt: the resolved session user. Suspended
/// users resolve successfully here so the UI can route them to the suspended
/// screen; blocking happens at the routing layer, not by throwing.
abstract class AuthRepository {
  /// Authenticate with a member ID + password against the real backend.
  Future<AppUser> signInWithMemberId({
    required String memberId,
    required String password,
  });

  /// The currently signed-in user, or null. Emits on auth state changes.
  Stream<AppUser?> authStateChanges();

  /// Re-fetch the latest user profile for the signed-in account.
  Future<AppUser?> refreshSession();

  /// Persist a new avatar URL on the signed-in user's own profile.
  Future<void> updateProfilePhoto(String uid, String photoUrl);

  Future<void> signOut();
}

/// Firebase-backed auth. Member-ID login is a two-step flow: resolve the
/// member ID to its account email via the `users` collection, then sign in
/// through Firebase Auth. No demo credentials or role selection — the persona
/// is derived from the stored user document.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  @override
  Future<AppUser> signInWithMemberId({
    required String memberId,
    required String password,
  }) async {
    final trimmed = memberId.trim();
    if (trimmed.isEmpty) throw const AuthException('Enter your member ID.');
    if (password.isEmpty) throw const AuthException('Enter your password.');

    // 1. Resolve member ID -> account email via the public login projection
    //    (the private `users` doc isn't readable until authenticated).
    final login = await _db.collection('member_login').doc(trimmed).get();
    final email = login.data()?['email'] as String?;
    if (!login.exists || email == null || email.isEmpty) {
      throw const AuthException('No account found for that member ID.');
    }

    // 2. Authenticate with Firebase Auth.
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    }

    // 3. Load the fresh profile (now authenticated) and gate on status.
    final user = await refreshSession();
    if (user == null) {
      await _auth.signOut();
      throw const AuthException('Your profile could not be loaded. Contact your HOD.');
    }
    if (user.status == AccountStatus.pending) {
      await _auth.signOut();
      throw const AuthException('Your application is still awaiting approval.');
    }
    if (user.status == AccountStatus.rejected) {
      await _auth.signOut();
      throw const AuthException('This application was not approved. Contact your HOD.');
    }
    return user;
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) return null;
      return _loadByUid(fbUser.uid);
    });
  }

  @override
  Future<AppUser?> refreshSession() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    return _loadByUid(fbUser.uid);
  }

  @override
  Future<void> updateProfilePhoto(String uid, String photoUrl) {
    // Nested update — only the `person` key changes, which the rules permit
    // the owner to write.
    return _users.doc(uid).update({'person.photo_url': photoUrl});
  }

  @override
  Future<void> signOut() => _auth.signOut();

  /// Roles that may use this app. The Firebase project is shared with the
  /// public DCN Sermons member app; members carry no `role` claim.
  static const _workerRoles = {'WORKER', 'SUBHOD', 'HOD', 'PASTOR', 'SUPER_ADMIN'};

  Future<AppUser?> _loadByUid(String uid) async {
    // Gate on the auth token's role claim first: an account without a worker
    // role (e.g. a DCN Sermons member) is signed out and treated as a guest,
    // regardless of what documents exist for it.
    final fbUser = _auth.currentUser;
    if (fbUser == null || fbUser.uid != uid) return null;
    final claims = (await fbUser.getIdTokenResult()).claims ?? const {};
    if (!_workerRoles.contains(claims['role'])) {
      await _auth.signOut();
      return null;
    }
    // Prefer a doc keyed by the auth uid; fall back to a uid field lookup.
    final byId = await _users.doc(uid).get();
    if (byId.exists) return AppUser.fromMap(byId.id, byId.data()!);
    final byField = await _users.where('uid', isEqualTo: uid).limit(1).get();
    if (byField.docs.isEmpty) return null;
    final d = byField.docs.first;
    return AppUser.fromMap(d.id, d.data());
  }

  String _mapAuthError(FirebaseAuthException e) {
    return switch (e.code) {
      'wrong-password' || 'invalid-credential' => 'Incorrect password. Try again.',
      'user-not-found' => 'No account found for that member ID.',
      'user-disabled' => 'This account has been disabled.',
      'too-many-requests' => 'Too many attempts. Please wait and try again.',
      'network-request-failed' => 'Network error. Check your connection.',
      _ => 'Could not sign you in. Please try again.',
    };
  }
}
