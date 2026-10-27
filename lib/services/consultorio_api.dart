import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../formato.dart';

class ConsultorioException implements Exception {
  ConsultorioException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

class ApiConfig {
  static const clave = 'sisco_api_base';

  static String porPlataforma() => 'http://$equipoLocal:5112/';

  static Future<String> leer() async {
    final prefs = await SharedPreferences.getInstance();
    final guardada = prefs.getString(clave);
    if (guardada == null || guardada.trim().isEmpty) return porPlataforma();
    return hostEnEsteEquipo(guardada);
  }

  static Future<void> guardar(String base) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(clave, hostEnEsteEquipo(base));
  }

  static Future<void> olvidar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(clave);
  }
}

String _mensajeHttp(int status, String body, String ruta) {
  try {
    final cuerpo = jsonDecode(body);
    if (cuerpo is Map) {
      final mensaje = cadena(cuerpo['message']);
      if (mensaje.contains('192.168.200.110')) {
        return 'SISCOAPI no alcanza la base del consultorio en 192.168.200.110.';
      }
      if (mensaje.isNotEmpty) return mensaje;
      final error = cadena(cuerpo['error']);
      if (error.isNotEmpty) return error;
    }
  } catch (_) {}
  if (status == 401) return 'SISCOAPI rechazó la sesión.';
  return 'El API respondió $status en $ruta.';
}

class ConsultorioApi {
  ConsultorioApi(this.origen, {this.cabeceras = const {'Accept': 'application/json'}});

  final String origen;
  final Map<String, String> cabeceras;

  Future<String> crearMeet({String? folio, String? inicio, String? fin, String? resumen}) async {
    final uri = Uri.parse('${origen}api/llamada/consultorio');
    try {
      final respuesta = await http
          .post(
            uri,
            headers: {...cabeceras, 'Content-Type': 'application/json'},
            body: jsonEncode({'folio': folio, 'inicio': inicio, 'fin': fin, 'resumen': resumen}),
          )
          .timeout(const Duration(seconds: 25));
      final cuerpo = jsonDecode(respuesta.body);
      final mapaCuerpo = cuerpo is Map ? Map<String, dynamic>.from(cuerpo) : <String, dynamic>{};
      if (respuesta.statusCode >= 400) {
        throw ConsultorioException(cadena(mapaCuerpo['message']).isNotEmpty ? cadena(mapaCuerpo['message']) : 'No se pudo crear la sala de Meet.');
      }
      final enlace = cadena(mapaCuerpo['meetingUri']);
      if (enlace.isEmpty) {
        throw ConsultorioException('La sala no devolvió un enlace de Meet.');
      }
      return enlace;
    } on ConsultorioException {
      rethrow;
    } on TimeoutException {
      throw ConsultorioException('Meet tardó demasiado en responder.');
    } on SocketException {
      throw ConsultorioException('No hay conexión con SISCOAPI para crear la sala.');
    }
  }

  Future<Map<String, dynamic>> get(String ruta) async {
    final uri = Uri.parse('${origen}api/consultorio$ruta');
    try {
      final respuesta = await http.get(uri, headers: cabeceras).timeout(const Duration(seconds: 40));
      if (respuesta.statusCode >= 400) {
        throw ConsultorioException(_mensajeHttp(respuesta.statusCode, respuesta.body, ruta));
      }
      final cuerpo = jsonDecode(respuesta.body);
      if (cuerpo is Map<String, dynamic>) return cuerpo;
      if (cuerpo is Map) return Map<String, dynamic>.from(cuerpo);
      throw ConsultorioException('La respuesta de $ruta no tiene el formato del consultorio.');
    } on ConsultorioException {
      rethrow;
    } on TimeoutException {
      throw ConsultorioException('El API tardó demasiado en responder.');
    } on SocketException {
      throw ConsultorioException(
        'No hay conexión con el API. Revisa que SISCOAPI esté encendido y que la dirección en Ajustes sea alcanzable desde este dispositivo.',
      );
    }
  }

  Future<void> leerTodo({
    required void Function(Map<String, dynamic> contrato) contrato,
    required void Function(Map<String, dynamic> agenda) agenda,
    required void Function(Map<String, dynamic> paciente) paciente,
    required void Function(Map<String, dynamic> hospital) hospital,
    required void Function(Map<String, dynamic> medico) medico,
  }) async {
    final partes = await Future.wait([
      get('/contrato'),
      get('/agenda'),
      get('/paciente'),
      get('/hospital'),
      get('/medico'),
    ]);
    contrato(partes[0]);
    agenda(partes[1]);
    paciente(partes[2]);
    hospital(partes[3]);
    medico(partes[4]);
  }
}
