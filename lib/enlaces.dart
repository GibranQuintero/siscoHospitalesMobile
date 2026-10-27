import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> abrirSiPuede(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  final abrio = uri != null && await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!abrio && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el enlace.')));
  }
}

String enlaceTelefono(String numero) {
  final limpio = numero.replaceAll(RegExp(r'[^\d+]'), '');
  return 'tel:$limpio';
}
