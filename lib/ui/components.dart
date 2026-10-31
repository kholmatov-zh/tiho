import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/storage.dart';
import 'theme.dart';

class WeatherIcon extends StatelessWidget {
  const WeatherIcon(this.code, {super.key, this.size = 24, this.isDay = true});
  final int code;
  final double size;
  final bool isDay;
  @override
  Widget build(BuildContext context) {
    final kind = weatherKind(code);
    final icon = switch (kind) {
      WeatherKind.snow => CupertinoIcons.snow,
      WeatherKind.thunder => CupertinoIcons.cloud_bolt,
      WeatherKind.fog => CupertinoIcons.cloud_fog,
      WeatherKind.unknown => CupertinoIcons.question_circle,
      WeatherKind.sun when !isDay => CupertinoIcons.moon_stars,
      _ => null,
    };
    final description = weatherDescription(code, isDay: isDay);
    if (icon != null) {
      return Semantics(
        label: description,
        child: Icon(icon, size: size, color: context.colors.green),
      );
    }
    final asset = switch (kind) {
      WeatherKind.rain => 'rain',
      WeatherKind.cloud => 'cloud',
      _ => 'sun',
    };
    return Image.asset(
      'assets/images/$asset.png',
      width: size,
      height: size,
      color: context.isDark ? const Color(0xFFD4DDC3) : null,
      semanticLabel: description,
      filterQuality: FilterQuality.high,
    );
  }
}

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.color,
    this.padding = 18,
  });
  final Widget child;
  final Color? color;
  final double padding;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: color ?? context.colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: child,
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading(this.title, this.subtitle, {super.key});
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 12),
      Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class WeatherEmpty extends StatelessWidget {
  const WeatherEmpty({
    super.key,
    required this.loading,
    required this.retry,
    this.error,
  });
  final bool loading;
  final String? error;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 72),
    child: Column(
      children: [
        Icon(
          loading ? CupertinoIcons.cloud_sun : CupertinoIcons.wifi_slash,
          size: 54,
          color: context.colors.green,
        ),
        const SizedBox(height: 24),
        Text(
          loading ? 'Собираем погоду для вас' : 'Погода немного задерживается',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Text(
          loading
              ? 'Ещё немного — и можно планировать день.'
              : error ?? 'Проверьте подключение к интернету.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        if (loading)
          const CupertinoActivityIndicator()
        else
          FilledButton(
            onPressed: retry,
            child: const Text('Попробовать снова'),
          ),
      ],
    ),
  );
}

class SourceNote extends StatelessWidget {
  const SourceNote({super.key, this.weather});
  final WeatherData? weather;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: TextButton(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('О прогнозе'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    'Погода — Open-Meteo\nhttps://open-meteo.com/\n\nДанные: CC BY 4.0\nhttps://creativecommons.org/licenses/by/4.0/\n\nПоиск городов: GeoNames через Open-Meteo.\n\nПрогноз рассчитывается погодными моделями и может отличаться от наблюдений.',
                  ),
                  TextButton(
                    onPressed: () => _open(context, 'https://open-meteo.com/'),
                    child: const Text('Открыть Open-Meteo ↗'),
                  ),
                  TextButton(
                    onPressed: () => _open(
                      context,
                      'https://creativecommons.org/licenses/by/4.0/',
                    ),
                    child: const Text('Лицензия CC BY 4.0 ↗'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Понятно'),
              ),
            ],
          ),
        ),
        child: Text(
          'Open-Meteo · CC BY 4.0${weather == null ? '' : ' · ${clockTime(weather!.time)}'}',
          style: TextStyle(fontSize: 10, color: context.colors.muted),
        ),
      ),
    ),
  );
  Future<void> _open(BuildContext context, String url) async {
    try {
      await PlatformStorage().openSource(url);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Не удалось открыть ссылку. Адрес можно скопировать выше.',
            ),
          ),
        );
      }
    }
  }
}
