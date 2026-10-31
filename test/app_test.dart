import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiho/data/app_controller.dart';
import 'package:tiho/main.dart';
import 'package:tiho/ui/theme.dart';

import 'fixtures.dart';

Future<void> loadFonts() async {
  for (final name in ['Manrope', 'Lora']) {
    final loader = FontLoader(name)
      ..addFont(rootBundle.load('assets/fonts/$name.ttf'));
    await loader.load();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);
  testWidgets('navigation, city search, dark theme and settings persistence', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? saved;
    final c = AppController(
      service: FakeWeatherService(),
      readStorage: () async => saved,
      writeStorage: (s) async {
        saved = s;
      },
    );
    await c.initialize();
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('capture'),
        child: TihoApp(controller: c),
      ),
    );
    await tester.runAsync(() async {
      final context = tester.element(find.byType(TihoApp));
      await Future.wait(
        ['landscape', 'sun', 'cloud', 'rain', 'pin'].map(
          (name) =>
              precacheImage(AssetImage('assets/images/$name.png'), context),
        ),
      );
    });
    await tester.pumpAndSettle();
    expect(find.text('Ближайшие часы'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _capture(tester, 'today-light');
    await tester.tap(find.text('Прогноз'));
    await tester.pumpAndSettle();
    expect(find.text('Неделя без спешки'), findsOneWidget);
    await _capture(tester, 'forecast-light');
    await tester.tap(find.text('Города'));
    await tester.pumpAndSettle();
    expect(find.text('Свои места'), findsOneWidget);
    await _capture(tester, 'cities-light');
    await tester.enterText(find.byType(TextField), 'Лондон');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Лондон').last);
    await tester.pumpAndSettle();
    expect(c.selectedCity.name, 'Лондон');
    await tester.tap(find.byTooltip('Настройки'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Тёмная'));
    await tester.pumpAndSettle();
    expect(c.themeMode, ThemeMode.dark);
    expect(saved, contains('"theme":"dark"'));
    final settingsContext = tester.element(find.text('Как вам уютнее'));
    expect(Theme.of(settingsContext).brightness, Brightness.dark);
    expect(settingsContext.colors.paper, TihoColors.dark.paper);
    await _capture(tester, 'settings-dark');
    await tester.tap(find.byTooltip('Назад'));
    await tester.pumpAndSettle();
    await _capture(tester, 'today-dark');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets('all screens fit narrow phones with larger text', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final c = AppController(
      service: FakeWeatherService(),
      readStorage: () async => null,
      writeStorage: (_) async {},
    );
    await c.initialize();
    await tester.pumpWidget(TihoApp(controller: c));
    await tester.pumpAndSettle();
    for (final tab in ['Сегодня', 'Прогноз', 'Города']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Overflow on $tab');
    }
    await tester.tap(find.byTooltip('Настройки'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets('network failure offers retry without invented forecast', (
    tester,
  ) async {
    final c = AppController(
      service: FakeWeatherService()..fail = true,
      readStorage: () async => null,
      writeStorage: (_) async {},
    );
    await c.initialize();
    await tester.pumpWidget(TihoApp(controller: c));
    await tester.pumpAndSettle();
    expect(find.text('Попробовать снова'), findsOneWidget);
    expect(find.text('18°'), findsNothing);
    expect(find.text('Нет интернета'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('UPDATE_PREVIEWS')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('artifacts/previews').create(recursive: true);
    await File('artifacts/previews/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
