import 'package:flutter/material.dart';

import '../formato.dart';
import '../models/tarjeta_derechohabiente.dart';
import '../state/consultorio_store.dart';
import '../theme/sisco_theme.dart';
import '../widgets/comun.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ConsultorioScope.of(context);
    final paciente = store.pacienteActivo;
    final tarjeta = paciente == null ? null : TarjetaDerechohabiente.de(paciente);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        const Text('Wallet', style: TextStyle(color: marino, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Tu tarjeta virtual de derechohabiente.', style: TextStyle(color: gris)),
        const SizedBox(height: 18),
        if (tarjeta == null)
          const AvisoVacio(texto: 'Elige tu expediente en Mis citas para ver tu tarjeta de derechohabiente.')
        else ...[
          TarjetaVirtual(tarjeta: tarjeta),
          const SizedBox(height: 14),
          Text(
            tarjeta.cubierta
                ? 'Muéstrala en recepción o caja. Identifica tu derecho a servicio y el cargo a la póliza.'
                : 'Esta credencial te identifica en la red SISCO. La póliza no está activa, así que caja no puede cargarle la atención.',
            style: const TextStyle(color: suave, height: 1.4),
          ),
          const SizedBox(height: 16),
          FichaBloque(
            titulo: 'COBERTURA',
            child: Column(
              children: [
                DatoFila(etiqueta: 'PLAN', valor: tarjeta.plan),
                DatoFila(etiqueta: 'NÚMERO', valor: tarjeta.numero),
                DatoFila(etiqueta: 'EXPEDIENTE', valor: tarjeta.expediente),
                DatoFila(etiqueta: 'VIGENCIA', valor: tarjeta.vigenciaHasta.isEmpty ? '' : fechaDia(tarjeta.vigenciaHasta)),
                DatoFila(etiqueta: 'ESTADO', valor: etiquetaTarjeta(tarjeta.estado)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          BotonPastilla(
            texto: 'Presentar en caja',
            icono: Icons.qr_code_2,
            onPressed: () => abrirTarjeta(context, tarjeta),
            expandir: true,
          ),
        ],
      ],
    );
  }
}

void abrirTarjeta(BuildContext context, TarjetaDerechohabiente tarjeta) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => _PresentarTarjeta(tarjeta: tarjeta)));
}

class TarjetaVirtual extends StatelessWidget {
  const TarjetaVirtual({super.key, required this.tarjeta, this.grande = false});

  final TarjetaDerechohabiente tarjeta;
  final bool grande;

  @override
  Widget build(BuildContext context) {
    final vigencia = tarjeta.vigenciaHasta.isEmpty ? 'Sin vigencia' : fechaDia(tarjeta.vigenciaHasta);
    return AspectRatio(
      aspectRatio: grande ? 1.55 : 1.7,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF004B7F), Color(0xFF29669D), Color(0xFF0FA7E2)],
          ),
          boxShadow: const [BoxShadow(color: Color(0x33004B7F), blurRadius: 24, offset: Offset(0, 12))],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -36,
              top: -48,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(grande ? 22 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x33FFFFFF)),
                        child: const Text('S', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'SISCO Servicios Médicos',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                      _EstadoTarjeta(estado: tarjeta.estado),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: 36,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: const LinearGradient(colors: [Color(0xFFF3E6B8), Color(0xFFC4A35A)]),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'TARJETA DE DERECHOHABIENTE',
                    style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tarjeta.titular,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white, fontSize: grande ? 22 : 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tarjeta.numero,
                    style: TextStyle(color: Colors.white, fontSize: grande ? 18 : 16, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _DatoTarjeta(etiqueta: 'VIGENCIA', valor: vigencia),
                      const SizedBox(width: 18),
                      _DatoTarjeta(etiqueta: 'EXPEDIENTE', valor: tarjeta.expediente),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadoTarjeta extends StatelessWidget {
  const _EstadoTarjeta({required this.estado});

  final String estado;

  @override
  Widget build(BuildContext context) {
    final cubierta = estado == 'vigente';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cubierta ? const Color(0xFF059669) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        etiquetaTarjeta(estado),
        style: TextStyle(color: cubierta ? Colors.white : aviso, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _DatoTarjeta extends StatelessWidget {
  const _DatoTarjeta({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
        const SizedBox(height: 2),
        Text(valor, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _PresentarTarjeta extends StatelessWidget {
  const _PresentarTarjeta({required this.tarjeta});

  final TarjetaDerechohabiente tarjeta;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: marino,
      appBar: AppBar(
        backgroundColor: marino,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Presentar tarjeta'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            children: [
              TarjetaVirtual(tarjeta: tarjeta, grande: true),
              const SizedBox(height: 20),
              const Text(
                'Acerca el teléfono a caja o recepción para que lean tu número de derechohabiente.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
