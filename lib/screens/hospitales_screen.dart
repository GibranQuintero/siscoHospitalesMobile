import 'package:flutter/material.dart';

import '../enlaces.dart';
import '../state/consultorio_store.dart';
import '../formato.dart';
import '../models/consultorio.dart';
import '../theme/sisco_theme.dart';
import '../widgets/comun.dart';

class HospitalesScreen extends StatefulWidget {
  const HospitalesScreen({super.key});

  @override
  State<HospitalesScreen> createState() => _HospitalesScreenState();
}

class _HospitalesScreenState extends State<HospitalesScreen> {
  String _tipo = '';
  final _busqueda = TextEditingController();

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ConsultorioScope.of(context);
    final consulta = limpio(_busqueda.text.trim());
    final hospitales = store.hospitales.where((hospital) {
      if (_tipo.isNotEmpty && hospital.tipo != _tipo) return false;
      if (consulta.isEmpty) return true;
      return limpio('${hospital.nombre} ${hospital.ciudad}').contains(consulta);
    }).toList();

    return RefreshIndicator(
      color: azul,
      onRefresh: store.cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Text('Red hospitalaria', style: TextStyle(color: marino, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('${store.hospitales.length} sedes · ${store.medicos.length} médicos', style: const TextStyle(color: suave)),
          const SizedBox(height: 12),
          TextField(
            controller: _busqueda,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'Buscar sede o ciudad', prefixIcon: Icon(Icons.search)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final opcion in const [('', 'Todas'), ('sucursal', 'Sucursales'), ('matriz', 'Matrices'), ('aseguradora', 'Aseguradoras')])
                ChoiceChip(
                  label: Text(opcion.$2),
                  selected: _tipo == opcion.$1,
                  onSelected: (_) => setState(() => _tipo = opcion.$1),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (store.cargando && store.hospitales.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 28), child: Center(child: CircularProgressIndicator()))
          else if (hospitales.isEmpty)
            const AvisoVacio(texto: 'No hay sedes con ese criterio.')
          else
            for (final hospital in hospitales)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _HospitalTarjeta(
                  hospital: hospital,
                  especialidades: hospital.especialidades.map(store.nombreEspecialidad).where((nombre) => nombre.isNotEmpty).take(4).join(', '),
                  medicos: store.medicosDe(hospital.id).length,
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => HospitalDetalleScreen(hospitalId: hospital.id)));
                  },
                ),
              ),
        ],
      ),
    );
  }
}

class _HospitalTarjeta extends StatelessWidget {
  const _HospitalTarjeta({
    required this.hospital,
    required this.especialidades,
    required this.medicos,
    required this.onTap,
  });

  final HospitalRed hospital;
  final String especialidades;
  final int medicos;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          decoration: tarjeta(),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(hospital.nombre, style: const TextStyle(color: texto, fontWeight: FontWeight.w800, fontSize: 16))),
                  if (hospital.convenio) const Icon(Icons.verified_outlined, color: azul, size: 18),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                [etiquetaTipoHospital(hospital.tipo), hospital.ciudad, etiquetaNivel(hospital.nivel)].where((parte) => parte.isNotEmpty).join(' · '),
                style: const TextStyle(color: suave, fontSize: 13),
              ),
              if (especialidades.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(especialidades, style: const TextStyle(color: acero, fontSize: 13)),
              ],
              if (medicos > 0) Text('$medicos médicos en esta sede', style: const TextStyle(color: suave, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class HospitalDetalleScreen extends StatelessWidget {
  const HospitalDetalleScreen({super.key, required this.hospitalId});

  final String hospitalId;

  @override
  Widget build(BuildContext context) {
    final store = ConsultorioScope.of(context);
    final hospital = store.hospitalPorId(hospitalId);
    final medicos = store.medicosDe(hospitalId);

    return Scaffold(
      appBar: AppBar(title: const Text('Sede')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (hospital == null)
            const AvisoVacio(texto: 'Esta sede ya no está en la red.')
          else ...[
            Text(hospital.nombre, style: const TextStyle(color: marino, fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: tarjeta(),
              child: Column(
                children: [
                  DatoFila(etiqueta: 'Tipo', valor: etiquetaTipoHospital(hospital.tipo)),
                  DatoFila(etiqueta: 'Ciudad', valor: hospital.ciudad),
                  DatoFila(etiqueta: 'Nivel', valor: etiquetaNivel(hospital.nivel)),
                  DatoFila(etiqueta: 'Camas', valor: hospital.camas == null ? '' : '${hospital.camas}'),
                  DatoFila(etiqueta: 'Quirófanos', valor: hospital.quirofanos == null ? '' : '${hospital.quirofanos}'),
                  DatoFila(etiqueta: 'Dirección', valor: hospital.direccion),
                  DatoFila(
                    etiqueta: 'Teléfono',
                    valor: hospital.telefono,
                    onTap: hospital.telefono.isEmpty ? null : () => abrirSiPuede(context, enlaceTelefono(hospital.telefono)),
                  ),
                  DatoFila(etiqueta: 'Correo', valor: hospital.correo, onTap: hospital.correo.isEmpty ? null : () => abrirSiPuede(context, 'mailto:${hospital.correo}')),
                  DatoFila(etiqueta: 'Convenio', valor: hospital.convenio ? 'Sí' : 'No'),
                ],
              ),
            ),
            if (hospital.especialidades.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(hospital.especialidades.map(store.nombreEspecialidad).join(', '), style: const TextStyle(color: texto, height: 1.4)),
            ],
            const SizedBox(height: 16),
            const Text('Médicos', style: TextStyle(color: marino, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if (medicos.isEmpty)
              const AvisoVacio(texto: 'No hay médicos ligados a esta sede.')
            else
              for (final medico in medicos)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: tarjeta(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(medico.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w700, color: texto)),
                        Text(
                          [medico.esEspecialista ? medico.especialidad : 'Medicina general', medico.cedula.isEmpty ? '' : 'cédula ${medico.cedula}']
                              .where((parte) => parte.isNotEmpty)
                              .join(' · '),
                          style: const TextStyle(color: suave, fontSize: 13),
                        ),
                        if (medico.telefono.isNotEmpty)
                          TextButton(
                            onPressed: () => abrirSiPuede(context, enlaceTelefono(medico.telefono)),
                            child: Text(medico.telefono),
                          ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
