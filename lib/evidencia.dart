import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'theme/sisco_theme.dart';

/// Elige un archivo local y devuelve su nombre. El contenido no sale del teléfono.
Future<String?> pedirEvidencia(BuildContext context) async {
  try {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    );
    final nombre = resultado?.files.single.name.trim() ?? '';
    if (nombre.isNotEmpty) return nombre;
    return null;
  } catch (_) {
    if (!context.mounted) return null;
    return _pedirNombre(context);
  }
}

Future<String?> _pedirNombre(BuildContext context) async {
  final controlador = TextEditingController();
  final nombre = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Adjuntar evidencia'),
      content: TextField(
        controller: controlador,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Nombre del archivo, por ejemplo resultado.pdf'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        TextButton(
          onPressed: () => Navigator.pop(context, controlador.text.trim()),
          child: const Text('Adjuntar', style: TextStyle(color: azul)),
        ),
      ],
    ),
  );
  controlador.dispose();
  if (nombre == null || nombre.isEmpty) return null;
  return nombre;
}
