import 'package:flutter/material.dart';

import '../enlaces.dart';
import '../state/consultorio_store.dart';
import '../theme/sisco_theme.dart';
import '../widgets/comun.dart';

class MedicosScreen extends StatelessWidget {
  const MedicosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ConsultorioScope.of(context);

    return RefreshIndicator(
      color: azul,
      onRefresh: store.cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Text('Médicos', style: TextStyle(color: marino, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('${store.medicos.length} en la red', style: const TextStyle(color: suave)),
          const SizedBox(height: 12),
          if (store.medicos.isEmpty)
            const AvisoVacio(texto: 'No hay médicos cargados.')
          else
            for (final medico in store.medicos)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: tarjeta(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(medico.nombreCompleto, style: const TextStyle(color: texto, fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                        medico.esEspecialista && medico.especialidad.isNotEmpty ? medico.especialidad : 'Médico general',
                        style: const TextStyle(color: acero, fontWeight: FontWeight.w700),
                      ),
                      if (medico.cedula.isNotEmpty) Text('Cédula ${medico.cedula}', style: const TextStyle(color: suave)),
                      if (medico.estatus.isNotEmpty) Text(medico.estatus, style: const TextStyle(color: suave)),
                      if (medico.telefono.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => abrirSiPuede(context, enlaceTelefono(medico.telefono)),
                          icon: const Icon(Icons.call_outlined, size: 18),
                          label: Text(medico.telefono),
                        ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
