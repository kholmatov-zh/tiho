import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

abstract interface class WeatherService {
  Future<WeatherData> forecast(City city);
  Future<List<City>> search(String query);
  void close();
}

class WeatherException implements Exception {
  const WeatherException(this.message);
  final String message;
  @override
  String toString() => message;
}

class OpenMeteoService implements WeatherService {
  OpenMeteoService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  Future<Map<String, dynamic>> _get(Uri uri) async {
    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 429) {
        throw const WeatherException(
          'Сервису нужна небольшая пауза. Попробуйте позже.',
        );
      }
      if (response.statusCode != 200) {
        throw const WeatherException(
          'Погода пока недоступна. Попробуйте ещё раз.',
        );
      }
      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (json['error'] == true) {
        throw const WeatherException(
          'Не удалось получить прогноз для этого места.',
        );
      }
      return json;
    } on WeatherException {
      rethrow;
    } on TimeoutException {
      throw const WeatherException(
        'Ответ задерживается. Проверьте интернет и попробуйте снова.',
      );
    } catch (_) {
      throw const WeatherException(
        'Не удалось связаться с погодой. Проверьте интернет.',
      );
    }
  }

  @override
  Future<WeatherData> forecast(City city) async {
    final json = await _get(
      Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': '${city.latitude}',
        'longitude': '${city.longitude}',
        'current': 'temperature_2m,apparent_temperature,is_day,weather_code,wind_speed_10m,relative_humidity_2m',
        'hourly':
            'temperature_2m,weather_code,precipitation_probability,is_day',
        'daily': 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset',
        'timezone': 'auto',
        'forecast_days': '7',
        'wind_speed_unit': 'ms',
      }),
    );
    try {
      return WeatherData.fromJson(json);
    } catch (_) {
      throw const WeatherException(
        'Прогноз пришёл не полностью. Попробуйте обновить.',
      );
    }
  }

  @override
  Future<List<City>> search(String query) async {
    if (query.trim().length < 2) return [];
    final json = await _get(
      Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
        'name': query.trim(),
        'count': '12',
        'language': 'ru',
        'format': 'json',
      }),
    );
    try {
      return (json['results'] as List? ?? [])
          .map((e) => City.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const WeatherException('Не удалось прочитать список городов.');
    }
  }

  @override
  void close() => _client.close();
}
