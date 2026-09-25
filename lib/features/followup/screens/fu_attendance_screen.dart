import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/member.dart';
import '../../worker/data/worker_providers.dart';
import '../data/fu_providers.dart';

class FuAttendanceScreen extends ConsumerStatefulWidget {
  const FuAttendanceScreen({super.key, required this.service});
  final String service; // SUNDAY | TUESDAY
  @override
  ConsumerState<FuAttendanceScreen> createState() => _State();
}

class _State extends ConsumerState<FuAttendanceScreen> {
  final Map<String, String> _marks = {};
  String _q = '';
  bool _loaded = false;
  bool _busy = false;

  bool get _isTuesday => widget.service == 'TUESDAY';
  String get _serviceName => _isTuesday ? 'Believers Equip' : 'The Experience';
  String get _date => _isTuesday ? 'Tuesday' : 'Sunday';

  void _set(String id, String val) {
    setState(() {
      if (_marks[id] == val) {
        _marks.remove(id);
      } else {
        _marks[id] = val;
      }
    });
  }

  Future<void> _save() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(fuRepositoryProvider).saveAttendance(
            uid,
            widget.service,
            serviceName: _serviceName,
            date: _date,
            marks: _marks,
          );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance saved'), behavior: SnackBarBehavior.floating));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save. Try again.'), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final members = ref.watch(fuMembersProvider).valueOrNull ?? const <Member>[];
    // Load any previously-saved marks once.
    final saved = ref.watch(fuAttendanceProvider(widget.service)).valueOrNull;
    if (!_loaded && saved != null && saved.isNotEmpty) {
      _marks.addAll(saved);
      _loaded = true;
    }

    final filtered = members.where((m) => _q.isEmpty || m.name.toLowerCase().contains(_q.toLowerCase())).toList();
    var present = 0, absent = 0, late = 0;
    for (final v in _marks.values) {
      if (v == 'present') present++;
      if (v == 'absent') absent++;
      if (v == 'late') late++;
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(
              title: _serviceName,
              sub: _date,
              onBack: () => context.pop(),
              right: [
                GestureDetector(
                  onTap: _busy ? null : _save,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: c.brand, borderRadius: BorderRadius.circular(999)),
                    child: Text('Save', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ],
            ),
            Container(
              color: c.surface,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
              child: Column(
                children: [
                  Row(children: [
                    Expanded(child: _Count(label: 'Marked', value: _marks.length, total: members.length, tone: DcnTone.brand)),
                    const SizedBox(width: 8),
                    Expanded(child: _Count(label: 'Present', value: present, tone: DcnTone.success)),
                    const SizedBox(width: 8),
                    Expanded(child: _Count(label: 'Late', value: late, tone: DcnTone.warning)),
                    const SizedBox(width: 8),
                    Expanded(child: _Count(label: 'Absent', value: absent, tone: DcnTone.danger)),
                  ]),
                  const SizedBox(height: 12),
                  DcnField(icon: 'search', placeholder: 'Find member…', onChanged: (v) => setState(() => _q = v)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            for (final m in members) {
                              _marks[m.id] = 'present';
                            }
                          }),
                          child: Container(
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: c.successSoft, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.success)),
                            child: Text('Mark all present', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.success)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _marks.clear()),
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.border)),
                          child: Text('Clear', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.textMuted)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final m = filtered[i];
                  final mark = _marks[m.id];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.border)),
                    child: Row(
                      children: [
                        DcnAvatar(name: m.name, size: 36),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.name, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.text)),
                              Text(m.isFirstTimer ? 'First-Timer' : '${m.weeksAbsent}w absent', style: TextStyle(fontSize: 11, color: c.textMuted)),
                            ],
                          ),
                        ),
                        _pal(c, mark == 'present', DcnTone.success, 'P', () => _set(m.id, 'present')),
                        const SizedBox(width: 4),
                        _pal(c, mark == 'absent', DcnTone.danger, 'A', () => _set(m.id, 'absent')),
                        const SizedBox(width: 4),
                        _pal(c, mark == 'late', DcnTone.warning, 'L', () => _set(m.id, 'late')),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pal(DcnColors c, bool active, DcnTone tone, String letter, VoidCallback onTap) {
    final fg = switch (tone) { DcnTone.success => c.success, DcnTone.danger => c.danger, _ => c.warning };
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? fg : c.surface,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: active ? fg : c.border, width: 1.5),
        ),
        child: Text(letter, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: active ? Colors.white : c.textMuted)),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.label, required this.value, this.total, required this.tone});
  final String label;
  final int value;
  final int? total;
  final DcnTone tone;
  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final fg = switch (tone) { DcnTone.success => c.success, DcnTone.danger => c.danger, DcnTone.warning => c.warning, _ => c.brand };
    final bg = switch (tone) { DcnTone.success => c.successSoft, DcnTone.danger => c.dangerSoft, DcnTone.warning => c.warningSoft, _ => c.brandSoft };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: fg)),
      child: Column(
        children: [
          Text.rich(TextSpan(children: [
            TextSpan(text: '$value', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: fg)),
            if (total != null) TextSpan(text: '/$total', style: TextStyle(fontSize: 11, color: fg.withValues(alpha: 0.7))),
          ])),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }
}
