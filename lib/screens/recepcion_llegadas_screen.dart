import 'package:flutter/material.dart';

import '../formato.dart';
import '../models/consultorio.dart';
import '../state/consultorio_store.dart';
import '../theme/sisco_theme.dart';
import '../widgets/comun.dart';

class RecepcionLlegadasScreen extends StatelessWidget {
  const RecepcionLlegadasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ConsultorioScope.of(context);
    final hoy = DateTime.now();
    final citas = store.citasDelDia(hoy);

    return RefreshIndicator(
      color: azul,
      onRefresh: store.cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const Text('Llegadas', style: TextStyle(color: marino, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            citas.isEmpty ? 'Hoy no hay citas en la agenda' : '${citas.length} citas hoy · ${fechaTitulo(hoy)}',
            style: const TextStyle(color: suave),
          ),
          const SizedBox(height: 14),
          if (store.cargando && citas.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 28), child: Center(child: CircularProgressIndicator()))
          else if (citas.isEmpty)
            const AvisoVacio(texto: 'Cuando haya citas para hoy, aquí se confirman y se registra la llegada.')
          else
            for (final cita in citas)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: LlegadaTarjeta(cita: cita, paciente: store.porId(cita.pacienteId)),
              ),
        ],
      ),
    );
  }
}

class LlegadaTarjeta extends StatelessWidget {
  const LlegadaTarjeta({super.key, required this.cita, required this.paciente});

  final Cita cita;
  final Paciente? paciente;

  @override
  Widget build(BuildContext context) {
    final inicio = cita.inicio;
    final nombre = paciente?.nombreCompleto ?? 'Paciente';
    final accion = accionRecepcion(cita.estado);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => mostrarFichaRecepcion(context, cita, paciente),
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
                            Expanded(child: Text(nombre, style: const TextStyle(color: texto, fontWeight: FontWeight.w700, fontSize: 16))),
                            EstadoChip(estado: cita.estado),
                          ],
                        ),
                        if (cita.motivo.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(cita.motivo, style: const TextStyle(color: gris, fontSize: 13)),
                        ],
                        if (cita.clinica.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(cita.clinica, style: const TextStyle(color: suave, fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (accion != null) ...[
                const SizedBox(height: 12),
                BotonPastilla(
                  texto: accion,
                  icono: cita.estado == 'confirmada' ? Icons.how_to_reg_outlined : Icons.event_available_outlined,
                  onPressed: () => aplicarPasoRecepcion(context, cita),
                  fondo: const Color(0x1A0F766E),
                  borde: const Color(0x4D0F766E),
                  color: const Color(0xFF0F766E),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

void aplicarPasoRecepcion(BuildContext context, Cita cita) {
  final accion = accionRecepcion(cita.estado);
  if (accion == null) return;
  ConsultorioScope.of(context).registrarPasoRecepcion(cita.id);
  final mensaje = cita.estado == 'no_confirmada' ? 'Cita confirmada' : 'Llegada registrada. El paciente pasa con el doctor.';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
}

void mostrarFichaRecepcion(BuildContext context, Cita cita, Paciente? paciente) {
  final anfitrion = context;
  final nombre = paciente?.nombreCompleto ?? 'Paciente';
  final alergias = paciente == null
      ? ''
      : paciente.alergias.isEmpty
          ? 'Sin alergias registradas'
          : paciente.alergias.join(', ');
  final accion = accionRecepcion(cita.estado);
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: fondo,
    showDragHandle: true,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AvatarIniciales(
                  iniciales: inicialesDe(paciente?.nombre ?? nombre, paciente?.apellido ?? ''),
                  gradiente: gradienteRecepcion,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nombre, style: const TextStyle(color: texto, fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      EstadoChip(estado: cita.estado),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DatoFila(etiqueta: 'MOTIVO', valor: cita.motivo),
            DatoFila(etiqueta: 'HORA', valor: cita.inicio == null ? '' : horaDe(cita.inicio!)),
            DatoFila(etiqueta: 'SEDE', valor: cita.clinica),
            DatoFila(etiqueta: 'FOLIO', valor: cita.folio),
            DatoFila(etiqueta: 'TELÉFONO', valor: paciente?.telefono ?? ''),
            DatoFila(etiqueta: 'ALERGIAS', valor: alergias),
            if (accion != null) ...[
              const SizedBox(height: 8),
              BotonPastilla(
                texto: accion,
                icono: cita.estado == 'confirmada' ? Icons.how_to_reg_outlined : Icons.event_available_outlined,
                expandir: true,
                onPressed: () {
                  Navigator.pop(context);
                  aplicarPasoRecepcion(anfitrion, cita);
                },
                fondo: const Color(0x1A0F766E),
                borde: const Color(0x4D0F766E),
                color: const Color(0xFF0F766E),
              ),
            ],
          ],
        ),
      );
    },
  );
}
