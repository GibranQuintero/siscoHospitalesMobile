import '../formato.dart';

class SeguroPaciente {
  const SeguroPaciente({
    required this.aseguradora,
    required this.afiliado,
    required this.certificado,
    required this.vigenciaHasta,
  });

  final String aseguradora;
  final String afiliado;
  final String certificado;
  final String vigenciaHasta;

  factory SeguroPaciente.fromJson(Map<String, dynamic> json) {
    return SeguroPaciente(
      aseguradora: cadena(json['aseguradora']),
      afiliado: cadena(json['afiliado']),
      certificado: cadena(json['certificado']),
      vigenciaHasta: cadena(json['vigenciaHasta']),
    );
  }
}

class ContactoEmergencia {
  const ContactoEmergencia({
    required this.nombre,
    required this.parentesco,
    required this.telefono,
  });

  final String nombre;
  final String parentesco;
  final String telefono;

  factory ContactoEmergencia.fromJson(Map<String, dynamic> json) {
    return ContactoEmergencia(
      nombre: cadena(json['nombre']),
      parentesco: cadena(json['parentesco']),
      telefono: cadena(json['telefono']),
    );
  }
}

class Paciente {
  const Paciente({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.segundoApellido,
    required this.alias,
    required this.curp,
    required this.telefono,
    required this.correo,
    required this.sexo,
    required this.fechaNacimiento,
    required this.tipoSangre,
    required this.direccion,
    required this.ocupacion,
    required this.alergias,
    required this.seguros,
    required this.contactos,
    this.regionIndep = '',
  });

  final String id;
  final String nombre;
  final String apellido;
  final String segundoApellido;
  final String alias;
  final String curp;
  final String telefono;
  final String correo;
  final String sexo;
  final String fechaNacimiento;
  final String tipoSangre;
  final String direccion;
  final String ocupacion;
  final List<String> alergias;
  final List<SeguroPaciente> seguros;
  final List<ContactoEmergencia> contactos;
  final String regionIndep;

  String get nombreCompleto {
    return [nombre, apellido, segundoApellido].where((parte) => parte.trim().isNotEmpty).join(' ');
  }

  String get afiliacion {
    for (final seguro in seguros) {
      if (seguro.afiliado.trim().isNotEmpty) return seguro.afiliado.trim();
    }
    return '';
  }

  String get regionAgenda => regionIndep.trim().isEmpty ? 'Sin región' : regionIndep.trim();

  factory Paciente.fromJson(Map<String, dynamic> json) {
    final antecedentes = mapa(json['antecedentes']);
    final bloqueAlergias = mapa(antecedentes['alergias']);
    final items = bloqueAlergias['items'];
    final alergias = <String>[];
    if (items is List) {
      for (final item in items) {
        final alergeno = item is Map ? cadena(item['alergeno']) : cadena(item);
        if (alergeno.isNotEmpty) alergias.add(alergeno);
      }
    }
    final seguros = lista(json['seguros'], SeguroPaciente.fromJson);
    final seguroSuelto = mapa(json['seguro']);
    if (seguros.isEmpty && seguroSuelto.isNotEmpty) {
      seguros.add(SeguroPaciente.fromJson(seguroSuelto));
    }
    return Paciente(
      id: cadena(json['id']),
      nombre: cadena(json['nombre']),
      apellido: cadena(json['apellido']),
      segundoApellido: cadena(json['segundoApellido']),
      alias: cadena(json['alias']),
      curp: cadena(json['curp']),
      telefono: cadena(json['telefono']),
      correo: cadena(json['correo']),
      sexo: cadena(json['sexo']),
      fechaNacimiento: cadena(json['fechaNacimiento']),
      tipoSangre: cadena(json['tipoSangre']),
      direccion: cadena(json['direccion']),
      ocupacion: cadena(json['ocupacion']),
      alergias: alergias,
      seguros: seguros,
      contactos: lista(json['contactosEmergencia'], ContactoEmergencia.fromJson),
      regionIndep: cadena(json['regionIndep']).isNotEmpty ? cadena(json['regionIndep']) : cadena(json['region']),
    );
  }
}

class Cita {
  const Cita({
    required this.id,
    required this.pacienteId,
    required this.clinica,
    required this.inicio,
    required this.fin,
    required this.estado,
    required this.motivo,
    required this.notas,
    required this.videollamada,
    required this.videollamadaUrl,
    required this.pacienteNuevo,
    required this.folio,
    this.tipoServicio = 'Médico general',
    this.medicoId = '',
    this.etiquetas = '',
    this.origen = '',
    this.creadoPor = '',
  });

  final String id;
  final String pacienteId;
  final String clinica;
  final DateTime? inicio;
  final DateTime? fin;
  final String estado;
  final String motivo;
  final String notas;
  final bool videollamada;
  final String videollamadaUrl;
  final bool pacienteNuevo;
  final String folio;
  final String tipoServicio;
  final String medicoId;
  final String etiquetas;
  final String origen;
  final String creadoPor;

  bool get sinHospital => clinica.trim().isEmpty;

  factory Cita.fromJson(Map<String, dynamic> json) {
    final origen = cadena(json['origen']);
    return Cita(
      id: cadena(json['id']),
      pacienteId: cadena(json['pacienteId']),
      clinica: cadena(json['clinica']),
      inicio: fechaHora(json['inicio']),
      fin: fechaHora(json['fin']),
      estado: cadena(json['estado']),
      motivo: cadena(json['motivo']),
      notas: cadena(json['notas']),
      videollamada: bandera(json['videollamada']),
      videollamadaUrl: cadena(json['videollamadaUrl']),
      pacienteNuevo: bandera(json['pacienteNuevo']),
      folio: cadena(json['folio']),
      tipoServicio: cadena(json['tipoServicio']).isEmpty ? 'Médico general' : cadena(json['tipoServicio']),
      medicoId: cadena(json['medicoId']),
      etiquetas: cadena(json['etiquetas']),
      origen: origen == 'llamada' || origen == 'agenda' ? origen : '',
      creadoPor: cadena(json['creadoPor']),
    );
  }

  Cita copiar({String? estado}) {
    return Cita(
      id: id,
      pacienteId: pacienteId,
      clinica: clinica,
      inicio: inicio,
      fin: fin,
      estado: estado ?? this.estado,
      motivo: motivo,
      notas: notas,
      videollamada: videollamada,
      videollamadaUrl: videollamadaUrl,
      pacienteNuevo: pacienteNuevo,
      folio: folio,
      tipoServicio: tipoServicio,
      medicoId: medicoId,
      etiquetas: etiquetas,
      origen: origen,
      creadoPor: creadoPor,
    );
  }
}

class HospitalRed {
  const HospitalRed({
    required this.id,
    required this.nombre,
    required this.ciudad,
    required this.nivel,
    required this.camas,
    required this.quirofanos,
    required this.especialidades,
    required this.convenio,
    required this.tipo,
    required this.telefono,
    required this.correo,
    required this.direccion,
    required this.estatus,
  });

  final String id;
  final String nombre;
  final String ciudad;
  final String nivel;
  final int? camas;
  final int? quirofanos;
  final List<String> especialidades;
  final bool convenio;
  final String tipo;
  final String telefono;
  final String correo;
  final String direccion;
  final String estatus;

  factory HospitalRed.fromJson(Map<String, dynamic> json) {
    final especialidades = json['especialidades'];
    return HospitalRed(
      id: cadena(json['id']),
      nombre: cadena(json['nombre']),
      ciudad: cadena(json['ciudad']),
      nivel: cadena(json['nivel']),
      camas: entero(json['camas']),
      quirofanos: entero(json['quirofanos']),
      especialidades: especialidades is List ? especialidades.map(cadena).where((e) => e.isNotEmpty).toList() : const [],
      convenio: bandera(json['convenio']),
      tipo: cadena(json['tipo']),
      telefono: cadena(json['telefono']),
      correo: cadena(json['correo']),
      direccion: cadena(json['direccion']),
      estatus: cadena(json['estatus']),
    );
  }
}

class Medico {
  const Medico({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.segundoApellido,
    required this.cedula,
    required this.especialidad,
    required this.esEspecialista,
    required this.telefono,
    required this.correo,
    required this.estatus,
    required this.hospitales,
  });

  final String id;
  final String nombre;
  final String apellido;
  final String segundoApellido;
  final String cedula;
  final String especialidad;
  final bool esEspecialista;
  final String telefono;
  final String correo;
  final String estatus;
  final List<String> hospitales;

  String get nombreCompleto {
    return [nombre, apellido, segundoApellido].where((parte) => parte.trim().isNotEmpty).join(' ');
  }

  factory Medico.fromJson(Map<String, dynamic> json) {
    final sedes = json['hospitales'];
    return Medico(
      id: cadena(json['id']),
      nombre: cadena(json['nombre']),
      apellido: cadena(json['apellido']),
      segundoApellido: cadena(json['segundoApellido']),
      cedula: cadena(json['cedula']),
      especialidad: cadena(json['especialidad']),
      esEspecialista: bandera(json['esEspecialista']),
      telefono: cadena(json['telefono']),
      correo: cadena(json['correo']),
      estatus: cadena(json['estatus']),
      hospitales: sedes is List ? sedes.map(cadena).where((e) => e.isNotEmpty).toList() : const [],
    );
  }
}

class Mensaje {
  const Mensaje({
    required this.id,
    required this.pacienteId,
    required this.texto,
    required this.de,
    required this.cuando,
  });

  final String id;
  final String pacienteId;
  final String texto;
  final String de;
  final DateTime? cuando;

  factory Mensaje.fromJson(Map<String, dynamic> json) {
    return Mensaje(
      id: cadena(json['id']),
      pacienteId: cadena(json['pacienteId']),
      texto: cadena(json['texto']),
      de: cadena(json['de']).isNotEmpty ? cadena(json['de']) : cadena(json['origen']),
      cuando: fechaHora(json['cuando']),
    );
  }
}

class Antecedente {
  const Antecedente({required this.titulo, required this.detalle});

  final String titulo;
  final String detalle;
}

class ArchivoExpediente {
  const ArchivoExpediente({required this.nombre, required this.fecha});

  final String nombre;
  final String fecha;
}

class ConsentimientoRegistro {
  const ConsentimientoRegistro({required this.nombre, required this.fecha, required this.firmado});

  final String nombre;
  final String fecha;
  final bool firmado;
}

class ExpedienteClinico {
  const ExpedienteClinico({
    required this.pacienteId,
    required this.antecedentes,
    required this.archivos,
    required this.consentimientos,
  });

  final String pacienteId;
  final List<Antecedente> antecedentes;
  final List<ArchivoExpediente> archivos;
  final List<ConsentimientoRegistro> consentimientos;
}

class MedicamentoLinea {
  const MedicamentoLinea({
    required this.nombre,
    this.detalle = '',
    this.indicacion = '',
    this.estatusEntrega = 'pendiente',
    this.notaSurtido = '',
    this.evidenciaNombre = '',
    this.fechaEntrega = '',
  });

  final String nombre;
  final String detalle;
  final String indicacion;
  final String estatusEntrega;
  final String notaSurtido;
  final String evidenciaNombre;
  final String fechaEntrega;

  bool get pendiente => estatusEntrega != 'surtido' && estatusEntrega != 'entregado' && estatusEntrega != 'no_surtido';

  MedicamentoLinea copiar({
    String? estatusEntrega,
    String? notaSurtido,
    String? evidenciaNombre,
    String? fechaEntrega,
  }) {
    return MedicamentoLinea(
      nombre: nombre,
      detalle: detalle,
      indicacion: indicacion,
      estatusEntrega: estatusEntrega ?? this.estatusEntrega,
      notaSurtido: notaSurtido ?? this.notaSurtido,
      evidenciaNombre: evidenciaNombre ?? this.evidenciaNombre,
      fechaEntrega: fechaEntrega ?? this.fechaEntrega,
    );
  }
}

class OrdenEstudio {
  const OrdenEstudio({
    required this.id,
    required this.tipo,
    required this.concepto,
    this.indicacion = '',
    this.lugar = '',
    this.folio = '',
    this.estatus = 'pendiente',
    this.resultado = '',
    this.evidenciaNombre = '',
    this.fechaResultado = '',
  });

  final String id;
  final String tipo;
  final String concepto;
  final String indicacion;
  final String lugar;
  final String folio;
  final String estatus;
  final String resultado;
  final String evidenciaNombre;
  final String fechaResultado;

  bool get cerrada => estatus == 'resultado' || estatus == 'cancelada';

  OrdenEstudio copiar({
    String? estatus,
    String? resultado,
    String? evidenciaNombre,
    String? fechaResultado,
  }) {
    return OrdenEstudio(
      id: id,
      tipo: tipo,
      concepto: concepto,
      indicacion: indicacion,
      lugar: lugar,
      folio: folio,
      estatus: estatus ?? this.estatus,
      resultado: resultado ?? this.resultado,
      evidenciaNombre: evidenciaNombre ?? this.evidenciaNombre,
      fechaResultado: fechaResultado ?? this.fechaResultado,
    );
  }
}

class ConsultaClinica {
  const ConsultaClinica({
    required this.id,
    required this.citaId,
    required this.pacienteId,
    required this.medicoId,
    required this.motivo,
    required this.diagnostico,
    required this.plan,
    required this.notaClinica,
    this.folio = '',
    this.folioReceta = '',
    this.medicamentos = const [],
    this.ordenes = const [],
  });

  final String id;
  final String citaId;
  final String pacienteId;
  final String medicoId;
  final String motivo;
  final String diagnostico;
  final String plan;
  final String notaClinica;
  final String folio;
  final String folioReceta;
  final List<MedicamentoLinea> medicamentos;
  final List<OrdenEstudio> ordenes;

  bool get recetaCerrada => medicamentos.isNotEmpty && medicamentos.every((linea) => !linea.pendiente);

  ConsultaClinica copiar({List<MedicamentoLinea>? medicamentos, List<OrdenEstudio>? ordenes}) {
    return ConsultaClinica(
      id: id,
      citaId: citaId,
      pacienteId: pacienteId,
      medicoId: medicoId,
      motivo: motivo,
      diagnostico: diagnostico,
      plan: plan,
      notaClinica: notaClinica,
      folio: folio,
      folioReceta: folioReceta,
      medicamentos: medicamentos ?? this.medicamentos,
      ordenes: ordenes ?? this.ordenes,
    );
  }
}
