import 'package:flutter/material.dart';

import '../state/consultorio_store.dart';
import '../theme/sisco_theme.dart';

class ModulosScreen extends StatelessWidget {
  const ModulosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ConsultorioScope.of(context);
    final nombre = store.sesion?.nombre ?? '';

    return Scaffold(
      backgroundColor: fondo,
      appBar: AppBar(
        title: const Text('SISCO Hospitales'),
        actions: [
          IconButton(
            tooltip: 'Salir',
            onPressed: () {
              store.salir();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          const Text('Elige un módulo', style: TextStyle(color: marino, fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            nombre.isEmpty ? 'Cada perfil ve su propio flujo.' : '$nombre, elige cómo vas a entrar.',
            style: const TextStyle(color: suave, height: 1.35),
          ),
          const SizedBox(height: 20),
          _ModuloTarjeta(
            icono: Icons.person_outline,
            titulo: 'Pacientes',
            detalle: 'Citas programadas, Meet, llamada a CAT y tu expediente.',
            onTap: () => store.elegirModulo(ModuloApp.paciente),
          ),
          _ModuloTarjeta(
            icono: Icons.medical_services_outlined,
            titulo: 'Doctores',
            detalle: 'Agenda del día, expedientes y la consulta en curso.',
            onTap: () => store.elegirModulo(ModuloApp.doctor),
          ),
          _ModuloTarjeta(
            icono: Icons.admin_panel_settings_outlined,
            titulo: 'Administración',
            detalle: 'Médicos, red hospitalaria y el panorama del consultorio.',
            onTap: () => store.elegirModulo(ModuloApp.admin),
          ),
        ],
      ),
    );
  }
}

class _ModuloTarjeta extends StatelessWidget {
  const _ModuloTarjeta({required this.icono, required this.titulo, required this.detalle, required this.onTap});

  final IconData icono;
  final String titulo;
  final String detalle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            decoration: tarjeta(),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: tinte, foregroundColor: azul, child: Icon(icono)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, style: const TextStyle(color: marino, fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(detalle, style: const TextStyle(color: suave, height: 1.35)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: acero),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
