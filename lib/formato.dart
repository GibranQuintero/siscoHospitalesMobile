const dias = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
const meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

String limpio(String texto) {
  return texto
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('à', 'a')
      .replaceAll('ä', 'a')
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ë', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ì', 'i')
      .replaceAll('ï', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ò', 'o')
      .replaceAll('ö', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ù', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ñ', 'n');
}

String cadena(dynamic valor) => valor == null ? '' : valor.toString();

bool bandera(dynamic valor) => valor == true || valor == 1 || valor == '1' || valor == 'true';

int? entero(dynamic valor) {
  if (valor == null) return null;
  if (valor is int) return valor;
  if (valor is num) return valor.toInt();
  return int.tryParse(valor.toString());
}

Map<String, dynamic> mapa(dynamic valor) {
  if (valor is Map<String, dynamic>) return valor;
  if (valor is Map) return Map<String, dynamic>.from(valor);
  return {};
}

List<T> lista<T>(dynamic valor, T Function(Map<String, dynamic>) leer) {
  if (valor is! List) return [];
  return valor.whereType<Map>().map((item) => leer(Map<String, dynamic>.from(item))).toList();
}

DateTime? fechaHora(dynamic valor) {
  final crudo = cadena(valor).trim();
  if (crudo.isEmpty) return null;
  return DateTime.tryParse(crudo)?.toLocal();
}

bool esMismoDia(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String fechaLarga(DateTime dia) {
  return '${dias[dia.weekday - 1]} ${dia.day} de ${meses[dia.month - 1]}';
}

String fechaDia(String iso) {
  final coincidencia = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(iso.trim());
  if (coincidencia == null) return iso;
  return '${coincidencia.group(3)}/${coincidencia.group(2)}/${coincidencia.group(1)}';
}

String horaDe(DateTime momento) {
  final hora = momento.hour.toString().padLeft(2, '0');
  final minuto = momento.minute.toString().padLeft(2, '0');
  return '$hora:$minuto';
}

String etiquetaDia(DateTime dia, DateTime hoy) {
  if (esMismoDia(dia, hoy)) return 'Hoy';
  final manana = DateTime(hoy.year, hoy.month, hoy.day).add(const Duration(days: 1));
  if (esMismoDia(dia, manana)) return 'Mañana';
  return fechaLarga(dia);
}

String normalizarBase(String raw) {
  var base = raw.trim();
  if (base.isEmpty) return base;
  if (!base.contains('://')) base = 'http://$base';
  while (base.endsWith('/')) {
    base = base.substring(0, base.length - 1);
  }
  for (final sufijo in ['/api/consultorio', '/api']) {
    if (base.endsWith(sufijo)) {
      base = base.substring(0, base.length - sufijo.length);
      break;
    }
  }
  return '$base/';
}

const equipoLocal = '172.16.21.170';

String hostEnEsteEquipo(String base) {
  final normal = normalizarBase(base);
  final uri = Uri.tryParse(normal);
  if (uri == null) return normal;
  const locales = {'localhost', '127.0.0.1', '10.0.2.2'};
  if (locales.contains(uri.host)) {
    return uri.replace(host: equipoLocal).toString();
  }
  return normal;
}

String etiquetaEstado(String estado) {
  const mapa = {
    'no_confirmada': 'Por confirmar',
    'confirmada': 'Confirmada',
    'en_consulta': 'En consulta',
    'terminada': 'Terminada',
    'cancelada': 'Cancelada',
    'inasistencia': 'No se presentó',
  };
  return mapa[estado] ?? estado.replaceAll('_', ' ');
}

String etiquetaNivel(String nivel) {
  const mapa = {
    'primer': 'Primer nivel',
    'segundo': 'Segundo nivel',
    'tercer': 'Tercer nivel',
  };
  return mapa[nivel] ?? '';
}

String etiquetaTipoHospital(String tipo) {
  const mapa = {
    'aseguradora': 'Aseguradora',
    'matriz': 'Matriz',
    'sucursal': 'Sucursal',
  };
  return mapa[tipo] ?? tipo;
}
