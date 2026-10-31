import 'package:flutter/material.dart';

@immutable
class TihoColors extends ThemeExtension<TihoColors> {
  const TihoColors({
    required this.paper,
    required this.ink,
    required this.muted,
    required this.sage,
    required this.green,
    required this.peach,
    required this.white,
    required this.line,
    required this.blue,
  });
  final Color paper, ink, muted, sage, green, peach, white, line, blue;
  static const light = TihoColors(
    paper: Color(0xFFF7F3EA),
    ink: Color(0xFF303E35),
    muted: Color(0xFF737C70),
    sage: Color(0xFFE3E9DB),
    green: Color(0xFF526A50),
    peach: Color(0xFFF4D5B5),
    white: Color(0xFFFFFDF8),
    line: Color(0xFFE4E4D8),
    blue: Color(0xFFE2E9ED),
  );
  static const dark = TihoColors(
    paper: Color(0xFF18231F),
    ink: Color(0xFFF1EDDF),
    muted: Color(0xFFAFB9AC),
    sage: Color(0xFF344738),
    green: Color(0xFFC2D5B1),
    peach: Color(0xFF594536),
    white: Color(0xFF24312A),
    line: Color(0xFF3A483E),
    blue: Color(0xFF30434A),
  );
  @override
  TihoColors copyWith({
    Color? paper,
    Color? ink,
    Color? muted,
    Color? sage,
    Color? green,
    Color? peach,
    Color? white,
    Color? line,
    Color? blue,
  }) => TihoColors(
    paper: paper ?? this.paper,
    ink: ink ?? this.ink,
    muted: muted ?? this.muted,
    sage: sage ?? this.sage,
    green: green ?? this.green,
    peach: peach ?? this.peach,
    white: white ?? this.white,
    line: line ?? this.line,
    blue: blue ?? this.blue,
  );
  @override
  TihoColors lerp(covariant TihoColors? other, double t) {
    if (other == null) return this;
    return TihoColors(
      paper: Color.lerp(paper, other.paper, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      sage: Color.lerp(sage, other.sage, t)!,
      green: Color.lerp(green, other.green, t)!,
      peach: Color.lerp(peach, other.peach, t)!,
      white: Color.lerp(white, other.white, t)!,
      line: Color.lerp(line, other.line, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
    );
  }
}

extension TihoContext on BuildContext {
  TihoColors get colors => Theme.of(this).extension<TihoColors>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

ThemeData tihoTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? TihoColors.dark : TihoColors.light;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'Manrope',
    extensions: [c],
    scaffoldBackgroundColor: c.paper,
    canvasColor: c.paper,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.green,
      brightness: brightness,
      surface: c.paper,
      onSurface: c.ink,
      primary: c.green,
      surfaceContainerHighest: c.sage,
    ),
    textTheme: TextTheme(
      headlineMedium: TextStyle(
        fontFamily: 'Lora',
        fontSize: 27,
        height: 1.4,
        color: c.ink,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: c.ink,
      ),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: c.ink),
      bodySmall: TextStyle(fontSize: 12, height: 1.4, color: c.muted),
    ),
    iconTheme: IconThemeData(color: c.green, size: 22),
    dividerColor: c.line,
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.green,
        textStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.sage,
        foregroundColor: c.green,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.paper,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.white,
      hintStyle: TextStyle(color: c.muted, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    ),
  );
}
