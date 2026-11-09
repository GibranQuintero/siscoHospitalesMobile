import 'package:flutter/material.dart';

import '../formato.dart';
import '../models/consultorio.dart';
import '../theme/sisco_theme.dart';

class EstadoChip extends StatelessWidget {
  const EstadoChip({super.key, required this.estado});

  final String estado;

  @override
  Widget build(BuildContext context) {
    final color = colorEstado(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(etiquetaEstado(estado), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

Color colorEstado(String estado) {
  switch (estado) {
    case 'confirmada':
      return cian;
    case 'en_consulta':
      return azul;
    case 'terminada':
      return exito;
    case 'cancelada':
      return suave;
    case 'inasistencia':
    case 'no_confirmada':
      return aviso;
    default:
      return aviso;
  }
}

class MarcaPaciente {
  const MarcaPaciente(this.texto, this.color);

  final String texto;
  final Color color;
}

MarcaPaciente marcaDePaciente(List<Cita> citas, [DateTime? hoy]) {
  final referencia = hoy ?? DateTime.now();
  final activas = citas.where((cita) => cita.estado != 'cancelada' && cita.inicio != null);
  if (activas.any((cita) => esMismoDia(cita.inicio!, referencia))) {
    return const MarcaPaciente('Activa hoy', exitoVivo);
  }
  final inicioDia = DateTime(referencia.year, referencia.month, referencia.day);
  if (activas.any((cita) => !cita.inicio!.isBefore(inicioDia))) {
    return const MarcaPaciente('Cita próx.', aviso);
  }
  return const MarcaPaciente('Control', control);
}

String ultimaVisitaDe(List<Cita> citas, [DateTime? hoy]) {
  final referencia = hoy ?? DateTime.now();
  final pasadas = citas.where((cita) => cita.inicio != null && cita.inicio!.isBefore(referencia)).toList()
    ..sort((a, b) => b.inicio!.compareTo(a.inicio!));
  if (pasadas.isEmpty) return '';
  return 'Última visita: ${fechaCorta(pasadas.first.inicio!)}';
}

String inicialesDe(String nombre, String apellido) {
  final a = nombre.trim().isEmpty ? '' : nombre.trim()[0];
  final b = apellido.trim().isEmpty ? '' : apellido.trim()[0];
  final juntas = (a + b).toUpperCase();
  return juntas.isEmpty ? '?' : juntas;
}

class AvatarIniciales extends StatelessWidget {
  const AvatarIniciales({super.key, required this.iniciales, required this.gradiente, this.tamano = 48});

  final String iniciales;
  final Gradient gradiente;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: gradiente,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: Text(iniciales, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: tamano * 0.32)),
    );
  }
}

class BotonPastilla extends StatelessWidget {
  const BotonPastilla({
    super.key,
    required this.texto,
    required this.onPressed,
    this.icono,
    this.fondo = const Color(0x1F0082AB),
    this.borde = const Color(0x4D0068A2),
    this.color = azul,
    this.expandir = false,
  });

  final String texto;
  final VoidCallback? onPressed;
  final IconData? icono;
  final Color fondo;
  final Color borde;
  final Color color;
  final bool expandir;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: expandir ? double.infinity : null,
      child: Material(
      color: fondo,
      shape: StadiumBorder(side: BorderSide(color: borde)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: expandir ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (icono != null) ...[
                Icon(icono, size: 16, color: color),
                const SizedBox(width: 6),
              ],
              Text(texto, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class CitaTarjeta extends StatelessWidget {
  const CitaTarjeta({
    super.key,
    required this.cita,
    required this.paciente,
    this.linea = '',
    this.medico = '',
    this.onTap,
    this.onMeet,
    this.onCat,
    this.meetListo = false,
  });

  final Cita cita;
  final String paciente;
  final String linea;
  final String medico;
  final VoidCallback? onTap;
  final VoidCallback? onMeet;
  final VoidCallback? onCat;
  final bool meetListo;

  @override
  Widget build(BuildContext context) {
    final inicio = cita.inicio;
    final sede = cita.sinHospital ? 'Sin consultorio - hospital' : cita.clinica;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: tarjeta(),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 58,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('HORA', style: TextStyle(color: suave, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                        const SizedBox(height: 2),
                        Text(
                          inicio == null ? '--:--' : horaDe(inicio),
                          style: const TextStyle(color: marino, fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(paciente, style: const TextStyle(color: texto, fontWeight: FontWeight.w700, fontSize: 16))),
                            EstadoChip(estado: cita.estado),
                          ],
                        ),
                        if (linea.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(linea, style: const TextStyle(color: azul, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                        if (cita.tipoServicio.isNotEmpty || medico.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            [cita.tipoServicio, if (medico.isNotEmpty) medico].where((parte) => parte.isNotEmpty).join(' · '),
                            style: const TextStyle(color: gris, fontSize: 13),
                          ),
                        ],
                        if (cita.motivo.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(cita.motivo, style: const TextStyle(color: gris, fontSize: 13)),
                        ],
                        if (sede.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(sede, style: const TextStyle(color: suave, fontSize: 12)),
                        ],
                        if (cita.pacienteNuevo)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text('Derechohabiente nuevo', style: TextStyle(color: acero, fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (onMeet != null || onCat != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (onMeet != null)
                      BotonPastilla(
                        texto: 'Videollamada',
                        icono: Icons.videocam_outlined,
                        onPressed: onMeet,
                        fondo: Color(meetListo ? 0x240FA7E2 : 0x0F0FA7E2),
                        borde: const Color(0x4D0FA7E2),
                        color: cian,
                      ),
                    if (onCat != null)
                      BotonPastilla(
                        texto: 'Llamar a CAT',
                        icono: Icons.call_outlined,
                        onPressed: onCat,
                        fondo: const Color(0x0F4C5593),
                        borde: const Color(0x4D4C5593),
                        color: indigo,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class PacienteTarjeta extends StatelessWidget {
  const PacienteTarjeta({
    super.key,
    required this.paciente,
    required this.citas,
    required this.onTap,
    this.gradiente = gradientePaciente,
  });

  final Paciente paciente;
  final List<Cita> citas;
  final VoidCallback onTap;
  final Gradient gradiente;

  @override
  Widget build(BuildContext context) {
    final marca = marcaDePaciente(citas);
    final visita = ultimaVisitaDe(citas);
    final correo = paciente.correo.isEmpty ? paciente.telefono : paciente.correo;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: tarjeta(),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AvatarIniciales(iniciales: inicialesDe(paciente.nombre, paciente.apellido), gradiente: gradiente),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(paciente.nombreCompleto, style: const TextStyle(color: texto, fontWeight: FontWeight.w700, fontSize: 16))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: marca.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                          child: Text(marca.texto, style: TextStyle(color: marca.color, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    if (correo.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(correo, style: const TextStyle(color: gris, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      ['Exp: ${paciente.id}', visita].where((parte) => parte.isNotEmpty).join('  •  '),
                      style: const TextStyle(color: suave, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AvisoVacio extends StatelessWidget {
  const AvisoVacio({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: linea),
      ),
      child: Text(texto, style: const TextStyle(color: suave, height: 1.4)),
    );
  }
}

class DatoFila extends StatelessWidget {
  const DatoFila({super.key, required this.etiqueta, required this.valor, this.onTap});

  final String etiqueta;
  final String valor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (valor.trim().isEmpty) return const SizedBox.shrink();
    final fila = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 132, child: Text(etiqueta, style: const TextStyle(color: suave, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.3))),
          Expanded(child: Text(valor, style: TextStyle(color: onTap == null ? texto : azul, fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (onTap == null) return fila;
    return InkWell(onTap: onTap, child: fila);
  }
}

class FichaBloque extends StatelessWidget {
  const FichaBloque({super.key, required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: tarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(color: azul, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
