import 'package:flutter/material.dart';

/// DCN design tokens, ported 1:1 from the prototype's `DCN_THEME` (app/ui.jsx).
///
/// Exposed as a [ThemeExtension] so any widget can read the current palette via
/// `Theme.of(context).extension<DcnColors>()!` and it swaps automatically on the
/// light/dark toggle.
@immutable
class DcnColors extends ThemeExtension<DcnColors> {
  const DcnColors({
    required this.bg,
    required this.bgSubtle,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.divider,
    required this.text,
    required this.textMuted,
    required this.textDim,
    required this.brand,
    required this.brandSoft,
    required this.brandInk,
    required this.brandDeep,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.info,
    required this.infoSoft,
  });

  // surfaces
  final Color bg;
  final Color bgSubtle;
  final Color surface;
  final Color surface2;
  final Color border;
  final Color divider;
  // ink
  final Color text;
  final Color textMuted;
  final Color textDim;
  // brand
  final Color brand;
  final Color brandSoft;
  final Color brandInk;
  final Color brandDeep;
  // semantic
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;
  final Color info;
  final Color infoSoft;

  static const light = DcnColors(
    bg: Color(0xFFFAFAFC),
    bgSubtle: Color(0xFFF3F4FF),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF7F6FB),
    border: Color(0xFFECECF1),
    divider: Color(0xFFF1F0F5),
    text: Color(0xFF111827),
    textMuted: Color(0xFF6B7280),
    textDim: Color(0xFF9CA3AF),
    brand: Color(0xFF7C3AED),
    brandSoft: Color(0xFFF3F0FF),
    brandInk: Color(0xFF5B21B6),
    brandDeep: Color(0xFF6D28D9),
    success: Color(0xFF10B981),
    successSoft: Color(0xFFECFDF5),
    warning: Color(0xFFF59E0B),
    warningSoft: Color(0xFFFEF3C7),
    danger: Color(0xFFEF4444),
    dangerSoft: Color(0xFFFEF2F2),
    info: Color(0xFF3B82F6),
    infoSoft: Color(0xFFEFF6FF),
  );

  static const dark = DcnColors(
    bg: Color(0xFF0E0B14),
    bgSubtle: Color(0xFF15111E),
    surface: Color(0xFF1B1626),
    surface2: Color(0xFF241D33),
    border: Color(0xFF2A2340),
    divider: Color(0xFF221A33),
    text: Color(0xFFF6F4FB),
    textMuted: Color(0xFFA39FB8),
    textDim: Color(0xFF6F6A85),
    brand: Color(0xFFA78BFA),
    brandSoft: Color(0xFF2C1F44),
    brandInk: Color(0xFFEDE4FF),
    brandDeep: Color(0xFF7C3AED),
    success: Color(0xFF34D399),
    successSoft: Color(0xFF0E2E26),
    warning: Color(0xFFFBBF24),
    warningSoft: Color(0xFF3A2A0E),
    danger: Color(0xFFF87171),
    dangerSoft: Color(0xFF3A1A1F),
    info: Color(0xFF60A5FA),
    infoSoft: Color(0xFF0E1F3A),
  );

  @override
  DcnColors copyWith({
    Color? bg,
    Color? bgSubtle,
    Color? surface,
    Color? surface2,
    Color? border,
    Color? divider,
    Color? text,
    Color? textMuted,
    Color? textDim,
    Color? brand,
    Color? brandSoft,
    Color? brandInk,
    Color? brandDeep,
    Color? success,
    Color? successSoft,
    Color? warning,
    Color? warningSoft,
    Color? danger,
    Color? dangerSoft,
    Color? info,
    Color? infoSoft,
  }) {
    return DcnColors(
      bg: bg ?? this.bg,
      bgSubtle: bgSubtle ?? this.bgSubtle,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      textDim: textDim ?? this.textDim,
      brand: brand ?? this.brand,
      brandSoft: brandSoft ?? this.brandSoft,
      brandInk: brandInk ?? this.brandInk,
      brandDeep: brandDeep ?? this.brandDeep,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      info: info ?? this.info,
      infoSoft: infoSoft ?? this.infoSoft,
    );
  }

  @override
  DcnColors lerp(ThemeExtension<DcnColors>? other, double t) {
    if (other is! DcnColors) return this;
    return DcnColors(
      bg: Color.lerp(bg, other.bg, t)!,
      bgSubtle: Color.lerp(bgSubtle, other.bgSubtle, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textDim: Color.lerp(textDim, other.textDim, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      brandInk: Color.lerp(brandInk, other.brandInk, t)!,
      brandDeep: Color.lerp(brandDeep, other.brandDeep, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoSoft: Color.lerp(infoSoft, other.infoSoft, t)!,
    );
  }
}

/// Convenience accessor: `context.dcn` returns the active [DcnColors].
extension DcnColorsX on BuildContext {
  DcnColors get dcn => Theme.of(this).extension<DcnColors>()!;
}
