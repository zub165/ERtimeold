// Smoke test: default counter template does not match this app.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:er_wait_time_flutter/main.dart';
import 'package:er_wait_time_flutter/screens/splash_screen.dart';

void main() {
  testWidgets('MyApp builds and shows splash shell', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
