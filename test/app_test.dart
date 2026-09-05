import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kumi/main.dart';
import 'package:kumi/screens/home_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> boot(WidgetTester tester) async {
    await tester.pumpWidget(const KumiApp());
    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('app boots through the splash into the home screen',
      (tester) async {
    await boot(tester);

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('home renders the personal dashboard shell', (tester) async {
    await boot(tester);

    expect(find.text('Kumi'), findsWidgets);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Screen time'), findsOneWidget);
    expect(find.text('Nothing watched yet'), findsOneWidget);
    expect(find.byIcon(Symbols.search_rounded), findsNothing);
  });

  testWidgets('browse carries the search field', (tester) async {
    await boot(tester);

    await tester.tap(find.descendant(
      of: find.byType(AppBar),
      matching: find.byIcon(Symbols.grid_view_rounded),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Browse'), findsWidgets);
    expect(find.byType(TextField), findsOneWidget);
  });
}