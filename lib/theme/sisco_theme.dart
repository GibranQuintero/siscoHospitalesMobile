import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const nombreAplicacion = 'SISCO Servicios Médicos';

/// Tinta de títulos. En Figma es #0F172A.
const marino = Color(0xFF0F172A);
const texto = Color(0xFF0F172A);

/// Azul institucional #29669D y cian de acción #0FA7E2.
const azul = Color(0xFF29669D);
const acero = Color(0xFF3B94BC);
const cian = Color(0xFF0FA7E2);
const encabezado = Color(0xFF004B7F);
const encabezadoClaro = Color(0xFF4896D3);

const suave = Color(0xFF64748B);
const gris = Color(0xFF58595B);
const chevron = Color(0xFFCBD5E1);
const fondo = Color(0xFFF8FAFC);
const tinte = Color(0x1A29669D);
const linea = Color(0x339A9CAE);

const exito = Color(0xFF059669);
const exitoVivo = Color(0xFF10B981);
const aviso = Color(0xFFD97706);
const indigo = Color(0xFF4C5593);
const control = Color(0xFF0082AB);

const gradienteEncabezado = LinearGradient(
  colors: [encabezado, encabezadoClaro],
);

const gradientePaciente = LinearGradient(
  begin: Alignment.bottomLeft,
  end: Alignment.topRight,
  colors: [Color(0xFF29669D), Color(0xFF0FA7E2)],
);

const gradienteDoctor = LinearGradient(
  begin: Alignment.bottomLeft,
  end: Alignment.topRight,
  colors: [Color(0xFF0FA7E2), Color(0xFF5FD3FF)],
);

const gradienteAdmin = LinearGradient(
  begin: Alignment.bottomLeft,
  end: Alignment.topRight,
  colors: [Color(0xFF4338CA), Color(0xFF818CD3)],
);

const gradienteFarmacia = LinearGradient(
  begin: Alignment.bottomLeft,
  end: Alignment.topRight,
  colors: [Color(0xFF9A3412), Color(0xFFEA580C)],
);

const gradienteLaboratorio = LinearGradient(
  begin: Alignment.bottomLeft,
  end: Alignment.topRight,
  colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
);

const gradienteRecepcion = LinearGradient(
  begin: Alignment.bottomLeft,
  end: Alignment.topRight,
  colors: [Color(0xFF0F766E), Color(0xFF2DD4BF)],
);

ThemeData siscoTheme() {
  const titulo = TextStyle(color: texto, fontWeight: FontWeight.w800);
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: fondo,
    colorScheme: ColorScheme.fromSeed(
      seedColor: azul,
      primary: azul,
      secondary: cian,
      surface: Colors.white,
    ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(color: texto, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.4),
      titleLarge: titulo,
      titleMedium: TextStyle(color: texto, fontSize: 16, fontWeight: FontWeight.w700, height: 1.5),
      bodyMedium: TextStyle(color: gris, fontSize: 14, height: 1.4),
      bodySmall: TextStyle(color: suave, fontSize: 12, height: 1.35),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: encabezado,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.4),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xF2FFFFFF),
      indicatorColor: tinte,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final activo = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: activo ? FontWeight.w800 : FontWeight.w600,
          color: activo ? azul : suave,
        );
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: azul,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: suave, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: linea)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: linea)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: azul)),
    ),
  );
}

BoxDecoration tarjeta() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: linea),
    boxShadow: const [
      BoxShadow(color: Color(0x140F172A), blurRadius: 18, offset: Offset(0, 6)),
    ],
  );
}

class BotonEncabezado extends StatelessWidget {
  const BotonEncabezado({super.key, required this.icono, required this.tooltip, required this.onPressed});

  final IconData icono;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(12),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icono, color: Colors.white),
        ),
      ),
    );
  }
}

class BarraGradiente extends StatelessWidget implements PreferredSizeWidget {
  const BarraGradiente({super.key, required this.titulo, this.actions});

  final String titulo;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: encabezado,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      flexibleSpace: const SizedBox.expand(
        child: DecoratedBox(decoration: BoxDecoration(gradient: gradienteEncabezado)),
      ),
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: gradientePaciente),
            child: const Text('S', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  nombreAplicacion,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, height: 1.1),
                ),
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }
}
