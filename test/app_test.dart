import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kumi/main.dart';
import 'package:kumi/screens/home_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('app boots through the splash into the home screen',
      (tester) async {
    await tester.pumpWidget(const KumiApp());
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('home screen renders the discovery shell', (tester) async {
    await tester.pumpWidget(const KumiApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Kumi'), findsWidgets);
    expect(find.text('Movies'), findsOneWidget);
    expect(find.text('Series'), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byIcon(Icons.search_outlined), findsWidgets);
  });
}
