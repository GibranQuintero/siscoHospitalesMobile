import 'package:flutter/material.dart';

import '../formato.dart';
import '../state/consultorio_store.dart';
import '../theme/sisco_theme.dart';
import '../widgets/comun.dart';

class ExpedienteClinicoVista extends StatelessWidget {
  const ExpedienteClinicoVista({super.key, required this.pacienteId});

  final String pacienteId;

  @override
  Widget build(BuildContext context) {
    final store = ConsultorioScope.of(context);
    final expediente = store.expedienteDe(pacienteId);
    final consultas = store.consultasDe(pacienteId);
    final vacio = expediente == null && consultas.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lectura del expediente. El seguimiento de la consulta se captura en el escritorio.',
          style: TextStyle(color: suave, height: 1.35),
        ),
        const SizedBox(height: 12),
        if (vacio)
          const AvisoVacio(texto: 'Este expediente todavía no tiene notas, recetas ni estudios.')
        else ...[
          if (expediente != null && expediente.antecedentes.isNotEmpty)
            FichaBloque(
              titulo: 'ANTECEDENTES',
              child: Column(
                children: [
                  for (final nota in expediente.antecedentes) DatoFila(etiqueta: nota.titulo.toUpperCase(), valor: nota.detalle),
                ],
              ),
            ),
          for (final consulta in consultas) ...[
            const SizedBox(height: 12),
            FichaBloque(
              titulo: 'CONSULTA',
              child: Column(
                children: [
                  DatoFila(etiqueta: 'MOTIVO', valor: consulta.motivo),
                  DatoFila(etiqueta: 'MÉDICO', valor: store.nombreMedico(consulta.medicoId)),
                  DatoFila(etiqueta: 'DIAGNÓSTICO', valor: consulta.diagnostico),
                  DatoFila(etiqueta: 'PLAN', valor: consulta.plan),
                  DatoFila(etiqueta: 'NOTA', valor: consulta.notaClinica),
                  if (consulta.folioReceta.isNotEmpty) DatoFila(etiqueta: 'RECETA', valor: consulta.folioReceta),
                ],
              ),
            ),
            if (consulta.medicamentos.isNotEmpty) ...[
              const SizedBox(height: 12),
              FichaBloque(
                titulo: 'MEDICAMENTOS',
                child: Column(
                  children: [
                    for (final linea in consulta.medicamentos)
                      DatoFila(
                        etiqueta: etiquetaSurtido(linea.estatusEntrega).toUpperCase(),
                        valor: [linea.nombre, linea.detalle, if (linea.evidenciaNombre.isNotEmpty) linea.evidenciaNombre].where((parte) => parte.isNotEmpty).join(' · '),
                      ),
                  ],
                ),
              ),
            ],
            if (consulta.ordenes.isNotEmpty) ...[
              const SizedBox(height: 12),
              FichaBloque(
                titulo: 'LABORATORIO Y GABINETE',
                child: Column(
                  children: [
                    for (final orden in consulta.ordenes)
                      DatoFila(
                        etiqueta: etiquetaOrden(orden.estatus).toUpperCase(),
                        valor: [
                          orden.tipo,
                          orden.concepto,
                          if (orden.folio.isNotEmpty) orden.folio,
                          if (orden.resultado.isNotEmpty) orden.resultado,
                          if (orden.evidenciaNombre.isNotEmpty) orden.evidenciaNombre,
                        ].join(' · '),
                      ),
                  ],
                ),
              ),
            ],
          ],
          if (expediente != null && expediente.archivos.isNotEmpty) ...[
            const SizedBox(height: 12),
            FichaBloque(
              titulo: 'ARCHIVOS',
              child: Column(
                children: [
                  for (final archivo in expediente.archivos) DatoFila(etiqueta: fechaDia(archivo.fecha), valor: archivo.nombre),
                ],
              ),
            ),
          ],
          if (expediente != null && expediente.consentimientos.isNotEmpty) ...[
            const SizedBox(height: 12),
            FichaBloque(
              titulo: 'CONSENTIMIENTOS',
              child: Column(
                children: [
                  for (final consentimiento in expediente.consentimientos)
                    DatoFila(
                      etiqueta: consentimiento.firmado ? 'FIRMADO' : 'PENDIENTE',
                      valor: '${consentimiento.nombre} · ${fechaDia(consentimiento.fecha)}',
                    ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class SeguimientoDerechohabiente extends StatelessWidget {
  const SeguimientoDerechohabiente({super.key, required this.pacienteId});

  final String pacienteId;

  @override
  Widget build(BuildContext context) {
    final store = ConsultorioScope.of(context);
    final consultas = store.consultasDe(pacienteId);
    final medicamentos = [for (final consulta in consultas) ...consulta.medicamentos];
    final ordenes = [for (final consulta in consultas) ...consulta.ordenes];
    if (medicamentos.isEmpty && ordenes.isEmpty) {
      return const AvisoVacio(texto: 'Todavía no tienes medicamentos ni estudios ligados a tu expediente.');
    }
    return Column(
      children: [
        if (medicamentos.isNotEmpty)
          FichaBloque(
            titulo: 'MIS MEDICAMENTOS',
            child: Column(
              children: [
                for (final linea in medicamentos)
                  DatoFila(etiqueta: etiquetaSurtido(linea.estatusEntrega).toUpperCase(), valor: linea.nombre),
              ],
            ),
          ),
        if (ordenes.isNotEmpty) ...[
          const SizedBox(height: 12),
          FichaBloque(
            titulo: 'MIS ESTUDIOS',
            child: Column(
              children: [
                for (final orden in ordenes)
                  DatoFila(etiqueta: etiquetaOrden(orden.estatus).toUpperCase(), valor: '${orden.tipo} · ${orden.concepto}'),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class AvisoConsultorio extends StatefulWidget {
  const AvisoConsultorio({super.key, required this.pacienteId});

  final String pacienteId;

  @override
  State<AvisoConsultorio> createState() => _AvisoConsultorioState();
}

class _AvisoConsultorioState extends State<AvisoConsultorio> {
  final _texto = TextEditingController();

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ConsultorioScope.of(context);
    return FichaBloque(
      titulo: 'AVISO AL CONSULTORIO',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('El consultorio lo ve en este teléfono. Todavía no sale al escritorio.', style: TextStyle(color: suave, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: _texto,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Escribe un aviso sobre tu cita, un estudio o un medicamento'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () {
              final texto = _texto.text.trim();
              if (texto.isEmpty) return;
              store.dejarMensaje(widget.pacienteId, texto);
              _texto.clear();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aviso registrado en este teléfono.')));
            },
            child: const Text('Enviar aviso'),
          ),
        ],
      ),
    );
  }
}
