import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_sheet.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/member.dart';
import '../data/fu_hod_providers.dart';
import '../data/fu_providers.dart';
import '../widgets/fu_widgets.dart';

const _outcomes = <({String id, String label, String desc, Color color})>[
  (id: 'CALLED_SPOKE', label: 'Called & Spoke', desc: 'Reached and had a conversation', color: Color(0xFF10B981)),
  (id: 'VOICEMAIL', label: 'Left Voicemail', desc: 'Rang but went to voicemail', color: Color(0xFF3B82F6)),
  (id: 'NOT_PICKING', label: 'Not Picking', desc: 'Phone rang but no answer', color: Color(0xFFF59E0B)),
  (id: 'SWITCHED_OFF', label: 'Switched Off', desc: 'Phone unreachable', color: Color(0xFFEF4444)),
  (id: 'MESSAGED_SMS', label: 'Messaged via SMS', desc: 'Sent a text message', color: Color(0xFF8B5CF6)),
  (id: 'VISITED_PERSON', label: 'Visited in Person', desc: 'Met them face-to-face', color: Color(0xFF06B6D4)),
];

class FuMemberDetailScreen extends ConsumerStatefulWidget {
  const FuMemberDetailScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<FuMemberDetailScreen> createState() => _State();
}

class _State extends ConsumerState<FuMemberDetailScreen> {
  bool _busy = false;

  Future<void> _log(String outcome, {String? note}) async {
    final worker = ref.read(authStateProvider).valueOrNull?.fullName ?? 'You';
    setState(() => _busy = true);
    try {
      await ref.read(fuRepositoryProvider).logContact(widget.id, outcome: outcome, workerName: worker, note: note);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logged: $outcome'), behavior: SnackBarBehavior.floating));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not log. Try again.'), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openCallSheet(Member m) async {
    final note = TextEditingController();
    await showDcnSheet<void>(
      context: context,
      title: 'Log contact outcome',
      builder: (ctx) {
        final c = ctx.dcn;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What happened when you reached out to ${m.name}?', style: TextStyle(fontSize: 13, color: c.textMuted)),
            const SizedBox(height: 12),
            for (final o in _outcomes)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _log(o.label, note: note.text);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.border)),
                    child: Row(
                      children: [
                        Container(width: 36, height: 36, alignment: Alignment.center, decoration: BoxDecoration(color: o.color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(10)), child: DcnIcon('checkCircle', size: 18, color: o.color)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(o.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
                              Text(o.desc, style: TextStyle(fontSize: 12, color: c.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 6),
            DcnField(label: 'Notes (optional)', controller: note, placeholder: 'What was discussed, next steps…', multiline: true),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Future<void> _openSmsSheet(Member m) async {
    final text = TextEditingController(
      text: "Hi ${m.name.split(' ').first}, missed seeing you at The Experience — hoping you're doing OK. We'd love to see you Sunday. — DCN",
    );
    final send = await showDcnSheet<bool>(
      context: context,
      title: 'Send SMS',
      builder: (ctx) {
        final c = ctx.dcn;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Goes out from the DCN church number to ${m.phone}.', style: TextStyle(fontSize: 12.5, color: c.textMuted)),
            const SizedBox(height: 12),
            DcnField(label: 'Message', controller: text, multiline: true),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: DcnButton(label: 'Cancel', variant: DcnButtonVariant.ghost, full: true, onPressed: () => Navigator.of(ctx).pop(false))),
              const SizedBox(width: 10),
              Expanded(child: DcnButton(label: 'Send now', icon: 'send', full: true, onPressed: () => Navigator.of(ctx).pop(true))),
            ]),
            const SizedBox(height: 8),
          ],
        );
      },
    );
    if (send == true) _log('Messaged via SMS');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final m = ref.watch(memberStreamProvider(widget.id)).valueOrNull;
    if (m == null) {
      return Scaffold(backgroundColor: c.bg, body: SafeArea(child: Column(children: [DcnHeaderBar(title: 'Member', onBack: () => context.pop()), const Expanded(child: DcnEmptyState(icon: 'user', title: 'Not found', body: ''))])));
    }
    final s = memberStatus(m);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'Member', onBack: () => context.pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Center(
                      child: Column(
                        children: [
                          DcnAvatar(name: m.name, size: 84, photoUrl: m.photoUrl),
                          const SizedBox(height: 12),
                          Text(m.name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.text)),
                          const SizedBox(height: 4),
                          Text([m.school, m.level].where((x) => x.isNotEmpty).join(' · '), style: TextStyle(fontSize: 13.5, color: c.textMuted)),
                          const SizedBox(height: 10),
                          DcnChip(label: s.label, tone: s.tone),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(children: [
                        Expanded(child: _Contact(icon: 'phone', label: 'Call', tone: DcnTone.brand, onTap: () => _openCallSheet(m))),
                        const SizedBox(width: 8),
                        Expanded(child: _Contact(icon: 'msg', label: 'SMS', tone: DcnTone.info, onTap: () => _openSmsSheet(m))),
                        const SizedBox(width: 8),
                        Expanded(child: _Contact(icon: 'location', label: 'Visit', tone: DcnTone.success, onTap: () => _log('Visited in Person'))),
                      ]),
                    ),
                    const DcnSectionHeader(title: 'Last 12 Sundays'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DcnCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Attendance rate', style: TextStyle(fontSize: 12, color: c.textMuted, fontWeight: FontWeight.w600)),
                                Text('${m.attendanceRate}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c.text)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                for (final on in (m.attendance.isEmpty ? List.filled(12, false) : m.attendance))
                                  Expanded(
                                    child: Container(
                                      height: 32,
                                      margin: const EdgeInsets.symmetric(horizontal: 2),
                                      decoration: BoxDecoration(
                                        color: on ? c.success : c.dangerSoft,
                                        borderRadius: BorderRadius.circular(4),
                                        border: on ? null : Border.all(color: c.danger),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const DcnSectionHeader(title: 'Profile'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DcnCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _row(c, 'phone', 'Phone', m.phone),
                            _row(c, 'cake', 'Birthday', m.dob),
                            _row(c, 'school', 'School', [m.school, m.level].where((x) => x.isNotEmpty).join(' · ')),
                            _row(c, 'user', 'Status', m.status),
                            _row(c, 'calendar', 'First seen', m.firstSeen, last: true),
                          ],
                        ),
                      ),
                    ),
                    DcnSectionHeader(title: 'Follow-up history', action: '+ Add', onAction: () => _openCallSheet(m)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: m.followUpNotes.isEmpty
                          ? DcnCard(child: Text('No follow-up notes yet. Log a contact to start the history.', style: TextStyle(fontSize: 12.5, color: c.textMuted)))
                          : Column(
                              children: [
                                for (final n in m.followUpNotes)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: DcnCard(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              DcnAvatar(name: n.from, size: 26),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(n.from, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.text)),
                                                    Text(n.at, style: TextStyle(fontSize: 10.5, color: c.textMuted)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(n.body, style: TextStyle(fontSize: 13, color: c.text, height: 1.5)),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.border))),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: DcnButton(label: 'Log contact', icon: 'phone', size: DcnButtonSize.lg, full: true, loading: _busy, onPressed: _busy ? null : () => _openCallSheet(m)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(DcnColors c, String icon, String label, String value, {bool last = false}) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: c.divider))),
        child: Row(
          children: [
            Container(width: 32, height: 32, alignment: Alignment.center, decoration: BoxDecoration(color: c.brandSoft, borderRadius: BorderRadius.circular(10)), child: DcnIcon(icon, size: 16, color: c.brand)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 11, color: c.textMuted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(value.isNotEmpty ? value : '—', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: c.text)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _Contact extends StatelessWidget {
  const _Contact({required this.icon, required this.label, required this.tone, required this.onTap});
  final String icon;
  final String label;
  final DcnTone tone;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final t = switch (tone) {
      DcnTone.info => (bg: c.infoSoft, fg: c.info),
      DcnTone.success => (bg: c.successSoft, fg: c.success),
      _ => (bg: c.brandSoft, fg: c.brand),
    };
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            DcnIcon(icon, size: 22, color: t.fg),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: t.fg)),
          ],
        ),
      ),
    );
  }
}
