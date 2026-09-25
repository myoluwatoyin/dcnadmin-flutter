import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shell/persona_scaffold.dart';
import '../../worker/data/worker_providers.dart';
import 'pastor_alerts_screen.dart';
import 'pastor_departments_screen.dart';
import 'pastor_home_screen.dart';
import 'pastor_more_screen.dart';
import 'pastor_people_screen.dart';

/// Pastor / Super-Admin shell: Home · Depts · People · Alerts · More.
class PastorShell extends ConsumerStatefulWidget {
  const PastorShell({super.key});

  @override
  ConsumerState<PastorShell> createState() => _State();
}

class _State extends ConsumerState<PastorShell> {
  int _index = 0;
  static const _order = ['home', 'departments', 'people', 'alerts', 'more'];

  void _openTab(String id) {
    final i = _order.indexOf(id);
    if (i >= 0) setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final unread = ref.watch(workerUnreadCountProvider);

    return PersonaScaffold(
      activeIndex: _index,
      onIndexChanged: (i) => setState(() => _index = i),
      badges: {if (unread > 0) 'alerts': unread},
      tabs: [
        PersonaTab(id: 'home', label: 'Home', icon: 'home', builder: (_) => PastorHomeScreen(onOpenTab: _openTab)),
        PersonaTab(id: 'departments', label: 'Depts', icon: 'grid', builder: (_) => const PastorDepartmentsScreen()),
        PersonaTab(id: 'people', label: 'People', icon: 'users', builder: (_) => const PastorPeopleScreen()),
        PersonaTab(id: 'alerts', label: 'Alerts', icon: 'bell', builder: (_) => const PastorAlertsScreen()),
        PersonaTab(id: 'more', label: 'More', icon: 'moreH', builder: (_) => PastorMoreScreen(onOpenTab: _openTab)),
      ],
    );
  }
}
