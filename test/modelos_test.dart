import 'package:flutter_test/flutter_test.dart';
import 'package:sisco_hospitales_mobile/formato.dart';
import 'package:sisco_hospitales_mobile/models/consultorio.dart';
import 'package:sisco_hospitales_mobile/services/sesion.dart';

void main() {
  test('arma el nombre y las alergias del paciente', () {
    final paciente = Paciente.fromJson({
      'id': 'p1',
      'nombre': 'Ana',
      'apellido': 'López',
      'segundoApellido': 'Ruiz',
      'antecedentes': {
        'alergias': {
          'items': [
            {'alergeno': 'Penicilina'},
          ],
        },
      },
    });
    expect(paciente.nombreCompleto, 'Ana López Ruiz');
    expect(paciente.alergias, ['Penicilina']);
  });

  test('lee la cita con la hora del consultorio', () {
    final cita = Cita.fromJson({
      'id': 'c1',
      'pacienteId': 'p1',
      'inicio': '2026-10-27T09:30',
      'estado': 'confirmada',
      'videollamada': 1,
      'pacienteNuevo': false,
    });
    expect(cita.inicio?.hour, 9);
    expect(cita.inicio?.minute, 30);
    expect(cita.videollamada, isTrue);
    expect(etiquetaEstado(cita.estado), 'Confirmada');
  });

  test('toma el token del login de SISCO', () {
    final sesion = interpretarLogin(200, {
      'data': {
        'security': {'token': 'abc'},
        'user': {'id': 15, 'fullname': 'Ana López', 'email': 'ana@sisco.mx', 'twoFactor': false},
      },
    });
    expect(sesion.token, 'abc');
    expect(sesion.idUsuario, '15');
    expect(sesion.nombre, 'Ana López');
    expect(sesion.cabeceras['Authorization'], tokenApiLocal);
    expect(sesion.cabeceras['idUser'], '15');
  });

  test('rechaza el login con verificación en dos pasos', () {
    expect(
      () => interpretarLogin(200, {
        'data': {
          'security': {'token': 'abc'},
          'user': {'twoFactor': true},
        },
      }),
      throwsA(isA<Exception>()),
    );
  });

  test('localhost y el emulador apuntan a este equipo', () {
    expect(hostEnEsteEquipo('http://127.0.0.1:5112/'), 'http://172.16.21.170:5112/');
    expect(hostEnEsteEquipo('http://10.0.2.2:5112/'), 'http://172.16.21.170:5112/');
    expect(hostEnEsteEquipo('localhost:5112'), 'http://172.16.21.170:5112/');
  });

  test('normaliza la URL del API', () {
    expect(normalizarBase('10.0.2.2:5112'), 'http://10.0.2.2:5112/');
    expect(normalizarBase('http://127.0.0.1:5112/api/consultorio/'), 'http://127.0.0.1:5112/');
  });
}
