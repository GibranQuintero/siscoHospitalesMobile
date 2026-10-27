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

  String get nombreCompleto {
    return [nombre, apellido, segundoApellido].where((parte) => parte.trim().isNotEmpty).join(' ');
  }

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

  factory Cita.fromJson(Map<String, dynamic> json) {
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
