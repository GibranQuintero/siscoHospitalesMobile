import 'package:flutter/material.dart';

import '../evidencia.dart';
import '../formato.dart';
import '../models/consultorio.dart';
import '../state/consultorio_store.dart';
import '../theme/sisco_theme.dart';
import '../widgets/comun.dart';

class LaboratorioScreen extends StatefulWidget {
  const LaboratorioScreen({super.key});

  @override
  State<LaboratorioScreen> createState() => _LaboratorioScreenState();
}

class _LaboratorioScreenState extends State<LaboratorioScreen> {
  var _filtro = 'abiertas';
  var _tipo = '';

  @override
  Widget build(BuildContext context) {
    final store = ConsultorioScope.of(context);
    final filas = _filas(store);

    return RefreshIndicator(
      color: azul,
      onRefresh: store.cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const Text('Órdenes', style: TextStyle(color: marino, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text(
            'Aprueba el estudio, escribe el resultado y sube la evidencia. Laboratorio usa folio LB y gabinete folio GB. El cambio queda en este teléfono.',
            style: TextStyle(color: suave, height: 1.35),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final opcion in const [('abiertas', 'Abiertas'), ('cerradas', 'Cerradas'), ('todas', 'Todas')])
                ChoiceChip(label: Text(opcion.$2), selected: _filtro == opcion.$1, onSelected: (_) => setState(() => _filtro = opcion.$1)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final opcion in const [('', 'Laboratorio y gabinete'), ('Laboratorio', 'Laboratorio'), ('Gabinete', 'Gabinete')])
                ChoiceChip(label: Text(opcion.$2), selected: _tipo == opcion.$1, onSelected: (_) => setState(() => _tipo = opcion.$1)),
            ],
          ),
          const SizedBox(height: 14),
          if (filas.isEmpty)
            const AvisoVacio(texto: 'No hay estudios en este filtro. Aparecen cuando el médico los solicita en la consulta.')
          else
            for (final fila in filas)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OrdenTarjeta(fila: fila),
              ),
        ],
      ),
    );
  }

  List<_FilaOrden> _filas(ConsultorioStore store) {
    final salida = <_FilaOrden>[];
    for (final consulta in store.consultas) {
      for (final orden in consulta.ordenes) {
        if (_tipo.isNotEmpty && orden.tipo != _tipo) continue;
        if (_filtro == 'abiertas' && orden.cerrada) continue;
        if (_filtro == 'cerradas' && !orden.cerrada) continue;
        salida.add(_FilaOrden(consultaId: consulta.id, paciente: store.nombrePaciente(consulta.pacienteId), orden: orden));
      }
    }
    return salida;
  }
}

class _FilaOrden {
  const _FilaOrden({required this.consultaId, required this.paciente, required this.orden});

  final String consultaId;
  final String paciente;
  final OrdenEstudio orden;
}

class _OrdenTarjeta extends StatelessWidget {
  const _OrdenTarjeta({required this.fila});

  final _FilaOrden fila;

  @override
  Widget build(BuildContext context) {
    final store = ConsultorioScope.of(context);
    final orden = fila.orden;
    final momento = fechaHora(orden.fechaResultado);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: tarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(orden.folio.isEmpty ? 'Sin folio' : 'Folio ${orden.folio}', style: const TextStyle(color: cian, fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(orden.tipo, style: const TextStyle(color: azul, fontWeight: FontWeight.w800, fontSize: 12)),
          const SizedBox(height: 2),
          Text(orden.concepto, style: const TextStyle(color: texto, fontSize: 16, fontWeight: FontWeight.w800)),
          Text(fila.paciente, style: const TextStyle(color: suave)),
          if (orden.indicacion.isNotEmpty) Text(orden.indicacion, style: const TextStyle(color: gris, fontSize: 13)),
          if (orden.lugar.isNotEmpty) Text(orden.lugar, style: const TextStyle(color: suave, fontSize: 13)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final opcion in const [
                ('pendiente', 'Pendiente'),
                ('recibida', 'Aprobada'),
                ('en_proceso', 'En proceso'),
                ('resultado', 'Con evidencia'),
                ('cancelada', 'Cancelada'),
              ])
                ChoiceChip(
                  label: Text(opcion.$2),
                  selected: orden.estatus == opcion.$1,
                  onSelected: (_) => store.actualizarOrden(fila.consultaId, orden.id, estatus: opcion.$1),
                ),
            ],
          ),
          if (orden.estatus == 'pendiente') ...[
            const SizedBox(height: 8),
            FilledButton(onPressed: () => store.aprobarOrden(fila.consultaId, orden.id), child: const Text('Aprobar')),
          ],
          if (momento != null) ...[
            const SizedBox(height: 8),
            Text('${fechaCorta(momento)} ${horaDe(momento)}', style: const TextStyle(color: suave, fontSize: 12)),
          ],
          const SizedBox(height: 10),
          _ResultadoCampo(
            inicial: orden.resultado,
            onGuardar: (texto) => store.guardarResultadoOrden(fila.consultaId, orden.id, texto),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final nombre = await pedirEvidencia(context);
              if (nombre == null) return;
              store.evidenciarOrden(fila.consultaId, orden.id, nombre);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Evidencia adjunta: $nombre')));
              }
            },
            icon: const Icon(Icons.attach_file),
            label: const Text('Subir evidencia'),
          ),
          if (orden.evidenciaNombre.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(orden.evidenciaNombre, style: const TextStyle(color: azul, fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }
}

class _ResultadoCampo extends StatefulWidget {
  const _ResultadoCampo({required this.inicial, required this.onGuardar});

  final String inicial;
  final ValueChanged<String> onGuardar;

  @override
  State<_ResultadoCampo> createState() => _ResultadoCampoState();
}

class _ResultadoCampoState extends State<_ResultadoCampo> {
  late final TextEditingController _controlador;

  @override
  void initState() {
    super.initState();
    _controlador = TextEditingController(text: widget.inicial);
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controlador,
      minLines: 2,
      maxLines: 4,
      decoration: const InputDecoration(hintText: 'Resultado o interpretación'),
      onEditingComplete: () => widget.onGuardar(_controlador.text),
      onTapOutside: (_) => widget.onGuardar(_controlador.text),
    );
  }
}
