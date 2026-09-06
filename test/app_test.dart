import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kumi/main.dart';
import 'package:kumi/models/media_item.dart';
import 'package:kumi/screens/home_screen.dart';
import 'package:kumi/services/favorites.dart';
import 'package:kumi/services/watch_history.dart';
import 'package:kumi/widgets/kumi_mark.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await WatchHistory.instance.clear();
    await Favorites.instance.clear();
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

    expect(find.byType(KumiMark), findsWidgets);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Browse'), findsWidgets);
    expect(find.text('Screen time'), findsOneWidget);
    expect(find.text('Nothing watched yet'), findsOneWidget);
    expect(find.byIcon(PhosphorIcons.magnifyingGlass()), findsNothing);
  });

  testWidgets('browse carries the search field', (tester) async {
    await boot(tester);

    await tester.tap(find.text('Browse').first);
    await tester.pumpAndSettle();

    expect(find.text('Browse'), findsWidgets);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('All categories'), findsOneWidget);
  });

  testWidgets('home shows continue watching after a title is recorded',
      (tester) async {
    await boot(tester);

    await WatchHistory.instance.record(const MediaItem(
      id: 123,
      title: 'Sample Flick',
      overview: 'A test title.',
      posterPath: '',
      rating: 7.5,
      releaseDate: '2026-01-01',
      genreIds: [28],
      mediaType: 'movie',
    ));
    await tester.pump();

    expect(find.text('CONTINUE WATCHING'), findsOneWidget);
    expect(find.text('WATCH HISTORY'), findsOneWidget);
    expect(find.text('Sample Flick'), findsWidgets);
  });

  testWidgets('favourited titles appear on My List', (tester) async {
    await boot(tester);

    await Favorites.instance.toggle(const MediaItem(
      id: 456,
      title: 'Fav Flick',
      overview: 'A saved title.',
      posterPath: '',
      rating: 8.0,
      releaseDate: '2026-02-02',
      genreIds: [18],
      mediaType: 'movie',
    ));
    await tester.pump();

    await tester.tap(find.text('My List').first);
    await tester.pumpAndSettle();

    expect(find.text('Nothing saved yet'), findsNothing);
    expect(find.text('Fav Flick'), findsWidgets);
  });
}