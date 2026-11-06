import 'package:flutter/material.dart';

import '../formato.dart';
import '../services/consultorio_api.dart';
import '../state/consultorio_store.dart';
import '../theme/sisco_theme.dart';
import '../widgets/comun.dart';

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
  var _conexion = false;
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

  void _entrar() {
    ConsultorioScope.of(context).entrarSinRed();
  }

  void _aviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    const estilo = TextStyle(color: texto, fontSize: 16);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: fondo,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, MediaQuery.paddingOf(context).top + 18, 24, 28),
            decoration: const BoxDecoration(gradient: gradienteEncabezado),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AvatarIniciales(iniciales: 'S', gradiente: gradientePaciente, tamano: 52),
                SizedBox(height: 16),
                Text(nombreAplicacion, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(height: 6),
                Text(
                  'Inicia sesión\nen tu cuenta',
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700, height: 1.15, letterSpacing: -0.6),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              children: [
                const Text('Correo electrónico', style: TextStyle(color: suave, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _email,
                  style: estilo,
                  cursorColor: azul,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: const InputDecoration(hintText: 'correoelectronico@gmail.com'),
                ),
                const SizedBox(height: 14),
                const Text('Contraseña', style: TextStyle(color: suave, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _password,
                  style: estilo,
                  cursorColor: azul,
                  obscureText: _oculto,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (!_entrando) _entrar();
                  },
                  decoration: InputDecoration(
                    hintText: '•••••••',
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _oculto = !_oculto),
                      icon: Icon(_oculto ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: suave),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _aviso('Recupera la contraseña desde el portal de SISCO.'),
                    child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: cian, fontWeight: FontWeight.w600)),
                  ),
                ),
                if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: Color(0xFFBE123C), height: 1.4)),
                  const SizedBox(height: 12),
                ],
                BotonPastilla(
                  texto: _entrando ? 'Entrando…' : 'Iniciar sesión',
                  onPressed: _entrando ? null : _entrar,
                  fondo: const Color(0x1F0082AB),
                  borde: const Color(0x4D0068A2),
                  color: azul,
                  expandir: true,
                ),
                const SizedBox(height: 22),
                const Row(
                  children: [
                    Expanded(child: Divider(color: linea)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('O inicia sesión con', style: TextStyle(color: suave, fontSize: 12)),
                    ),
                    Expanded(child: Divider(color: linea)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _RedSocial(etiqueta: 'Google', onTap: () => _aviso('El acceso de SISCO es con correo y contraseña.'))),
                    const SizedBox(width: 10),
                    Expanded(child: _RedSocial(etiqueta: 'Facebook', onTap: () => _aviso('El acceso de SISCO es con correo y contraseña.'))),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() => _conexion = !_conexion),
                  child: Text(_conexion ? 'Ocultar conexión' : 'Conexión del consultorio', style: const TextStyle(color: suave)),
                ),
                if (_conexion) ...[
                  Text(
                    'El teléfono y esta computadora deben estar en la misma red. Los datos salen de http://$equipoLocal:5112/',
                    style: const TextStyle(color: suave, height: 1.35, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _api,
                    style: estilo,
                    cursorColor: azul,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    decoration: const InputDecoration(labelText: 'API de este equipo'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RedSocial extends StatelessWidget {
  const _RedSocial({required this.etiqueta, required this.onTap});

  final String etiqueta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: texto,
        side: const BorderSide(color: linea),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
      child: Text(etiqueta),
    );
  }
}
