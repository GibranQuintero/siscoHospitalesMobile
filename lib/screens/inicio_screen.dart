import 'package:flutter/material.dart';

import '../acciones_cita.dart';
import '../formato.dart';
import '../state/consultorio_store.dart';
import '../theme/sisco_theme.dart';
import '../widgets/comun.dart';
import 'expediente_screen.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

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

    return RefreshIndicator(
      color: azul,
      onRefresh: store.cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _Encabezado(store: store, hoy: hoy),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => llamarACat(context),
            icon: const Icon(Icons.call_outlined),
            label: const Text('Llamar a CAT'),
          ),
          const SizedBox(height: 12),
          if (store.error != null) ...[
            _ErrorApi(mensaje: store.error!, origen: store.origen),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _busqueda,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Buscar paciente, CURP o alergia',
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
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PacienteFila(nombre: paciente.nombreCompleto, detalle: paciente.curp.isEmpty ? paciente.telefono : paciente.curp, onTap: () => abrirExpediente(context, paciente.id)),
                ),
          ] else ...[
            _Resumen(store: store, hoy: hoy),
            const SizedBox(height: 16),
            const Text('Citas de hoy', style: TextStyle(color: marino, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if (store.cargando && store.citas.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 28), child: Center(child: CircularProgressIndicator()))
            else if (citas.isEmpty)
              const AvisoVacio(texto: 'No hay citas para hoy.')
            else
              for (final cita in citas)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
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
                  child: _PacienteFila(
                    nombre: store.nombrePaciente(aviso.pacienteId),
                    detalle: aviso.texto,
                    onTap: () => abrirExpediente(context, aviso.pacienteId),
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.store, required this.hoy});

  final ConsultorioStore store;
  final DateTime hoy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: marino, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SISCO HOSPITALES', style: TextStyle(color: cian, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
          const SizedBox(height: 4),
          Text(store.titulo, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          if (store.subtitulo.isNotEmpty)
            Text(store.subtitulo, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(fechaLarga(hoy), style: const TextStyle(color: Colors.white70)),
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
      ('confirmada', 'Confirmadas'),
      ('no_confirmada', 'Por confirmar'),
      ('en_consulta', 'En consulta'),
      ('terminada', 'Terminadas'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.5,
      children: [
        for (final estado in estados)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: tarjeta(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${store.contarEstado(hoy, estado.$1)}', style: const TextStyle(color: marino, fontSize: 20, fontWeight: FontWeight.w800)),
                Text(estado.$2, style: const TextStyle(color: suave, fontSize: 12)),
              ],
            ),
          ),
      ],
    );
  }
}

class _PacienteFila extends StatelessWidget {
  const _PacienteFila({required this.nombre, required this.detalle, required this.onTap});

  final String nombre;
  final String detalle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          decoration: tarjeta(),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nombre, style: const TextStyle(fontWeight: FontWeight.w700, color: texto)),
              if (detalle.isNotEmpty) Text(detalle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: suave, fontSize: 13)),
            ],
          ),
        ),
      ),
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
      decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFED7AA))),
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
