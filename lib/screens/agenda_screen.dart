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
  var _rango = 'hoy';

  @override
  Widget build(BuildContext context) {
    final store = ConsultorioScope.of(context);
    final hoy = DateTime.now();
    final citas = store.citas.where((cita) {
      if (cita.inicio == null || cita.estado == 'cancelada') return false;
      return _entra(cita.inicio!, hoy);
    }).toList()
      ..sort((a, b) => a.inicio!.compareTo(b.inicio!));
    final grupos = <String, List<Cita>>{};
    for (final cita in citas) {
      final dia = cita.inicio!;
      grupos.putIfAbsent('${dia.year}-${dia.month}-${dia.day}', () => []).add(cita);
    }

    return RefreshIndicator(
      color: azul,
      onRefresh: store.cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const Text('Agenda', style: TextStyle(color: marino, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(_resumen(citas.length), style: const TextStyle(color: suave)),
          const SizedBox(height: 12),
          Row(
            children: [
              _Rango(texto: 'Hoy', activo: _rango == 'hoy', onTap: () => setState(() => _rango = 'hoy')),
              const SizedBox(width: 8),
              _Rango(texto: 'Semana', activo: _rango == 'semana', onTap: () => setState(() => _rango = 'semana')),
              const SizedBox(width: 8),
              _Rango(texto: 'Mes', activo: _rango == 'mes', onTap: () => setState(() => _rango = 'mes')),
            ],
          ),
          const SizedBox(height: 14),
          if (store.cargando && citas.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 28), child: Center(child: CircularProgressIndicator()))
          else if (grupos.isEmpty)
            const AvisoVacio(texto: 'La agenda no tiene citas en este periodo.')
          else
            for (final entrada in grupos.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 8),
                child: Text(etiquetaDia(entrada.value.first.inicio!, hoy), style: const TextStyle(color: azul, fontWeight: FontWeight.w800)),
              ),
              for (final cita in entrada.value)
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
            ],
        ],
      ),
    );
  }

  bool _entra(DateTime inicio, DateTime hoy) {
    final dia = DateTime(inicio.year, inicio.month, inicio.day);
    final base = DateTime(hoy.year, hoy.month, hoy.day);
    switch (_rango) {
      case 'semana':
        final lunes = base.subtract(Duration(days: base.weekday - 1));
        final domingo = lunes.add(const Duration(days: 6));
        return !dia.isBefore(lunes) && !dia.isAfter(domingo);
      case 'mes':
        return inicio.year == hoy.year && inicio.month == hoy.month;
      default:
        return esMismoDia(inicio, hoy);
    }
  }

  String _resumen(int total) {
    switch (_rango) {
      case 'semana':
        return '$total citas activas en la semana';
      case 'mes':
        return '$total citas activas en el mes';
      default:
        return '$total citas activas hoy';
    }
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
