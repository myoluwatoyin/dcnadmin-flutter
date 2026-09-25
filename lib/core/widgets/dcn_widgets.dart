import 'package:flutter/material.dart';

import '../theme/dcn_colors.dart';
import 'dcn_icon.dart';

// ─────────────────────────────────────────────────────────────
// BUTTON — primary / secondary / ghost / danger / success / plain
// ─────────────────────────────────────────────────────────────
enum DcnButtonVariant { primary, secondary, ghost, danger, success, plain }

enum DcnButtonSize { sm, md, lg }

class DcnButton extends StatelessWidget {
  const DcnButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = DcnButtonVariant.primary,
    this.size = DcnButtonSize.md,
    this.icon,
    this.iconRight,
    this.full = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final DcnButtonVariant variant;
  final DcnButtonSize size;
  final String? icon;
  final String? iconRight;
  final bool full;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final ({double h, double px, double fs, double gap}) s = switch (size) {
      DcnButtonSize.sm => (h: 36, px: 14, fs: 13, gap: 6),
      DcnButtonSize.md => (h: 44, px: 18, fs: 14, gap: 8),
      DcnButtonSize.lg => (h: 52, px: 22, fs: 15, gap: 10),
    };
    final ({Color bg, Color fg, Color border}) v = switch (variant) {
      DcnButtonVariant.primary => (bg: c.brand, fg: Colors.white, border: Colors.transparent),
      DcnButtonVariant.secondary => (bg: c.brandSoft, fg: c.brandInk, border: Colors.transparent),
      DcnButtonVariant.ghost => (bg: Colors.transparent, fg: c.text, border: c.border),
      DcnButtonVariant.danger => (bg: c.danger, fg: Colors.white, border: Colors.transparent),
      DcnButtonVariant.success => (bg: c.success, fg: Colors.white, border: Colors.transparent),
      DcnButtonVariant.plain => (bg: c.surface, fg: c.text, border: c.border),
    };
    final disabled = onPressed == null || loading;

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Material(
        color: v.bg,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: disabled ? null : onPressed,
          child: Container(
            height: s.h,
            width: full ? double.infinity : null,
            padding: EdgeInsets.symmetric(horizontal: s.px),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: v.border),
            ),
            child: Row(
              mainAxisSize: full ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading) ...[
                  SizedBox(
                    width: s.fs + 2,
                    height: s.fs + 2,
                    child: CircularProgressIndicator(strokeWidth: 2, color: v.fg),
                  ),
                  SizedBox(width: s.gap),
                ] else if (icon != null) ...[
                  DcnIcon(icon!, size: s.fs + 4, color: v.fg),
                  SizedBox(width: s.gap),
                ],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: v.fg,
                      fontSize: s.fs,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.14,
                    ),
                  ),
                ),
                if (iconRight != null) ...[
                  SizedBox(width: s.gap),
                  DcnIcon(iconRight!, size: s.fs + 4, color: v.fg),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CARD — surface with 16 radius, 1px border, optional press
// ─────────────────────────────────────────────────────────────
class DcnCard extends StatelessWidget {
  const DcnCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final content = Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      padding: padding,
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CHIP / BADGE — tonal (soft bg + saturated text)
// ─────────────────────────────────────────────────────────────
enum DcnTone { neutral, brand, success, warning, danger, info }

class DcnChip extends StatelessWidget {
  const DcnChip({
    super.key,
    required this.label,
    this.tone = DcnTone.neutral,
    this.icon,
    this.size = DcnButtonSize.md,
  });

  final String label;
  final DcnTone tone;
  final String? icon;
  final DcnButtonSize size;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final ({Color bg, Color fg}) t = switch (tone) {
      DcnTone.neutral => (bg: c.surface2, fg: c.textMuted),
      DcnTone.brand => (bg: c.brandSoft, fg: c.brandInk),
      DcnTone.success => (bg: c.successSoft, fg: c.success),
      DcnTone.warning => (bg: c.warningSoft, fg: c.warning),
      DcnTone.danger => (bg: c.dangerSoft, fg: c.danger),
      DcnTone.info => (bg: c.infoSoft, fg: c.info),
    };
    final ({double h, double px, double fs}) s = switch (size) {
      DcnButtonSize.sm => (h: 20, px: 8, fs: 10),
      DcnButtonSize.md => (h: 24, px: 10, fs: 11),
      DcnButtonSize.lg => (h: 28, px: 12, fs: 12),
    };
    return Container(
      height: s.h,
      padding: EdgeInsets.symmetric(horizontal: s.px),
      decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            DcnIcon(icon!, size: s.fs + 2, color: t.fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(color: t.fg, fontSize: s.fs, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FIELD — labeled text input, optional leading icon / hint / error
// ─────────────────────────────────────────────────────────────
class DcnField extends StatelessWidget {
  const DcnField({
    super.key,
    this.label,
    this.controller,
    this.value,
    this.onChanged,
    this.placeholder,
    this.icon,
    this.hint,
    this.error,
    this.obscure = false,
    this.multiline = false,
    this.keyboardType,
    this.trailing,
    this.enabled = true,
  });

  final String? label;
  final TextEditingController? controller;
  final String? value;
  final ValueChanged<String>? onChanged;
  final String? placeholder;
  final String? icon;
  final String? hint;
  final String? error;
  final bool obscure;
  final bool multiline;
  final TextInputType? keyboardType;
  final Widget? trailing;
  final bool enabled;

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
        Container(
          constraints: BoxConstraints(minHeight: multiline ? 88 : 48),
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: multiline ? 12 : 0),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: error != null ? c.danger : c.border),
          ),
          child: Row(
            crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Padding(
                  padding: EdgeInsets.only(top: multiline ? 2 : 0),
                  child: DcnIcon(icon!, size: 18, color: c.textDim),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  obscureText: obscure,
                  enabled: enabled,
                  keyboardType: keyboardType ??
                      (multiline ? TextInputType.multiline : TextInputType.text),
                  maxLines: multiline ? 4 : 1,
                  minLines: multiline ? 3 : 1,
                  style: TextStyle(fontSize: 15, color: c.text),
                  cursorColor: c.brand,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: placeholder,
                    hintStyle: TextStyle(color: c.textDim, fontSize: 15),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(error!, style: TextStyle(fontSize: 11, color: c.danger)),
          )
        else if (hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(hint!, style: TextStyle(fontSize: 11, color: c.textDim)),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────────
class DcnSectionHeader extends StatelessWidget {
  const DcnSectionHeader({super.key, required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: c.text,
              letterSpacing: -0.15,
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Row(
                children: [
                  Text(
                    action!,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.brand),
                  ),
                  DcnIcon('chevronRight', size: 14, color: c.brand),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AVATAR — initials fallback
// ─────────────────────────────────────────────────────────────
class DcnAvatar extends StatelessWidget {
  const DcnAvatar({super.key, this.name = '?', this.size = 36, this.photoUrl});

  final String name;
  final double size;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initials(c),
        ),
      );
    }
    return _initials(c);
  }

  Widget _initials(DcnColors c) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts
        .take(2)
        .map((s) => s.isNotEmpty ? s[0] : '')
        .join()
        .toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.brand, shape: BoxShape.circle),
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SEGMENTED CONTROL
// ─────────────────────────────────────────────────────────────
class DcnSegmented extends StatelessWidget {
  const DcnSegmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.small = false,
  });

  /// Each option is (id, label).
  final List<({String id, String label})> options;
  final String value;
  final ValueChanged<String> onChanged;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(o.id),
                child: Container(
                  height: small ? 32 : 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == o.id ? c.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: value == o.id
                        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 2)]
                        : null,
                  ),
                  child: Text(
                    o.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: small ? 12 : 13,
                      fontWeight: FontWeight.w600,
                      color: value == o.id ? c.text : c.textMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TOGGLE — pill switch
// ─────────────────────────────────────────────────────────────
class DcnToggle extends StatelessWidget {
  const DcnToggle({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 42,
        height: 24,
        decoration: BoxDecoration(
          color: value ? c.brand : c.border,
          borderRadius: BorderRadius.circular(99),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STAT TILE — dashboard metric card
// ─────────────────────────────────────────────────────────────
class DcnStatTile extends StatelessWidget {
  const DcnStatTile({
    super.key,
    required this.label,
    required this.value,
    this.sub,
    this.icon,
    this.tone = DcnTone.brand,
    this.onTap,
  });

  final String label;
  final String value;
  final String? sub;
  final String? icon;
  final DcnTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    final ({Color bg, Color fg}) t = switch (tone) {
      DcnTone.neutral => (bg: c.surface2, fg: c.textMuted),
      DcnTone.brand => (bg: c.brandSoft, fg: c.brand),
      DcnTone.success => (bg: c.successSoft, fg: c.success),
      DcnTone.warning => (bg: c.warningSoft, fg: c.warning),
      DcnTone.danger => (bg: c.dangerSoft, fg: c.danger),
      DcnTone.info => (bg: c.infoSoft, fg: c.info),
    };
    return DcnCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: c.textMuted,
                  ),
                ),
              ),
              if (icon != null)
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: t.bg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DcnIcon(icon!, size: 15, color: t.fg),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: c.text,
              letterSpacing: -0.5,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(
              sub!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: t.fg, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────
class DcnEmptyState extends StatelessWidget {
  const DcnEmptyState({
    super.key,
    this.icon = 'sparkle',
    required this.title,
    this.body,
    this.action,
    this.onAction,
  });

  final String icon;
  final String title;
  final String? body;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.dcn;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.brandSoft, shape: BoxShape.circle),
            child: DcnIcon(icon, size: 28, color: c.brand),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.text),
          ),
          if (body != null) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: 240,
              child: Text(
                body!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: c.textMuted),
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 16),
            DcnButton(label: action!, size: DcnButtonSize.sm, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}
