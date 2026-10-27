import 'package:flutter/material.dart';

import '../services/consultorio_api.dart';
import '../services/sesion.dart';
import '../state/consultorio_store.dart';
import '../theme/sisco_theme.dart';

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  final _base = TextEditingController();
  final _cat = TextEditingController();
  var _listo = false;

  @override
  void initState() {
    super.initState();
    Future.wait([ApiConfig.leer(), Sesion.leerTelefonoCat()]).then((valores) {
      if (!mounted) return;
      _base.text = valores[0];
      _cat.text = valores[1];
      setState(() => _listo = true);
    });
  }

  @override
  void dispose() {
    _base.dispose();
    _cat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ConsultorioScope.of(context);
    final sugerida = ApiConfig.porPlataforma();

    return Scaffold(
      appBar: AppBar(title: const Text('Conexión')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Dirección de SISCOAPI', style: TextStyle(color: marino, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text(
            'El consultorio móvil lee los mismos controladores que la web. En un teléfono, esta computadora es http://172.16.21.170:5112/. El teléfono tiene que estar en la misma red Wi-Fi.',
            style: TextStyle(color: suave, height: 1.4),
          ),
          const SizedBox(height: 16),
          const Text('Teléfono de CAT', style: TextStyle(color: marino, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text(
            'Llamar a CAT marca este número. Si lo dejas vacío, se usa el teléfono de la cuenta del consultorio.',
            style: TextStyle(color: suave, height: 1.4),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cat,
            enabled: _listo,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Teléfono CAT'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: !_listo
                ? null
                : () async {
                    await store.guardarTelefonoCat(_cat.text);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Teléfono de CAT guardado.')));
                    }
                  },
            child: const Text('Guardar teléfono de CAT'),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _base,
            enabled: _listo && !store.cargando,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(hintText: sugerida, labelText: 'URL base'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: !_listo || store.cargando
                ? null
                : () async {
                    if (_base.text.trim().isEmpty) return;
                    await store.guardarOrigen(_base.text);
                    if (context.mounted) Navigator.of(context).pop();
                  },
            child: const Text('Guardar y recargar'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: store.cargando
                ? null
                : () async {
                    await store.restaurarOrigen();
                    if (context.mounted) Navigator.of(context).pop();
                  },
            child: Text('Usar la dirección de este dispositivo ($sugerida)'),
          ),
        ],
      ),
    );
  }
}
