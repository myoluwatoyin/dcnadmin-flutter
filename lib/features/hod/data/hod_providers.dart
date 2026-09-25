import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../models/application.dart';
import '../../../models/life_update.dart';
import '../../../models/meeting.dart';
import '../../../models/scorecard.dart';
import '../../../models/task.dart';
import '../../../models/team_worker.dart';
import 'hod_repository.dart';

final hodRepositoryProvider = Provider<HodRepository>((ref) => HodRepository());

/// The signed-in HOD's department code + uid.
final hodDeptProvider = Provider<String?>(
  (ref) => ref.watch(authStateProvider).valueOrNull?.departmentCode,
);
final hodUidProvider = Provider<String?>(
  (ref) => ref.watch(authStateProvider).valueOrNull?.id,
);

StreamProvider<T> _deptScoped<T>(
  Stream<T> Function(HodRepository repo, String dept) build,
  T empty,
) {
  return StreamProvider<T>((ref) {
    final dept = ref.watch(hodDeptProvider);
    if (dept == null) return Stream.value(empty);
    return build(ref.watch(hodRepositoryProvider), dept);
  });
}

final hodTeamProvider = StreamProvider<List<TeamWorker>>((ref) {
  final dept = ref.watch(hodDeptProvider);
  final uid = ref.watch(hodUidProvider);
  if (dept == null) return Stream.value(const []);
  return ref.watch(hodRepositoryProvider).watchTeam(dept, excludeUid: uid);
});

final hodDeptTasksProvider =
    _deptScoped<List<Task>>((r, d) => r.watchDeptTasks(d), const []);

final hodMeetingsProvider =
    _deptScoped<List<Meeting>>((r, d) => r.watchDeptMeetings(d), const []);

final hodApplicationsProvider =
    _deptScoped<List<Application>>((r, d) => r.watchApplications(d), const []);

final hodScorecardsProvider =
    _deptScoped<List<Scorecard>>((r, d) => r.watchDeptScorecards(d), const []);

final hodLifeInboxProvider =
    _deptScoped<List<LifeUpdate>>((r, d) => r.watchLifeInbox(d), const []);

/// Submitted tasks awaiting review, derived from the dept task list.
final hodReviewQueueProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(hodDeptTasksProvider).valueOrNull ?? const [];
  return tasks
      .where((t) =>
          t.status == TaskStatus.submitted || t.status == TaskStatus.underReview)
      .toList();
});

/// A single team worker by uid.
final hodWorkerByIdProvider = Provider.family<TeamWorker?, String>((ref, uid) {
  final team = ref.watch(hodTeamProvider).valueOrNull ?? const [];
  for (final w in team) {
    if (w.uid == uid) return w;
  }
  return null;
});

/// A single dept task by id.
final hodTaskByIdProvider = Provider.family<Task?, String>((ref, id) {
  final tasks = ref.watch(hodDeptTasksProvider).valueOrNull ?? const [];
  for (final t in tasks) {
    if (t.id == id) return t;
  }
  return null;
});

/// A single dept meeting by id.
final hodMeetingByIdProvider = Provider.family<Meeting?, String>((ref, id) {
  final meetings = ref.watch(hodMeetingsProvider).valueOrNull ?? const [];
  for (final m in meetings) {
    if (m.id == id) return m;
  }
  return null;
});
