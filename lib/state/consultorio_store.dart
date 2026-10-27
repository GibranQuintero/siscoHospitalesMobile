import 'package:flutter/widgets.dart';

import '../formato.dart';
import '../models/consultorio.dart';
import '../services/consultorio_api.dart';
import '../services/sesion.dart';

class ConsultorioScope extends InheritedNotifier<ConsultorioStore> {
  const ConsultorioScope({super.key, required ConsultorioStore store, required super.child}) : super(notifier: store);

  static ConsultorioStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ConsultorioScope>();
    assert(scope != null, 'ConsultorioScope no está en el árbol');
    return scope!.notifier!;
  }
}

class ConsultorioStore extends ChangeNotifier {
  ConsultorioStore({this.cargando = false});

  var _activo = true;
  bool cargando;
  bool listo = false;
  Sesion? sesion;
  String telefonoCat = '';
  String cuentaTelefono = '';
  final salas = <String, String>{};
  String? error;
  String origen = '';
  String cuenta = '';
  String clinica = '';
  List<Paciente> pacientes = [];
  List<Cita> citas = [];
  List<HospitalRed> hospitales = [];
  List<Medico> medicos = [];
  List<Mensaje> mensajes = [];
  Map<String, String> catalogoEspecialidad = {};

  String get titulo {
    if (cuenta.isNotEmpty) return cuenta;
    if (clinica.isNotEmpty) return clinica;
    return 'SISCO Hospitales';
  }

  String get subtitulo => cuenta.isNotEmpty && clinica.isNotEmpty ? clinica : '';

  String get telefonoParaCat => telefonoCat.isNotEmpty ? telefonoCat : cuentaTelefono;

  String enlaceMeet(Cita cita) {
    final creada = salas[cita.id];
    if (creada != null && creada.isNotEmpty) return creada;
    return cita.videollamadaUrl;
  }

  Future<void> restaurar() async {
    sesion = await Sesion.leer();
    telefonoCat = await Sesion.leerTelefonoCat();
    listo = true;
    _avisar();
  }

  Future<void> entrar(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw ConsultorioException('Escribe el correo y la contraseña.');
    }
    sesion = await Sesion.entrar(email, password);
    telefonoCat = await Sesion.leerTelefonoCat();
    listo = true;
    _avisar();
    await cargar();
  }

  Future<void> salir() async {
    await Sesion.olvidar();
    sesion = null;
    salas.clear();
    pacientes = [];
    citas = [];
    hospitales = [];
    medicos = [];
    mensajes = [];
    error = null;
    _avisar();
  }

  Future<void> guardarTelefonoCat(String telefono) async {
    telefonoCat = telefono.trim();
    await Sesion.guardarTelefonoCat(telefonoCat);
    _avisar();
  }

  Future<String> salaMeet(Cita cita) async {
    final existente = enlaceMeet(cita);
    if (existente.isNotEmpty) return existente;
    origen = origen.isEmpty ? await ApiConfig.leer() : origen;
    final api = ConsultorioApi(origen, cabeceras: sesion?.cabeceras ?? const {'Accept': 'application/json'});
    final paciente = nombrePaciente(cita.pacienteId);
    final enlace = await api.crearMeet(
      folio: cita.folio.isNotEmpty ? cita.folio : cita.id,
      inicio: cita.inicio?.toIso8601String(),
      fin: cita.fin?.toIso8601String(),
      resumen: cita.motivo.isEmpty ? 'Consulta $paciente' : 'Consulta $paciente · ${cita.motivo}',
    );
    salas[cita.id] = enlace;
    _avisar();
    return enlace;
  }

  Future<void> cargar() async {
    cargando = true;
    error = null;
    _avisar();
    try {
      origen = await ApiConfig.leer();
      telefonoCat = await Sesion.leerTelefonoCat();
      final api = ConsultorioApi(origen, cabeceras: sesion?.cabeceras ?? const {'Accept': 'application/json'});
      await api.leerTodo(
        contrato: (json) {
          final datosCuenta = mapa(json['cuenta']);
          cuenta = cadena(datosCuenta['nombre']);
          cuentaTelefono = cadena(datosCuenta['telefono']);
        },
        agenda: (json) {
          clinica = cadena(json['clinica']);
          citas = lista(json['citas'], Cita.fromJson);
        },
        paciente: (json) {
          pacientes = lista(json['pacientes'], Paciente.fromJson);
          mensajes = lista(json['mensajes'], Mensaje.fromJson);
        },
        hospital: (json) {
          hospitales = lista(json['hospitales'], HospitalRed.fromJson)..sort((a, b) => a.nombre.compareTo(b.nombre));
          catalogoEspecialidad = {
            for (final item in lista(json['catalogoEspecialidad'], (e) => e))
              if (cadena(item['clave']).isNotEmpty) cadena(item['clave']): cadena(item['nombre']),
          };
        },
        medico: (json) {
          medicos = lista(json['medicos'], Medico.fromJson)..sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));
        },
      );
    } on ConsultorioException catch (e) {
      error = e.mensaje;
    } catch (_) {
      error = 'No se pudo leer el consultorio.';
    } finally {
      cargando = false;
      _avisar();
    }
  }

  void _avisar() {
    if (_activo) notifyListeners();
  }

  @override
  void dispose() {
    _activo = false;
    super.dispose();
  }

  Future<void> guardarOrigen(String base) async {
    await ApiConfig.guardar(base);
    await cargar();
  }

  Future<void> restaurarOrigen() async {
    await ApiConfig.olvidar();
    await cargar();
  }

  Paciente? porId(String id) {
    for (final paciente in pacientes) {
      if (paciente.id == id) return paciente;
    }
    return null;
  }

  String nombrePaciente(String id) => porId(id)?.nombreCompleto ?? 'Paciente';

  HospitalRed? hospitalPorId(String id) {
    for (final hospital in hospitales) {
      if (hospital.id == id) return hospital;
    }
    return null;
  }

  String nombreEspecialidad(String clave) => catalogoEspecialidad[clave] ?? clave;

  List<Cita> citasDelDia(DateTime dia, {bool incluirCanceladas = false}) {
    final delDia = citas.where((cita) {
      if (cita.inicio == null || !esMismoDia(cita.inicio!, dia)) return false;
      if (!incluirCanceladas && cita.estado == 'cancelada') return false;
      return true;
    }).toList();
    delDia.sort((a, b) => a.inicio!.compareTo(b.inicio!));
    return delDia;
  }

  int contarEstado(DateTime dia, String estado) {
    return citas.where((cita) => cita.inicio != null && esMismoDia(cita.inicio!, dia) && cita.estado == estado).length;
  }

  List<Cita> citasDe(String pacienteId) {
    final propias = citas.where((cita) => cita.pacienteId == pacienteId).toList();
    propias.sort((a, b) {
      final ai = a.inicio ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bi = b.inicio ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bi.compareTo(ai);
    });
    return propias;
  }

  List<Medico> medicosDe(String hospitalId) {
    return medicos.where((medico) => medico.hospitales.contains(hospitalId)).toList();
  }

  List<Paciente> buscarPacientes(String consulta) {
    if (consulta.trim().isEmpty) return pacientes;
    final palabras = limpio(consulta)
        .split(RegExp(r'\s+'))
        .where((palabra) => palabra.length > 1 && !_ruido.contains(palabra))
        .toList();
    if (palabras.isEmpty) return [];
    return pacientes.where((paciente) {
      final datos = limpio(
        [
          paciente.nombre,
          paciente.apellido,
          paciente.segundoApellido,
          paciente.alias,
          paciente.curp,
          paciente.telefono,
          paciente.alergias.join(' '),
        ].join(' '),
      );
      return palabras.every(datos.contains);
    }).toList();
  }

  List<Mensaje> get avisos {
    final recientes = mensajes.where((mensaje) => mensaje.de == 'paciente' && mensaje.texto.isNotEmpty).toList();
    recientes.sort((a, b) {
      final ac = a.cuando ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bc = b.cuando ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bc.compareTo(ac);
    });
    return recientes.take(5).toList();
  }
}

const _ruido = {'pacientes', 'paciente', 'con', 'que', 'tienen', 'de'};
