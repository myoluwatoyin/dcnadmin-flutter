import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/storage_service.dart';
import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/app_user.dart';
import '../../../models/task.dart';
import '../../../models/weekly_report.dart';
import '../data/worker_providers.dart';

class WorkerProfileScreen extends ConsumerStatefulWidget {
  const WorkerProfileScreen({super.key});
  @override
  ConsumerState<WorkerProfileScreen> createState() => _State();
}

class _State extends ConsumerState<WorkerProfileScreen> {
  bool _showKey = false;
  bool _uploadingPhoto = false;
  String? _localPhotoUrl;

  Future<void> _changePhoto(AppUser user) async {
    if (_uploadingPhoto) return;
    try {
      final path = await ref.read(storageServiceProvider).pickImage();
      if (path == null) return;
      setState(() => _uploadingPhoto = true);
      final url = await ref.read(storageServiceProvider).uploadUserPhoto(user.id, path);
      await ref.read(authRepositoryProvider).updateProfilePhoto(user.id, url);
      if (!mounted) return;
      setState(() {
        _localPhotoUrl = url;
        _uploadingPhoto = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Profile photo updated'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not update photo. Please try again.'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final user = ref.watch(authStateProvider).valueOrNull;
    final tasks = ref.watch(workerTasksProvider).valueOrNull ?? const <Task>[];
    final reports = ref.watch(workerReportsProvider).valueOrNull ?? const <WeeklyReport>[];

    final tasksDone = tasks.where((t) => t.status == TaskStatus.approved).length;
    final reportsCount = reports.where((r) => r.submitted).length;
    final rate = reports.isEmpty
        ? '—'
        : '${((reportsCount / reports.length) * 100).round()}%';

    var streak = 0;
    var seen = false;
    for (final r in reports) {
      if (r.submitted) {
        streak++;
        seen = true;
      } else if (seen) {
        break;
      }
    }

    final deptSub = [user?.departmentName, user?.subUnitName]
        .where((s) => (s ?? '').isNotEmpty)
        .join(' · ');

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DcnHeaderBar(title: 'Profile', onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: user == null ? null : () => _changePhoto(user),
                          child: Stack(
                            children: [
                              DcnAvatar(
                                name: user?.fullName ?? '?',
                                size: 84,
                                photoUrl: _localPhotoUrl ?? user?.photoUrl,
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: c.brand,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: c.bg, width: 2),
                                  ),
                                  child: _uploadingPhoto
                                      ? const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(Colors.white),
                                          ),
                                        )
                                      : const DcnIcon('camera', size: 14, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(user?.fullName.isNotEmpty == true ? user!.fullName : 'Worker',
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w800, color: c.text)),
                        if (deptSub.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(deptSub, style: TextStyle(fontSize: 13.5, color: c.textMuted)),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: [
                            if (user?.role != null)
                              DcnChip(label: user!.role!.wire, tone: DcnTone.brand),
                            if ((user?.memberId ?? '').isNotEmpty)
                              DcnChip(label: user!.memberId, tone: DcnTone.neutral),
                            DcnChip(label: '${streak}w streak', tone: DcnTone.success, icon: 'flame'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(child: _MiniStat(label: 'Tasks done', value: '$tasksDone')),
                        const SizedBox(width: 8),
                        Expanded(child: _MiniStat(label: 'Reports', value: '$reportsCount')),
                        const SizedBox(width: 8),
                        Expanded(child: _MiniStat(label: 'Service rate', value: rate)),
                      ],
                    ),
                  ),
                  if ((user?.accessKey ?? '').isNotEmpty) ...[
                    const DcnSectionHeader(title: 'Access key'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DcnCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Your department access key. Don't share it.",
                                style: TextStyle(
                                    fontSize: 12, color: c.textMuted, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: c.surface2,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  DcnIcon('lock', size: 18, color: c.brand),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _showKey ? user!.accessKey! : '•••••••••••••••',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: c.text,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => setState(() => _showKey = !_showKey),
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: DcnIcon(_showKey ? 'eyeOff' : 'eye', size: 18, color: c.brand),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: user!.accessKey!));
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                        content: Text('Copied to clipboard'),
                                        behavior: SnackBarBehavior.floating,
                                      ));
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: DcnIcon('upload', size: 18, color: c.brand),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const DcnSectionHeader(title: 'Personal details'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DcnCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _DetailRow(icon: 'phone', label: 'Phone', value: user?.phone),
                          _DetailRow(icon: 'user', label: 'Email', value: user?.email),
                          _DetailRow(
                              icon: 'school',
                              label: 'School',
                              value: [user?.school, user?.level]
                                  .where((s) => (s ?? '').isNotEmpty)
                                  .join(' · ')),
                          _DetailRow(icon: 'cake', label: 'Birthday', value: user?.dob),
                          _DetailRow(icon: 'calendar', label: 'Joined', value: user?.joinedLabel, last: true),
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
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return DcnCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.text)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: c.textMuted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, this.value, this.last = false});
  final String icon;
  final String label;
  final String? value;
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
                Text(label, style: TextStyle(fontSize: 11, color: c.textMuted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text((value ?? '').isNotEmpty ? value! : '—',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: c.text)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
