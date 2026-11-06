import 'package:flutter/material.dart';

import '../acciones_cita.dart';
import '../formato.dart';
import '../state/consultorio_store.dart';
import '../theme/sisco_theme.dart';
import '../widgets/comun.dart';
import 'expediente_screen.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key, this.onVerAgenda});

  final VoidCallback? onVerAgenda;

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  final _busqueda = TextEditingController();

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ConsultorioScope.of(context);
    final hoy = DateTime.now();
    final citas = store.citasDelDia(hoy);
    final consulta = _busqueda.text.trim();
    final resultados = consulta.isEmpty ? const [] : store.buscarPacientes(consulta);
    final sede = store.clinica.isNotEmpty ? store.clinica : store.titulo;

    return RefreshIndicator(
      color: azul,
      onRefresh: store.cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          _TarjetaInstitucional(sede: sede, fecha: fechaTitulo(hoy), onCat: () => llamarACat(context)),
          const SizedBox(height: 12),
          if (store.error != null) ...[
            _ErrorApi(mensaje: store.error!, origen: store.origen),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _busqueda,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Buscar paciente, CURP o alerta...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 14),
          if (consulta.isNotEmpty) ...[
            Text('${resultados.length} coincidencias', style: const TextStyle(color: suave, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (resultados.isEmpty)
              const AvisoVacio(texto: 'Ningún expediente coincide con esa búsqueda.')
            else
              for (final paciente in resultados.take(20))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PacienteTarjeta(
                    paciente: paciente,
                    citas: store.citasDe(paciente.id),
                    gradiente: gradienteDoctor,
                    onTap: () => abrirExpediente(context, paciente.id),
                  ),
                ),
          ] else ...[
            _Resumen(store: store, hoy: hoy),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(child: Text('Citas de hoy', style: TextStyle(color: marino, fontSize: 18, fontWeight: FontWeight.w800))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: tinte, borderRadius: BorderRadius.circular(999)),
                  child: Text('${citas.length} total', style: const TextStyle(color: azul, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
                if (widget.onVerAgenda != null)
                  TextButton(
                    onPressed: widget.onVerAgenda,
                    child: const Text('Ver todas'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (store.cargando && store.citas.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 28), child: Center(child: CircularProgressIndicator()))
            else if (citas.isEmpty)
              const AvisoVacio(texto: 'No hay citas para hoy.')
            else
              for (final cita in citas)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: CitaTarjeta(
                    cita: cita,
                    paciente: store.nombrePaciente(cita.pacienteId),
                    meetListo: store.enlaceMeet(cita).isNotEmpty,
                    onTap: () => abrirExpediente(context, cita.pacienteId),
                    onMeet: () => crearOAbrirMeet(context, cita),
                    onCat: () => llamarACat(context),
                  ),
                ),
            if (store.avisos.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Avisos', style: TextStyle(color: marino, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final aviso in store.avisos)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => abrirExpediente(context, aviso.pacienteId),
                      child: Ink(
                        decoration: tarjeta(),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(store.nombrePaciente(aviso.pacienteId), style: const TextStyle(fontWeight: FontWeight.w700, color: texto)),
                            const SizedBox(height: 4),
                            Text(aviso.texto, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: gris, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _TarjetaInstitucional extends StatelessWidget {
  const _TarjetaInstitucional({required this.sede, required this.fecha, required this.onCat});

  final String sede;
  final String fecha;
  final VoidCallback onCat;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: tarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(nombreAplicacion, style: TextStyle(color: texto, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF767779)),
              const SizedBox(width: 6),
              Expanded(child: Text(sede, style: const TextStyle(color: Color(0xFF767779), fontWeight: FontWeight.w500))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF767779)),
              const SizedBox(width: 6),
              Text(fecha, style: const TextStyle(color: Color(0xFF767779), fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 14),
          BotonPastilla(
            texto: 'Llamar a CAT (Soporte Directo)',
            icono: Icons.call_outlined,
            onPressed: onCat,
            expandir: true,
          ),
        ],
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.store, required this.hoy});

  final ConsultorioStore store;
  final DateTime hoy;

  @override
  Widget build(BuildContext context) {
    const estados = [
      ('confirmada', 'Confirmadas', Color(0x240FA7E2), cian),
      ('no_confirmada', 'Por confirmar', Color(0xFFFFFBEB), aviso),
      ('en_consulta', 'En consulta', tinte, azul),
      ('terminada', 'Terminadas', Color(0x1C10B981), exito),
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
                      style: TextStyle(color: estado.$1 == 'en_consulta' ? azul : marino, fontSize: 30, fontWeight: FontWeight.w800, height: 1),
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

class _ErrorApi extends StatelessWidget {
  const _ErrorApi({required this.mensaje, required this.origen});

  final String mensaje;
  final String origen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x94FBBF24))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(mensaje, style: const TextStyle(color: texto, height: 1.4)),
          if (origen.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(origen, style: const TextStyle(color: suave, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}
