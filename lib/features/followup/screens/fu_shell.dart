import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shell/persona_scaffold.dart';
import '../../worker/screens/worker_report_screen.dart';
import '../../worker/screens/worker_schedule_screen.dart';
import '../data/fu_providers.dart';
import 'fu_home_screen.dart';
import 'fu_members_screen.dart';
import 'fu_more_screen.dart';

/// Follow-Up worker shell: Home · Members · Report · Schedule · More.
/// Report and Schedule reuse the worker screens (both are uid-scoped).
class FuShell extends ConsumerStatefulWidget {
  const FuShell({super.key});

  @override
  ConsumerState<FuShell> createState() => _FuShellState();
}

class _FuShellState extends ConsumerState<FuShell> {
  int _index = 0;
  static const _order = ['home', 'members', 'report', 'schedule', 'more'];

  void _openTab(String id) {
    final i = _order.indexOf(id);
    if (i >= 0) setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(fuQueueProvider).where((m) => !m.queueDone).length;

    return PersonaScaffold(
      activeIndex: _index,
      onIndexChanged: (i) => setState(() => _index = i),
      badges: {if (pending > 0) 'members': pending},
      tabs: [
        PersonaTab(id: 'home', label: 'Home', icon: 'home', builder: (_) => FuHomeScreen(onOpenTab: _openTab)),
        PersonaTab(id: 'members', label: 'Members', icon: 'users', builder: (_) => const FuMembersScreen()),
        PersonaTab(id: 'report', label: 'Report', icon: 'bookOpen', builder: (_) => const WorkerReportScreen()),
        PersonaTab(id: 'schedule', label: 'Schedule', icon: 'calendar', builder: (_) => const WorkerScheduleScreen()),
        PersonaTab(id: 'more', label: 'More', icon: 'moreH', builder: (_) => FuMoreScreen(onOpenTab: _openTab)),
      ],
    );
  }
}
