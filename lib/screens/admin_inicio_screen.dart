import 'package:flutter/material.dart';

import '../formato.dart';
import '../state/consultorio_store.dart';
import '../theme/sisco_theme.dart';

class AdminInicioScreen extends StatelessWidget {
  const AdminInicioScreen({super.key, this.onMedicos, this.onHospitales});

  final VoidCallback? onMedicos;
  final VoidCallback? onHospitales;

  @override
  Widget build(BuildContext context) {
    final store = ConsultorioScope.of(context);
    final hoy = DateTime.now();
    final sedes = store.hospitales.map((hospital) => hospital.nombre).where((nombre) => nombre.isNotEmpty).take(3).join(', ');

    return RefreshIndicator(
      color: azul,
      onRefresh: store.cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: tarjeta(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SISCO', style: TextStyle(color: Color(0xFF0068A2), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                const Text('Hospitales', style: TextStyle(color: texto, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(fechaTitulo(hoy), style: const TextStyle(color: Color(0xFF767779), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (store.error != null) ...[
            const SizedBox(height: 12),
            Text(store.error!, style: const TextStyle(color: aviso)),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Conteo(numero: store.medicos.length, texto: 'Médicos', color: indigo),
              _Conteo(numero: store.hospitales.length, texto: 'Hospitales', color: cian),
              _Conteo(numero: store.pacientes.length, texto: 'Derechohabientes', color: azul),
              _Conteo(numero: store.citasDelDia(hoy).length, texto: 'Citas de hoy', color: exito),
            ],
          ),
          const SizedBox(height: 20),
          const Text('GESTIÓN', style: TextStyle(color: suave, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
          const SizedBox(height: 10),
          _Gestion(
            icono: Icons.local_hospital_outlined,
            gradiente: gradienteAdmin,
            titulo: 'Red Hospitalaria',
            detalle: sedes.isEmpty ? '${store.hospitales.length} sedes activas' : '${store.hospitales.length} sedes activas ($sedes)',
            onTap: onHospitales,
          ),
          _Gestion(
            icono: Icons.medical_services_outlined,
            gradiente: gradienteDoctor,
            titulo: 'Directorio Médico y Tarifas',
            detalle: 'Convenios de especialistas',
            onTap: onMedicos,
          ),
          _Gestion(
            icono: Icons.person_add_alt_1_outlined,
            gradiente: gradientePaciente,
            titulo: 'Alta de nuevo médico o sede',
            detalle: 'El alta se registra en el consultorio de escritorio.',
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Alta de nuevo médico o sede'),
                  content: const Text('Esa captura se hace en el consultorio de escritorio. Aquí puedes consultar el directorio y la red.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Conteo extends StatelessWidget {
  const _Conteo({required this.numero, required this.texto, required this.color});

  final int numero;
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 156,
      padding: const EdgeInsets.all(14),
      decoration: tarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$numero', style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.w800)),
          Text(texto, style: const TextStyle(color: suave)),
        ],
      ),
    );
  }
}

class _Gestion extends StatelessWidget {
  const _Gestion({
    required this.icono,
    required this.gradiente,
    required this.titulo,
    required this.detalle,
    required this.onTap,
  });

  final IconData icono;
  final Gradient gradiente;
  final String titulo;
  final String detalle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            decoration: tarjeta(),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(gradient: gradiente, shape: BoxShape.circle),
                  child: Icon(icono, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, style: const TextStyle(color: texto, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(detalle, style: const TextStyle(color: suave, fontSize: 13)),
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
