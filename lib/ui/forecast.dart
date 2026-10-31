import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/models.dart';
import 'components.dart';
import 'theme.dart';

class ForecastPage extends StatelessWidget {
  const ForecastPage({super.key, required this.weather, required this.city});
  final WeatherData weather;
  final City city;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final days = weather.days;
    final dry = days
        .where(
          (d) =>
              d.rain != null &&
              d.rain! < 30 &&
              weatherKind(d.code) == WeatherKind.sun,
        )
        .toList();
    final minimum = days.map((d) => d.low ?? 0).reduce(math.min);
    final maximum = days.map((d) => d.high ?? 0).reduce(math.max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeading(
          'Неделя без спешки',
          '${city.name} · ${shortDate(days.first.date)} — ${shortDate(days.last.date)}',
        ),
        const SizedBox(height: 24),
        SoftCard(
          color: c.peach,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dry.isEmpty
                    ? 'У каждого дня своё настроение'
                    : 'Впереди ${dry.length} ${_daysWord(dry.length)} с солнцем',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                dry.isEmpty
                    ? 'Посмотрите прогноз и выберите время для себя.'
                    : 'Оставьте немного времени для прогулки.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...List.generate(days.length, (i) {
          final day = days[i];
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _details(context, day),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          i == 0
                              ? 'Сегодня'
                              : '${shortWeekdays[day.date.weekday - 1]}, ${day.date.day}',
                        ),
                        const SizedBox(height: 3),
                        Text(
                          weatherDescription(day.code),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  WeatherIcon(day.code),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 30,
                    child: Text(
                      degrees(day.low),
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final range = math.max(1.0, maximum - minimum);
                        final left =
                            ((day.low ?? minimum) - minimum) /
                            range *
                            constraints.maxWidth;
                        final width = math.max(
                          6.0,
                          ((day.high ?? maximum) - (day.low ?? minimum)) /
                              range *
                              constraints.maxWidth,
                        );
                        return SizedBox(
                          height: 5,
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: c.line,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              Positioned(
                                left: left.clamp(
                                  0,
                                  math.max(0, constraints.maxWidth - 6),
                                ),
                                width: width.clamp(6, constraints.maxWidth),
                                top: 0,
                                bottom: 0,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: c.isLight ? c.peach : c.green,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 34,
                    child: Text(degrees(day.high), textAlign: TextAlign.right),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
        Text(
          'Нажмите на день, чтобы узнать подробности.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  String _daysWord(int n) => n == 1
      ? 'день'
      : n < 5
      ? 'дня'
      : 'дней';
  void _details(BuildContext context, DayForecast day) {
    final hours = weather.hours
        .where(
          (h) =>
              h.time.year == day.date.year &&
              h.time.month == day.date.month &&
              h.time.day == day.date.day,
        )
        .toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            children: [
              PageHeading(fullDate(day.date), city.name),
              const SizedBox(height: 20),
              SoftCard(
                color: context.colors.sage,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${degrees(day.low)} — ${degrees(day.high)}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(weatherDescription(day.code)),
                    const SizedBox(height: 8),
                    Text('Осадки: ${day.rain == null ? '—' : '${day.rain}%'}'),
                    if (day.sunrise != null && day.sunset != null)
                      Text(
                        'Рассвет ${clockTime(day.sunrise!)} · Закат ${clockTime(day.sunset!)}',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...hours.map(
                (h) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Text(clockTime(h.time)),
                      const SizedBox(width: 22),
                      WeatherIcon(h.code, isDay: h.isDay),
                      const SizedBox(width: 16),
                      Expanded(child: Text(degrees(h.temperature))),
                      Text(
                        h.rain == null ? '—' : '${h.rain}% осадки',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on TihoColors {
  bool get isLight => paper == TihoColors.light.paper;
}
