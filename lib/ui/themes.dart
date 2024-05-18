import 'package:flutter/material.dart';

class CustomThemeData {
  static final Color _darkFocusColor = Colors.white.withOpacity(0.12);

  static ThemeData oledThemeData = themeData(oledColorScheme, _darkFocusColor);

  static ThemeData themeData(ColorScheme colorScheme, Color focusColor) {
    Color customTextColor = Color.alphaBlend(Colors.white.withAlpha((0.48 * 255).toInt()), colorScheme.primary);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      primaryColor: colorScheme.primary,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
      ),
      iconTheme: IconThemeData(color: colorScheme.onPrimary),
      scaffoldBackgroundColor: colorScheme.surface,
      highlightColor: Colors.transparent,
      focusColor: focusColor,
      canvasColor: colorScheme.primary,
      dialogBackgroundColor: colorScheme.primary,
      cardColor: colorScheme.primary,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: customTextColor,
        selectionColor: customTextColor,
        selectionHandleColor: customTextColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(
          color: customTextColor,
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: customTextColor,
          ),
        ),
        border: UnderlineInputBorder(
          borderSide: BorderSide(
            color: customTextColor,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: customTextColor,
        inactiveTrackColor: customTextColor.withAlpha(50),
        thumbColor: customTextColor,
      ),
      bottomSheetTheme: BottomSheetThemeData(modalBackgroundColor: colorScheme.primary),
      dividerColor: const Color(0x1FFFFFFF),
      dividerTheme: DividerThemeData(color: colorScheme.secondaryContainer),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return customTextColor.withAlpha(50);
          } else {
            return colorScheme.surface;
          }
        }),
      ),
    );
  }

  static const ColorScheme oledColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xff212529),
    onPrimary: Colors.white,
    secondary: Color(0xff484d51),
    onSecondary: Colors.white,
    error: Colors.red,
    onError: Colors.white,
    surface: Colors.black,
    onSurface: Colors.white,
  );
}
