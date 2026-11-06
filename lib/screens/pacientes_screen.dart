import 'package:flutter/material.dart';

import '../state/consultorio_store.dart';
import '../theme/sisco_theme.dart';
import '../widgets/comun.dart';
import 'expediente_screen.dart';

class PacientesScreen extends StatefulWidget {
  const PacientesScreen({super.key});

  @override
  State<PacientesScreen> createState() => _PacientesScreenState();
}

class _PacientesScreenState extends State<PacientesScreen> {
  final _busqueda = TextEditingController();

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ConsultorioScope.of(context);
    final pacientes = store.buscarPacientes(_busqueda.text);

    return RefreshIndicator(
      color: azul,
      onRefresh: store.cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Row(
            children: [
              const Expanded(child: Text('Expedientes', style: TextStyle(color: marino, fontSize: 22, fontWeight: FontWeight.w800))),
              Text('${store.pacientes.length} Registros', style: const TextStyle(color: suave, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _busqueda,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'Buscar por nombre o correo...', prefixIcon: Icon(Icons.search)),
          ),
          const SizedBox(height: 12),
          if (store.cargando && store.pacientes.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 28), child: Center(child: CircularProgressIndicator()))
          else if (pacientes.isEmpty)
            const AvisoVacio(texto: 'No hay expedientes con ese criterio.')
          else
            for (final paciente in pacientes)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PacienteTarjeta(
                  paciente: paciente,
                  citas: store.citasDe(paciente.id),
                  gradiente: gradienteDoctor,
                  onTap: () => abrirExpediente(context, paciente.id),
                ),
              ),
        ],
      ),
    );
  }
}
