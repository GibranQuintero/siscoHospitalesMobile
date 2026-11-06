import 'package:flutter/material.dart';

import '../formato.dart';
import '../state/consultorio_store.dart';
import '../theme/sisco_theme.dart';
import '../widgets/comun.dart';
import 'recepcion_llegadas_screen.dart';

class RecepcionInicioScreen extends StatelessWidget {
  const RecepcionInicioScreen({super.key, this.onVerLlegadas});

  final VoidCallback? onVerLlegadas;

  @override
  Widget build(BuildContext context) {
    final store = ConsultorioScope.of(context);
    final hoy = DateTime.now();
    final delDia = store.citasDelDia(hoy);
    final pendientes = delDia.where((cita) => accionRecepcion(cita.estado) != null).toList();
    final sede = store.clinica.isNotEmpty ? store.clinica : store.titulo;

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
                const Text('SISCO', style: TextStyle(color: Color(0xFF0F766E), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                const Text('Recepción', style: TextStyle(color: texto, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(fechaTitulo(hoy), style: const TextStyle(color: Color(0xFF767779), fontWeight: FontWeight.w500)),
                if (sede.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(sede, style: const TextStyle(color: suave, fontSize: 13)),
                ],
              ],
            ),
          ),
          if (store.error != null) ...[
            const SizedBox(height: 12),
            Text(store.error!, style: const TextStyle(color: aviso)),
          ],
          const SizedBox(height: 16),
          _Conteos(store: store, hoy: hoy),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text('POR ATENDER', style: TextStyle(color: suave, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
              ),
              TextButton(onPressed: onVerLlegadas, child: const Text('Ver el día')),
            ],
          ),
          if (pendientes.isEmpty)
            const AvisoVacio(texto: 'No hay pacientes por recibir. Las llegadas de hoy aparecen en la agenda.')
          else
            for (final cita in pendientes)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: LlegadaTarjeta(cita: cita, paciente: store.porId(cita.pacienteId)),
              ),
        ],
      ),
    );
  }
}

class _Conteos extends StatelessWidget {
  const _Conteos({required this.store, required this.hoy});

  final ConsultorioStore store;
  final DateTime hoy;

  @override
  Widget build(BuildContext context) {
    const estados = [
      ('no_confirmada', 'Por confirmar', Color(0xFFFFFBEB), aviso),
      ('confirmada', 'Por llegar', Color(0x1A0F766E), Color(0xFF0F766E)),
      ('en_consulta', 'En consulta', tinte, azul),
      ('terminada', 'Atendidas', Color(0x1C10B981), exito),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.7,
      children: [
        for (final estado in estados)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: tarjeta(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      '${store.contarEstado(hoy, estado.$1)}',
                      style: TextStyle(color: estado.$4, fontSize: 30, fontWeight: FontWeight.w800, height: 1),
                    ),
                    const Spacer(),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(color: estado.$3, shape: BoxShape.circle, border: Border.all(color: estado.$4.withValues(alpha: 0.35))),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(estado.$2, style: const TextStyle(color: suave, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
      ],
    );
  }
}
