import 'models/consultorio.dart';

class DatosPrueba {
  static DateTime hora(int dias, int hora, int minuto) {
    final hoy = DateTime.now();
    return DateTime(hoy.year, hoy.month, hoy.day + dias, hora, minuto);
  }

  static List<Paciente> pacientes() {
    return const [
      Paciente(
        id: 'p-ana',
        nombre: 'Ana',
        apellido: 'Ríos',
        segundoApellido: 'Luna',
        alias: 'Ana',
        curp: 'RILA900101MDFRNN01',
        telefono: '5551002001',
        correo: 'ana.rios@ejemplo.local',
        sexo: 'Femenino',
        fechaNacimiento: '1990-01-01',
        tipoSangre: 'O+',
        direccion: 'Roma Norte, Ciudad de México',
        ocupacion: 'Diseñadora',
        alergias: ['Penicilina'],
        seguros: [SeguroPaciente(aseguradora: 'Seguro ejemplo', afiliado: 'Ana Ríos', certificado: 'PX-1001', vigenciaHasta: '2027-12-31')],
        contactos: [ContactoEmergencia(nombre: 'Luis Ríos', parentesco: 'Hermano', telefono: '5551002002')],
      ),
      Paciente(
        id: 'p-bruno',
        nombre: 'Bruno',
        apellido: 'Salas',
        segundoApellido: 'Vega',
        alias: '',
        curp: 'SAVB850512HDFLLR02',
        telefono: '5551003003',
        correo: 'bruno.salas@ejemplo.local',
        sexo: 'Masculino',
        fechaNacimiento: '1985-05-12',
        tipoSangre: 'A+',
        direccion: 'Guadalajara, Jalisco',
        ocupacion: 'Contador',
        alergias: ['Mariscos'],
        seguros: [SeguroPaciente(aseguradora: 'Seguro ejemplo', afiliado: 'Bruno Salas', certificado: 'PX-1002', vigenciaHasta: '2027-06-30')],
        contactos: [ContactoEmergencia(nombre: 'Marta Vega', parentesco: 'Esposa', telefono: '5551003004')],
      ),
      Paciente(
        id: 'p-clara',
        nombre: 'Clara',
        apellido: 'Nieto',
        segundoApellido: 'Paz',
        alias: '',
        curp: 'NIPC780908MDFZLR03',
        telefono: '5551004005',
        correo: 'clara.nieto@ejemplo.local',
        sexo: 'Femenino',
        fechaNacimiento: '1978-09-08',
        tipoSangre: 'B+',
        direccion: 'Monterrey, Nuevo León',
        ocupacion: 'Docente',
        alergias: [],
        seguros: [],
        contactos: [],
      ),
    ];
  }

  static List<Cita> citas() {
    return [
      Cita(
        id: 'c-1',
        pacienteId: 'p-ana',
        clinica: 'Consultorio Roma',
        inicio: hora(0, 9, 0),
        fin: hora(0, 9, 30),
        estado: 'confirmada',
        motivo: 'Control de presión',
        notas: 'Trae estudios de la semana pasada.',
        videollamada: true,
        videollamadaUrl: '',
        pacienteNuevo: false,
        folio: 'C-1001',
      ),
      Cita(
        id: 'c-2',
        pacienteId: 'p-bruno',
        clinica: 'Consultorio Roma',
        inicio: hora(0, 11, 30),
        fin: hora(0, 12, 0),
        estado: 'en_consulta',
        motivo: 'Dolor lumbar',
        notas: '',
        videollamada: false,
        videollamadaUrl: '',
        pacienteNuevo: false,
        folio: 'C-1002',
      ),
      Cita(
        id: 'c-3',
        pacienteId: 'p-clara',
        clinica: 'Hospital del Valle',
        inicio: hora(0, 16, 0),
        fin: hora(0, 16, 30),
        estado: 'no_confirmada',
        motivo: 'Primera valoración',
        notas: '',
        videollamada: true,
        videollamadaUrl: '',
        pacienteNuevo: true,
        folio: 'C-1003',
      ),
      Cita(
        id: 'c-4',
        pacienteId: 'p-ana',
        clinica: 'Consultorio Roma',
        inicio: hora(0, 13, 0),
        fin: hora(0, 13, 20),
        estado: 'terminada',
        motivo: 'Resultados de laboratorio',
        notas: 'Se explicaron los resultados.',
        videollamada: false,
        videollamadaUrl: '',
        pacienteNuevo: false,
        folio: 'C-1004',
      ),
      Cita(
        id: 'c-5',
        pacienteId: 'p-bruno',
        clinica: 'Hospital del Valle',
        inicio: hora(1, 10, 0),
        fin: hora(1, 10, 30),
        estado: 'confirmada',
        motivo: 'Seguimiento',
        notas: '',
        videollamada: false,
        videollamadaUrl: '',
        pacienteNuevo: false,
        folio: 'C-1005',
      ),
    ];
  }

  static List<HospitalRed> hospitales() {
    return const [
      HospitalRed(
        id: 'h-roma',
        nombre: 'Consultorio Roma',
        ciudad: 'Ciudad de México',
        nivel: 'Consulta externa',
        camas: 0,
        quirofanos: 0,
        especialidades: ['medicina_general', 'cardiologia'],
        convenio: true,
        tipo: 'sucursal',
        telefono: '5552001001',
        correo: 'roma@ejemplo.local',
        direccion: 'Av. Álvaro Obregón 100',
        estatus: 'Activo',
      ),
      HospitalRed(
        id: 'h-valle',
        nombre: 'Hospital del Valle',
        ciudad: 'Monterrey',
        nivel: 'Segundo nivel',
        camas: 80,
        quirofanos: 4,
        especialidades: ['traumatologia', 'medicina_general'],
        convenio: true,
        tipo: 'matriz',
        telefono: '5552001002',
        correo: 'valle@ejemplo.local',
        direccion: 'Av. Constitución 250',
        estatus: 'Activo',
      ),
      HospitalRed(
        id: 'h-segura',
        nombre: 'Aseguradora Ejemplo',
        ciudad: 'Guadalajara',
        nivel: 'Convenio',
        camas: null,
        quirofanos: null,
        especialidades: ['medicina_general'],
        convenio: true,
        tipo: 'aseguradora',
        telefono: '5552001003',
        correo: 'convenio@ejemplo.local',
        direccion: 'Av. Americas 40',
        estatus: 'Activo',
      ),
    ];
  }

  static List<Medico> medicos() {
    return const [
      Medico(
        id: 'm-1',
        nombre: 'Elena',
        apellido: 'Cruz',
        segundoApellido: 'Sol',
        cedula: '1234567',
        especialidad: 'Medicina general',
        esEspecialista: false,
        telefono: '5553001001',
        correo: 'elena.cruz@ejemplo.local',
        estatus: 'Activo',
        hospitales: ['h-roma', 'h-valle'],
      ),
      Medico(
        id: 'm-2',
        nombre: 'Iván',
        apellido: 'Mora',
        segundoApellido: 'León',
        cedula: '7654321',
        especialidad: 'Cardiología',
        esEspecialista: true,
        telefono: '5553001002',
        correo: 'ivan.mora@ejemplo.local',
        estatus: 'Activo',
        hospitales: ['h-roma'],
      ),
      Medico(
        id: 'm-3',
        nombre: 'Rosa',
        apellido: 'Pineda',
        segundoApellido: 'Gil',
        cedula: '2468101',
        especialidad: 'Traumatología',
        esEspecialista: true,
        telefono: '5553001003',
        correo: 'rosa.pineda@ejemplo.local',
        estatus: 'Activo',
        hospitales: ['h-valle'],
      ),
    ];
  }

  static List<Mensaje> mensajes() {
    return [
      Mensaje(id: 'msg-1', pacienteId: 'p-ana', texto: '¿Puedo llegar diez minutos tarde?', de: 'paciente', cuando: hora(0, 8, 10)),
      Mensaje(id: 'msg-2', pacienteId: 'p-clara', texto: 'Confirmo la cita de las 16:00.', de: 'paciente', cuando: hora(0, 7, 40)),
    ];
  }

  static Map<String, String> especialidades() {
    return const {
      'medicina_general': 'Medicina general',
      'cardiologia': 'Cardiología',
      'traumatologia': 'Traumatología',
    };
  }
}
