import 'package:flutter/material.dart';

import '../acciones_cita.dart';
import '../formato.dart';
import '../state/consultorio_store.dart';
import '../theme/sisco_theme.dart';
import '../widgets/comun.dart';
import 'expediente_screen.dart';

class PacienteHomeScreen extends StatelessWidget {
  const PacienteHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ConsultorioScope.of(context);
    final paciente = store.pacienteActivo;

    return RefreshIndicator(
      color: azul,
      onRefresh: store.cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Text('Tu consultorio', style: TextStyle(color: marino, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Citas, videollamada y expediente.', style: TextStyle(color: suave)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => llamarACat(context),
            icon: const Icon(Icons.call_outlined),
            label: const Text('Llamar a CAT'),
          ),
          if (store.error != null) ...[
            const SizedBox(height: 12),
            Text(store.error!, style: const TextStyle(color: Color(0xFF8A4B08))),
          ],
          const SizedBox(height: 16),
          if (paciente == null) ...[
            const Text('Elige tu expediente', style: TextStyle(color: marino, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if (store.pacientes.isEmpty)
              const AvisoVacio(texto: 'Todavía no hay expedientes en el consultorio.')
            else
              for (final candidato in store.pacientes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: linea)),
                    tileColor: Colors.white,
                    title: Text(candidato.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(candidato.correo.isEmpty ? candidato.telefono : candidato.correo),
                    onTap: () => store.elegirPaciente(candidato.id),
                  ),
                ),
          ] else ...[
            Text(paciente.nombreCompleto, style: const TextStyle(color: marino, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => abrirExpediente(context, paciente.id),
              icon: const Icon(Icons.folder_shared_outlined),
              label: const Text('Ver mi expediente'),
            ),
            const SizedBox(height: 16),
            const Text('Mis citas', style: TextStyle(color: marino, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if (store.citasDe(paciente.id).isEmpty)
              const AvisoVacio(texto: 'No tienes citas registradas.')
            else
              for (final cita in store.citasDe(paciente.id))
                if (cita.estado != 'cancelada')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: CitaTarjeta(
                      cita: cita,
                      paciente: paciente.nombreCompleto,
                      meetListo: store.enlaceMeet(cita).isNotEmpty,
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
