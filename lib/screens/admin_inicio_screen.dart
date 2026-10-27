import 'package:flutter/material.dart';

import '../formato.dart';
import '../state/consultorio_store.dart';
import '../theme/sisco_theme.dart';

class AdminInicioScreen extends StatelessWidget {
  const AdminInicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ConsultorioScope.of(context);
    final hoy = DateTime.now();

    return RefreshIndicator(
      color: azul,
      onRefresh: store.cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(store.titulo, style: const TextStyle(color: marino, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(fechaLarga(hoy), style: const TextStyle(color: suave)),
          const SizedBox(height: 8),
          const Text(
            'Altas de médicos, red hospitalaria y el panorama de citas. Los costos y el convenio se ven en cada sede.',
            style: TextStyle(color: suave, height: 1.35),
          ),
          if (store.error != null) ...[
            const SizedBox(height: 12),
            Text(store.error!, style: const TextStyle(color: Color(0xFF8A4B08))),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Conteo(numero: store.medicos.length, texto: 'Médicos'),
              _Conteo(numero: store.hospitales.length, texto: 'Hospitales'),
              _Conteo(numero: store.pacientes.length, texto: 'Pacientes'),
              _Conteo(numero: store.citasDelDia(hoy).length, texto: 'Citas de hoy'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Conteo extends StatelessWidget {
  const _Conteo({required this.numero, required this.texto});

  final int numero;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 156,
      padding: const EdgeInsets.all(14),
      decoration: tarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$numero', style: const TextStyle(color: marino, fontSize: 28, fontWeight: FontWeight.w800)),
          Text(texto, style: const TextStyle(color: suave)),
        ],
      ),
    );
  }
}
