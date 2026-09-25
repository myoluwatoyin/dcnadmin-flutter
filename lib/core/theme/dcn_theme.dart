import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dcn_colors.dart';

/// Builds the app [ThemeData] for a given brightness, wiring the DCN palette
/// into Material and setting Inter (weights 400–800) as the type family, per the
/// prototype's design tokens.
class DcnTheme {
  static ThemeData light() => _build(Brightness.light, DcnColors.light);
  static ThemeData dark() => _build(Brightness.dark, DcnColors.dark);

  static ThemeData _build(Brightness brightness, DcnColors c) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: c.text,
      displayColor: c.text,
    );

    return base.copyWith(
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      textTheme: textTheme,
      primaryColor: c.brand,
      dividerColor: c.divider,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.brand,
        onPrimary: Colors.white,
        secondary: c.brandInk,
        onSecondary: Colors.white,
        error: c.danger,
        onError: Colors.white,
        surface: c.surface,
        onSurface: c.text,
      ),
      extensions: <ThemeExtension<dynamic>>[c],
      splashFactory: InkRipple.splashFactory,
    );
  }
}
