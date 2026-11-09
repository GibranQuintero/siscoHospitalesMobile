import 'package:flutter_test/flutter_test.dart';
import 'package:sisco_hospitales_mobile/formato.dart';
import 'package:sisco_hospitales_mobile/models/consultorio.dart';
import 'package:sisco_hospitales_mobile/services/sesion.dart';
import 'package:sisco_hospitales_mobile/state/consultorio_store.dart';

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

  test('la agenda arma la misma línea que la web', () {
    final store = ConsultorioStore();
    store.usarDemostracion();
    final cita = store.citas.firstWhere((item) => item.id == 'c-1');
    expect(cita.tipoServicio, 'Médico general');
    expect(cita.medicoId, 'm-1');
    expect(store.lineaAgenda(cita), 'DH-1001 · C-1001 · Centro');
    expect(store.llamadasPendientes.any((item) => item.id == 'c-6'), isTrue);
    expect(store.sedesAgenda, containsAll(['Consultorio Roma', 'Hospital del Valle']));
    store.dispose();
  });

  test('farmacia y laboratorio actualizan el seguimiento local', () {
    final store = ConsultorioStore();
    store.usarDemostracion();
    final consulta = store.consultas.firstWhere((item) => item.id == 'k-ana');
    final indice = consulta.medicamentos.indexWhere((linea) => linea.nombre == 'Losartán');
    store.marcarMedicamento(consulta.id, indice, 'surtido');
    store.anotarMedicamento(consulta.id, indice, 'Lote 18');
    store.evidenciarMedicamento(consulta.id, indice, 'entrega-losartan.jpg');
    final linea = store.consultas.firstWhere((item) => item.id == 'k-ana').medicamentos[indice];
    expect(linea.estatusEntrega, 'surtido');
    expect(linea.notaSurtido, 'Lote 18');
    expect(linea.evidenciaNombre, 'entrega-losartan.jpg');
    expect(linea.fechaEntrega, isNotEmpty);

    store.aprobarOrden('k-ana', 'o-ana-gab');
    final aprobada = store.consultasDe('p-ana').first.ordenes.firstWhere((orden) => orden.id == 'o-ana-gab');
    expect(aprobada.estatus, 'recibida');
    expect(etiquetaOrden(aprobada.estatus), 'Aprobada');

    store.evidenciarOrden('k-bruno', 'o-bruno-gab', 'rx-lumbar.pdf');
    final estudio = store.consultasDe('p-bruno').first.ordenes.first;
    expect(estudio.estatus, 'resultado');
    expect(estudio.evidenciaNombre, 'rx-lumbar.pdf');
    expect(etiquetaOrden(estudio.estatus), 'Con evidencia');

    store.dejarMensaje('p-ana', 'Ya recogí el losartán');
    expect(store.avisos.map((aviso) => aviso.texto), contains('Ya recogí el losartán'));
    store.dispose();
  });

  test('normaliza la URL del API', () {
    expect(normalizarBase('10.0.2.2:5112'), 'http://10.0.2.2:5112/');
    expect(normalizarBase('http://127.0.0.1:5112/api/consultorio/'), 'http://127.0.0.1:5112/');
  });
}
