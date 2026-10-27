import 'package:flutter_test/flutter_test.dart';
import 'package:sisco_hospitales_mobile/main.dart';

void main() {
  testWidgets('el consultorio abre en Inicio', (tester) async {
    await tester.pumpWidget(const SiscoApp(autoCargar: false, omitirLogin: true));
    expect(find.text('Consultorio'), findsOneWidget);
    expect(find.text('SISCO HOSPITALES'), findsOneWidget);

    await tester.tap(find.text('Hospitales'));
    await tester.pump();
    expect(find.text('Red hospitalaria'), findsOneWidget);
  });
}
