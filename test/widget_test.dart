import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pc_app/data/firebase_state.dart';
import 'package:pc_app/main.dart';
import 'package:pc_app/screens/root_shell.dart';

void main() {
  testWidgets('App renders root shell when Firebase is unavailable', (
    WidgetTester tester,
  ) async {
    firebaseAvailable = false;

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(RootShell), findsOneWidget);
  });
}
