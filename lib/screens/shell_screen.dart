import 'package:flutter/material.dart';

import '../state/consultorio_store.dart';
import '../theme/sisco_theme.dart';
import 'admin_inicio_screen.dart';
import 'agenda_screen.dart';
import 'ajustes_screen.dart';
import 'hospitales_screen.dart';
import 'inicio_screen.dart';
import 'medicos_screen.dart';
import 'paciente_home_screen.dart';
import 'pacientes_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  var _indice = 0;

  @override
  Widget build(BuildContext context) {
    final store = ConsultorioScope.of(context);
    final modulo = store.modulo ?? ModuloApp.doctor;
    final pantallas = _pantallas(modulo);
    final destinos = _destinos(modulo);
    final indice = _indice.clamp(0, pantallas.length - 1);

    return Scaffold(
      appBar: AppBar(
        title: Text(tituloModulo(modulo)),
        actions: [
          IconButton(
            tooltip: 'Cambiar módulo',
            onPressed: store.quitarModulo,
            icon: const Icon(Icons.apps),
          ),
          IconButton(
            tooltip: 'Recargar',
            onPressed: store.cargando ? null : () => store.cargar(),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Conexión',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AjustesScreen()));
            },
            icon: const Icon(Icons.tune),
          ),
          IconButton(
            tooltip: 'Salir',
            onPressed: () {
              store.salir();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          if (store.cargando) const LinearProgressIndicator(minHeight: 2, color: cian, backgroundColor: marino),
          Expanded(child: IndexedStack(index: indice, children: pantallas)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: indice,
        onDestinationSelected: (valor) => setState(() => _indice = valor),
        destinations: destinos,
      ),
    );
  }

  List<Widget> _pantallas(ModuloApp modulo) {
    switch (modulo) {
      case ModuloApp.paciente:
        return const [PacienteHomeScreen()];
      case ModuloApp.doctor:
        return const [InicioScreen(), AgendaScreen(), PacientesScreen()];
      case ModuloApp.admin:
        return const [AdminInicioScreen(), MedicosScreen(), HospitalesScreen()];
    }
  }

  List<NavigationDestination> _destinos(ModuloApp modulo) {
    switch (modulo) {
      case ModuloApp.paciente:
        return const [
          NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note), label: 'Mis citas'),
        ];
      case ModuloApp.doctor:
        return const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Agenda'),
          NavigationDestination(icon: Icon(Icons.folder_shared_outlined), selectedIcon: Icon(Icons.folder_shared), label: 'Expedientes'),
        ];
      case ModuloApp.admin:
        return const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Resumen'),
          NavigationDestination(icon: Icon(Icons.medical_services_outlined), selectedIcon: Icon(Icons.medical_services), label: 'Médicos'),
          NavigationDestination(icon: Icon(Icons.local_hospital_outlined), selectedIcon: Icon(Icons.local_hospital), label: 'Hospitales'),
        ];
    }
  }
}
