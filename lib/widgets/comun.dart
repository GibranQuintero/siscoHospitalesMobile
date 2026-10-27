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
      return azul;
    case 'en_consulta':
      return const Color(0xFF0F766E);
    case 'terminada':
      return const Color(0xFF3F7D1E);
    case 'cancelada':
      return suave;
    case 'inasistencia':
      return const Color(0xFFB45309);
    default:
      return const Color(0xFF9A6700);
  }
}

class CitaTarjeta extends StatelessWidget {
  const CitaTarjeta({super.key, required this.cita, required this.paciente, this.onTap, this.onMeet, this.onCat, this.meetListo = false});

  final Cita cita;
  final String paciente;
  final VoidCallback? onTap;
  final VoidCallback? onMeet;
  final VoidCallback? onCat;
  final bool meetListo;

  @override
  Widget build(BuildContext context) {
    final inicio = cita.inicio;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          decoration: tarjeta(),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 52,
                child: Text(
                  inicio == null ? '--:--' : horaDe(inicio),
                  style: const TextStyle(color: marino, fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(paciente, style: const TextStyle(color: texto, fontWeight: FontWeight.w700, fontSize: 16)),
                    if (cita.motivo.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(cita.motivo, style: const TextStyle(color: suave, fontSize: 13)),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        EstadoChip(estado: cita.estado),
                        if (cita.pacienteNuevo) const Text('Nuevo', style: TextStyle(color: acero, fontSize: 12, fontWeight: FontWeight.w700)),
                        if (cita.videollamada) const Icon(Icons.videocam_outlined, size: 16, color: acero),
                        if (cita.clinica.isNotEmpty) Text(cita.clinica, style: const TextStyle(color: suave, fontSize: 12)),
                      ],
                    ),
                    if (onMeet != null || onCat != null)
                      Row(
                        children: [
                          if (onMeet != null)
                            TextButton.icon(
                              onPressed: onMeet,
                              icon: const Icon(Icons.videocam_outlined, size: 18),
                              label: Text(meetListo ? 'Entrar a Meet' : 'Crear Meet'),
                            ),
                          if (onCat != null)
                            TextButton.icon(
                              onPressed: onCat,
                              icon: const Icon(Icons.call_outlined, size: 18),
                              label: const Text('Llamar a CAT'),
                            ),
                        ],
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
        color: const Color(0xFFFBFCFd),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: linea, style: BorderStyle.solid),
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
          SizedBox(width: 110, child: Text(etiqueta, style: const TextStyle(color: suave, fontSize: 13))),
          Expanded(child: Text(valor, style: TextStyle(color: onTap == null ? texto : azul, fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (onTap == null) return fila;
    return InkWell(onTap: onTap, child: fila);
  }
}
