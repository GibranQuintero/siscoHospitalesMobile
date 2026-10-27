import 'package:flutter/material.dart';

import '../state/consultorio_store.dart';
import '../theme/sisco_theme.dart';
import 'agenda_screen.dart';
import 'ajustes_screen.dart';
import 'hospitales_screen.dart';
import 'inicio_screen.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultorio'),
        actions: [
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
          Expanded(
            child: IndexedStack(
              index: _indice,
              children: const [
                InicioScreen(),
                AgendaScreen(),
                PacientesScreen(),
                HospitalesScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (indice) => setState(() => _indice = indice),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Agenda'),
          NavigationDestination(icon: Icon(Icons.folder_shared_outlined), selectedIcon: Icon(Icons.folder_shared), label: 'Pacientes'),
          NavigationDestination(icon: Icon(Icons.local_hospital_outlined), selectedIcon: Icon(Icons.local_hospital), label: 'Hospitales'),
        ],
      ),
    );
  }
}
