import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../formato.dart';
import '../models/consultorio.dart';
import '../models/tarjeta_derechohabiente.dart';
import '../state/consultorio_store.dart';

/// Cartera del derechohabiente, igual a la demo "Cartera SaludOMG · Plata":
///  - Al frente, la tarjeta de pago Plata Servicios Médicos.
///  - Atrás, la credencial con la aseguradora, la foto y los datos básicos.
/// Tocar una abre su detalle. La tarjeta de pago todavía no tiene base: saldo y movimientos son de ejemplo.

// ---------------------------------------------------------------------------
// Colores y letras de la demo
// ---------------------------------------------------------------------------

const _bg = Color(0xFFEEF2F1);
const _surface = Colors.white;
const _surface2 = Color(0xFFF5F8F7);
const _fg = Color(0xFF14211F);
const _muted = Color(0xFF5D6D6A);
const _line = Color(0xFFDBE3E1);
const _accent = Color(0xFF0B8178);
const _accentSoft = Color(0xFFD8EFEC);
const _ok = Color(0xFF1F7A46);
const _warn = Color(0xFFA15C00);
const _tinta = Color(0xFF13221F);
const _tintaSuave = Color(0xFF4D5C59);
const _ui = 'Manrope';
const _num = 'IBMPlexMono';

/// Proporción de una tarjeta ID-1 (85.6 × 54 mm).
const _proporcion = 85.6 / 54;

/// Tema de la cartera: misma letra y colores en todas sus pantallas.
Widget _conTema(BuildContext context, Widget child) {
  final base = Theme.of(context);
  return Theme(
    data: base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: _ui, bodyColor: _fg, displayColor: _fg),
      scaffoldBackgroundColor: _bg,
    ),
    child: DefaultTextStyle.merge(style: const TextStyle(fontFamily: _ui, color: _fg, fontSize: 15, height: 1.45), child: child),
  );
}

// ---------------------------------------------------------------------------
// Aseguradoras (datos de cobertura de la demo)
// ---------------------------------------------------------------------------

class Aseguradora {
  const Aseguradora({
    required this.id,
    required this.nombre,
    required this.plan,
    required this.color,
    required this.suave,
    required this.poliza,
    required this.certificado,
    required this.vigencia,
    required this.deducible,
    required this.coaseguro,
    required this.tope,
    required this.cabina,
  });

  final String id;
  final String nombre;
  final String plan;
  final Color color;
  final Color suave;
  final String poliza;
  final String certificado;
  final String vigencia;
  final String deducible;
  final String coaseguro;
  final String tope;
  final String cabina;
}

const aseguradorasDemo = [
  Aseguradora(
    id: 'indep',
    nombre: 'INDEP',
    plan: 'Gastos médicos mayores · Plan Plata',
    color: Color(0xFF31508F),
    suave: Color(0xFFDFE6F4),
    poliza: 'GMM-2026-118734',
    certificado: '0042815',
    vigencia: '01/01/2026 – 31/12/2026',
    deducible: r'$15,000.00',
    coaseguro: '10 %',
    tope: r'$5,000,000.00',
    cabina: '800 000 1111',
  ),
  Aseguradora(
    id: 'amparo',
    nombre: 'Amparo Salud',
    plan: 'Colectivo empresarial · Plan Integral',
    color: Color(0xFF8A2F4F),
    suave: Color(0xFFF3DFE6),
    poliza: 'AMP-77-004512',
    certificado: '15-0042815',
    vigencia: '15/02/2026 – 14/02/2027',
    deducible: r'$10,000.00',
    coaseguro: '15 %',
    tope: r'$3,000,000.00',
    cabina: '800 000 2222',
  ),
  Aseguradora(
    id: 'niveluno',
    nombre: 'Nivel Uno Seguros',
    plan: 'Gastos médicos menores · Plan Básico',
    color: Color(0xFFB4691B),
    suave: Color(0xFFF6E6D4),
    poliza: 'N1-GM-2026-90021',
    certificado: 'NU-0042815',
    vigencia: '01/06/2026 – 31/05/2027',
    deducible: r'$0.00',
    coaseguro: '20 %',
    tope: r'$250,000.00',
    cabina: '800 000 3333',
  ),
];

/// La aseguradora de la ficha si está en la lista; si no, la primera.
Aseguradora aseguradoraDe(TarjetaDerechohabiente t) {
  final nombre = t.aseguradora.trim().toLowerCase();
  for (final a in aseguradorasDemo) {
    if (nombre.isNotEmpty && (a.nombre.toLowerCase() == nombre || a.id == nombre)) return a;
  }
  return aseguradorasDemo.first;
}

/// Datos que muestran las tarjetas: los de la ficha y, donde la ficha no trae el dato, los de la aseguradora.
class DatosCredencial {
  DatosCredencial({required this.tarjeta, required this.aseguradora, required this.medico, required this.consultorio});

  final TarjetaDerechohabiente tarjeta;
  final Aseguradora aseguradora;
  final String medico;
  final String consultorio;

  String get nombre => tarjeta.titular;
  String get afiliado => tarjeta.afiliado.isNotEmpty ? tarjeta.afiliado : tarjeta.expediente;
  String get poliza => aseguradora.poliza;
  String get certificado => tarjeta.numero.isNotEmpty && tarjeta.numero != tarjeta.expediente ? tarjeta.numero : aseguradora.certificado;
  String get vigencia => tarjeta.vigenciaHasta.isNotEmpty && aseguradora.nombre.toLowerCase() == tarjeta.aseguradora.toLowerCase()
      ? 'Hasta ${fechaDia(tarjeta.vigenciaHasta)}'
      : aseguradora.vigencia;
  String get sangre => tarjeta.tipoSangre.isEmpty ? '—' : tarjeta.tipoSangre;
  String get alergias => tarjeta.alergias.isEmpty ? 'Ninguna registrada' : tarjeta.alergias;
  String get emergencia => tarjeta.emergencia.isEmpty ? 'Sin contacto registrado' : tarjeta.emergencia;

  String get nacimiento {
    final fecha = DateTime.tryParse(tarjeta.fechaNacimiento);
    if (fecha == null) return '';
    final hoy = DateTime.now();
    var edad = hoy.year - fecha.year;
    if (hoy.month < fecha.month || (hoy.month == fecha.month && hoy.day < fecha.day)) edad--;
    return '${fechaDia(tarjeta.fechaNacimiento)} ($edad años)';
  }

  String get iniciales {
    final partes = nombre.trim().split(RegExp(r'\s+')).where((x) => x.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    final a = partes.first[0];
    final b = partes.length > 1 ? partes[1][0] : '';
    return (a + b).toUpperCase();
  }

  String get codigo => 'SOMG|$afiliado|$poliza|${aseguradora.id}';

  static DatosCredencial de(ConsultorioStore store, Paciente paciente, Aseguradora? elegida) {
    final tarjeta = TarjetaDerechohabiente.de(paciente);
    final citas = store.citasDe(paciente.id).where((c) => c.medicoId.isNotEmpty).toList()
      ..sort((a, b) => (b.inicio ?? DateTime(2000)).compareTo(a.inicio ?? DateTime(2000)));
    final ultima = citas.isEmpty ? null : citas.first;
    return DatosCredencial(
      tarjeta: tarjeta,
      aseguradora: elegida ?? aseguradoraDe(tarjeta),
      medico: ultima == null ? '' : store.nombreMedico(ultima.medicoId),
      consultorio: ultima?.clinica ?? '',
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta de pago: datos de ejemplo (todavía sin base)
// ---------------------------------------------------------------------------

class MovimientoPago {
  const MovimientoPago(this.concepto, this.detalle, this.monto);

  final String concepto;
  final String detalle;
  final double monto;
}

class PagoDemo {
  PagoDemo({required this.terminacion, required this.saldo, required this.movimientos});

  final String terminacion;
  double saldo;
  final List<MovimientoPago> movimientos;

  factory PagoDemo.ejemplo() => PagoDemo(
        terminacion: '4821',
        saldo: 3250,
        movimientos: [
          const MovimientoPago('Copago consulta general', 'Consultorio Centro · 12 nov', -250),
          const MovimientoPago('Farmacia de la red', 'Receta R-2026-0187 · 12 nov', -184.5),
          const MovimientoPago('Recarga de la empresa', 'Aportación mensual · 1 nov', 2000),
          const MovimientoPago('Laboratorio: biometría hemática', 'Laboratorio Norte · 28 oct', -120),
        ],
      );
}

String _dinero(double n) {
  final partes = n.abs().toStringAsFixed(2).split('.');
  final entero = partes[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return '${n < 0 ? '−' : ''}\$$entero.${partes[1]}';
}

// ---------------------------------------------------------------------------
// Pantalla principal: Cartera
// ---------------------------------------------------------------------------

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _pago = PagoDemo.ejemplo();
  Aseguradora? _aseguradora;

  @override
  Widget build(BuildContext context) {
    final store = ConsultorioScope.of(context);
    final paciente = store.pacienteActivo;
    final datos = paciente == null ? null : DatosCredencial.de(store, paciente, _aseguradora);

    return _conTema(
      context,
      ColoredBox(
        color: _bg,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          children: [
            Row(
              children: [
                const Expanded(child: Text('Cartera', style: TextStyle(fontFamily: _ui, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.24, color: _fg))),
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: _accent, shape: BoxShape.circle),
                  child: Text(datos?.iniciales ?? '', style: const TextStyle(fontFamily: _ui, color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ],
            ),
            if (store.demostracion) ...[
              const SizedBox(height: 18),
              const _AvisoDemo(),
            ],
            const SizedBox(height: 18),
            if (datos == null)
              const _Panel(child: Text('Elige tu expediente en Mis citas para ver tus tarjetas.', style: TextStyle(color: _muted)))
            else
              _Pila(
                atras: _FotoPaciente(
                  expediente: datos.tarjeta.expediente,
                  builder: (foto) => CredencialFrente(datos: datos, foto: foto),
                ),
                frente: TarjetaPlata(terminacion: _pago.terminacion),
                alTocarAtras: () => _abrir(
                  context,
                  DetalleCredencial(
                    paciente: paciente!,
                    aseguradoraInicial: datos.aseguradora,
                    alCambiarAseguradora: (a) => _aseguradora = a,
                  ),
                ),
                alTocarFrente: () => _abrir(context, DetallePago(pago: _pago, titular: datos.nombre)),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrir(BuildContext context, Widget pantalla) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => pantalla));
    if (mounted) setState(() {});
  }
}

class _AvisoDemo extends StatelessWidget {
  const _AvisoDemo();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BordePunteado(),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          'Demo sin conexión: todos los datos son de ejemplo y no salen de este teléfono.',
          style: TextStyle(fontFamily: _ui, fontSize: 12, color: _warn),
        ),
      ),
    );
  }
}

class _BordePunteado extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10));
    canvas.drawRRect(rr, Paint()..color = _surface);
    final borde = Paint()
      ..color = _line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final camino = Path()..addRRect(rr);
    for (final m in camino.computeMetrics()) {
      for (double d = 0; d < m.length; d += 7) {
        canvas.drawPath(m.extractPath(d, math.min(d + 4, m.length)), borde);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// La credencial asoma su franja de arriba y la tarjeta de pago queda al frente.
class _Pila extends StatelessWidget {
  const _Pila({required this.atras, required this.frente, required this.alTocarAtras, required this.alTocarFrente});

  final Widget atras;
  final Widget frente;
  final VoidCallback alTocarAtras;
  final VoidCallback alTocarFrente;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, medidas) {
        final ancho = math.min(medidas.maxWidth, 420.0);
        final alto = ancho / _proporcion;
        final asoma = alto * 0.318;
        return Center(
          child: SizedBox(
            width: ancho,
            height: alto + asoma,
            child: Stack(
              children: [
                Positioned(left: 0, right: 0, top: 0, height: alto, child: GestureDetector(onTap: alTocarAtras, child: atras)),
                Positioned(left: 0, right: 0, top: asoma, height: alto, child: GestureDetector(onTap: alTocarFrente, child: frente)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Piezas comunes de las pantallas de detalle
// ---------------------------------------------------------------------------

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.titulo});

  final Widget child;
  final String? titulo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (titulo != null) ...[
            Text(titulo!, style: const TextStyle(fontFamily: _ui, fontSize: 15, fontWeight: FontWeight.w700, color: _fg)),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

/// Lista de etiqueta y valor (como la lista de datos de la demo).
class _Datos extends StatelessWidget {
  const _Datos(this.filas);

  final List<(String, Widget)> filas;

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      children: [
        for (final f in filas)
          TableRow(children: [
            Padding(
              padding: const EdgeInsets.only(right: 14, bottom: 8),
              child: Text(f.$1, style: const TextStyle(fontFamily: _ui, fontSize: 14, color: _muted)),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DefaultTextStyle.merge(style: const TextStyle(fontFamily: _ui, fontSize: 14, fontWeight: FontWeight.w600, color: _fg), child: f.$2),
            ),
          ]),
      ],
    );
  }
}

(String, Widget) _fila(String etiqueta, String valor) => (etiqueta, Text(valor));

class _Pastilla extends StatelessWidget {
  const _Pastilla(this.texto, {this.alerta = false});

  final String texto;
  final bool alerta;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: alerta ? _warn.withValues(alpha: 0.18) : _accentSoft, borderRadius: BorderRadius.circular(999)),
        child: Text(texto, style: TextStyle(fontFamily: _ui, fontSize: 12, fontWeight: FontWeight.w700, color: alerta ? _warn : _accent)),
      ),
    );
  }
}

class _Boton extends StatelessWidget {
  const _Boton({required this.texto, required this.onPressed, this.primario = false});

  final String texto;
  final VoidCallback onPressed;
  final bool primario;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primario ? _accent : _surface,
      shape: StadiumBorder(side: BorderSide(color: primario ? _accent : _line)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Text(
            texto,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: _ui, fontSize: 14, fontWeight: FontWeight.w700, color: primario ? Colors.white : _fg),
          ),
        ),
      ),
    );
  }
}

/// "← Cartera" para volver, en lugar de la barra de arriba.
class _Detalle extends StatelessWidget {
  const _Detalle({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _conTema(
      context,
      Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 6), foregroundColor: _accent),
                      child: const Text('← Cartera', style: TextStyle(fontFamily: _ui, fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) const SizedBox(height: 18),
                    children[i],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta de pago (Plata Servicios Médicos)
// ---------------------------------------------------------------------------

class TarjetaPlata extends StatelessWidget {
  const TarjetaPlata({super.key, required this.terminacion});

  final String terminacion;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _proporcion,
      child: LayoutBuilder(
        builder: (context, medidas) {
          final u = medidas.maxWidth / 100; // 1 % del ancho de la tarjeta
          return Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18 * u / 3.88),
              gradient: const RadialGradient(
                center: Alignment(-0.7, -1),
                radius: 1.3,
                colors: [Color(0xFF2A2A2B), Color(0xFF161617), Color(0xFF0A0A0B)],
                stops: [0, 0.45, 1],
              ),
              boxShadow: const [BoxShadow(color: Color(0x1A10282A), blurRadius: 24, offset: Offset(0, 8))],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-1, -0.6),
                        end: Alignment(1, 0.6),
                        colors: [Color(0x12FFFFFF), Color(0x00FFFFFF), Color(0x00FFFFFF), Color(0x0AFFFFFF)],
                        stops: [0, 0.38, 0.7, 1],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(6 * u, 5 * u, 6 * u, 6 * u),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 1 * u),
                      AspectRatio(aspectRatio: 480 / 84, child: const CustomPaint(painter: _LogoPlata())),
                      SizedBox(height: 2.2 * u),
                      ShaderMask(
                        shaderCallback: (r) => const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFF4F4F5), Color(0xFF9B9CA0)],
                        ).createShader(r),
                        child: Text(
                          'SERVICIOS MÉDICOS',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: _ui, color: Colors.white, fontSize: 3.6 * u, fontWeight: FontWeight.w600, letterSpacing: 1.5 * u, height: 1),
                        ),
                      ),
                      SizedBox(height: 4.5 * u),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _Chip(ancho: 13 * u),
                          SizedBox(width: 7 * u, height: 7 * u, child: const CustomPaint(painter: _SinContacto(Color(0xFFB9BABD)))),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('débito', style: TextStyle(fontFamily: _ui, color: const Color(0xFFE9E9EA), fontSize: 5.2 * u, fontWeight: FontWeight.w600, height: 1.2)),
                              SizedBox(height: 1 * u),
                              Text(
                                '•••• $terminacion',
                                style: TextStyle(fontFamily: _num, color: const Color(0xFF8D8E93), fontSize: 3.4 * u, letterSpacing: 0.4 * u, height: 1.2),
                              ),
                            ],
                          ),
                          _CirculosRed(alto: 13.5 * u),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// "PLATA" en trazo plateado, con las A sin barra.
class _LogoPlata extends CustomPainter {
  const _LogoPlata();

  @override
  void paint(Canvas canvas, Size size) {
    final escala = math.min(size.width / 480, size.height / 84);
    canvas.save();
    canvas.translate((size.width - 480 * escala) / 2, (size.height - 84 * escala) / 2);
    canvas.scale(escala);
    final pintura = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeJoin = StrokeJoin.miter
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF5F5F6), Color(0xFFB4B5B9), Color(0xFF6F7075)],
      ).createShader(const Rect.fromLTWH(0, 0, 480, 84));
    final p = Path()
      ..moveTo(14, 80)
      ..lineTo(14, 10)
      ..lineTo(54, 10)
      ..quadraticBezierTo(74, 10, 74, 29)
      ..quadraticBezierTo(74, 48, 54, 48)
      ..lineTo(14, 48)
      ..moveTo(118, 8)
      ..lineTo(118, 75.5)
      ..lineTo(180, 75.5)
      ..moveTo(204, 82)
      ..lineTo(244, 10)
      ..lineTo(284, 82)
      ..moveTo(302, 14.5)
      ..lineTo(382, 14.5)
      ..moveTo(342, 14.5)
      ..lineTo(342, 82)
      ..moveTo(398, 82)
      ..lineTo(438, 10)
      ..lineTo(478, 82);
    canvas.drawPath(p, pintura);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Las tres ondas del pago sin contacto (igual que el ícono de la demo).
class _SinContacto extends CustomPainter {
  const _SinContacto(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round;
    void arco(double x, double alto) {
      final path = Path()
        ..moveTo(x * s, (12 - alto / 2) * s)
        ..quadraticBezierTo((x + alto * 0.42) * s, 12 * s, x * s, (12 + alto / 2) * s);
      canvas.drawPath(path, p);
    }

    arco(8.5, 9);
    arco(12, 14);
    arco(15.5, 19);
  }

  @override
  bool shouldRepaint(covariant _SinContacto oldDelegate) => oldDelegate.color != color;
}

class _Chip extends StatelessWidget {
  const _Chip({required this.ancho});

  final double ancho;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ancho,
      height: ancho * 10 / 13,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ancho * 0.14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFDCDCDE), Color(0xFF9B9CA0), Color(0xFFCFD0D3)],
        ),
        border: Border.all(color: const Color(0x59FFFFFF)),
      ),
      child: CustomPaint(painter: _LineasChip()),
    );
  }
}

class _LineasChip extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x73282830)
      ..strokeWidth = 1;
    final y1 = size.height * 0.3, y2 = size.height * 0.7, x1 = size.width * 0.32, x2 = size.width * 0.68;
    canvas.drawLine(Offset(0, y1), Offset(size.width, y1), p);
    canvas.drawLine(Offset(0, y2), Offset(size.width, y2), p);
    canvas.drawLine(Offset(x1, 0), Offset(x1, size.height), p);
    canvas.drawLine(Offset(x2, 0), Offset(x2, size.height), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Círculos de la red de pago (rojo, amarillo y el cruce naranja).
class _CirculosRed extends StatelessWidget {
  const _CirculosRed({required this.alto});

  final double alto;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: alto * 1.62, height: alto, child: CustomPaint(painter: _PintaCirculos()));
  }
}

class _PintaCirculos extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.height / 2;
    final izq = Offset(r, r);
    final der = Offset(size.width - r, r);
    canvas.drawCircle(izq, r, Paint()..color = const Color(0xFFEB001B));
    canvas.drawCircle(der, r, Paint()..color = const Color(0xFFF79E1B));
    final cruce = Path.combine(
      PathOperation.intersect,
      Path()..addOval(Rect.fromCircle(center: izq, radius: r)),
      Path()..addOval(Rect.fromCircle(center: der, radius: r)),
    );
    canvas.drawPath(cruce, Paint()..color = const Color(0xFFFF5F00));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Detalle de la tarjeta de pago
// ---------------------------------------------------------------------------

class DetallePago extends StatefulWidget {
  const DetallePago({super.key, required this.pago, required this.titular});

  final PagoDemo pago;
  final String titular;

  @override
  State<DetallePago> createState() => _DetallePagoState();
}

class _DetallePagoState extends State<DetallePago> {
  /// '' nada abierto, 'acercar' pago por acercamiento, 'codigo' código QR.
  String _vista = '';
  String _estadoAcercar = 'esperando';
  String _referencia = '';
  int _restante = 30;
  Timer? _reloj;
  final _azar = math.Random();

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  void _mostrarCodigo() {
    _reloj?.cancel();
    setState(() {
      _vista = 'codigo';
      _nuevaReferencia();
    });
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _restante--;
        if (_restante <= 0) _nuevaReferencia();
      });
    });
  }

  void _nuevaReferencia() {
    final digitos = List.generate(12, (_) => _azar.nextInt(10)).join();
    _referencia = digitos.replaceAllMapped(RegExp(r'(\d{4})(?=\d)'), (m) => '${m[1]} ');
    _restante = 30;
  }

  void _acercar() {
    _reloj?.cancel();
    setState(() {
      _vista = 'acercar';
      _estadoAcercar = 'esperando';
    });
  }

  void _simularCobro() {
    setState(() => _estadoAcercar = 'procesando');
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        widget.pago.saldo -= 250;
        widget.pago.movimientos.insert(0, const MovimientoPago('Copago consulta general', 'Consultorio Centro · hoy', -250));
        _estadoAcercar = 'aprobado';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final pago = widget.pago;
    return _Detalle(
      children: [
        TarjetaPlata(terminacion: pago.terminacion),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Saldo disponible', style: TextStyle(fontFamily: _ui, color: _fg, fontSize: 15)),
                  Text(_dinero(pago.saldo), style: const TextStyle(fontFamily: _num, fontSize: 26, fontWeight: FontWeight.w500, color: _fg, height: 1.1)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _Boton(texto: 'Pagar acercando', primario: true, onPressed: _acercar)),
                  const SizedBox(width: 10),
                  Expanded(child: _Boton(texto: 'Mostrar código', onPressed: _mostrarCodigo)),
                ],
              ),
              if (_vista == 'acercar') _VistaAcercar(estado: _estadoAcercar, saldo: pago.saldo, onSimular: _simularCobro),
              if (_vista == 'codigo') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: [
                      QrImageView(
                        data: 'SOMGPAGO|${pago.terminacion}|${_referencia.replaceAll(' ', '')}',
                        size: 188,
                        padding: EdgeInsets.zero,
                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: _tinta),
                        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: _tinta),
                      ),
                      const SizedBox(height: 8),
                      Text(_referencia, style: const TextStyle(fontFamily: _num, fontSize: 15, letterSpacing: 1.8, color: _tinta)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          width: 188,
                          height: 4,
                          child: LinearProgressIndicator(value: _restante / 30, color: _accent, backgroundColor: const Color(0xFFE3EBE9)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Vence en $_restante s', style: const TextStyle(fontFamily: _ui, fontSize: 12, color: _muted)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Muestre este código en caja o farmacia. Cambia cada 30 segundos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: _ui, fontSize: 12.5, color: _muted),
                ),
              ],
            ],
          ),
        ),
        _Panel(
          titulo: 'Movimientos',
          child: Column(
            children: [
              for (var i = 0; i < pago.movimientos.length; i++)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(border: i == 0 ? null : const Border(top: BorderSide(color: _line))),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pago.movimientos[i].concepto, style: const TextStyle(fontFamily: _ui, fontWeight: FontWeight.w600, color: _fg, fontSize: 15)),
                            Text(pago.movimientos[i].detalle, style: const TextStyle(fontFamily: _ui, fontSize: 12.5, color: _muted)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${pago.movimientos[i].monto > 0 ? '+' : ''}${_dinero(pago.movimientos[i].monto)}',
                        style: const TextStyle(fontFamily: _num, fontWeight: FontWeight.w500, color: _fg, fontSize: 15),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        _Panel(
          titulo: 'Datos de la tarjeta',
          child: _Datos([
            _fila('Titular', widget.titular),
            _fila('Tipo', 'Débito Plata para servicios médicos'),
            _fila('Se usa en', 'Copagos de consulta, farmacia, laboratorio y gabinete de la red'),
            _fila('Vence', '08/29'),
            ('Estado', const _Pastilla('Activa')),
          ]),
        ),
      ],
    );
  }
}

class _VistaAcercar extends StatelessWidget {
  const _VistaAcercar({required this.estado, required this.saldo, required this.onSimular});

  final String estado;
  final double saldo;
  final VoidCallback onSimular;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
      child: Column(
        children: [
          if (estado != 'aprobado') const _Ondas(),
          const SizedBox(height: 10),
          if (estado == 'esperando') ...[
            const Text('Acerque el teléfono a la terminal de la caja', textAlign: TextAlign.center, style: TextStyle(fontFamily: _ui, color: _fg)),
            const SizedBox(height: 10),
            _Boton(texto: r'Simular cobro de copago ($250.00)', onPressed: onSimular),
          ],
          if (estado == 'procesando') const Text('Procesando…', style: TextStyle(fontFamily: _ui, color: _fg)),
          if (estado == 'aprobado') ...[
            const Text('Pago aprobado', style: TextStyle(fontFamily: _ui, color: _ok, fontWeight: FontWeight.w800, fontSize: 18)),
            Text('\$250.00 · Saldo ${_dinero(saldo)}', style: const TextStyle(fontFamily: _ui, color: _fg)),
          ],
        ],
      ),
    );
  }
}

class _Ondas extends StatefulWidget {
  const _Ondas();

  @override
  State<_Ondas> createState() => _OndasState();
}

class _OndasState extends State<_Ondas> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              Builder(builder: (_) {
                final t = (_c.value + i / 3) % 1;
                return Transform.scale(
                  scale: 0.4 + 0.7 * t,
                  child: Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _accent.withValues(alpha: 0.9 * (1 - t)), width: 2)),
                  ),
                );
              }),
            const SizedBox(width: 44, height: 44, child: CustomPaint(painter: _SinContacto(_accent))),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Credencial del derechohabiente
// ---------------------------------------------------------------------------

class CredencialFrente extends StatelessWidget {
  const CredencialFrente({super.key, required this.datos, required this.foto});

  final DatosCredencial datos;
  final Uint8List? foto;

  @override
  Widget build(BuildContext context) {
    final a = datos.aseguradora;
    return AspectRatio(
      aspectRatio: _proporcion,
      child: LayoutBuilder(
        builder: (context, medidas) {
          final s = medidas.maxWidth / 388; // escala respecto a la demo
          return Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFFBFCFC),
              borderRadius: BorderRadius.circular(18 * s),
              boxShadow: const [
                BoxShadow(color: Color(0x14102824), blurRadius: 2, offset: Offset(0, 1)),
                BoxShadow(color: Color(0x1A102824), blurRadius: 24, offset: Offset(0, 8)),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: medidas.maxHeight * 0.34,
                  child: Container(
                    color: a.color,
                    foregroundDecoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-1, -0.2),
                        end: Alignment(1, 0.2),
                        colors: [Color(0x2EFFFFFF), Color(0x00FFFFFF)],
                        stops: [0, 0.6],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(18 * s, 14 * s, 18 * s, 14 * s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: _ui, color: Colors.white, fontSize: 15 * s, fontWeight: FontWeight.w800, height: 1.3)),
                                Text(a.plan, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: _ui, color: const Color(0xE6FFFFFF), fontSize: 11 * s, height: 1.3)),
                              ],
                            ),
                          ),
                          SizedBox(width: 10 * s),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 3 * s),
                            decoration: BoxDecoration(color: const Color(0x38FFFFFF), borderRadius: BorderRadius.circular(999)),
                            child: Text('TITULAR', style: TextStyle(fontFamily: _ui, color: Colors.white, fontSize: 10 * s, fontWeight: FontWeight.w700, letterSpacing: 0.8 * s)),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _Retrato(foto: foto, color: a.color, suave: a.suave, ancho: 64 * s),
                          SizedBox(width: 12 * s),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(datos.nombre, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: _ui, color: _tinta, fontSize: 15 * s, fontWeight: FontWeight.w800, height: 1.2)),
                                SizedBox(height: 6 * s),
                                Wrap(
                                  spacing: 14 * s,
                                  runSpacing: 2 * s,
                                  children: [
                                    _DatoCredencial(etiqueta: 'Afiliado', valor: datos.afiliado, s: s),
                                    _DatoCredencial(etiqueta: 'Póliza', valor: datos.poliza, s: s),
                                    _DatoCredencial(etiqueta: 'Sangre', valor: datos.sangre, s: s),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class CredencialReverso extends StatelessWidget {
  const CredencialReverso({super.key, required this.datos});

  final DatosCredencial datos;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _proporcion,
      child: LayoutBuilder(
        builder: (context, medidas) {
          final s = medidas.maxWidth / 388;
          Widget mini(String etiqueta, String valor) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(etiqueta.toUpperCase(), style: TextStyle(fontFamily: _ui, fontSize: 9 * s, fontWeight: FontWeight.w700, letterSpacing: 0.72 * s, color: _tintaSuave)),
                  Text(valor, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: _ui, fontSize: 11.5 * s, color: _tinta, height: 1.3)),
                ],
              );
          return Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFFBFCFC),
              borderRadius: BorderRadius.circular(18 * s),
              boxShadow: const [
                BoxShadow(color: Color(0x14102824), blurRadius: 2, offset: Offset(0, 1)),
                BoxShadow(color: Color(0x1A102824), blurRadius: 24, offset: Offset(0, 8)),
              ],
            ),
            child: Stack(
              children: [
                Positioned(left: 0, right: 0, bottom: 0, height: 8 * s, child: ColoredBox(color: datos.aseguradora.color)),
                Padding(
                  padding: EdgeInsets.fromLTRB(18 * s, 14 * s, 18 * s, 14 * s),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            mini('Vigencia', datos.vigencia),
                            SizedBox(height: 5 * s),
                            mini('Alergias', datos.alergias),
                            SizedBox(height: 5 * s),
                            mini('Emergencia', datos.emergencia),
                            SizedBox(height: 5 * s),
                            mini('Cabina de la aseguradora', datos.aseguradora.cabina),
                          ],
                        ),
                      ),
                      SizedBox(width: 12 * s),
                      QrImageView(
                        data: datos.codigo,
                        size: 104 * s,
                        padding: EdgeInsets.zero,
                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: _tinta),
                        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: _tinta),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DatoCredencial extends StatelessWidget {
  const _DatoCredencial({required this.etiqueta, required this.valor, required this.s});

  final String etiqueta;
  final String valor;
  final double s;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(etiqueta.toUpperCase(), style: TextStyle(fontFamily: _ui, color: _tintaSuave, fontSize: 9 * s, fontWeight: FontWeight.w600, letterSpacing: 0.8 * s, height: 1.3)),
        Text(valor, style: TextStyle(fontFamily: _num, color: _tinta, fontSize: 12 * s, fontWeight: FontWeight.w500, height: 1.3)),
      ],
    );
  }
}

/// Foto del derechohabiente (formato de credencial). Sin foto se ve una silueta.
class _Retrato extends StatelessWidget {
  const _Retrato({required this.foto, required this.color, required this.suave, required this.ancho, this.borde = true});

  final Uint8List? foto;
  final Color color;
  final Color suave;
  final double ancho;
  final bool borde;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ancho,
      height: ancho * 76 / 64,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: suave,
        borderRadius: BorderRadius.circular(ancho * 10 / 64),
        border: borde ? Border.all(color: Colors.white, width: ancho * 3 / 64) : null,
        boxShadow: borde ? const [BoxShadow(color: Color(0x2E000000), blurRadius: 6, offset: Offset(0, 2))] : null,
      ),
      child: foto == null
          ? Align(alignment: Alignment.bottomCenter, child: SizedBox(width: ancho * 0.8, height: ancho * 0.8, child: CustomPaint(painter: _Silueta(color))))
          : Image.memory(foto!, fit: BoxFit.cover, gaplessPlayback: true),
    );
  }
}

class _Silueta extends CustomPainter {
  const _Silueta(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final p = Paint()..color = color;
    canvas.drawCircle(Offset(12 * s, 8.5 * s), 4.2 * s, p);
    final cuerpo = Path()
      ..moveTo(3.5 * s, 24 * s)
      ..cubicTo(3.5 * s, 18.8 * s, 7.3 * s, 15.4 * s, 12 * s, 15.4 * s)
      ..cubicTo(16.7 * s, 15.4 * s, 20.5 * s, 18.8 * s, 20.5 * s, 24 * s)
      ..close();
    canvas.drawPath(cuerpo, p);
  }

  @override
  bool shouldRepaint(covariant _Silueta oldDelegate) => oldDelegate.color != color;
}

/// Lee la foto guardada en el teléfono para ese expediente y la entrega al [builder].
class _FotoPaciente extends StatefulWidget {
  const _FotoPaciente({required this.expediente, required this.builder});

  final String expediente;
  final Widget Function(Uint8List? foto) builder;

  @override
  State<_FotoPaciente> createState() => _FotoPacienteState();
}

class _FotoPacienteState extends State<_FotoPaciente> {
  Uint8List? _foto;

  void _leer() {
    FotoCredencial.leer(widget.expediente).then((foto) {
      if (mounted) setState(() => _foto = foto);
    });
  }

  @override
  void initState() {
    super.initState();
    _leer();
  }

  @override
  void didUpdateWidget(covariant _FotoPaciente oldWidget) {
    super.didUpdateWidget(oldWidget);
    _leer();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_foto);
}

/// La foto de la credencial se guarda solo en el teléfono, por expediente.
class FotoCredencial {
  static String _clave(String expediente) => 'sisco_foto_credencial_$expediente';

  static Future<Uint8List?> leer(String expediente) async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_clave(expediente));
    if (texto == null || texto.isEmpty) return null;
    try {
      return base64Decode(texto);
    } catch (_) {
      return null;
    }
  }

  static Future<void> guardar(String expediente, Uint8List? bytes) async {
    final prefs = await SharedPreferences.getInstance();
    if (bytes == null) {
      await prefs.remove(_clave(expediente));
    } else {
      await prefs.setString(_clave(expediente), base64Encode(bytes));
    }
  }
}

// ---------------------------------------------------------------------------
// Detalle de la credencial
// ---------------------------------------------------------------------------

class DetalleCredencial extends StatefulWidget {
  const DetalleCredencial({super.key, required this.paciente, required this.aseguradoraInicial, required this.alCambiarAseguradora});

  final Paciente paciente;
  final Aseguradora aseguradoraInicial;
  final ValueChanged<Aseguradora> alCambiarAseguradora;

  @override
  State<DetalleCredencial> createState() => _DetalleCredencialState();
}

class _DetalleCredencialState extends State<DetalleCredencial> with SingleTickerProviderStateMixin {
  late final AnimationController _giro = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  late Aseguradora _aseguradora = widget.aseguradoraInicial;
  Uint8List? _foto;

  @override
  void initState() {
    super.initState();
    FotoCredencial.leer(TarjetaDerechohabiente.de(widget.paciente).expediente).then((foto) {
      if (mounted) setState(() => _foto = foto);
    });
  }

  @override
  void dispose() {
    _giro.dispose();
    super.dispose();
  }

  void _voltear() {
    if (_giro.value < 0.5) {
      _giro.forward();
    } else {
      _giro.reverse();
    }
  }

  Future<void> _elegirFoto(String expediente) async {
    final resultado = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    final bytes = resultado?.files.firstOrNull?.bytes;
    if (bytes == null) return;
    if (bytes.lengthInBytes > 2 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La foto pesa más de 2 MB. Elija una más ligera.')));
      return;
    }
    await FotoCredencial.guardar(expediente, bytes);
    if (mounted) setState(() => _foto = bytes);
  }

  Future<void> _quitarFoto(String expediente) async {
    await FotoCredencial.guardar(expediente, null);
    if (mounted) setState(() => _foto = null);
  }

  @override
  Widget build(BuildContext context) {
    final store = ConsultorioScope.of(context);
    final d = DatosCredencial.de(store, widget.paciente, _aseguradora);
    final a = d.aseguradora;
    return _Detalle(
      children: [
        Column(
          children: [
            GestureDetector(
              onTap: _voltear,
              child: AnimatedBuilder(
                animation: _giro,
                builder: (context, _) {
                  final t = Curves.easeOutCubic.transform(_giro.value);
                  final angulo = t * math.pi;
                  final reverso = angulo > math.pi / 2;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 1 / 1200)
                      ..rotateY(angulo),
                    child: reverso
                        ? Transform(alignment: Alignment.center, transform: Matrix4.rotationY(math.pi), child: CredencialReverso(datos: d))
                        : CredencialFrente(datos: d, foto: _foto),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Toque la credencial para ver el reverso con el código de identificación.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: _ui, fontSize: 12.5, color: _muted),
            ),
          ],
        ),
        _Panel(
          titulo: 'Foto del derechohabiente',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _Retrato(foto: _foto, color: _accent, suave: _accentSoft, ancho: 64, borde: false),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Boton(texto: 'Elegir foto', primario: true, onPressed: () => _elegirFoto(d.tarjeta.expediente)),
                        _Boton(texto: 'Quitar', onPressed: () => _quitarFoto(d.tarjeta.expediente)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'La foto solo se guarda en este teléfono para la demo y aparece únicamente en la credencial.',
                style: TextStyle(fontFamily: _ui, fontSize: 12.5, color: _muted),
              ),
            ],
          ),
        ),
        _Panel(
          titulo: 'Aseguradora (cambie para ver cómo se ve)',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final x in aseguradorasDemo)
                Material(
                  color: x.id == a.id ? _accent : _surface2,
                  shape: StadiumBorder(side: BorderSide(color: x.id == a.id ? _accent : _line)),
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: () {
                      setState(() => _aseguradora = x);
                      widget.alCambiarAseguradora(x);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Text(
                        x.nombre,
                        style: TextStyle(fontFamily: _ui, fontSize: 13, fontWeight: FontWeight.w600, color: x.id == a.id ? Colors.white : _fg),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        _Panel(
          titulo: 'Datos del paciente',
          child: _Datos([
            _fila('Nombre', d.nombre),
            if (d.nacimiento.isNotEmpty) _fila('Nacimiento', d.nacimiento),
            if (d.tarjeta.sexo.isNotEmpty) _fila('Sexo', d.tarjeta.sexo),
            _fila('Tipo de sangre', d.sangre),
            ('Alergias', _Pastilla(d.alergias, alerta: d.tarjeta.alergias.isNotEmpty)),
            if (d.medico.isNotEmpty) _fila('Médico asignado', d.medico),
            if (d.consultorio.isNotEmpty) _fila('Consultorio', d.consultorio),
            _fila('Emergencia', d.emergencia),
          ]),
        ),
        _Panel(
          titulo: 'Cobertura',
          child: _Datos([
            _fila('Aseguradora', a.nombre),
            _fila('Plan', a.plan),
            _fila('Póliza', d.poliza),
            _fila('Certificado', d.certificado),
            _fila('Vigencia', d.vigencia),
            _fila('Deducible', a.deducible),
            _fila('Coaseguro', a.coaseguro),
            _fila('Suma asegurada', a.tope),
            _fila('Cabina 24 h', a.cabina),
            ('Estado', _Pastilla(d.tarjeta.cubierta ? 'Vigente' : 'Vencida', alerta: !d.tarjeta.cubierta)),
          ]),
        ),
      ],
    );
  }
}
