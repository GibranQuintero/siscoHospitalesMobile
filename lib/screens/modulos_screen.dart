import 'package:flutter/material.dart';

import '../state/consultorio_store.dart';
import '../theme/sisco_theme.dart';
import '../widgets/comun.dart';

class ModulosScreen extends StatelessWidget {
  const ModulosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ConsultorioScope.of(context);
    final nombre = store.sesion?.nombre ?? '';

    return Scaffold(
      backgroundColor: fondo,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 12, 12, 16),
            decoration: const BoxDecoration(gradient: gradienteEncabezado),
            child: Row(
              children: [
                const AvatarIniciales(iniciales: 'S', gradiente: gradientePaciente, tamano: 40),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(nombreAplicacion, maxLines: 2, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  tooltip: 'Salir',
                  onPressed: store.salir,
                  icon: const Icon(Icons.logout, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              children: [
                const Text('Elige un módulo', style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
                const SizedBox(height: 6),
                Text(
                  store.demostracion
                      ? 'Recorrido con datos de prueba. No se conecta a la base'
                      : nombre.isEmpty
                          ? 'Cada perfil ve su propio flujo.'
                          : '$nombre, elige cómo vas a entrar.',
                  style: const TextStyle(color: gris, fontSize: 16, height: 1.25),
                ),
                const SizedBox(height: 20),
                _ModuloTarjeta(
                  gradiente: gradientePaciente,
                  icono: Icons.person_outline,
                  titulo: 'Pacientes',
                  detalle: 'Citas programadas, Meet, llamada a CAT y tu expediente.',
                  onTap: () => store.elegirModulo(ModuloApp.paciente),
                ),
                _ModuloTarjeta(
                  gradiente: gradienteDoctor,
                  icono: Icons.medical_services_outlined,
                  titulo: 'Doctores',
                  detalle: 'Agenda del día, expedientes y la consulta en curso.',
                  onTap: () => store.elegirModulo(ModuloApp.doctor),
                ),
                _ModuloTarjeta(
                  gradiente: gradienteRecepcion,
                  icono: Icons.how_to_reg_outlined,
                  titulo: 'Recepción',
                  detalle: 'Agenda del día, llegadas y pase con el doctor.',
                  onTap: () => store.elegirModulo(ModuloApp.recepcion),
                ),
                _ModuloTarjeta(
                  gradiente: gradienteAdmin,
                  icono: Icons.admin_panel_settings_outlined,
                  titulo: 'Administración',
                  detalle: 'Médicos, red hospitalaria y el panorama del consultorio.',
                  onTap: () => store.elegirModulo(ModuloApp.admin),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuloTarjeta extends StatelessWidget {
  const _ModuloTarjeta({
    required this.gradiente,
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.onTap,
  });

  final Gradient gradiente;
  final IconData icono;
  final String titulo;
  final String detalle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            decoration: tarjeta(),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(gradient: gradiente, shape: BoxShape.circle),
                  child: Icon(icono, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, style: const TextStyle(color: texto, fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(detalle, style: const TextStyle(color: gris, fontSize: 12, height: 1.35)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: chevron),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
