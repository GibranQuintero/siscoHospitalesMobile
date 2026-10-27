import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'enlaces.dart';
import 'models/consultorio.dart';
import 'services/consultorio_api.dart';
import 'state/consultorio_store.dart';
import 'theme/sisco_theme.dart';

Future<void> crearOAbrirMeet(BuildContext context, Cita cita) async {
  final store = ConsultorioScope.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  var dialogo = true;
  try {
    final url = await store.salaMeet(cita);
    if (context.mounted) Navigator.of(context).pop();
    dialogo = false;
    if (!context.mounted) return;
    final modo = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => _HojaMeet(url: url),
    );
    if (!context.mounted || modo == null) return;
    if (modo == 'telefono' || modo == 'ambos') {
      await abrirSiPuede(context, url);
    }
    if (!context.mounted) return;
    if (modo == 'escritorio' || modo == 'ambos') {
      await store.abrirEnEscritorio(url);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La sesión de escritorio se abrió en este equipo.')),
        );
      }
    }
  } on ConsultorioException catch (e) {
    if (dialogo && context.mounted) Navigator.of(context).pop();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensaje)));
    }
  } catch (_) {
    if (dialogo && context.mounted) Navigator.of(context).pop();
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

class _HojaMeet extends StatelessWidget {
  const _HojaMeet({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final partes = url.split('/').where((parte) => parte.isNotEmpty).toList();
    final codigo = partes.isEmpty ? url : partes.last;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Videollamada', style: TextStyle(color: marino, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('La sala $codigo queda lista en el teléfono y en el escritorio de este equipo.', style: const TextStyle(color: suave)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, 'ambos'),
              icon: const Icon(Icons.video_call_outlined),
              label: const Text('Teléfono y escritorio'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context, 'telefono'),
              icon: const Icon(Icons.smartphone_outlined),
              label: const Text('Solo en este teléfono'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context, 'escritorio'),
              icon: const Icon(Icons.desktop_windows_outlined),
              label: const Text('Solo sesión de escritorio'),
            ),
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: url));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enlace copiado.')));
                }
              },
              child: const Text('Copiar enlace'),
            ),
          ],
        ),
      ),
    );
  }
}
