import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/dcn_colors.dart';
import '../../../core/widgets/dcn_icon.dart';
import '../../../core/widgets/dcn_widgets.dart';
import '../../../models/department.dart';

/// "Who invited you?" autocomplete. Calls the backend worker search as the user
/// types (min 2 chars, ~300ms debounce), shows results with avatar + dept ·
/// sub-unit + role, and a cleared selected state — per the brief. Stores both
/// the worker id and display name via [onSelected].
class WorkerSearchField extends ConsumerStatefulWidget {
  const WorkerSearchField({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.placeholder,
  });

  final String label;
  final WorkerRef? selected;
  final ValueChanged<WorkerRef?> onSelected;
  final String? placeholder;

  @override
  ConsumerState<WorkerSearchField> createState() => _WorkerSearchFieldState();
}

class _WorkerSearchFieldState extends ConsumerState<WorkerSearchField> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<WorkerRef> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final q = value.trim();
    if (q.length < 2) {
      setState(() {
        _results = [];
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final res = await ref.read(signupRepositoryProvider).searchWorkers(q);
        if (mounted) {
          setState(() {
            _results = res;
            _loading = false;
            _error = null;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = 'Could not search right now.';
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final sel = widget.selected;

    if (sel != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textMuted)),
          const SizedBox(height: 6),
          DcnCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                DcnAvatar(name: sel.name, size: 40, photoUrl: sel.photoUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sel.name,
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
                      Text(
                        [sel.departmentName, sel.subUnitName]
                            .where((s) => (s ?? '').isNotEmpty)
                            .join(' · '),
                        style: TextStyle(fontSize: 12, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
                if (sel.role != null) DcnChip(label: sel.role!, tone: DcnTone.brand),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    widget.onSelected(null);
                    _controller.clear();
                    setState(() => _results = []);
                  },
                  child: DcnIcon('x', size: 18, color: c.textDim),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DcnField(
          label: widget.label,
          controller: _controller,
          icon: 'search',
          placeholder: widget.placeholder ?? 'Search the worker who invited you…',
          onChanged: _onChanged,
          error: _error,
        ),
        if (_loading)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: c.textDim)),
                const SizedBox(width: 8),
                Text('Searching…', style: TextStyle(fontSize: 12, color: c.textMuted)),
              ],
            ),
          ),
        if (!_loading && _results.isNotEmpty) ...[
          const SizedBox(height: 8),
          DcnCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < _results.length; i++)
                  InkWell(
                    onTap: () {
                      widget.onSelected(_results[i]);
                      FocusScope.of(context).unfocus();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: i == _results.length - 1
                            ? null
                            : Border(bottom: BorderSide(color: c.divider)),
                      ),
                      child: Row(
                        children: [
                          DcnAvatar(
                              name: _results[i].name,
                              size: 34,
                              photoUrl: _results[i].photoUrl),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_results[i].name,
                                    style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: c.text)),
                                Text(
                                  [_results[i].departmentName, _results[i].subUnitName]
                                      .where((s) => (s ?? '').isNotEmpty)
                                      .join(' · '),
                                  style: TextStyle(fontSize: 11.5, color: c.textMuted),
                                ),
                              ],
                            ),
                          ),
                          if (_results[i].role != null)
                            DcnChip(
                                label: _results[i].role!,
                                tone: DcnTone.brand,
                                size: DcnButtonSize.sm),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
