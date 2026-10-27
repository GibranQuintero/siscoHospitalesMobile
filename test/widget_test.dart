import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sisco_hospitales_mobile/main.dart';

void main() {
  testWidgets('administración abre la red hospitalaria', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SiscoApp(autoCargar: false, omitirLogin: true));
    expect(find.text('Elige un módulo'), findsOneWidget);

    await tester.tap(find.text('Administración'));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Hospitales')));
    await tester.pump();
    expect(find.text('Red hospitalaria'), findsOneWidget);
  });
}
