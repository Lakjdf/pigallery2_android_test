import 'package:flutter/material.dart';

class CustomThemeData {
  static final Color _darkFocusColor = Colors.white.withOpacity(0.12);

  static ThemeData oledThemeData = themeData(oledColorScheme, _darkFocusColor);

  static ThemeData themeData(ColorScheme colorScheme, Color focusColor) {
    Color customTextColor = Color.alphaBlend(Colors.white.withAlpha((0.48 * 255).toInt()), colorScheme.primary);
    return ThemeData(
      colorScheme: colorScheme,
      primaryColor: colorScheme.primary,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
      ),
      iconTheme: IconThemeData(color: colorScheme.onPrimary),
      scaffoldBackgroundColor: colorScheme.background,
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
    background: Colors.black,
    onBackground: Colors.white,
    surface: Color(0xff000000),
    onSurface: Colors.white,
  );
}
