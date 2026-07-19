import 'package:flutter/material.dart';

abstract final class LightSwordTheme {
  static const background = Color(0xfff8f9fa);
  static const backgroundLower = Color(0xffeef1f4);
  static const surface = Color(0xebffffff);
  static const surfaceSolid = Color(0xffffffff);
  static const surfaceMuted = Color(0xfff3f5f7);
  static const ink = Color(0xff1f2328);
  static const mutedInk = Color(0xff666c73);
  static const line = Color(0x1f5f6368);
  static const accent = Color(0xff5f6368);
  static const scripture = Color(0xff3b4046);
  static const event = Color(0xff6f5f45);
  static const prophecy = Color(0xff725a6f);

  static const panelRadius = 18.0;
  static const controlRadius = 12.0;
  static const cardRadius = 14.0;
  static const serifFontFamily = 'LightSwordSerif';
  static const serifFontFamilyFallback = ['Georgia', 'serif'];

  static ThemeData get theme {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.light,
        ).copyWith(
          primary: scripture,
          secondary: event,
          surface: surfaceSolid,
          surfaceContainerHighest: surfaceMuted,
          onSurface: ink,
          onSurfaceVariant: mutedInk,
          outline: line,
        );

    final base = ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      useMaterial3: true,
      fontFamily: serifFontFamily,
      fontFamilyFallback: serifFontFamilyFallback,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
        fontFamily: serifFontFamily,
        fontFamilyFallback: serifFontFamilyFallback,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surfaceMuted,
        selectedColor: surfaceMuted,
        side: const BorderSide(color: line),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: ink,
          backgroundColor: surfaceMuted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceSolid,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: const BorderSide(color: scripture, width: 1.4),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: surfaceSolid,
          foregroundColor: mutedInk,
          selectedBackgroundColor: scripture,
          selectedForegroundColor: Colors.white,
          side: const BorderSide(color: line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
        ),
      ),
    );
  }

  static const appBackground = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [background, backgroundLower],
    ),
  );

  static BoxDecoration panelDecoration() {
    return BoxDecoration(
      color: surface,
      border: Border.all(color: line),
      borderRadius: BorderRadius.circular(panelRadius),
      boxShadow: const [
        BoxShadow(
          color: Color(0x243f454d),
          blurRadius: 40,
          offset: Offset(0, 12),
        ),
      ],
    );
  }

  static BoxDecoration recordDecoration(Color leadingColor) {
    return BoxDecoration(
      color: surfaceSolid,
      border: Border(
        left: BorderSide(color: leadingColor, width: 3),
        top: const BorderSide(color: line),
        right: const BorderSide(color: line),
        bottom: const BorderSide(color: line),
      ),
      borderRadius: BorderRadius.circular(cardRadius),
    );
  }
}
