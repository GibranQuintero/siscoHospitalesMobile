import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/shell_screen.dart';
import 'state/consultorio_store.dart';
import 'theme/sisco_theme.dart';

void main() {
  runApp(const SiscoApp());
}

class SiscoApp extends StatefulWidget {
  const SiscoApp({super.key, this.autoCargar = true, this.omitirLogin = false});

  final bool autoCargar;
  final bool omitirLogin;

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
    if (widget.omitirLogin) {
      _store.listo = true;
      if (widget.autoCargar) _store.cargar();
    } else {
      _store.restaurar().then((_) {
        if (_store.sesion != null && widget.autoCargar) _store.cargar();
      });
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
        title: 'SISCO Hospitales',
        debugShowCheckedModeBanner: false,
        theme: siscoTheme(),
        home: !_store.listo
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : entro
                ? const ShellScreen()
                : const LoginScreen(),
      ),
    );
  }
}
