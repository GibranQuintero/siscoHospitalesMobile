import 'package:flutter/material.dart';

import '../acciones_cita.dart';
import '../enlaces.dart';
import '../formato.dart';
import '../state/consultorio_store.dart';
import '../theme/sisco_theme.dart';
import '../widgets/comun.dart';

void abrirExpediente(BuildContext context, String pacienteId) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExpedienteScreen(pacienteId: pacienteId)));
}

class ExpedienteScreen extends StatelessWidget {
  const ExpedienteScreen({super.key, required this.pacienteId});

  final String pacienteId;

  @override
  Widget build(BuildContext context) {
    final store = ConsultorioScope.of(context);
    final paciente = store.porId(pacienteId);
    final citas = store.citasDe(pacienteId);

    return Scaffold(
      appBar: AppBar(title: const Text('Expediente')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (paciente == null)
            const AvisoVacio(texto: 'Este expediente ya no está en el consultorio.')
          else ...[
            Text(paciente.nombreCompleto, style: const TextStyle(color: marino, fontSize: 24, fontWeight: FontWeight.w800)),
            if (paciente.alias.isNotEmpty) Text(paciente.alias, style: const TextStyle(color: suave)),
            const SizedBox(height: 14),
            _Bloque(
              titulo: 'Ficha',
              child: Column(
                children: [
                  DatoFila(etiqueta: 'CURP', valor: paciente.curp),
                  DatoFila(etiqueta: 'Sexo', valor: paciente.sexo),
                  DatoFila(etiqueta: 'Nacimiento', valor: paciente.fechaNacimiento.isEmpty ? '' : fechaDia(paciente.fechaNacimiento)),
                  DatoFila(etiqueta: 'Sangre', valor: paciente.tipoSangre),
                  DatoFila(etiqueta: 'Ocupación', valor: paciente.ocupacion),
                  DatoFila(etiqueta: 'Dirección', valor: paciente.direccion),
                  DatoFila(
                    etiqueta: 'Teléfono',
                    valor: paciente.telefono,
                    onTap: paciente.telefono.isEmpty ? null : () => abrirSiPuede(context, enlaceTelefono(paciente.telefono)),
                  ),
                  DatoFila(etiqueta: 'Correo', valor: paciente.correo, onTap: paciente.correo.isEmpty ? null : () => abrirSiPuede(context, 'mailto:${paciente.correo}')),
                ],
              ),
            ),
            if (paciente.alergias.isNotEmpty) ...[
              const SizedBox(height: 12),
              _Bloque(
                titulo: 'Alergias',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final alergia in paciente.alergias)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(999)),
                        child: Text(alergia, style: const TextStyle(color: Color(0xFF9A3412), fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),
            ],
            if (paciente.seguros.isNotEmpty) ...[
              const SizedBox(height: 12),
              _Bloque(
                titulo: 'Seguros',
                child: Column(
                  children: [
                    for (final seguro in paciente.seguros)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(seguro.aseguradora, style: const TextStyle(fontWeight: FontWeight.w700, color: texto)),
                            Text(
                              [seguro.certificado, seguro.vigenciaHasta.isEmpty ? '' : 'vigente al ${fechaDia(seguro.vigenciaHasta)}']
                                  .where((parte) => parte.isNotEmpty)
                                  .join(' · '),
                              style: const TextStyle(color: suave, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (paciente.contactos.isNotEmpty) ...[
              const SizedBox(height: 12),
              _Bloque(
                titulo: 'Contactos',
                child: Column(
                  children: [
                    for (final contacto in paciente.contactos)
                      DatoFila(
                        etiqueta: contacto.parentesco.isEmpty ? 'Contacto' : contacto.parentesco,
                        valor: [contacto.nombre, contacto.telefono].where((parte) => parte.isNotEmpty).join(' · '),
                        onTap: contacto.telefono.isEmpty ? null : () => abrirSiPuede(context, enlaceTelefono(contacto.telefono)),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            _Bloque(
              titulo: 'Citas',
              child: citas.isEmpty
                  ? const Text('Sin citas registradas.', style: TextStyle(color: suave))
                  : Column(
                      children: [
                        for (final cita in citas.take(8))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: CitaTarjeta(
                              cita: cita,
                              paciente: paciente.nombreCompleto,
                              meetListo: store.enlaceMeet(cita).isNotEmpty,
                              onMeet: () => crearOAbrirMeet(context, cita),
                              onCat: () => llamarACat(context),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Bloque extends StatelessWidget {
  const _Bloque({required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: tarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(color: acero, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
