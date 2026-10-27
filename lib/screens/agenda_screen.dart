import 'package:flutter/material.dart';

import '../acciones_cita.dart';
import '../formato.dart';
import '../models/consultorio.dart';
import '../state/consultorio_store.dart';
import '../theme/sisco_theme.dart';
import '../widgets/comun.dart';
import 'expediente_screen.dart';

class AgendaScreen extends StatelessWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ConsultorioScope.of(context);
    final hoy = DateTime.now();
    final grupos = <String, List<Cita>>{};
    final citas = store.citas.where((cita) => cita.inicio != null && cita.estado != 'cancelada').toList()
      ..sort((a, b) => a.inicio!.compareTo(b.inicio!));
    for (final cita in citas) {
      final dia = cita.inicio!;
      final clave = '${dia.year}-${dia.month}-${dia.day}';
      grupos.putIfAbsent(clave, () => []).add(cita);
    }

    return RefreshIndicator(
      color: azul,
      onRefresh: store.cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Text('Agenda', style: TextStyle(color: marino, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('${citas.length} citas activas', style: const TextStyle(color: suave)),
          const SizedBox(height: 14),
          if (store.cargando && citas.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 28), child: Center(child: CircularProgressIndicator()))
          else if (grupos.isEmpty)
            const AvisoVacio(texto: 'La agenda no tiene citas activas.')
          else
            for (final entrada in grupos.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 8),
                child: Text(etiquetaDia(entrada.value.first.inicio!, hoy), style: const TextStyle(color: acero, fontWeight: FontWeight.w800)),
              ),
              for (final cita in entrada.value)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CitaTarjeta(
                    cita: cita,
                    paciente: store.nombrePaciente(cita.pacienteId),
                    meetListo: store.enlaceMeet(cita).isNotEmpty,
                    onTap: () => abrirExpediente(context, cita.pacienteId),
                    onMeet: () => crearOAbrirMeet(context, cita),
                    onCat: () => llamarACat(context),
                  ),
                ),
            ],
        ],
      ),
    );
  }
}
