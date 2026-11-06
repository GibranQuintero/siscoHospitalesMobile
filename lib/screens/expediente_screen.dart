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
    final edad = paciente == null ? null : edadCumplida(paciente.fechaNacimiento);

    return Scaffold(
      appBar: const BarraGradiente(titulo: 'Expediente'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          if (paciente == null)
            const AvisoVacio(texto: 'Este expediente ya no está en el consultorio.')
          else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: tarjeta(),
              child: Row(
                children: [
                  AvatarIniciales(iniciales: inicialesDe(paciente.nombre, paciente.apellido), gradiente: gradientePaciente),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PACIENTE ACTIVO', style: TextStyle(color: cian, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                        Text(paciente.nombreCompleto, style: const TextStyle(color: texto, fontSize: 20, fontWeight: FontWeight.w800)),
                        Text('Nº Expediente: ${paciente.id}', style: const TextStyle(color: suave, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (paciente.alergias.isNotEmpty) ...[
              const SizedBox(height: 12),
              FichaBloque(
                titulo: 'ALERGIAS CONOCIDAS',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final alergia in paciente.alergias)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(999)),
                        child: Text(alergia, style: const TextStyle(color: Color(0xFFBE123C), fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            FichaBloque(
              titulo: 'FICHA DE IDENTIFICACIÓN',
              child: Column(
                children: [
                  DatoFila(etiqueta: 'CURP', valor: paciente.curp),
                  DatoFila(etiqueta: 'SEXO', valor: paciente.sexo),
                  DatoFila(etiqueta: 'GRUPO SANGUÍNEO', valor: paciente.tipoSangre),
                  DatoFila(
                    etiqueta: 'NACIMIENTO',
                    valor: paciente.fechaNacimiento.isEmpty
                        ? ''
                        : '${fechaDia(paciente.fechaNacimiento)}${edad == null ? '' : ' · $edad años cumplidos'}',
                  ),
                  DatoFila(etiqueta: 'OCUPACIÓN', valor: paciente.ocupacion),
                  DatoFila(etiqueta: 'DIRECCIÓN', valor: paciente.direccion),
                  DatoFila(
                    etiqueta: 'TELÉFONO',
                    valor: paciente.telefono,
                    onTap: paciente.telefono.isEmpty ? null : () => abrirSiPuede(context, enlaceTelefono(paciente.telefono)),
                  ),
                  DatoFila(etiqueta: 'CORREO', valor: paciente.correo, onTap: paciente.correo.isEmpty ? null : () => abrirSiPuede(context, 'mailto:${paciente.correo}')),
                ],
              ),
            ),
            if (paciente.seguros.isNotEmpty) ...[
              const SizedBox(height: 12),
              FichaBloque(
                titulo: 'PÓLIZA Y SEGUROS',
                child: Column(
                  children: [
                    for (final seguro in paciente.seguros)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(seguro.aseguradora, style: const TextStyle(fontWeight: FontWeight.w700, color: texto))),
                                const Text('Vigente', style: TextStyle(color: exito, fontSize: 12, fontWeight: FontWeight.w700)),
                              ],
                            ),
                            Text(
                              [if (seguro.certificado.isNotEmpty) 'Póliza: ${seguro.certificado}', if (seguro.vigenciaHasta.isNotEmpty) 'Vigencia hasta ${fechaDia(seguro.vigenciaHasta)}']
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
              FichaBloque(
                titulo: 'CONTACTO DE EMERGENCIA',
                child: Column(
                  children: [
                    for (final contacto in paciente.contactos)
                      DatoFila(
                        etiqueta: contacto.parentesco.isEmpty ? 'CONTACTO' : contacto.parentesco.toUpperCase(),
                        valor: [contacto.nombre, contacto.telefono].where((parte) => parte.isNotEmpty).join(' · '),
                        onTap: contacto.telefono.isEmpty ? null : () => abrirSiPuede(context, enlaceTelefono(contacto.telefono)),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            FichaBloque(
              titulo: 'HISTORIAL DE CITAS',
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
