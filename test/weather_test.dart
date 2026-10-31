import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tiho/data/app_controller.dart';
import 'package:tiho/data/models.dart';
import 'package:tiho/data/weather_api.dart';

import 'fixtures.dart';

void main() {
  test(
    'hourly forecast starts at city current hour, not midnight or device time',
    () {
      final w = WeatherData.fromJson(forecastJson());
      expect(w.upcomingHours.first.time, DateTime(2026, 10, 16, 14));
      expect(w.upcomingHours.length, 24);
      expect(w.days.length, 7);
      expect(w.days.first.sunset, DateTime(2026, 10, 16, 17, 26));
    },
  );
  test('missing optional data stays unavailable instead of becoming zero', () {
    final json = forecastJson();
    (json['daily'] as Map)['temperature_2m_min'] = [null];
    (json['hourly'] as Map)['precipitation_probability'] = [null];
    final w = WeatherData.fromJson(json);
    expect(w.days.first.low, isNull);
    expect(w.hours.last.rain, isNull);
    expect(degrees(w.days.first.low), '—');
    expect(weatherKind(66), WeatherKind.rain);
    expect(weatherKind(99), WeatherKind.thunder);
    expect(weatherKind(-1), WeatherKind.unknown);
  });
  test(
    'forecast request uses HTTPS, city coordinates, timezone and m/s',
    () async {
      final service = OpenMeteoService(
        client: MockClient((r) async {
          expect(r.url.scheme, 'https');
          expect(r.url.host, 'api.open-meteo.com');
          expect(r.url.queryParameters['latitude'], '55.7522');
          expect(r.url.queryParameters['timezone'], 'auto');
          expect(r.url.queryParameters['wind_speed_unit'], 'ms');
          expect(r.url.queryParameters['forecast_days'], '7');
          return http.Response(
            jsonEncode(forecastJson()),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      expect((await service.forecast(City.defaults.first)).temperature, 18);
      service.close();
    },
  );
  test(
    'geocoding handles Cyrillic queries, empty results and rate limits',
    () async {
      final service = OpenMeteoService(
        client: MockClient((r) async {
          expect(r.url.host, 'geocoding-api.open-meteo.com');
          expect(r.url.queryParameters['name'], 'Москва');
          expect(r.url.queryParameters['language'], 'ru');
          return http.Response('{}', 200);
        }),
      );
      expect(await service.search(' Москва '), isEmpty);
      service.close();
      final limited = OpenMeteoService(
        client: MockClient((_) async => http.Response('', 429)),
      );
      await expectLater(
        limited.forecast(City.defaults.first),
        throwsA(isA<WeatherException>()),
      );
      limited.close();
    },
  );
  test(
    'offline refresh preserves cached weather and reports failure',
    () async {
      String? saved;
      final service = FakeWeatherService();
      final first = AppController(
        service: service,
        readStorage: () async => saved,
        writeStorage: (s) async {
          saved = s;
        },
      );
      await first.initialize();
      await first.setTheme(ThemeMode.dark);
      await first.selectCity(City.defaults.last);
      first.dispose();
      final offline = FakeWeatherService()..fail = true;
      final restored = AppController(
        service: offline,
        readStorage: () async => saved,
        writeStorage: (s) async {
          saved = s;
        },
      );
      await restored.initialize();
      expect(restored.themeMode, ThemeMode.dark);
      expect(restored.selectedCity.name, 'Ташкент');
      expect(restored.weather?.temperature, 26);
      await restored.refreshCity(restored.selectedCity, force: true);
      expect(restored.error, 'Нет интернета');
      expect(restored.weather?.temperature, 26);
      restored.dispose();
    },
  );
  test(
    'a removed city cannot reappear when an old network response finishes',
    () async {
      final service = _DelayedService();
      final c = AppController(
        service: service,
        readStorage: () async => null,
        writeStorage: (_) async {},
      );
      final request = c.refreshCity(City.defaults.last);
      await c.removeCity(City.defaults.last);
      service.pending.complete(WeatherData.fromJson(forecastJson()));
      await request;
      expect(c.forecasts.containsKey(City.defaults.last.id), false);
      expect(c.cities.length, 2);
      c.dispose();
    },
  );
  test('fresh requests are coalesced and stale cache is refreshed', () async {
    final service = _DelayedService();
    final c = AppController(
      service: service,
      readStorage: () async => null,
      writeStorage: (_) async {},
    );
    final one = c.refreshCity(City.defaults.first);
    final two = c.refreshCity(City.defaults.first);
    expect(service.calls, 1);
    service.pending.complete(WeatherData.fromJson(forecastJson()));
    await Future.wait([one, two]);
    await c.refreshCity(City.defaults.first);
    expect(service.calls, 1);
    c.dispose();
  });
}

class _DelayedService extends FakeWeatherService {
  final pending = Completer<WeatherData>();
  @override
  Future<WeatherData> forecast(City city) {
    calls++;
    return pending.future;
  }
}
