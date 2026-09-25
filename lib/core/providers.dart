import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/signup_repository.dart';
import '../models/app_user.dart';
import '../models/department.dart';
import 'messaging_service.dart';

/// Repository singletons.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(),
);

/// Push-notification (FCM) registration + tap routing.
final messagingServiceProvider = Provider<MessagingService>((ref) => MessagingService());

final signupRepositoryProvider = Provider<SignupRepository>(
  (ref) => FirebaseSignupRepository(),
);

/// The current session user, streamed from Firebase auth state. Null = signed
/// out. Drives the router's redirect logic.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// App theme mode. Defaults to following the device; the settings screen can
/// flip this later. Mirrors the prototype's light/dark toggle.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// Ministry departments (+ sub-units) for the signup step, fetched live from
/// the backend. Refreshable so the Ministry step can show retry on error.
final departmentsProvider = FutureProvider.autoDispose<List<Department>>((ref) {
  return ref.watch(signupRepositoryProvider).fetchDepartments();
});
