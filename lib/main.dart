import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/modulos_screen.dart';
import 'screens/shell_screen.dart';
import 'state/consultorio_store.dart';
import 'theme/sisco_theme.dart';

const demostracionCompilada = bool.fromEnvironment('DEMO');

void main() {
  runApp(SiscoApp(demostracion: demostracionCompilada));
}

class SiscoApp extends StatefulWidget {
  const SiscoApp({super.key, this.autoCargar = true, this.omitirLogin = false, this.demostracion = false});

  final bool autoCargar;
  final bool omitirLogin;
  final bool demostracion;

  @override
  State<SiscoApp> createState() => _SiscoAppState();
}

class _SiscoAppState extends State<SiscoApp> {
  late final ConsultorioStore _store;

  @override
  void initState() {
    super.initState();
    _store = ConsultorioStore(cargando: false);
    _store.addListener(_alCambiar);
    _store.listo = true;
    if (widget.omitirLogin && widget.autoCargar && !widget.demostracion) {
      _store.cargar();
    }
  }

  void _alCambiar() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _store.removeListener(_alCambiar);
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entro = widget.omitirLogin || _store.sesion != null;
    return ConsultorioScope(
      store: _store,
      child: MaterialApp(
        title: nombreAplicacion,
        debugShowCheckedModeBanner: false,
        theme: siscoTheme(),
        home: !_store.listo
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : !entro
                ? const LoginScreen()
                : _store.modulo == null
                    ? const ModulosScreen()
                    : const ShellScreen(),
      ),
    );
  }
}
