import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/models.dart';
import 'components.dart';
import 'theme.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({super.key, required this.weather, required this.onForecast});
  final WeatherData weather;
  final VoidCallback onForecast;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final w = weather;
    final today = w.days.first;
    final advice = w.advice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(fullDate(w.time), style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 22),
        Center(
          child: Column(
            children: [
              SizedBox(
                height: 174,
                width: 342,
                child: Image.asset(
                  'assets/images/landscape.png',
                  fit: BoxFit.contain,
                  semanticLabel: 'Солнце над мягкими зелёными холмами',
                  filterQuality: FilterQuality.high,
                ),
              ),
              Text(
                degrees(w.temperature),
                style: TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 86,
                  height: 1.1,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  WeatherIcon(w.code, size: 20, isDay: w.isDay),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(w.description, textAlign: TextAlign.center),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Ощущается как ${degrees(w.feelsLike)}  ·  ↑ ${degrees(today.high)}  ↓ ${degrees(today.low)}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SoftCard(
          color: c.sage,
          padding: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(advice.$1, style: TextStyle(color: c.green, height: 1.5)),
              const SizedBox(height: 8),
              Text(
                advice.$2,
                style: TextStyle(color: c.green, fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Text(
                'Ближайшие часы',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton(
              onPressed: onForecast,
              child: const Text('На 7 дней  →', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: w.upcomingHours.length,
            separatorBuilder: (_, index) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final hour = w.upcomingHours[i];
              return Semantics(
                label:
                    '${i == 0 ? 'Сейчас' : clockTime(hour.time)}, ${degrees(i == 0 ? w.temperature : hour.temperature)}',
                child: Container(
                  width: 62,
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: i == 0 ? c.sage : c.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        i == 0 ? 'Сейчас' : clockTime(hour.time),
                        style: TextStyle(fontSize: 11, color: c.muted),
                      ),
                      WeatherIcon(
                        i == 0 ? w.code : hour.code,
                        isDay: i == 0 ? w.isDay : hour.isDay,
                      ),
                      Text(degrees(i == 0 ? w.temperature : hour.temperature)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        SoftCard(
          child: Column(
            children: [
              _Metric(
                icon: CupertinoIcons.wind,
                title: 'Ветер',
                value: w.wind == null
                    ? '—'
                    : '${w.wind!.toStringAsFixed(1)} м/с',
              ),
              const SizedBox(height: 16),
              _Metric(
                icon: CupertinoIcons.drop,
                title: 'Влажность',
                value: w.humidity == null ? '—' : '${w.humidity}%',
              ),
              const SizedBox(height: 16),
              _Metric(
                icon: CupertinoIcons.umbrella,
                title: 'Вероятность осадков',
                value: today.rain == null ? '—' : '${today.rain}%',
              ),
              if (today.sunset != null) ...[
                const SizedBox(height: 16),
                _Metric(
                  icon: CupertinoIcons.sunset,
                  title: 'Закат',
                  value: clockTime(today.sunset!),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.title, required this.value});
  final IconData icon;
  final String title, value;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20),
      const SizedBox(width: 12),
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.bodySmall),
      ),
      Text(value),
    ],
  );
}
