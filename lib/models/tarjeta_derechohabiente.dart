import 'consultorio.dart';

/// Credencial virtual del paciente para identificarse en caja y recepción.
class TarjetaDerechohabiente {
  const TarjetaDerechohabiente({
    required this.titular,
    required this.numero,
    required this.expediente,
    required this.plan,
    required this.vigenciaHasta,
    required this.estado,
  });

  final String titular;
  final String numero;
  final String expediente;
  final String plan;
  final String vigenciaHasta;

  /// `vigente`, `vencida` o `sin_poliza`.
  final String estado;

  bool get cubierta => estado == 'vigente';

  factory TarjetaDerechohabiente.de(Paciente paciente, [DateTime? hoy]) {
    final seguro = paciente.seguros.where((item) => item.certificado.isNotEmpty || item.aseguradora.isNotEmpty).firstOrNull;
    final referencia = hoy ?? DateTime.now();
    return TarjetaDerechohabiente(
      titular: paciente.nombreCompleto,
      numero: seguro != null && seguro.certificado.isNotEmpty ? seguro.certificado : paciente.id,
      expediente: paciente.id,
      plan: seguro == null || seguro.aseguradora.isEmpty ? 'Red SISCO' : seguro.aseguradora,
      vigenciaHasta: seguro?.vigenciaHasta ?? '',
      estado: _estado(seguro, referencia),
    );
  }
}

String etiquetaTarjeta(String estado) {
  switch (estado) {
    case 'vigente':
      return 'Vigente';
    case 'vencida':
      return 'Vencida';
    case 'sin_poliza':
      return 'Sin póliza';
    default:
      return estado;
  }
}

String _estado(SeguroPaciente? seguro, DateTime hoy) {
  if (seguro == null) return 'sin_poliza';
  final vigencia = seguro.vigenciaHasta.trim();
  if (vigencia.isEmpty) return 'vigente';
  final fecha = DateTime.tryParse(vigencia);
  if (fecha == null) return 'vigente';
  final limite = DateTime(fecha.year, fecha.month, fecha.day);
  final dia = DateTime(hoy.year, hoy.month, hoy.day);
  return limite.isBefore(dia) ? 'vencida' : 'vigente';
}
