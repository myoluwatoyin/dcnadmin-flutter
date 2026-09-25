import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shell/persona_scaffold.dart';
import '../data/fu_hod_providers.dart';
import 'fu_hod_home_screen.dart';
import 'fu_hod_members_screen.dart';
import 'fu_hod_more_screen.dart';
import 'fu_hod_sms_screen.dart';
import 'fu_hod_workers_screen.dart';

/// Follow-Up HOD shell: Home · Members · Workers · SMS · More.
class FuHodShell extends ConsumerStatefulWidget {
  const FuHodShell({super.key});

  @override
  ConsumerState<FuHodShell> createState() => _State();
}

class _State extends ConsumerState<FuHodShell> {
  int _index = 0;
  static const _order = ['home', 'members', 'workers', 'sms', 'more'];

  void _openTab(String id) {
    final i = _order.indexOf(id);
    if (i >= 0) setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final absence = ref.watch(absenceQueueProvider).length;

    return PersonaScaffold(
      activeIndex: _index,
      onIndexChanged: (i) => setState(() => _index = i),
      badges: {if (absence > 0) 'members': absence},
      tabs: [
        PersonaTab(id: 'home', label: 'Home', icon: 'home', builder: (_) => FuHodHomeScreen(onOpenTab: _openTab)),
        PersonaTab(id: 'members', label: 'Members', icon: 'users', builder: (_) => const FuHodMembersScreen()),
        PersonaTab(id: 'workers', label: 'Team', icon: 'user', builder: (_) => const FuHodWorkersScreen()),
        PersonaTab(id: 'sms', label: 'SMS', icon: 'send', builder: (_) => const FuHodSmsScreen()),
        PersonaTab(id: 'more', label: 'More', icon: 'moreH', builder: (_) => FuHodMoreScreen(onOpenTab: _openTab)),
      ],
    );
  }
}
