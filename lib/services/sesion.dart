import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../formato.dart';
import 'consultorio_api.dart';

const seguridadLogin = 'https://seguridad.centraldeoperaciones.com/v2/auth/Login';
const aplicacionSisco = 9;

/// Token registrado en Operacion.UserTokenSisco. SISCOAPI local lo exige en
/// Authorization; el token del login de seguridad no pasa ese filtro y responde 401.
/// Es el mismo valor que manda el TokenInterceptor de la web.
const tokenApiLocal =
    'eyJhbGciOiJSUzI1NiIsImtpZCI6IjE1MjU1NWEyMjM3MWYxMGY0ZTIyZjFhY2U3NjJmYzUwZmYzYmVlMGMiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoiQWxhbiIsImlzcyI6Imh0dHBzOi8vc2VjdXJldG9rZW4uZ29vZ2xlLmNvbS9nYS1zZWN1cml0eSIsImF1ZCI6ImdhLXNlY3VyaXR5IiwiYXV0aF90aW1lIjoxNjM1MzY2NjM2LCJ1c2VyX2lkIjoidE9kM2E1bkNXYVhJT3BZZVFUQXZ4WDVrcHQ3MyIsInN1YiI6InRPZDNhNW5DV2FYSU9wWWVRVEF2eFg1a3B0NzMiLCJpYXQiOjE2MzUzNjY2MzYsImV4cCI6MTYzNTM3MDIzNiwiZW1haWwiOiJhbGFuLnJvc2FsZXNAZ3J1cG9hbmRyYWRlLmNvbS5teCIsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwicGhvbmVfbnVtYmVyIjoiKzUyNTUxODA5NTk2MCIsImZpcmViYXNlIjp7ImlkZW50aXRpZXMiOnsicGhvbmUiOlsiKzUyNTUxODA5NTk2MCJdLCJlbWFpbCI6WyJhbGFuLnJvc2FsZXNAZ3J1cG9hbmRyYWRlLmNvbS5teCJdfSwic2lnbl9pbl9wcm92aWRlciI6InBhc3N3b3JkIn19.HYqHJ72lUEFcCw0OEw72ZS4pJhsYxhcbQ1qUIjVgsbO8SfejAlC984Ti2eIH-UHu-kLSSbPw724NY8itXgPYgfAyuc4siaoH-wfrDzotqnd-ViJeW_vuYXqlQlELUfk236n2vf-tRrIvw_o1eyVbMIH6lgK7K3GoPzbjDTJHUxPVXd2N3FtWhZvFOr0RruJITDPJuZzqck6inUyqSUFjlO7CwPiMJoOyRzov1XR6FSFZPfvyHCkMmviiAWiRjrTjniaBak9pkIukWYbXsEyU3IErguPSHuf6HG4HTkDZyTztpj2vmuArfdW4vKS6pgQjpuD7JG2iL-wNbdOKOyTDeg';

class Sesion {
  const Sesion({
    required this.token,
    required this.idUsuario,
    required this.nombre,
    required this.email,
  });

  final String token;
  final String idUsuario;
  final String nombre;
  final String email;

  Map<String, String> get cabeceras => {
        'Accept': 'application/json',
        'Authorization': tokenApiLocal,
        if (idUsuario.isNotEmpty) 'idUser': idUsuario,
      };

  static const _token = 'sisco_token';
  static const _id = 'sisco_user_id';
  static const _nombre = 'sisco_user_nombre';
  static const _email = 'sisco_user_email';
  static const _cat = 'sisco_cat_telefono';

  static Future<Sesion?> leer() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_token) ?? '';
    if (token.isEmpty) return null;
    return Sesion(
      token: token,
      idUsuario: prefs.getString(_id) ?? '',
      nombre: prefs.getString(_nombre) ?? '',
      email: prefs.getString(_email) ?? '',
    );
  }

  static Future<void> guardar(Sesion sesion) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_token, sesion.token);
    await prefs.setString(_id, sesion.idUsuario);
    await prefs.setString(_nombre, sesion.nombre);
    await prefs.setString(_email, sesion.email);
  }

  static Future<void> olvidar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_token);
    await prefs.remove(_id);
    await prefs.remove(_nombre);
    await prefs.remove(_email);
  }

  static Future<String> leerTelefonoCat() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cat) ?? '';
  }

  static Future<void> guardarTelefonoCat(String telefono) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cat, telefono.trim());
  }

  static Future<Sesion> entrar(String email, String password) async {
    try {
      final respuesta = await http
          .post(
            Uri.parse(seguridadLogin),
            headers: const {'Accept': 'application/json', 'Content-Type': 'application/json'},
            body: jsonEncode({
              'credentials': {'email': email.trim(), 'password': password},
              'application': aplicacionSisco,
            }),
          )
          .timeout(const Duration(seconds: 20));
      final cuerpo = jsonDecode(respuesta.body);
      final mapaCuerpo = cuerpo is Map ? Map<String, dynamic>.from(cuerpo) : <String, dynamic>{};
      final sesion = interpretarLogin(respuesta.statusCode, mapaCuerpo);
      await guardar(sesion);
      return sesion;
    } on ConsultorioException {
      rethrow;
    } on TimeoutException {
      throw ConsultorioException('El servicio de seguridad tardó demasiado.');
    } on SocketException {
      throw ConsultorioException('No hay conexión con el login de SISCO.');
    }
  }
}

Sesion interpretarLogin(int status, Map<String, dynamic> cuerpo) {
  if (status >= 400) {
    throw ConsultorioException(mensajeErrorLogin(cuerpo));
  }
  final datos = mapa(cuerpo['data']);
  final usuario = mapa(datos['user']);
  final seguridad = mapa(datos['security']);
  if (bandera(usuario['twoFactor'])) {
    throw ConsultorioException('Esta cuenta pide un código al teléfono. Usa una cuenta de SISCO sin verificación en dos pasos.');
  }
  final token = cadena(seguridad['token']);
  if (token.isEmpty) {
    throw ConsultorioException(mensajeErrorLogin(cuerpo));
  }
  final nombre = cadena(usuario['fullname']).isNotEmpty ? cadena(usuario['fullname']) : cadena(usuario['name']);
  return Sesion(
    token: token,
    idUsuario: cadena(usuario['id']),
    nombre: nombre,
    email: cadena(usuario['email']),
  );
}

String mensajeErrorLogin(Map<String, dynamic> cuerpo) {
  final errores = cuerpo['errors'];
  if (errores is List && errores.isNotEmpty && errores.first is Map) {
    final descripcion = cadena(Map<String, dynamic>.from(errores.first)['description']);
    if (descripcion.isNotEmpty) return descripcion;
  }
  final mensaje = cadena(cuerpo['message']);
  if (mensaje.isNotEmpty) return mensaje;
  return 'No se pudo entrar a SISCO.';
}
