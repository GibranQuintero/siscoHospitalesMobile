import 'package:flutter/material.dart';

import 'enlaces.dart';
import 'models/consultorio.dart';
import 'services/consultorio_api.dart';
import 'state/consultorio_store.dart';

Future<void> crearOAbrirMeet(BuildContext context, Cita cita) async {
  final store = ConsultorioScope.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  try {
    final url = await store.salaMeet(cita);
    if (context.mounted) Navigator.of(context).pop();
    if (context.mounted) await abrirSiPuede(context, url);
  } on ConsultorioException catch (e) {
    if (context.mounted) Navigator.of(context).pop();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensaje)));
    }
  } catch (_) {
    if (context.mounted) Navigator.of(context).pop();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir Meet.')));
    }
  }
}

Future<void> llamarACat(BuildContext context) async {
  final store = ConsultorioScope.of(context);
  final telefono = store.telefonoParaCat;
  if (telefono.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configura el teléfono de CAT en Conexión.')),
    );
    return;
  }
  await abrirSiPuede(context, enlaceTelefono(telefono));
}
