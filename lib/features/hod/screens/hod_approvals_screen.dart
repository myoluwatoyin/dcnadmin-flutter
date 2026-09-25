import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/application.dart';
import '../data/hod_providers.dart';

class HodApprovalsScreen extends ConsumerWidget {
  const HodApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final async = ref.watch(hodApplicationsProvider);
    final apps = async.valueOrNull ?? const <Application>[];

    Future<void> decide(Application a, bool approved) async {
      try {
        await ref.read(hodRepositoryProvider).decideApplication(a.id, approved: approved);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(approved ? 'Worker approved · welcome SMS sent' : 'Application declined'),
            behavior: SnackBarBehavior.floating,
          ));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$e'),
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(
              title: 'Pending approvals',
              sub: '${apps.length} sign-up${apps.length == 1 ? '' : 's'} under your dept key',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: async.isLoading && !async.hasValue
                  ? const Center(child: CircularProgressIndicator())
                  : apps.isEmpty
                      ? const DcnEmptyState(icon: 'checkCircle', title: 'All caught up', body: 'No new sign-ups waiting on you.')
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: apps.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _ApplicationCard(a: apps[i], onDecide: decide),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.a, required this.onDecide});
  final Application a;
  final Future<void> Function(Application, bool) onDecide;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return DcnCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DcnAvatar(name: a.name, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text)),
                    Text('Applied ${a.appliedLabel}', style: TextStyle(fontSize: 11.5, color: c.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                _kv(c, 'School', '${a.school}${a.level.isNotEmpty ? ' · ${a.level}' : ''}'),
                if (a.subUnitPref.isNotEmpty) _kv(c, 'Wants to join', a.subUnitPref),
                if (a.responsibilities.isNotEmpty) _kv(c, 'Can serve in', a.responsibilities.join(', ')),
                if (a.phone.isNotEmpty) _kv(c, 'Phone', a.phone),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: DcnButton(label: 'Decline', variant: DcnButtonVariant.ghost, icon: 'x', full: true, onPressed: () => onDecide(a, false))),
              const SizedBox(width: 8),
              Expanded(child: DcnButton(label: 'Approve', variant: DcnButtonVariant.success, icon: 'check', full: true, onPressed: () => onDecide(a, true))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kv(DcnColors c, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(k, style: TextStyle(fontSize: 12, color: c.textMuted)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(v, textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.text)),
            ),
          ],
        ),
      );
}
