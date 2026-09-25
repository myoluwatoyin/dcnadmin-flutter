import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_header_bar.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/task.dart';
import '../data/worker_providers.dart';
import '../widgets/worker_rows.dart';

const _tabs = <({String id, String label})>[
  (id: 'ALL', label: 'All'),
  (id: 'ASSIGNED', label: 'To do'),
  (id: 'IN_PROGRESS', label: 'Active'),
  (id: 'SUBMITTED', label: 'Submitted'),
  (id: 'APPROVED', label: 'Done'),
  (id: 'OVERDUE', label: 'Overdue'),
];

class WorkerTasksScreen extends ConsumerStatefulWidget {
  const WorkerTasksScreen({super.key});

  @override
  ConsumerState<WorkerTasksScreen> createState() => _WorkerTasksScreenState();
}

class _WorkerTasksScreenState extends ConsumerState<WorkerTasksScreen> {
  String _tab = 'ALL';
  String _q = '';
  bool _scrolled = false;

  bool _match(Task t) {
    if (_tab != 'ALL' && t.status != TaskStatus.fromWire(_tab)) return false;
    if (_q.isNotEmpty && !t.title.toLowerCase().contains(_q.toLowerCase())) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final tasksA = ref.watch(workerTasksProvider);
    final all = tasksA.valueOrNull ?? const <Task>[];
    final overdue = all.where((t) => t.status == TaskStatus.overdue).length;
    final filtered = all.where(_match).toList();

    return Column(
      children: [
        DcnHeaderBar(
          scrolled: _scrolled,
          title: 'My Tasks',
          sub: '${all.length} total · $overdue overdue',
          right: [HeaderIconButton(icon: 'filter', onTap: () {})],
        ),
        // search + status chips
        Container(
          color: c.surface,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            children: [
              DcnField(
                icon: 'search',
                placeholder: 'Search tasks…',
                onChanged: (v) => setState(() => _q = v),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _tabs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final t = _tabs[i];
                    final active = _tab == t.id;
                    return GestureDetector(
                      onTap: () => setState(() => _tab = t.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: active ? c.brand : c.surface2,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          t.label,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: active ? Colors.white : c.textMuted,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: tasksA.isLoading && !tasksA.hasValue
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? DcnEmptyState(
                      icon: 'checkCircle',
                      title: 'Nothing here',
                      body: _tab == 'OVERDUE'
                          ? 'No overdue tasks. Great work.'
                          : 'No tasks match this filter.',
                    )
                  : NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        final s = n.metrics.pixels > 6;
                        if (s != _scrolled) setState(() => _scrolled = s);
                        return false;
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => TaskRow(
                          task: filtered[i],
                          onTap: () => context.push('/task/${filtered[i].id}'),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }
}
