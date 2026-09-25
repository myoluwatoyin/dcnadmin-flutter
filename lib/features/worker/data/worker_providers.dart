import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../models/accountability.dart';
import '../../../models/app_notification.dart';
import '../../../models/followup_assignment.dart';
import '../../../models/life_update.dart';
import '../../../models/meeting.dart';
import '../../../models/member.dart';
import '../../../models/scorecard.dart';
import '../../../models/task.dart';
import '../../../models/weekly_report.dart';
import 'worker_repository.dart';

final workerRepositoryProvider = Provider<WorkerRepository>(
  (ref) => WorkerRepository(),
);

/// The signed-in user's auth uid (== their users doc id), or null.
final currentUidProvider = Provider<String?>(
  (ref) => ref.watch(authStateProvider).valueOrNull?.id,
);

StreamProvider<T> _scoped<T>(
  Stream<T> Function(WorkerRepository repo, String uid) build,
  T empty,
) {
  return StreamProvider<T>((ref) {
    final uid = ref.watch(currentUidProvider);
    if (uid == null) return Stream.value(empty);
    return build(ref.watch(workerRepositoryProvider), uid);
  });
}

final workerTasksProvider =
    _scoped<List<Task>>((r, uid) => r.watchTasks(uid), const []);

final workerMeetingsProvider =
    _scoped<List<Meeting>>((r, uid) => r.watchMeetings(uid), const []);

final workerReportsProvider =
    _scoped<List<WeeklyReport>>((r, uid) => r.watchReports(uid), const []);

final workerFollowupsProvider =
    _scoped<List<FollowupAssignment>>((r, uid) => r.watchFollowups(uid), const []);

final workerNotificationsProvider =
    _scoped<List<AppNotification>>((r, uid) => r.watchNotifications(uid), const []);

final workerScorecardsProvider =
    _scoped<List<Scorecard>>((r, uid) => r.watchScorecards(uid), const []);

final workerLifeUpdatesProvider =
    _scoped<List<LifeUpdate>>((r, uid) => r.watchLifeUpdates(uid), const []);

final workerAccountabilityProvider = StreamProvider<Accountability?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(workerRepositoryProvider).watchAccountability(uid);
});

/// A member record by id (for follow-up detail).
final memberByIdProvider = FutureProvider.family<Member?, String>((ref, id) {
  return ref.watch(workerRepositoryProvider).getMember(id);
});

/// A single follow-up assignment by id, from the live list.
final followupByIdProvider =
    Provider.family<FollowupAssignment?, String>((ref, id) {
  final list = ref.watch(workerFollowupsProvider).valueOrNull ?? const [];
  for (final f in list) {
    if (f.id == id) return f;
  }
  return null;
});

/// A single task by id, derived from the live list so status changes reflect.
final workerTaskByIdProvider = Provider.family<Task?, String>((ref, id) {
  final tasks = ref.watch(workerTasksProvider).valueOrNull ?? const [];
  for (final t in tasks) {
    if (t.id == id) return t;
  }
  return null;
});

final workerMeetingByIdProvider = Provider.family<Meeting?, String>((ref, id) {
  final meetings = ref.watch(workerMeetingsProvider).valueOrNull ?? const [];
  for (final m in meetings) {
    if (m.id == id) return m;
  }
  return null;
});

/// Unread notification count for the header bell dot.
final workerUnreadCountProvider = Provider<int>((ref) {
  return ref
      .watch(workerNotificationsProvider)
      .valueOrNull
      ?.where((n) => !n.read)
      .length ??
      0;
});
