import 'package:flutter/material.dart';

import '../acciones_cita.dart';
import '../formato.dart';
import '../models/consultorio.dart';
import '../state/consultorio_store.dart';
import '../theme/sisco_theme.dart';
import '../widgets/comun.dart';
import 'expediente_screen.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  var _vista = 'dia';
  var _sede = '';
  late DateTime _foco;

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    _foco = DateTime(hoy.year, hoy.month, hoy.day);
  }

  @override
  Widget build(BuildContext context) {
    final store = ConsultorioScope.of(context);
    final citas = _citasPeriodo(store);
    final llamadas = store.llamadasPendientes;
    final soloConsulta = store.modulo == ModuloApp.doctor;

    return RefreshIndicator(
      color: azul,
      onRefresh: store.cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const Text('Agenda', style: TextStyle(color: marino, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(_tituloPeriodo(), style: const TextStyle(color: suave)),
          const SizedBox(height: 8),
          if (soloConsulta)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: tinte, borderRadius: BorderRadius.circular(12)),
              child: const Text(
                'Solo consulta: las citas las saca el personal de apoyo médico',
                style: TextStyle(color: azul, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Rango(texto: 'Día', activo: _vista == 'dia', onTap: () => setState(() => _vista = 'dia')),
              _Rango(texto: 'Semana', activo: _vista == 'semana', onTap: () => setState(() => _vista = 'semana')),
              _Rango(texto: 'Mes', activo: _vista == 'mes', onTap: () => setState(() => _vista = 'mes')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                tooltip: 'Anterior',
                onPressed: () => setState(() => _foco = _foco.add(Duration(days: _vista == 'mes' ? -30 : _vista == 'semana' ? -7 : -1))),
                icon: const Icon(Icons.chevron_left),
              ),
              TextButton(onPressed: () => setState(() {
                final hoy = DateTime.now();
                _foco = DateTime(hoy.year, hoy.month, hoy.day);
              }), child: const Text('Hoy')),
              IconButton(
                tooltip: 'Siguiente',
                onPressed: () => setState(() => _foco = _foco.add(Duration(days: _vista == 'mes' ? 30 : _vista == 'semana' ? 7 : 1))),
                icon: const Icon(Icons.chevron_right),
              ),
              const Spacer(),
              Text('${citas.length} citas', style: const TextStyle(color: suave, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Calendarios / sedes', style: const TextStyle(color: marino, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Rango(texto: 'Todas las sedes', activo: _sede.isEmpty, onTap: () => setState(() => _sede = '')),
              for (final sede in store.sedesAgenda)
                _Rango(texto: sede, activo: _sede == sede, onTap: () => setState(() => _sede = sede)),
            ],
          ),
          const SizedBox(height: 16),
          FichaBloque(
            titulo: 'CITAS SIN CONSULTORIO - HOSPITAL (${llamadas.length})',
            child: llamadas.isEmpty
                ? const Text(
                    'No hay citas sin consultorio - hospital. Registrar llamada CAT crea la cita sin fecha y sin sede.',
                    style: TextStyle(color: suave, height: 1.35),
                  )
                : Column(
                    children: [
                      for (final cita in llamadas)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '${cita.folio.isEmpty ? 'Folio al guardar' : cita.folio} · ${store.nombrePaciente(cita.pacienteId)}',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: texto),
                            ),
                            subtitle: Text(
                              [
                                'Sin hospital',
                                if (cita.inicio != null) '${fechaCorta(cita.inicio!)} ${horaDe(cita.inicio!)}',
                                if (cita.creadoPor.isNotEmpty) cita.creadoPor,
                              ].join(' · '),
                              style: const TextStyle(color: suave),
                            ),
                            onTap: () => _abrirCita(context, store, cita),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          if (store.cargando && citas.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 28), child: Center(child: CircularProgressIndicator()))
          else if (citas.isEmpty)
            const AvisoVacio(texto: 'La agenda no tiene citas en este periodo.')
          else
            for (final entrada in _grupos(citas).entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 8),
                child: Text(etiquetaDia(entrada.value.first.inicio!, DateTime.now()), style: const TextStyle(color: azul, fontWeight: FontWeight.w800)),
              ),
              for (final cita in entrada.value)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: CitaTarjeta(
                    cita: cita,
                    paciente: store.nombrePaciente(cita.pacienteId),
                    linea: store.lineaAgenda(cita),
                    medico: cita.medicoId.isEmpty ? '' : store.nombreMedico(cita.medicoId),
                    meetListo: store.enlaceMeet(cita).isNotEmpty,
                    onTap: () => _abrirCita(context, store, cita),
                    onMeet: cita.videollamada ? () => crearOAbrirMeet(context, cita) : null,
                    onCat: () => llamarACat(context),
                  ),
                ),
            ],
        ],
      ),
    );
  }

  String _tituloPeriodo() {
    switch (_vista) {
      case 'semana':
        final lunes = _foco.subtract(Duration(days: _foco.weekday - 1));
        final domingo = lunes.add(const Duration(days: 6));
        return '${fechaCorta(lunes)} – ${fechaCorta(domingo)}';
      case 'mes':
        return '${meses[_foco.month - 1][0].toUpperCase()}${meses[_foco.month - 1].substring(1)} ${_foco.year}';
      default:
        return fechaTitulo(_foco);
    }
  }

  List<Cita> _citasPeriodo(ConsultorioStore store) {
    return store.citas.where((cita) {
      if (cita.inicio == null || cita.estado == 'cancelada') return false;
      if (_sede.isNotEmpty && cita.clinica != _sede) return false;
      return _entra(cita.inicio!);
    }).toList()
      ..sort((a, b) => a.inicio!.compareTo(b.inicio!));
  }

  bool _entra(DateTime inicio) {
    final dia = DateTime(inicio.year, inicio.month, inicio.day);
    switch (_vista) {
      case 'semana':
        final lunes = _foco.subtract(Duration(days: _foco.weekday - 1));
        final domingo = lunes.add(const Duration(days: 6));
        return !dia.isBefore(lunes) && !dia.isAfter(domingo);
      case 'mes':
        return inicio.year == _foco.year && inicio.month == _foco.month;
      default:
        return esMismoDia(inicio, _foco);
    }
  }

  Map<String, List<Cita>> _grupos(List<Cita> citas) {
    final grupos = <String, List<Cita>>{};
    for (final cita in citas) {
      final dia = cita.inicio!;
      grupos.putIfAbsent('${dia.year}-${dia.month}-${dia.day}', () => []).add(cita);
    }
    return grupos;
  }

  void _abrirCita(BuildContext context, ConsultorioStore store, Cita cita) {
    final paciente = store.porId(cita.pacienteId);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(store.nombrePaciente(cita.pacienteId), style: const TextStyle(color: marino, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(store.lineaAgenda(cita), style: const TextStyle(color: azul, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                DatoFila(etiqueta: 'SERVICIO', valor: cita.tipoServicio),
                DatoFila(etiqueta: 'MÉDICO', valor: cita.medicoId.isEmpty ? 'Sin médico asignado' : store.nombreMedico(cita.medicoId)),
                DatoFila(
                  etiqueta: 'HORARIO',
                  valor: cita.inicio == null
                      ? 'Sin fecha'
                      : '${fechaLarga(cita.inicio!)} · ${horaDe(cita.inicio!)}${cita.fin == null ? '' : ' – ${horaDe(cita.fin!)}'}',
                ),
                DatoFila(etiqueta: 'SEDE', valor: cita.sinHospital ? 'Sin consultorio - hospital' : cita.clinica),
                DatoFila(etiqueta: 'ESTADO', valor: etiquetaEstado(cita.estado)),
                DatoFila(etiqueta: 'MOTIVO', valor: cita.motivo),
                DatoFila(etiqueta: 'ORIGEN', valor: cita.origen == 'llamada' ? 'CAT' : cita.origen == 'agenda' ? 'Agenda' : ''),
                DatoFila(etiqueta: 'CREADA POR', valor: cita.creadoPor),
                if (paciente != null) ...[
                  DatoFila(etiqueta: 'AFILIACIÓN', valor: paciente.afiliacion.isEmpty ? 'Sin registrar' : paciente.afiliacion),
                  DatoFila(etiqueta: 'REGIÓN', valor: paciente.regionAgenda),
                  DatoFila(etiqueta: 'TELÉFONO', valor: paciente.telefono),
                ],
                if (cita.pacienteNuevo) const Padding(padding: EdgeInsets.only(top: 6), child: Text('Es derechohabiente nuevo', style: TextStyle(color: acero, fontWeight: FontWeight.w700))),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        abrirExpediente(this.context, cita.pacienteId);
                      },
                      child: Text(store.modulo == ModuloApp.doctor && cita.estado == 'en_consulta' ? 'Continuar consulta' : 'Abrir expediente'),
                    ),
                    if (cita.videollamada)
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          crearOAbrirMeet(this.context, cita);
                        },
                        icon: const Icon(Icons.videocam_outlined),
                        label: const Text('Videollamada'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Rango extends StatelessWidget {
  const _Rango({required this.texto, required this.activo, required this.onTap});

  final String texto;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? tinte : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: activo ? azul : linea),
        ),
        child: Text(texto, style: TextStyle(color: activo ? azul : suave, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
