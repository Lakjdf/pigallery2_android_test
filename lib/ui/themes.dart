import 'package:flutter/material.dart';

const double toolbarHeight = 42;

class CustomThemeData {
  static final Color _darkFocusColor = Colors.white.withValues(alpha: 0.12);

  static ThemeData oledThemeData = themeData(oledColorScheme, _darkFocusColor);

  static ThemeData themeData(ColorScheme colorScheme, Color focusColor) {
    Color customTextColor = Color.alphaBlend(Colors.white.withAlpha((0.48 * 255).toInt()), colorScheme.primary);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      primaryColor: colorScheme.primary,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        toolbarHeight: toolbarHeight
      ),
      iconTheme: IconThemeData(color: colorScheme.onPrimary),
      scaffoldBackgroundColor: colorScheme.surface,
      highlightColor: Colors.transparent,
      focusColor: focusColor,
      canvasColor: colorScheme.primary,
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.primary,
      ),
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
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
      tabBarTheme: tabBarTheme(colorScheme),
    );
  }

  static TabBarThemeData tabBarTheme(ColorScheme colorScheme) {
    return TabBarThemeData(
      labelColor: colorScheme.onSurfaceVariant,
      unselectedLabelColor: colorScheme.onSurfaceVariant,
      // default values
      overlayColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          if (states.contains(WidgetState.pressed)) {
            return colorScheme.primary.withAlpha(25);
          }
          if (states.contains(WidgetState.hovered)) {
            return colorScheme.primary.withAlpha(20);
          }
          if (states.contains(WidgetState.focused)) {
            return colorScheme.primary.withAlpha(25);
          }
        }
        if (states.contains(WidgetState.pressed)) {
          return colorScheme.primary.withAlpha(25);
        }
        if (states.contains(WidgetState.hovered)) {
          return colorScheme.onSurface.withAlpha(20);
        }
        if (states.contains(WidgetState.focused)) {
          return colorScheme.onSurface.withAlpha(25);
        }
        return colorScheme.primary;
      }),
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
