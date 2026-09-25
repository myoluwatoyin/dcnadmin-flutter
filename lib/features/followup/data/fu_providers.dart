import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../worker/data/worker_providers.dart';
import '../../../models/member.dart';
import 'fu_repository.dart';

final fuRepositoryProvider = Provider<FuRepository>((ref) => FuRepository());

/// All members assigned to the signed-in follow-up worker.
final fuMembersProvider = StreamProvider<List<Member>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(fuRepositoryProvider).watchMyMembers(uid);
});

final fuMemberByIdProvider = Provider.family<Member?, String>((ref, id) {
  final list = ref.watch(fuMembersProvider).valueOrNull ?? const [];
  for (final m in list) {
    if (m.id == id) return m;
  }
  return null;
});

/// This week's follow-up queue (members flagged in_queue).
final fuQueueProvider = Provider<List<Member>>((ref) {
  final list = ref.watch(fuMembersProvider).valueOrNull ?? const [];
  final q = list.where((m) => m.inQueue).toList();
  // Urgent first, then high, med, low.
  int rank(String p) => switch (p) { 'urgent' => 0, 'high' => 1, 'med' => 2, _ => 3 };
  q.sort((a, b) => rank(a.queuePriority).compareTo(rank(b.queuePriority)));
  return q;
});

/// Members with an upcoming birthday label.
final fuBirthdaysProvider = Provider<List<Member>>((ref) {
  final list = ref.watch(fuMembersProvider).valueOrNull ?? const [];
  return list.where((m) => m.nextBirthdayLabel.isNotEmpty).toList();
});

/// First-timers, for the pipeline board.
final fuFirstTimersProvider = Provider<List<Member>>((ref) {
  final list = ref.watch(fuMembersProvider).valueOrNull ?? const [];
  return list.where((m) => m.isFirstTimer).toList();
});

final fuAttendanceProvider =
    StreamProvider.family<Map<String, String>, String>((ref, serviceId) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const {});
  return ref.watch(fuRepositoryProvider).watchAttendance(uid, serviceId);
});
