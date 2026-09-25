import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_scroll_scaffold.dart';
import '../../../core/widgets/dcn_sheet.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/weekly_report.dart';
import '../data/worker_providers.dart';

/// Bible & prayer report tab: streak hero, this-week status, history, and a
/// compose sheet that submits the week's entry to Firestore and bumps the streak.
class WorkerReportScreen extends ConsumerWidget {
  const WorkerReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dcn;
    final reportsA = ref.watch(workerReportsProvider);
    final reports = reportsA.valueOrNull ?? const <WeeklyReport>[];

    var streak = 0;
    var seenSubmitted = false;
    for (final r in reports) {
      if (r.submitted) {
        streak++;
        seenSubmitted = true;
      } else if (seenSubmitted) {
        break;
      }
    }
    final thisWeek = reports.isNotEmpty ? reports.first : null;
    final due = thisWeek == null || !thisWeek.submitted;

    Widget header(bool scrolled) =>
        DcnHeaderBar(scrolled: scrolled, title: 'Bible & Prayer', sub: 'Weekly report');

    if (reportsA.isLoading && !reportsA.hasValue) {
      return DcnScrollScaffold(
        header: header,
        child: const Padding(
          padding: EdgeInsets.only(top: 80),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return DcnScrollScaffold(
      header: header,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // streak hero (orange flame)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const DcnIcon('flame', size: 28, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$streak week streak',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                      Text(
                        due ? 'This week is still open' : 'This week is logged 🎉',
                        style: TextStyle(
                            fontSize: 12.5, color: Colors.white.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // this-week card
          DcnCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('This week',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
                    DcnChip(
                      label: due ? 'Due Thursday' : 'Submitted',
                      tone: due ? DcnTone.warning : DcnTone.success,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DcnButton(
                  label: due ? 'Log this week' : 'Update entry',
                  full: true,
                  icon: 'bookOpen',
                  onPressed: () => _openCompose(context, ref, thisWeek),
                ),
              ],
            ),
          ),
          if (reports.length > 1) ...[
            const DcnSectionHeader(title: 'History'),
            for (final r in reports.skip(due ? 1 : 0))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _HistoryCard(report: r),
              ),
          ] else if (reports.isEmpty) ...[
            const SizedBox(height: 24),
            DcnEmptyState(
              icon: 'bookOpen',
              title: 'No reports yet',
              body: 'Log your Bible reading and prayer each week to build your streak.',
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openCompose(
    BuildContext context,
    WidgetRef ref,
    WeeklyReport? current,
  ) async {
    final bible = TextEditingController(text: current?.bible ?? '');
    final prayer = TextEditingController(text: current?.prayer ?? '');
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    // Derive the week identity from the current open report, or start a new one.
    final week = current?.weekNumber ?? DateTime.now().difference(DateTime(DateTime.now().year)).inDays ~/ 7 + 1;
    final label = current?.weekLabel.isNotEmpty == true
        ? current!.weekLabel
        : 'W$week · This week';
    final reportId = '${uid}_w$week';

    await showDcnSheet<void>(
      context: context,
      title: 'This week — W$week',
      builder: (ctx) {
        final c = ctx.dcn;
        var busy = false;
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            Future<void> submit() async {
              if (bible.text.trim().isEmpty || prayer.text.trim().isEmpty) return;
              setSheet(() => busy = true);
              try {
                await ref.read(workerRepositoryProvider).submitReport(
                      uid,
                      reportId: reportId,
                      weekNumber: week,
                      weekLabel: label,
                      bible: bible.text,
                      prayer: prayer.text,
                    );
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Week submitted 🔥'),
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              } catch (_) {
                setSheet(() => busy = false);
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text('Could not submit. Try again.'),
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DcnField(
                  label: 'Bible reading',
                  controller: bible,
                  icon: 'bookOpen',
                  placeholder: 'What passage(s) did you read this week?',
                  multiline: true,
                ),
                const SizedBox(height: 12),
                DcnField(
                  label: 'Prayer log',
                  controller: prayer,
                  icon: 'flame',
                  placeholder: 'A brief personal prayer report…',
                  multiline: true,
                ),
                const SizedBox(height: 14),
                DcnButton(
                  label: busy ? 'Submitting…' : 'Submit week',
                  icon: 'send',
                  full: true,
                  loading: busy,
                  onPressed: busy ? null : submit,
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text("Submitted entries can't be edited after Thursday.",
                      style: TextStyle(fontSize: 11.5, color: c.textDim)),
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.report});
  final WeeklyReport report;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return DcnCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(report.weekLabel,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text)),
              DcnChip(
                label: report.submitted ? 'Logged' : 'Missed',
                tone: report.submitted ? DcnTone.success : DcnTone.neutral,
                size: DcnButtonSize.sm,
              ),
            ],
          ),
          if (report.bible.isNotEmpty && report.bible != '—') ...[
            const SizedBox(height: 8),
            _line(c, 'book', report.bible),
          ],
          if (report.prayer.isNotEmpty && report.prayer != '—') ...[
            const SizedBox(height: 6),
            _line(c, 'sparkle', report.prayer),
          ],
        ],
      ),
    );
  }

  Widget _line(DcnColors c, String icon, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: DcnIcon(icon, size: 13, color: c.textDim),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12.5, color: c.textMuted, height: 1.4)),
          ),
        ],
      );
}
