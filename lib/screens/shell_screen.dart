import 'package:flutter/material.dart';

import '../state/consultorio_store.dart';
import '../theme/sisco_theme.dart';
import 'admin_inicio_screen.dart';
import 'agenda_screen.dart';
import 'farmacia_screen.dart';
import 'hospitales_screen.dart';
import 'inicio_screen.dart';
import 'laboratorio_screen.dart';
import 'medicos_screen.dart';
import 'paciente_home_screen.dart';
import 'pacientes_screen.dart';
import 'recepcion_inicio_screen.dart';
import 'recepcion_llegadas_screen.dart';

class _BarraUnica extends StatelessWidget {
  const _BarraUnica({required this.destino});

  final NavigationDestination destino;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xF2FFFFFF),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconTheme(data: const IconThemeData(color: azul, size: 24), child: destino.selectedIcon ?? destino.icon),
              const SizedBox(height: 4),
              Text(destino.label, style: const TextStyle(color: azul, fontSize: 11, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

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
      appBar: BarraGradiente(
        titulo: tituloModulo(modulo),
        actions: [
          BotonEncabezado(
            tooltip: 'Propiedades',
            icono: Icons.grid_view_rounded,
            onPressed: store.quitarModulo,
          ),
          if (!store.demostracion)
            BotonEncabezado(
              tooltip: 'Recargar',
              icono: Icons.refresh,
              onPressed: store.cargando ? null : () => store.cargar(),
            ),
          BotonEncabezado(
            tooltip: 'Salir',
            icono: Icons.logout,
            onPressed: store.salir,
          ),
        ],
      ),
      body: Column(
        children: [
          if (store.cargando) const LinearProgressIndicator(minHeight: 2, color: cian, backgroundColor: encabezado),
          Expanded(child: IndexedStack(index: indice, children: pantallas)),
        ],
      ),
      bottomNavigationBar: destinos.length < 2
          ? _BarraUnica(destino: destinos.first)
          : NavigationBar(
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
        return [
          InicioScreen(onVerAgenda: () => setState(() => _indice = 1)),
          const AgendaScreen(),
          const PacientesScreen(),
        ];
      case ModuloApp.recepcion:
        return [
          RecepcionInicioScreen(onVerLlegadas: () => setState(() => _indice = 1)),
          const RecepcionLlegadasScreen(),
        ];
      case ModuloApp.admin:
        return [
          AdminInicioScreen(
            onMedicos: () => setState(() => _indice = 1),
            onHospitales: () => setState(() => _indice = 2),
          ),
          const MedicosScreen(),
          const HospitalesScreen(),
        ];
      case ModuloApp.farmacia:
        return const [FarmaciaScreen()];
      case ModuloApp.laboratorio:
        return const [LaboratorioScreen()];
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
      case ModuloApp.recepcion:
        return const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.how_to_reg_outlined), selectedIcon: Icon(Icons.how_to_reg), label: 'Llegadas'),
        ];
      case ModuloApp.admin:
        return const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Resumen'),
          NavigationDestination(icon: Icon(Icons.medical_services_outlined), selectedIcon: Icon(Icons.medical_services), label: 'Médicos'),
          NavigationDestination(icon: Icon(Icons.local_hospital_outlined), selectedIcon: Icon(Icons.local_hospital), label: 'Hospitales'),
        ];
      case ModuloApp.farmacia:
        return const [
          NavigationDestination(icon: Icon(Icons.medication_outlined), selectedIcon: Icon(Icons.medication), label: 'Recetas'),
        ];
      case ModuloApp.laboratorio:
        return const [
          NavigationDestination(icon: Icon(Icons.biotech_outlined), selectedIcon: Icon(Icons.biotech), label: 'Órdenes'),
        ];
    }
  }
}
