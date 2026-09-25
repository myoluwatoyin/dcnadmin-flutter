import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shell/persona_scaffold.dart';
import '../data/worker_providers.dart';
import 'worker_home_screen.dart';
import 'worker_more_screen.dart';
import 'worker_report_screen.dart';
import 'worker_schedule_screen.dart';
import 'worker_tasks_screen.dart';

/// Worker persona shell: Home · Tasks · Report · Schedule · More.
class WorkerShell extends ConsumerStatefulWidget {
  const WorkerShell({super.key});

  @override
  ConsumerState<WorkerShell> createState() => _WorkerShellState();
}

class _WorkerShellState extends ConsumerState<WorkerShell> {
  int _index = 0;

  static const _order = ['home', 'tasks', 'report', 'schedule', 'more'];

  void _openTab(String tabId) {
    final i = _order.indexOf(tabId);
    if (i >= 0) setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    // Badge the Tasks tab with the count of active tasks.
    final active =
        ref.watch(workerTasksProvider).valueOrNull?.where((t) => t.isActive).length ?? 0;

    return PersonaScaffold(
      activeIndex: _index,
      onIndexChanged: (i) => setState(() => _index = i),
      badges: {if (active > 0) 'tasks': active},
      tabs: [
        PersonaTab(
          id: 'home',
          label: 'Home',
          icon: 'home',
          builder: (_) => WorkerHomeScreen(onOpenTab: _openTab),
        ),
        PersonaTab(
          id: 'tasks',
          label: 'Tasks',
          icon: 'clipboard',
          builder: (_) => const WorkerTasksScreen(),
        ),
        PersonaTab(
          id: 'report',
          label: 'Report',
          icon: 'bookOpen',
          builder: (_) => const WorkerReportScreen(),
        ),
        PersonaTab(
          id: 'schedule',
          label: 'Schedule',
          icon: 'calendar',
          builder: (_) => const WorkerScheduleScreen(),
        ),
        PersonaTab(
          id: 'more',
          label: 'More',
          icon: 'moreH',
          builder: (_) => WorkerMoreScreen(onOpenTab: _openTab),
        ),
      ],
    );
  }
}
