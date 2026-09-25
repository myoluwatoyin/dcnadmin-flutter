import 'package:flutter/material.dart';

import '../../../core/theme/dcn_colors.dart';

/// Step heading — bold question + muted supporting line.
class StepHeading extends StatelessWidget {
  const StepHeading({super.key, required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: c.text, letterSpacing: -0.4)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 13, color: c.textMuted)),
      ],
    );
  }
}

/// Single-select pill group. Label above, wrapped pill options below.
class OptionPills extends StatelessWidget {
  const OptionPills({
    super.key,
    this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String? label;
  final List<String> options;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textMuted)),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in options)
              GestureDetector(
                onTap: () => onChanged(o),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: value == o ? c.brandSoft : c.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: value == o ? c.brand : c.border),
                  ),
                  child: Text(
                    '${value == o ? '✓ ' : ''}$o',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: value == o ? c.brandInk : c.text,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Multi-select pill group.
class MultiPills extends StatelessWidget {
  const MultiPills({
    super.key,
    this.label,
    required this.options,
    required this.values,
    required this.onToggle,
  });

  final String? label;
  final List<String> options;
  final List<String> values;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textMuted)),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in options)
              GestureDetector(
                onTap: () => onToggle(o),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: values.contains(o) ? c.brandSoft : c.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: values.contains(o) ? c.brand : c.border),
                  ),
                  child: Text(
                    '${values.contains(o) ? '✓ ' : ''}$o',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: values.contains(o) ? c.brandInk : c.text,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Inline info callout (info-toned), used for privacy notices etc.
class InfoCallout extends StatelessWidget {
  const InfoCallout({super.key, required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.infoSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.info.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 18, color: c.info),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.info)),
                const SizedBox(height: 2),
                Text(body, style: TextStyle(fontSize: 12, color: c.textMuted, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
