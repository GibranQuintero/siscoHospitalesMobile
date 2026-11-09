import 'package:flutter/material.dart';

import '../acciones_cita.dart';
import '../formato.dart';
import '../state/consultorio_store.dart';
import '../theme/sisco_theme.dart';
import '../widgets/comun.dart';
import 'expediente_clinico.dart';
import 'expediente_screen.dart';

class PacienteHomeScreen extends StatefulWidget {
  const PacienteHomeScreen({super.key});

  @override
  State<PacienteHomeScreen> createState() => _PacienteHomeScreenState();
}

class _PacienteHomeScreenState extends State<PacienteHomeScreen> {
  final _busqueda = TextEditingController();
  var _hoy = true;
  var _cambiando = false;

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ConsultorioScope.of(context);
    final paciente = _cambiando ? null : store.pacienteActivo;
    final consulta = _busqueda.text.trim().toLowerCase();
    final candidatos = store.pacientes.where((item) {
      if (consulta.isEmpty) return true;
      return '${item.nombreCompleto} ${item.correo}'.toLowerCase().contains(consulta);
    }).toList();

    return RefreshIndicator(
      color: azul,
      onRefresh: store.cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          const Text('Tu consultorio', style: TextStyle(color: marino, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Citas, videollamada y expediente.', style: TextStyle(color: gris)),
          const SizedBox(height: 12),
          BotonPastilla(
            texto: 'Llamar a CAT (Soporte Directo)',
            icono: Icons.call_outlined,
            onPressed: () => llamarACat(context),
            expandir: true,
          ),
          if (store.error != null) ...[
            const SizedBox(height: 12),
            Text(store.error!, style: const TextStyle(color: aviso)),
          ],
          const SizedBox(height: 18),
          if (paciente == null) ...[
            Row(
              children: [
                const Expanded(child: Text('Elige tu expediente', style: TextStyle(color: marino, fontSize: 18, fontWeight: FontWeight.w800))),
                Text('${store.pacientes.length} Registros', style: const TextStyle(color: suave, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Selecciona para abrir historial clínico', style: TextStyle(color: suave, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: _busqueda,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'Buscar por nombre o correo...', prefixIcon: Icon(Icons.search)),
            ),
            const SizedBox(height: 12),
            if (store.pacientes.isEmpty)
              const AvisoVacio(texto: 'Todavía no hay expedientes en el consultorio.')
            else if (candidatos.isEmpty)
              const AvisoVacio(texto: 'Ningún expediente coincide con esa búsqueda.')
            else
              for (final candidato in candidatos)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PacienteTarjeta(
                    paciente: candidato,
                    citas: store.citasDe(candidato.id),
                    onTap: () {
                      store.elegirPaciente(candidato.id);
                      setState(() => _cambiando = false);
                    },
                  ),
                ),
          ] else ...[
            _PacienteActivo(
              iniciales: inicialesDe(paciente.nombre, paciente.apellido),
              nombre: paciente.nombreCompleto,
              expediente: paciente.id,
              onExpediente: () => abrirExpediente(context, paciente.id),
              onCambiar: () => setState(() => _cambiando = true),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(child: Text('Mis citas', style: TextStyle(color: marino, fontSize: 18, fontWeight: FontWeight.w800))),
                _Selector(
                  izquierda: 'Hoy',
                  derecha: 'Historial',
                  izquierdaActiva: _hoy,
                  onIzquierda: () => setState(() => _hoy = true),
                  onDerecha: () => setState(() => _hoy = false),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._citas(context, store, paciente.nombreCompleto, paciente.id),
            const SizedBox(height: 8),
            SeguimientoDerechohabiente(pacienteId: paciente.id),
            const SizedBox(height: 12),
            AvisoConsultorio(pacienteId: paciente.id),
          ],
        ],
      ),
    );
  }

  List<Widget> _citas(BuildContext context, ConsultorioStore store, String nombre, String id) {
    final hoy = DateTime.now();
    final citas = store.citasDe(id).where((cita) {
      if (cita.estado == 'cancelada' || cita.inicio == null) return false;
      final esHoy = esMismoDia(cita.inicio!, hoy);
      return _hoy ? esHoy : !esHoy;
    }).toList();
    if (citas.isEmpty) {
      return [AvisoVacio(texto: _hoy ? 'No tienes citas para hoy.' : 'No hay citas en el historial.')];
    }
    return [
      for (final cita in citas)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: CitaTarjeta(
            cita: cita,
            paciente: nombre,
            linea: store.lineaAgenda(cita),
            medico: cita.medicoId.isEmpty ? '' : store.nombreMedico(cita.medicoId),
            meetListo: store.enlaceMeet(cita).isNotEmpty,
            onMeet: cita.videollamada ? () => crearOAbrirMeet(context, cita) : null,
            onCat: () => llamarACat(context),
          ),
        ),
    ];
  }
}

class _PacienteActivo extends StatelessWidget {
  const _PacienteActivo({
    required this.iniciales,
    required this.nombre,
    required this.expediente,
    required this.onExpediente,
    required this.onCambiar,
  });

  final String iniciales;
  final String nombre;
  final String expediente;
  final VoidCallback onExpediente;
  final VoidCallback onCambiar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: tarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarIniciales(iniciales: iniciales, gradiente: gradientePaciente),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DERECHOHABIENTE ACTIVO', style: TextStyle(color: cian, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                    Text(nombre, style: const TextStyle(color: texto, fontSize: 18, fontWeight: FontWeight.w800)),
                    Text('Nº Expediente: $expediente', style: const TextStyle(color: suave, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(tooltip: 'Cambiar expediente', onPressed: onCambiar, icon: const Icon(Icons.swap_horiz, color: suave)),
            ],
          ),
          const SizedBox(height: 12),
          BotonPastilla(
            texto: 'Ver mi expediente médico',
            icono: Icons.folder_shared_outlined,
            onPressed: onExpediente,
            expandir: true,
          ),
        ],
      ),
    );
  }
}

class _Selector extends StatelessWidget {
  const _Selector({
    required this.izquierda,
    required this.derecha,
    required this.izquierdaActiva,
    required this.onIzquierda,
    required this.onDerecha,
  });

  final String izquierda;
  final String derecha;
  final bool izquierdaActiva;
  final VoidCallback onIzquierda;
  final VoidCallback onDerecha;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _opcion(izquierda, izquierdaActiva, onIzquierda),
        const SizedBox(width: 6),
        _opcion(derecha, !izquierdaActiva, onDerecha),
      ],
    );
  }

  Widget _opcion(String texto, bool activo, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: activo ? tinte : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(texto, style: TextStyle(color: activo ? azul : suave, fontWeight: FontWeight.w700, fontSize: 12)),
      ),
    );
  }
}
