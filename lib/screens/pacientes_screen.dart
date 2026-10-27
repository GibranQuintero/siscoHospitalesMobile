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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Text('Expedientes', style: TextStyle(color: marino, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('${store.pacientes.length} pacientes', style: const TextStyle(color: suave)),
          const SizedBox(height: 12),
          TextField(
            controller: _busqueda,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'Nombre, CURP o teléfono', prefixIcon: Icon(Icons.search)),
          ),
          const SizedBox(height: 12),
          if (store.cargando && store.pacientes.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 28), child: Center(child: CircularProgressIndicator()))
          else if (pacientes.isEmpty)
            const AvisoVacio(texto: 'No hay expedientes con ese criterio.')
          else
            for (final paciente in pacientes)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => abrirExpediente(context, paciente.id),
                    child: Ink(
                      decoration: tarjeta(),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: tinte,
                            foregroundColor: azul,
                            child: Text(_iniciales(paciente.nombre, paciente.apellido), style: const TextStyle(fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(paciente.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w700, color: texto)),
                                Text(
                                  [paciente.telefono, paciente.curp].where((parte) => parte.isNotEmpty).join(' · '),
                                  style: const TextStyle(color: suave, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: suave),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

String _iniciales(String nombre, String apellido) {
  final a = nombre.trim().isEmpty ? '' : nombre.trim()[0];
  final b = apellido.trim().isEmpty ? '' : apellido.trim()[0];
  final juntas = (a + b).toUpperCase();
  return juntas.isEmpty ? '?' : juntas;
}
