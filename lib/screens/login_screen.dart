import 'package:flutter/material.dart';

import '../formato.dart';
import '../services/consultorio_api.dart';
import '../state/consultorio_store.dart';
import '../theme/sisco_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _api = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _oculto = true;
  var _entrando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    ApiConfig.leer().then((valor) {
      if (!mounted) return;
      _api.text = valor;
    });
  }

  @override
  void dispose() {
    _api.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    final store = ConsultorioScope.of(context);
    setState(() {
      _entrando = true;
      _error = null;
    });
    try {
      if (_api.text.trim().isNotEmpty) {
        await ApiConfig.guardar(_api.text);
      }
      await store.entrar(_email.text, _password.text);
    } on ConsultorioException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo entrar a SISCO.');
    } finally {
      if (mounted) setState(() => _entrando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const estilo = TextStyle(color: texto, fontSize: 16);
    final direccion = 'http://$equipoLocal:5112/';
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: marino,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('SISCO HOSPITALES', style: TextStyle(color: cian, fontWeight: FontWeight.w800, letterSpacing: 1)),
            const SizedBox(height: 8),
            const Text('Consultorio', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'El teléfono y esta computadora deben estar en la misma red. Los datos salen de $direccion',
              style: const TextStyle(color: Colors.white70, height: 1.35),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _api,
              style: estilo,
              cursorColor: azul,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: true,
              decoration: const InputDecoration(
                labelText: 'API de este equipo',
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _email,
              style: estilo,
              cursorColor: azul,
              autofocus: true,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Correo', filled: true, fillColor: Colors.white),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              style: estilo,
              cursorColor: azul,
              obscureText: _oculto,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!_entrando) _entrar();
              },
              decoration: InputDecoration(
                labelText: 'Contraseña',
                filled: true,
                fillColor: Colors.white,
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _oculto = !_oculto),
                  icon: Icon(_oculto ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Color(0xFFFFD7A8), height: 1.4)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: azul, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: _entrando ? null : _entrar,
              child: Text(_entrando ? 'Entrando…' : 'Entrar'),
            ),
          ],
        ),
      ),
    );
  }
}
