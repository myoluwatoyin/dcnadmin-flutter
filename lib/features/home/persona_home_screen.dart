import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/dcn_colors.dart';
import '../../core/widgets/dcn_icon.dart';
import '../../core/widgets/dcn_widgets.dart';
import '../../models/app_user.dart';
import '../../models/enums.dart';

/// Placeholder landing shown after a successful, approved sign-in. Confirms the
/// derived persona and provides sign-out. The full role dashboards are the next
/// build slices; this proves auth + routing end-to-end.
class PersonaHomeScreen extends ConsumerWidget {
  const PersonaHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final AppUser? user = ref.watch(authStateProvider).valueOrNull;
    final persona = user?.persona ?? Persona.worker;
    final label = switch (persona) {
      Persona.worker => 'Worker',
      Persona.followupWorker => 'Follow-Up Worker',
      Persona.hod => 'HOD',
      Persona.followupHod => 'Follow-Up HOD',
      Persona.pastor => 'Pastor / Admin',
    };

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: c.brandSoft, shape: BoxShape.circle),
                  child: DcnIcon('home', size: 32, color: c.brand),
                ),
                const SizedBox(height: 16),
                Text(
                  'Welcome${user?.fullName.isNotEmpty == true ? ', ${user!.fullName}' : ''}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.text),
                ),
                const SizedBox(height: 6),
                Text(
                  'Signed in as $label',
                  style: TextStyle(fontSize: 14, color: c.textMuted),
                ),
                const SizedBox(height: 4),
                DcnChip(label: '$label dashboard — coming next', tone: DcnTone.brand),
                const SizedBox(height: 28),
                DcnButton(
                  label: 'Sign out',
                  variant: DcnButtonVariant.plain,
                  icon: 'logout',
                  onPressed: () => ref.read(authRepositoryProvider).signOut(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
