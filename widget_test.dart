// This is a basic Flutter widget test for EntrenaFísico.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:entrenamiento_fisico/main.dart';
import 'package:entrenamiento_fisico/providers/app_provider.dart';

void main() {
  testWidgets('App starts and shows login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    // Verify login screen is shown
    expect(find.text('EntrenaFísico'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });
}