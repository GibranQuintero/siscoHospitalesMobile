import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sisco_hospitales_mobile/main.dart';

void main() {
  testWidgets('administración abre la red hospitalaria', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SiscoApp(autoCargar: false, omitirLogin: true));
    expect(find.text('Elige un módulo'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Administración'), 200);
    await tester.tap(find.text('Administración'));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Hospitales')));
    await tester.pump();
    expect(find.text('Red hospitalaria'), findsOneWidget);
  });

  testWidgets('el login abre la selección de perfil sin llamar al servicio', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SiscoApp(autoCargar: false));
    expect(find.text('Iniciar sesión'), findsOneWidget);

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();
    expect(find.text('Elige un módulo'), findsOneWidget);

    await tester.tap(find.text('Derechohabientes'));
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Tu consultorio'), findsOneWidget);
  });

  testWidgets('recepción confirma una cita del día', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const SiscoApp(autoCargar: false));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    final tarjeta = find.text('Agenda del día, llegadas y pase con el doctor.');
    await tester.scrollUntilVisible(tarjeta, 200);
    await tester.tap(tarjeta);
    await tester.pumpAndSettle();
    expect(find.text('POR ATENDER'), findsOneWidget);

    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Llegadas')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar cita').hitTestable());
    await tester.pump();
    expect(find.text('Confirmar cita'), findsNothing);
    expect(find.text('Cita confirmada'), findsOneWidget);
  });

  testWidgets('farmacia abre la receta local', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const SiscoApp(autoCargar: false));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    final tarjeta = find.text('Aprueba el surtido de cada medicamento y adjunta la evidencia.');
    await tester.scrollUntilVisible(tarjeta, 200);
    await tester.tap(tarjeta);
    await tester.pumpAndSettle();
    expect(find.text('Abrir receta'), findsWidgets);

    await tester.tap(find.text('Abrir receta').first);
    await tester.pumpAndSettle();
    expect(find.text('Losartán'), findsOneWidget);
    expect(find.text('Subir evidencia'), findsWidgets);
  });
}
