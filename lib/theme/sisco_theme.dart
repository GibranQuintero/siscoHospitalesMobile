import 'package:flutter/material.dart';

const marino = Color(0xFF091832);
const azul = Color(0xFF1E65AF);
const acero = Color(0xFF3F89B2);
const cian = Color(0xFF34CAD5);
const texto = Color(0xFF1F2A3C);
const suave = Color(0xFF66758A);
const linea = Color(0xFFE1E8EF);
const fondo = Color(0xFFF3F6F9);
const tinte = Color(0xFFEAF2F9);

ThemeData siscoTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: fondo,
    colorScheme: ColorScheme.fromSeed(seedColor: azul, primary: azul, surface: Colors.white),
    appBarTheme: const AppBarTheme(
      backgroundColor: marino,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: tinte,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final activo = states.contains(WidgetState.selected);
        return TextStyle(fontSize: 12, fontWeight: activo ? FontWeight.w700 : FontWeight.w500, color: activo ? azul : suave);
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: linea)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: linea)),
    ),
  );
}

BoxDecoration tarjeta() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: linea),
  );
}
