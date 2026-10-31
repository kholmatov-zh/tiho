import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/app_controller.dart';
import 'data/storage.dart';
import 'data/weather_api.dart';
import 'ui/home.dart';
import 'ui/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = PlatformStorage();
  final controller = AppController(
    service: OpenMeteoService(),
    readStorage: storage.read,
    writeStorage: storage.write,
  );
  runApp(TihoApp(controller: controller));
  unawaited(controller.initialize());
}

class TihoApp extends StatelessWidget {
  const TihoApp({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, child) => MaterialApp(
      title: 'Тихо — погода',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: tihoTheme(Brightness.light),
      darkTheme: tihoTheme(Brightness.dark),
      themeMode: controller.themeMode,
      home: TihoHome(controller: controller),
    ),
  );
}
