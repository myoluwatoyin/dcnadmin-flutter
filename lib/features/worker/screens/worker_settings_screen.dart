import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_widgets.dart';

class WorkerSettingsScreen extends ConsumerStatefulWidget {
  const WorkerSettingsScreen({super.key});
  @override
  ConsumerState<WorkerSettingsScreen> createState() => _State();
}

class _State extends ConsumerState<WorkerSettingsScreen> {
  bool _reminders = true;
  bool _smsBackup = false;
  bool _partnerNudges = true;
  bool _biometric = true;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final mode = ref.watch(themeModeProvider);
    final isDark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'Settings', onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  _Group(title: 'Appearance', rows: [
                    _SettingRow(
                      icon: 'sparkle',
                      label: 'Dark mode',
                      sub: 'Override your phone setting',
                      trailing: DcnToggle(
                        value: isDark,
                        onChanged: (v) => ref.read(themeModeProvider.notifier).state =
                            v ? ThemeMode.dark : ThemeMode.light,
                      ),
                    ),
                  ]),
                  _Group(title: 'Notifications', rows: [
                    _SettingRow(
                      icon: 'bell',
                      label: 'Push reminders',
                      sub: 'Tasks, meetings, reports',
                      trailing: DcnToggle(value: _reminders, onChanged: (v) => setState(() => _reminders = v)),
                    ),
                    _SettingRow(
                      icon: 'msg',
                      label: 'SMS backup',
                      sub: 'Get critical alerts via text too',
                      trailing: DcnToggle(value: _smsBackup, onChanged: (v) => setState(() => _smsBackup = v)),
                    ),
                    _SettingRow(
                      icon: 'users',
                      label: 'Accountability nudges',
                      sub: 'When your partner misses a week',
                      trailing: DcnToggle(value: _partnerNudges, onChanged: (v) => setState(() => _partnerNudges = v)),
                      last: true,
                    ),
                  ]),
                  _Group(title: 'Privacy', rows: [
                    _SettingRow(
                      icon: 'eye',
                      label: 'Profile visibility',
                      sub: 'Who can see your phone & email',
                      trailing: Text('HOD only',
                          style: TextStyle(fontSize: 12.5, color: c.textMuted, fontWeight: FontWeight.w600)),
                    ),
                    _SettingRow(icon: 'lock', label: 'Change password', chevron: true),
                    _SettingRow(
                      icon: 'fingerprint',
                      label: 'Biometric unlock',
                      trailing: DcnToggle(value: _biometric, onChanged: (v) => setState(() => _biometric = v)),
                      last: true,
                    ),
                  ]),
                  _Group(title: 'About', rows: [
                    _SettingRow(icon: 'bookOpen', label: 'Ministry handbook', chevron: true),
                    _SettingRow(icon: 'alertCircle', label: 'Privacy policy', chevron: true),
                    _SettingRow(
                      icon: 'settings',
                      label: 'Version',
                      trailing: Text('1.0.0',
                          style: TextStyle(fontSize: 12.5, color: c.textMuted, fontWeight: FontWeight.w600)),
                      last: true,
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.rows});
  final String title;
  final List<_SettingRow> rows;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DcnSectionHeader(title: title),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DcnCard(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: rows),
          ),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    this.sub,
    this.trailing,
    this.chevron = false,
    this.last = false,
  });
  final String icon;
  final String label;
  final String? sub;
  final Widget? trailing;
  final bool chevron;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: c.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.brandSoft, borderRadius: BorderRadius.circular(10)),
            child: DcnIcon(icon, size: 16, color: c.brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text)),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(sub!, style: TextStyle(fontSize: 12, color: c.textMuted)),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
          if (chevron) DcnIcon('chevronRight', size: 18, color: c.textDim),
        ],
      ),
    );
  }
}
