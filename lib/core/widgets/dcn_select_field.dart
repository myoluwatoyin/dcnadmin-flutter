import 'package:flutter/material.dart';

import '../theme/dcn_colors.dart';
import 'dcn_icon.dart';
import 'dcn_sheet.dart';

/// A labeled field that opens a bottom-sheet option picker, matching the
/// prototype's SelectField. [options] are plain strings; the selected value is
/// echoed back through [onChanged].
class DcnSelectField extends StatelessWidget {
  const DcnSelectField({
    super.key,
    this.label,
    required this.value,
    required this.onChanged,
    required this.options,
    this.icon,
    this.placeholder,
    this.loading = false,
    this.emptyText,
  });

  final String? label;
  final String? value;
  final ValueChanged<String> onChanged;
  final List<String> options;
  final String? icon;
  final String? placeholder;
  final bool loading;
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textMuted),
          ),
          const SizedBox(height: 6),
        ],
        GestureDetector(
          onTap: loading ? null : () => _open(context),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  DcnIcon(icon!, size: 18, color: c.textDim),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    value ?? placeholder ?? 'Select...',
                    style: TextStyle(
                      fontSize: 15,
                      color: value != null ? c.text : c.textDim,
                    ),
                  ),
                ),
                if (loading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: c.textDim),
                  )
                else
                  DcnIcon('chevronDown', size: 18, color: c.textDim),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _open(BuildContext context) {
    final c = context.dcn;
    showDcnSheet<void>(
      context: context,
      title: label,
      builder: (ctx) {
        if (options.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              emptyText ?? 'No options available.',
              style: TextStyle(color: c.textMuted, fontSize: 14),
            ),
          );
        }
        return Column(
          children: [
            for (final o in options)
              InkWell(
                onTap: () {
                  onChanged(o);
                  Navigator.of(ctx).pop();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: c.divider)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          o,
                          style: TextStyle(
                            fontSize: 15,
                            color: c.text,
                            fontWeight: value == o ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (value == o) DcnIcon('check', size: 18, color: c.brand),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
