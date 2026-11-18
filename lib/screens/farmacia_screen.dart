import 'package:flutter/material.dart';

import '../evidencia.dart';
import '../formato.dart';
import '../models/consultorio.dart';
import '../state/consultorio_store.dart';
import '../theme/sisco_theme.dart';
import '../widgets/comun.dart';

class FarmaciaScreen extends StatefulWidget {
  const FarmaciaScreen({super.key});

  @override
  State<FarmaciaScreen> createState() => _FarmaciaScreenState();
}

class _FarmaciaScreenState extends State<FarmaciaScreen> {
  var _filtro = 'pendientes';
  var _abiertaId = '';

  @override
  Widget build(BuildContext context) {
    final store = ConsultorioScope.of(context);
    final recetas = _recetas(store);
    final abierta = _abierta(store);

    return RefreshIndicator(
      color: azul,
      onRefresh: store.cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          if (abierta == null) ...[
            const Text('Recetas', style: TextStyle(color: marino, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text(
              'Marca cada medicamento como surtido o no surtido y adjunta la evidencia. El cambio queda en este teléfono.',
              style: TextStyle(color: suave, height: 1.35),
            ),
            const SizedBox(height: 12),
            _Filtros(
              opciones: const [('pendientes', 'Pendientes'), ('cerradas', 'Cerradas'), ('todas', 'Todas')],
              activo: _filtro,
              onElegir: (valor) => setState(() => _filtro = valor),
            ),
            const SizedBox(height: 14),
            if (recetas.isEmpty)
              const AvisoVacio(texto: 'No hay recetas en este filtro. Aparecen cuando el médico guarda la receta en la consulta.')
            else
              for (final receta in recetas)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RecetaTarjeta(
                    paciente: store.nombrePaciente(receta.pacienteId),
                    folio: receta.folioReceta.isEmpty ? receta.id : receta.folioReceta,
                    resumen: _resumen(receta),
                    onAbrir: () => setState(() => _abiertaId = receta.id),
                  ),
                ),
          ] else
            _RecetaAbierta(
              consulta: abierta,
              paciente: store.nombrePaciente(abierta.pacienteId),
              onCerrar: () => setState(() => _abiertaId = ''),
            ),
        ],
      ),
    );
  }

  ConsultaClinica? _abierta(ConsultorioStore store) {
    if (_abiertaId.isEmpty) return null;
    for (final consulta in store.consultas) {
      if (consulta.id == _abiertaId) return consulta;
    }
    return null;
  }

  List<ConsultaClinica> _recetas(ConsultorioStore store) {
    return store.consultas.where((consulta) {
      if (consulta.medicamentos.isEmpty) return false;
      if (_filtro == 'pendientes') return !consulta.recetaCerrada;
      if (_filtro == 'cerradas') return consulta.recetaCerrada;
      return true;
    }).toList();
  }

  String _resumen(ConsultaClinica receta) {
    final surtidos = receta.medicamentos.where((linea) => linea.estatusEntrega == 'surtido' || linea.estatusEntrega == 'entregado').length;
    final noSurtidos = receta.medicamentos.where((linea) => linea.estatusEntrega == 'no_surtido').length;
    final pendientes = receta.medicamentos.where((linea) => linea.pendiente).length;
    final total = receta.medicamentos.length;
    return '$total ${total == 1 ? 'medicamento' : 'medicamentos'} · $surtidos surtidos · $noSurtidos no surtidos · $pendientes pendientes';
  }
}

class _RecetaAbierta extends StatelessWidget {
  const _RecetaAbierta({required this.consulta, required this.paciente, required this.onCerrar});

  final ConsultaClinica consulta;
  final String paciente;
  final VoidCallback onCerrar;

  @override
  Widget build(BuildContext context) {
    final store = ConsultorioScope.of(context);
    final folio = consulta.folioReceta.isEmpty ? consulta.id : consulta.folioReceta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(onPressed: onCerrar, icon: const Icon(Icons.arrow_back), label: const Text('Volver a recetas')),
        Text('Receta $folio', style: const TextStyle(color: marino, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(paciente, style: const TextStyle(color: suave)),
        const SizedBox(height: 12),
        for (var i = 0; i < consulta.medicamentos.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _LineaMedicamento(consultaId: consulta.id, indice: i, linea: consulta.medicamentos[i], store: store),
          ),
      ],
    );
  }
}

class _LineaMedicamento extends StatelessWidget {
  const _LineaMedicamento({required this.consultaId, required this.indice, required this.linea, required this.store});

  final String consultaId;
  final int indice;
  final MedicamentoLinea linea;
  final ConsultorioStore store;

  @override
  Widget build(BuildContext context) {
    final momento = fechaHora(linea.fechaEntrega);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: tarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(linea.nombre, style: const TextStyle(color: texto, fontWeight: FontWeight.w800, fontSize: 16)),
          if (linea.detalle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(linea.detalle, style: const TextStyle(color: suave, fontSize: 13)),
          ],
          if (linea.indicacion.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(linea.indicacion, style: const TextStyle(color: gris, fontSize: 13)),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final opcion in const [('pendiente', 'Pendiente'), ('surtido', 'Surtido'), ('no_surtido', 'No surtido')])
                ChoiceChip(
                  label: Text(opcion.$2),
                  selected: etiquetaSurtido(linea.estatusEntrega) == opcion.$2,
                  onSelected: (_) => store.marcarMedicamento(consultaId, indice, opcion.$1),
                ),
            ],
          ),
          if (momento != null && !linea.pendiente) ...[
            const SizedBox(height: 8),
            Text('${fechaCorta(momento)} ${horaDe(momento)}', style: const TextStyle(color: suave, fontSize: 12)),
          ],
          const SizedBox(height: 10),
          _NotaCampo(
            inicial: linea.notaSurtido,
            pista: 'Nota: lote, faltante o por qué no se surtió',
            onGuardar: (nota) => store.anotarMedicamento(consultaId, indice, nota),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final nombre = await pedirEvidencia(context);
              if (nombre == null) return;
              store.evidenciarMedicamento(consultaId, indice, nombre);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Evidencia adjunta: $nombre')));
              }
            },
            icon: const Icon(Icons.attach_file),
            label: const Text('Subir evidencia'),
          ),
          if (linea.evidenciaNombre.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(linea.evidenciaNombre, style: const TextStyle(color: azul, fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }
}

class _NotaCampo extends StatefulWidget {
  const _NotaCampo({required this.inicial, required this.pista, required this.onGuardar});

  final String inicial;
  final String pista;
  final ValueChanged<String> onGuardar;

  @override
  State<_NotaCampo> createState() => _NotaCampoState();
}

class _NotaCampoState extends State<_NotaCampo> {
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
      maxLines: 3,
      decoration: InputDecoration(hintText: widget.pista),
      onEditingComplete: () => widget.onGuardar(_controlador.text),
      onTapOutside: (_) => widget.onGuardar(_controlador.text),
    );
  }
}

class _RecetaTarjeta extends StatelessWidget {
  const _RecetaTarjeta({required this.paciente, required this.folio, required this.resumen, required this.onAbrir});

  final String paciente;
  final String folio;
  final String resumen;
  final VoidCallback onAbrir;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: tarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Folio $folio', style: const TextStyle(color: cian, fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(paciente, style: const TextStyle(color: texto, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(resumen, style: const TextStyle(color: suave, fontSize: 13)),
          const SizedBox(height: 10),
          FilledButton(onPressed: onAbrir, child: const Text('Abrir receta')),
        ],
      ),
    );
  }
}

class _Filtros extends StatelessWidget {
  const _Filtros({required this.opciones, required this.activo, required this.onElegir});

  final List<(String, String)> opciones;
  final String activo;
  final ValueChanged<String> onElegir;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final opcion in opciones)
          ChoiceChip(
            label: Text(opcion.$2),
            selected: activo == opcion.$1,
            onSelected: (_) => onElegir(opcion.$1),
          ),
      ],
    );
  }
}
