// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Asegúrate de tener google_fonts en pubspec.yaml

class AppTheme {
  // Colores primarios y secundarios (ejemplos, ajústalos a tu paleta)
  static const Color _primaryColor = Color(0xFF0D47A1); // Un azul oscuro
  static const Color _primaryVariantColor = Color(0xFF1565C0); // Un azul un poco más claro
  static const Color _secondaryColor = Color(0xFF42A5F5); // Un azul más brillante para acentos
  static const Color _secondaryVariantColor = Color(0xFF90CAF9); // Un azul muy claro

  static const Color _lightTextColor = Colors.black87;
  static const Color _darkTextColor = Colors.white;

  // Constructor privado para evitar instanciación
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: _primaryColor,
      primaryColorDark: _primaryVariantColor, // Usado para variaciones más oscuras del primario
      primaryColorLight: _secondaryVariantColor, // Usado para variaciones más claras del primario
      // accentColor: _secondaryColor, // Deprecado, usar colorScheme.secondary
      
      colorScheme: const ColorScheme.light(
        primary: _primaryColor,
        onPrimary: Colors.white, // Texto/iconos sobre el color primario
        primaryContainer: _primaryVariantColor, // Un contenedor con el color primario
        secondary: _secondaryColor,
        onSecondary: Colors.white, // Texto/iconos sobre el color secundario
        secondaryContainer: _secondaryVariantColor,
        surface: Colors.white, // Color de superficie para Cards, Sheets, etc.
        onSurface: _lightTextColor,
        error: Colors.redAccent,
        onError: Colors.white,
      ),

      scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Fondo para Scaffolds

      textTheme: GoogleFonts.latoTextTheme( // Ejemplo con Google Fonts
        ThemeData.light().textTheme.copyWith(
          // Define estilos específicos si es necesario
          headlineSmall: const TextStyle(color: _lightTextColor, fontWeight: FontWeight.bold),
          titleLarge: const TextStyle(color: _lightTextColor),
          bodyMedium: const TextStyle(color: _lightTextColor),
        ),
      ),
      
      appBarTheme: const AppBarTheme(
        color: _primaryColor,
        elevation: 4.0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
        ),
      ),

      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        buttonColor: _primaryColor,
        textTheme: ButtonTextTheme.primary,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: _primaryColor, width: 2.0),
        ),
        labelStyle: const TextStyle(color: _primaryColor),
      ),

      // Define más personalizaciones de tema aquí
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: _primaryColor, // Puedes tener un primario diferente para el tema oscuro
      primaryColorDark: _primaryVariantColor,
      primaryColorLight: _secondaryVariantColor,
      // accentColor: _secondaryColor, // Deprecado

      colorScheme: ColorScheme.dark(
        primary: _secondaryColor, // Un azul más brillante puede funcionar bien en tema oscuro
        onPrimary: Colors.black, // Texto sobre el primario (si el primario es claro)
        primaryContainer: _primaryColor,
        secondary: _primaryVariantColor,
        onSecondary: Colors.white,
        secondaryContainer: _primaryColor, // Ejemplo
        surface: const Color(0xFF1E1E1E), // Superficies oscuras
        onSurface: _darkTextColor,
        error: Colors.red,
        onError: Colors.black,
      ),

      scaffoldBackgroundColor: const Color(0xFF121212),

      textTheme: GoogleFonts.latoTextTheme(
        ThemeData.dark().textTheme.copyWith(
          headlineSmall: const TextStyle(color: _darkTextColor, fontWeight: FontWeight.bold),
          titleLarge: const TextStyle(color: _darkTextColor),
          bodyMedium: const TextStyle(color: _darkTextColor),
        ),
      ),

      appBarTheme: const AppBarTheme(
        color: Color(0xFF1E1E1E), // AppBar más oscura
        elevation: 4.0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
        ),
      ),

      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        buttonColor: _secondaryColor,
        textTheme: ButtonTextTheme.primary,
      ),
       elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _secondaryColor,
          foregroundColor: Colors.black, // Texto oscuro sobre botón claro
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: _secondaryColor, width: 2.0),
        ),
        labelStyle: TextStyle(color: _secondaryColor),
        hintStyle: TextStyle(color: Colors.grey[400]),
        fillColor: Colors.grey.shade800.withOpacity(0.5), // Fondo sutil para campos de texto
        filled: true,
      ),
      
      // Define más personalizaciones de tema aquí
    );
  }
}
