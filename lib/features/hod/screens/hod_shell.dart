import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shell/persona_scaffold.dart';
import '../data/hod_providers.dart';
import 'hod_home_screen.dart';
import 'hod_meetings_screen.dart';
import 'hod_more_screen.dart';
import 'hod_tasks_screen.dart';
import 'hod_team_screen.dart';

/// HOD persona shell: Home · Team · Tasks · Meetings · More.
class HodShell extends ConsumerStatefulWidget {
  const HodShell({super.key});

  @override
  ConsumerState<HodShell> createState() => _HodShellState();
}

class _HodShellState extends ConsumerState<HodShell> {
  int _index = 0;
  static const _order = ['home', 'team', 'tasks', 'meetings', 'more'];

  void _openTab(String id) {
    final i = _order.indexOf(id);
    if (i >= 0) setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final review = ref.watch(hodReviewQueueProvider).length;

    return PersonaScaffold(
      activeIndex: _index,
      onIndexChanged: (i) => setState(() => _index = i),
      badges: {if (review > 0) 'tasks': review},
      tabs: [
        PersonaTab(id: 'home', label: 'Home', icon: 'home', builder: (_) => HodHomeScreen(onOpenTab: _openTab)),
        PersonaTab(id: 'team', label: 'Team', icon: 'users', builder: (_) => const HodTeamScreen()),
        PersonaTab(id: 'tasks', label: 'Tasks', icon: 'clipboard', builder: (_) => const HodTasksScreen()),
        PersonaTab(id: 'meetings', label: 'Meetings', icon: 'calendar', builder: (_) => const HodMeetingsScreen()),
        PersonaTab(id: 'more', label: 'More', icon: 'moreH', builder: (_) => const HodMoreScreen()),
      ],
    );
  }
}
