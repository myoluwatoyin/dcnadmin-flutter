import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/application.dart';
import '../../../models/invite_code.dart';
import '../../../models/life_update.dart';
import '../../../models/member.dart';
import '../../../models/scorecard.dart';
import '../../../models/team_worker.dart';
import '../../followup/data/fu_hod_providers.dart';
import 'pastor_repository.dart';

final pastorRepositoryProvider = Provider<PastorRepository>((ref) => PastorRepository());

final allUsersProvider = StreamProvider<List<TeamWorker>>((ref) {
  return ref.watch(pastorRepositoryProvider).watchAllUsers();
});

/// All workers church-wide (Worker / Sub-HOD / HOD, excluding pastor).
final pastorWorkersProvider = Provider<List<TeamWorker>>((ref) {
  final all = ref.watch(allUsersProvider).valueOrNull ?? const [];
  return all.where((w) {
    final r = w.role.toUpperCase();
    return r == 'WORKER' || r == 'SUBHOD' || r == 'HOD';
  }).toList();
});

final pastorWorkerByIdProvider = StreamProvider.family<TeamWorker?, String>((ref, uid) {
  return ref.watch(pastorRepositoryProvider).watchUser(uid);
});

final pastorApplicationsProvider = StreamProvider<List<Application>>((ref) {
  return ref.watch(pastorRepositoryProvider).watchAllApplications();
});

final pastorLifeInboxProvider = StreamProvider<List<LifeUpdate>>((ref) {
  return ref.watch(pastorRepositoryProvider).watchAllLifeUpdates();
});

final pastorScorecardsProvider = StreamProvider<List<Scorecard>>((ref) {
  return ref.watch(pastorRepositoryProvider).watchAllScorecards();
});

final inviteCodesProvider = StreamProvider<List<InviteCode>>((ref) {
  return ref.watch(pastorRepositoryProvider).watchInviteCodes();
});

final analyticsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return ref.watch(pastorRepositoryProvider).watchAnalytics();
});

/// A department's computed health, for the pastor dashboards.
class DeptHealth {
  const DeptHealth({
    required this.code,
    required this.name,
    required this.color,
    required this.hod,
    required this.workers,
    required this.reportsPct,
    required this.attendancePct,
    required this.tasksOverdue,
    required this.scorecardsDone,
  });

  final String code;
  final String name;
  final Color color;
  final String hod;
  final int workers;
  final int reportsPct;
  final int attendancePct;
  final int tasksOverdue;
  final int scorecardsDone;

  /// GOOD | WATCH | RISK
  String get health {
    if (reportsPct >= 80 && tasksOverdue == 0) return 'GOOD';
    if (reportsPct >= 65) return 'WATCH';
    return 'RISK';
  }
}

const _pastorDepts = [
  (code: 'WORSHIP', name: 'Worship', color: Color(0xFF7C3AED)),
  (code: 'MEDIA', name: 'Media', color: Color(0xFF3B82F6)),
  (code: 'USHERING', name: 'Ushering', color: Color(0xFF10B981)),
  (code: 'DRAMA', name: 'Drama', color: Color(0xFFF59E0B)),
  (code: 'TECHNICAL', name: 'Technical', color: Color(0xFFEF4444)),
  (code: 'FOLLOWUP', name: 'Follow-Up', color: Color(0xFF06B6D4)),
];

/// Per-department health, computed live from users + scorecards.
final deptHealthProvider = Provider<List<DeptHealth>>((ref) {
  final users = ref.watch(allUsersProvider).valueOrNull ?? const <TeamWorker>[];
  final scorecards = ref.watch(pastorScorecardsProvider).valueOrNull ?? const <Scorecard>[];

  return _pastorDepts.map((d) {
    final deptUsers = users.where((u) => u.departmentName.toUpperCase() == d.name.toUpperCase() || _codeOf(u) == d.code).toList();
    final workers = deptUsers.where((u) => u.role.toUpperCase() != 'PASTOR').toList();
    final nonHodWorkers = workers.where((u) => !u.isHod).toList();
    final hod = workers.where((u) => u.isHod).map((u) => u.name).firstOrNull ?? '—';
    final withReports = nonHodWorkers.where((u) => u.bothReports).length;
    final reportsPct = nonHodWorkers.isEmpty ? 0 : ((withReports / nonHodWorkers.length) * 100).round();
    final att = nonHodWorkers.isEmpty ? 0 : (nonHodWorkers.fold<int>(0, (s, u) => s + u.attendanceRate) / nonHodWorkers.length).round();
    final overdue = nonHodWorkers.fold<int>(0, (s, u) => s + u.tasksOverdue);
    final scDone = scorecards.where((s) => s.quarter == 'Q2' && s.year == 2026 && s.uid.isNotEmpty && workers.any((w) => w.uid == s.uid)).length;
    return DeptHealth(
      code: d.code,
      name: d.name,
      color: d.color,
      hod: hod,
      workers: workers.length,
      reportsPct: reportsPct,
      attendancePct: att,
      tasksOverdue: overdue,
      scorecardsDone: scDone,
    );
  }).toList();
});

final deptHealthByCodeProvider = Provider.family<DeptHealth?, String>((ref, code) {
  final list = ref.watch(deptHealthProvider);
  for (final d in list) {
    if (d.code == code) return d;
  }
  return null;
});

/// Church-wide roll-up stats.
class PastorStats {
  const PastorStats({
    required this.members,
    required this.workers,
    required this.hods,
    required this.atRisk,
    required this.unreachable,
    required this.firstTimers,
    required this.scorecardsDone,
    required this.scorecardsTotal,
    required this.reportsPct,
  });
  final int members, workers, hods, atRisk, unreachable, firstTimers, scorecardsDone, scorecardsTotal, reportsPct;
}

final pastorStatsProvider = Provider<PastorStats>((ref) {
  final workers = ref.watch(pastorWorkersProvider);
  final members = ref.watch(allMembersProvider).valueOrNull ?? const <Member>[];
  final scorecards = ref.watch(pastorScorecardsProvider).valueOrNull ?? const <Scorecard>[];
  final nonHod = workers.where((w) => !w.isHod).toList();
  final withReports = nonHod.where((w) => w.bothReports).length;
  return PastorStats(
    members: members.length,
    workers: workers.length,
    hods: workers.where((w) => w.isHod).length,
    atRisk: members.where((m) => m.isAtRisk).length,
    unreachable: members.where((m) => m.unreachable).length,
    firstTimers: members.where((m) => m.isFirstTimer).length,
    scorecardsDone: scorecards.where((s) => s.quarter == 'Q2' && s.year == 2026).length,
    scorecardsTotal: workers.length,
    reportsPct: nonHod.isEmpty ? 0 : ((withReports / nonHod.length) * 100).round(),
  );
});

String _codeOf(TeamWorker u) => u.departmentName.toUpperCase().replaceAll('-', '').replaceAll(' ', '');

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
