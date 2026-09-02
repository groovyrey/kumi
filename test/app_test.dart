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
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text("Hello, I'm Kumi."), findsOneWidget);
  });

  testWidgets('home screen renders the getting-started tiles', (tester) async {
    await tester.pumpWidget(const KumiApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Design a screen'), findsOneWidget);
    expect(find.text('Tune the theme'), findsOneWidget);
    expect(find.text('Ship an APK'), findsOneWidget);
  });
}