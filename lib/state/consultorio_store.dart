import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../datos_prueba.dart';
import '../formato.dart';
import '../models/consultorio.dart';
import '../services/consultorio_api.dart';
import '../services/sesion.dart';

enum ModuloApp { paciente, doctor, recepcion, admin, farmacia, laboratorio }

ModuloApp? moduloDe(String valor) {
  switch (valor) {
    case 'paciente':
      return ModuloApp.paciente;
    case 'doctor':
      return ModuloApp.doctor;
    case 'recepcion':
      return ModuloApp.recepcion;
    case 'admin':
      return ModuloApp.admin;
    case 'farmacia':
      return ModuloApp.farmacia;
    case 'laboratorio':
      return ModuloApp.laboratorio;
  }
  return null;
}

String claveModulo(ModuloApp modulo) {
  switch (modulo) {
    case ModuloApp.paciente:
      return 'paciente';
    case ModuloApp.doctor:
      return 'doctor';
    case ModuloApp.recepcion:
      return 'recepcion';
    case ModuloApp.admin:
      return 'admin';
    case ModuloApp.farmacia:
      return 'farmacia';
    case ModuloApp.laboratorio:
      return 'laboratorio';
  }
}

String tituloModulo(ModuloApp modulo) {
  switch (modulo) {
    case ModuloApp.paciente:
      return 'Derechohabientes';
    case ModuloApp.doctor:
      return 'Doctores';
    case ModuloApp.recepcion:
      return 'Recepción';
    case ModuloApp.admin:
      return 'Administración';
    case ModuloApp.farmacia:
      return 'Farmacia';
    case ModuloApp.laboratorio:
      return 'Laboratorio';
  }
}

String? siguienteEstadoRecepcion(String estado) {
  switch (estado) {
    case 'no_confirmada':
      return 'confirmada';
    case 'confirmada':
      return 'en_consulta';
  }
  return null;
}

String? accionRecepcion(String estado) {
  switch (estado) {
    case 'no_confirmada':
      return 'Confirmar cita';
    case 'confirmada':
      return 'Registrar llegada';
  }
  return null;
}

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
  bool demostracion = false;
  bool listo = false;
  Sesion? sesion;
  ModuloApp? modulo;
  String pacienteActivoId = '';
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
  List<ConsultaClinica> consultas = [];
  List<ExpedienteClinico> expedientes = [];
  Map<String, String> catalogoEspecialidad = {};

  String get titulo {
    if (cuenta.isNotEmpty) return cuenta;
    if (clinica.isNotEmpty) return clinica;
    return 'SISCO Servicios Médicos';
  }

  String get subtitulo => cuenta.isNotEmpty && clinica.isNotEmpty ? clinica : '';

  String get telefonoParaCat => telefonoCat.isNotEmpty ? telefonoCat : cuentaTelefono;

  String enlaceMeet(Cita cita) {
    final creada = salas[cita.id];
    if (creada != null && creada.isNotEmpty) return creada;
    return cita.videollamadaUrl;
  }

  static const _claveModulo = 'sisco_modulo';
  static const _clavePaciente = 'sisco_paciente_activo';

  Paciente? get pacienteActivo {
    if (pacienteActivoId.isNotEmpty) {
      final elegido = porId(pacienteActivoId);
      if (elegido != null) return elegido;
    }
    final correo = (sesion?.email ?? '').trim().toLowerCase();
    if (correo.isEmpty) return null;
    for (final paciente in pacientes) {
      if (paciente.correo.trim().toLowerCase() == correo) return paciente;
    }
    return null;
  }

  Future<void> restaurar() async {
    sesion = await Sesion.leer();
    telefonoCat = await Sesion.leerTelefonoCat();
    final prefs = await SharedPreferences.getInstance();
    modulo = moduloDe(prefs.getString(_claveModulo) ?? '');
    pacienteActivoId = prefs.getString(_clavePaciente) ?? '';
    listo = true;
    _avisar();
  }

  Future<void> elegirModulo(ModuloApp valor) async {
    modulo = valor;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveModulo, claveModulo(valor));
    _avisar();
  }

  Future<void> quitarModulo() async {
    modulo = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_claveModulo);
    _avisar();
  }

  Future<void> elegirPaciente(String id) async {
    pacienteActivoId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clavePaciente, id);
    _avisar();
  }

  void entrarSinRed() {
    demostracion = true;
    sesion = const Sesion(token: 'local', idUsuario: '', nombre: '', email: '');
    modulo = null;
    pacienteActivoId = '';
    listo = true;
    _llenarPrueba();
    _avisar();
  }

  void usarDemostracion() {
    demostracion = true;
    listo = true;
    _llenarPrueba();
    _avisar();
  }

  void _llenarPrueba({bool conservarOperacion = false}) {
    cuenta = 'SISCO Servicios Médicos';
    clinica = 'Consultorio Roma';
    cuentaTelefono = '5550000000';
    telefonoCat = '5550000000';
    origen = '';
    error = null;
    pacientes = DatosPrueba.pacientes();
    citas = DatosPrueba.citas();
    hospitales = DatosPrueba.hospitales();
    medicos = DatosPrueba.medicos();
    catalogoEspecialidad = DatosPrueba.especialidades();
    if (!conservarOperacion) {
      mensajes = DatosPrueba.mensajes();
      consultas = DatosPrueba.consultas();
      expedientes = DatosPrueba.expedientes();
    }
  }

  Future<void> entrar(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw ConsultorioException('Escribe el correo y la contraseña.');
    }
    sesion = await Sesion.entrar(email, password);
    telefonoCat = await Sesion.leerTelefonoCat();
    final prefs = await SharedPreferences.getInstance();
    modulo = moduloDe(prefs.getString(_claveModulo) ?? '');
    pacienteActivoId = prefs.getString(_clavePaciente) ?? '';
    listo = true;
    _avisar();
    await cargar();
  }

  Future<void> salir() async {
    if (demostracion) {
      sesion = null;
      modulo = null;
      pacienteActivoId = '';
      _llenarPrueba();
      _avisar();
      return;
    }
    await Sesion.olvidar();
    sesion = null;
    modulo = null;
    pacienteActivoId = '';
    salas.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_claveModulo);
    await prefs.remove(_clavePaciente);
    pacientes = [];
    citas = [];
    hospitales = [];
    medicos = [];
    mensajes = [];
    consultas = [];
    expedientes = [];
    error = null;
    _avisar();
  }

  Future<void> guardarTelefonoCat(String telefono) async {
    telefonoCat = telefono.trim();
    await Sesion.guardarTelefonoCat(telefonoCat);
    _avisar();
  }

  Future<String> salaMeet(Cita cita) async {
    if (demostracion) {
      final local = enlaceMeet(cita);
      if (local.isNotEmpty) return local;
      throw ConsultorioException('En el recorrido de prueba la videollamada no se conecta.');
    }
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

  Future<void> abrirEnEscritorio(String enlace) async {
    if (demostracion) {
      throw ConsultorioException('En el recorrido de prueba la sesión de escritorio no se abre.');
    }
    origen = origen.isEmpty ? await ApiConfig.leer() : origen;
    final api = ConsultorioApi(origen, cabeceras: sesion?.cabeceras ?? const {'Accept': 'application/json'});
    await api.abrirEnEscritorio(enlace);
  }

  Future<void> cargar() async {
    if (demostracion) {
      cargando = true;
      _avisar();
      _llenarPrueba(conservarOperacion: true);
      cargando = false;
      _avisar();
      return;
    }
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
      consultas = [];
      expedientes = [];
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

  String nombrePaciente(String id) => porId(id)?.nombreCompleto ?? 'Derechohabiente';

  String nombreMedico(String id) {
    for (final medico in medicos) {
      if (medico.id == id) return medico.nombreCompleto;
    }
    return 'Médico sin registrar';
  }

  /// Misma línea de la agenda web: afiliación · folio de consulta · región.
  String lineaAgenda(Cita cita) {
    final paciente = porId(cita.pacienteId);
    final afiliacion = (paciente?.afiliacion ?? '').isEmpty ? 'Sin afiliación' : paciente!.afiliacion;
    final region = paciente?.regionAgenda ?? 'Sin región';
    return '$afiliacion · ${folioConsulta(cita)} · $region';
  }

  String folioConsulta(Cita cita) {
    for (final consulta in consultas) {
      if (consulta.citaId == cita.id && consulta.folio.trim().isNotEmpty) return consulta.folio;
    }
    if (cita.folio.trim().isNotEmpty) return cita.folio;
    return 'Sin folio';
  }

  List<Cita> get llamadasPendientes {
    return citas.where((cita) => cita.sinHospital && cita.estado != 'cancelada').toList();
  }

  List<String> get sedesAgenda {
    final nombres = <String>{};
    for (final hospital in hospitales) {
      if (hospital.nombre.trim().isNotEmpty) nombres.add(hospital.nombre.trim());
    }
    for (final cita in citas) {
      if (cita.clinica.trim().isNotEmpty) nombres.add(cita.clinica.trim());
    }
    final lista = nombres.toList()..sort();
    return lista;
  }

  ExpedienteClinico? expedienteDe(String pacienteId) {
    for (final expediente in expedientes) {
      if (expediente.pacienteId == pacienteId) return expediente;
    }
    return null;
  }

  List<ConsultaClinica> consultasDe(String pacienteId) {
    return consultas.where((consulta) => consulta.pacienteId == pacienteId).toList();
  }

  void dejarMensaje(String pacienteId, String texto) {
    final limpio = texto.trim();
    if (pacienteId.isEmpty || limpio.isEmpty) return;
    mensajes = [
      Mensaje(
        id: 'msg-${DateTime.now().microsecondsSinceEpoch}',
        pacienteId: pacienteId,
        texto: limpio,
        de: 'paciente',
        cuando: DateTime.now(),
      ),
      ...mensajes,
    ];
    _avisar();
  }

  void marcarMedicamento(String consultaId, int indice, String estatus) {
    _editarConsulta(consultaId, (consulta) {
      if (indice < 0 || indice >= consulta.medicamentos.length) return consulta;
      final actual = consulta.medicamentos[indice];
      final clave = estatus == 'entregado' ? 'surtido' : estatus;
      final lineas = List<MedicamentoLinea>.of(consulta.medicamentos);
      lineas[indice] = actual.copiar(
        estatusEntrega: clave,
        fechaEntrega: clave == 'pendiente' ? '' : (actual.fechaEntrega.isNotEmpty ? actual.fechaEntrega : DateTime.now().toIso8601String()),
      );
      return consulta.copiar(medicamentos: lineas);
    });
  }

  void anotarMedicamento(String consultaId, int indice, String nota) {
    _editarConsulta(consultaId, (consulta) {
      if (indice < 0 || indice >= consulta.medicamentos.length) return consulta;
      final lineas = List<MedicamentoLinea>.of(consulta.medicamentos);
      lineas[indice] = lineas[indice].copiar(notaSurtido: nota.trim());
      return consulta.copiar(medicamentos: lineas);
    });
  }

  void evidenciarMedicamento(String consultaId, int indice, String nombre) {
    final archivo = nombre.trim();
    if (archivo.isEmpty) return;
    _editarConsulta(consultaId, (consulta) {
      if (indice < 0 || indice >= consulta.medicamentos.length) return consulta;
      final lineas = List<MedicamentoLinea>.of(consulta.medicamentos);
      lineas[indice] = lineas[indice].copiar(evidenciaNombre: archivo);
      return consulta.copiar(medicamentos: lineas);
    });
  }

  void actualizarOrden(String consultaId, String ordenId, {String? estatus, String? resultado, String? evidenciaNombre}) {
    _editarConsulta(consultaId, (consulta) {
      final ordenes = [
        for (final orden in consulta.ordenes)
          if (orden.id != ordenId)
            orden
          else
            orden.copiar(
              estatus: estatus,
              resultado: resultado,
              evidenciaNombre: evidenciaNombre,
              fechaResultado: estatus == 'resultado' && orden.fechaResultado.isEmpty ? DateTime.now().toIso8601String() : null,
            ),
      ];
      return consulta.copiar(ordenes: ordenes);
    });
  }

  void aprobarOrden(String consultaId, String ordenId) {
    for (final consulta in consultas) {
      if (consulta.id != consultaId) continue;
      for (final orden in consulta.ordenes) {
        if (orden.id != ordenId) continue;
        actualizarOrden(consultaId, ordenId, estatus: orden.estatus == 'pendiente' ? 'recibida' : 'en_proceso');
        return;
      }
    }
  }

  void guardarResultadoOrden(String consultaId, String ordenId, String resultado) {
    final texto = resultado.trim();
    var conEvidencia = false;
    for (final consulta in consultas) {
      if (consulta.id != consultaId) continue;
      for (final orden in consulta.ordenes) {
        if (orden.id == ordenId) conEvidencia = orden.evidenciaNombre.isNotEmpty;
      }
    }
    actualizarOrden(consultaId, ordenId, resultado: texto, estatus: texto.isNotEmpty || conEvidencia ? 'resultado' : null);
  }

  void evidenciarOrden(String consultaId, String ordenId, String nombre) {
    final archivo = nombre.trim();
    if (archivo.isEmpty) return;
    actualizarOrden(consultaId, ordenId, evidenciaNombre: archivo, estatus: 'resultado');
  }

  void _editarConsulta(String id, ConsultaClinica Function(ConsultaClinica) cambiar) {
    final indice = consultas.indexWhere((consulta) => consulta.id == id);
    if (indice < 0) return;
    final copia = List<ConsultaClinica>.of(consultas);
    copia[indice] = cambiar(copia[indice]);
    consultas = copia;
    _avisar();
  }

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

  void registrarPasoRecepcion(String citaId) {
    final indice = citas.indexWhere((cita) => cita.id == citaId);
    if (indice < 0) return;
    final siguiente = siguienteEstadoRecepcion(citas[indice].estado);
    if (siguiente == null) return;
    final copia = List<Cita>.of(citas);
    copia[indice] = citas[indice].copiar(estado: siguiente);
    citas = copia;
    _avisar();
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
          paciente.correo,
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

const _ruido = {'pacientes', 'paciente', 'derechohabientes', 'derechohabiente', 'con', 'que', 'tienen', 'de'};
