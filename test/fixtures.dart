import 'package:tiho/data/models.dart';
import 'package:tiho/data/weather_api.dart';

Map<String, dynamic> forecastJson({double temperature = 18, int code = 0}) {
  final start = DateTime(2026, 10, 16);
  final hours = List.generate(168, (i) => start.add(Duration(hours: i)));
  final days = List.generate(7, (i) => start.add(Duration(days: i)));
  return {
    'timezone': 'Europe/Moscow',
    'utc_offset_seconds': 10800,
    'current': <String, dynamic>{
      'time': '2026-10-16T14:15',
      'temperature_2m': temperature,
      'apparent_temperature': 16.0,
      'weather_code': code,
      'is_day': 1,
      'wind_speed_10m': 2.4,
      'relative_humidity_2m': 64,
    },
    'hourly': <String, dynamic>{
      'time': hours.map((d) => d.toIso8601String().substring(0, 16)).toList(),
      'temperature_2m': List.generate(168, (i) => 18.0 + (i % 5) - 2),
      'weather_code': List.generate(168, (i) => [0, 1, 2, 3, 61][i % 5]),
      'is_day': hours.map((d) => d.hour >= 7 && d.hour < 19 ? 1 : 0).toList(),
      'precipitation_probability': List.generate(168, (i) => i % 5 * 10),
    },
    'daily': <String, dynamic>{
      'time': days.map((d) => d.toIso8601String().substring(0, 10)).toList(),
      'temperature_2m_min': [11, 10, 9, 8, 7, 8, 9],
      'temperature_2m_max': [19, 18, 16, 13, 12, 15, 16],
      'weather_code': [0, 1, 3, 61, 3, 0, 1],
      'precipitation_probability_max': [0, 10, 20, 80, 20, 0, 0],
      'sunrise': days
          .map((d) => '${d.toIso8601String().substring(0, 10)}T07:03')
          .toList(),
      'sunset': days
          .map((d) => '${d.toIso8601String().substring(0, 10)}T17:26')
          .toList(),
    },
  };
}

class FakeWeatherService implements WeatherService {
  bool fail = false;
  int calls = 0;
  @override
  Future<WeatherData> forecast(City city) async {
    calls++;
    if (fail) throw const WeatherException('Нет интернета');
    return WeatherData.fromJson(
      forecastJson(temperature: city.id == '1512569' ? 26 : 18),
    );
  }

  @override
  Future<List<City>> search(String query) async => [
    const City(
      id: '2643743',
      name: 'Лондон',
      latitude: 51.5,
      longitude: -0.12,
      country: 'Великобритания',
    ),
  ];
  @override
  void close() {}
}
