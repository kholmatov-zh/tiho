import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/app_controller.dart';
import 'components.dart';
import 'theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, child) {
      final c = context.colors;
      return Scaffold(
        appBar: AppBar(
          backgroundColor: c.paper,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            tooltip: 'Назад',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(CupertinoIcons.chevron_back),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: [
                  const PageHeading(
                    'Как вам уютнее',
                    'Маленькие настройки для вашего ритма.',
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'ОФОРМЛЕНИЕ',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.6,
                      color: c.muted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SoftCard(
                    padding: 8,
                    child: Column(
                      children: [
                        _option(
                          context,
                          ThemeMode.light,
                          'Светлая',
                          'Мягкий свет и молочные оттенки',
                          CupertinoIcons.sun_max,
                        ),
                        _option(
                          context,
                          ThemeMode.dark,
                          'Тёмная',
                          'Глубокий зелёный и тёплые акценты',
                          CupertinoIcons.moon,
                        ),
                        _option(
                          context,
                          ThemeMode.system,
                          'Как на устройстве',
                          'Меняется вместе с системой',
                          CupertinoIcons.device_phone_portrait,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    height: 112,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: c.sage,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          context.isDark
                              ? CupertinoIcons.moon_stars
                              : CupertinoIcons.sun_max,
                          size: 40,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Тихо. И по-своему.',
                                style: TextStyle(
                                  fontFamily: 'Lora',
                                  fontSize: 20,
                                  color: c.ink,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Ваш выбор сохранится.',
                                style: TextStyle(fontSize: 12, color: c.green),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'О ПОГОДЕ',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.6,
                      color: c.muted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _info('Температура', '°C'),
                        const SizedBox(height: 16),
                        _info('Скорость ветра', 'м/с'),
                        const SizedBox(height: 16),
                        _info('Часовой пояс', 'По выбранному городу'),
                        const SizedBox(height: 16),
                        _info('Обновление', 'Каждые 15 минут'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Последний прогноз сохраняется на устройстве и доступен без сети. Для новых данных нужен интернет.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (controller.storageError != null) ...[
                    const SizedBox(height: 12),
                    Text(controller.storageError!),
                  ],
                  const SourceNote(),
                  Center(
                    child: Text(
                      'тихо · 1.0.0',
                      style: TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 17,
                        color: c.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
  Widget _option(
    BuildContext context,
    ThemeMode mode,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final selected = controller.themeMode == mode;
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: selected ? c.sage : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 7,
          ),
          leading: Icon(icon),
          title: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: c.muted),
          ),
          trailing: Icon(
            selected
                ? CupertinoIcons.checkmark_circle_fill
                : CupertinoIcons.circle,
            color: selected ? c.green : c.muted,
            size: 22,
          ),
          onTap: () => unawaited(controller.setTheme(mode)),
        ),
      ),
    );
  }

  Widget _info(String name, String value) => Row(
    children: [
      Expanded(child: Text(name)),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    ],
  );
}
