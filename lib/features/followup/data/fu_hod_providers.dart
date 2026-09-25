import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/department.dart';
import '../../../models/member.dart';
import '../../../models/sms.dart';
import 'fu_hod_repository.dart';
import 'fu_providers.dart';

final fuHodRepositoryProvider = Provider<FuHodRepository>((ref) => FuHodRepository());

/// All members in the follow-up system (FU HOD oversight).
final allMembersProvider = StreamProvider<List<Member>>((ref) {
  return ref.watch(fuRepositoryProvider).watchAllMembers();
});

/// A single member, live, from the members collection.
final memberStreamProvider = StreamProvider.family<Member?, String>((ref, id) {
  return ref.watch(fuRepositoryProvider).watchMember(id);
});

/// Members flagged unreachable.
final unreachableMembersProvider = Provider<List<Member>>((ref) {
  final list = ref.watch(allMembersProvider).valueOrNull ?? const [];
  return list.where((m) => m.unreachable).toList();
});

/// Absence escalation queue: at-risk / unreachable members, most-absent first.
final absenceQueueProvider = Provider<List<Member>>((ref) {
  final list = ref.watch(allMembersProvider).valueOrNull ?? const [];
  final q = list.where((m) => m.weeksAbsent >= 2 || m.unreachable).toList();
  q.sort((a, b) => b.weeksAbsent.compareTo(a.weeksAbsent));
  return q;
});

/// All approved workers (cross-department) for follow-up assignment.
final allWorkersProvider = StreamProvider<List<WorkerRef>>((ref) {
  return ref.watch(fuHodRepositoryProvider).watchAllWorkers();
});

final smsTemplatesProvider = StreamProvider<List<SmsTemplate>>((ref) {
  return ref.watch(fuHodRepositoryProvider).watchTemplates();
});

final smsRulesProvider = StreamProvider<List<SmsRule>>((ref) {
  return ref.watch(fuHodRepositoryProvider).watchRules();
});

final smsLogProvider = StreamProvider<List<SmsLogEntry>>((ref) {
  return ref.watch(fuHodRepositoryProvider).watchLog();
});
