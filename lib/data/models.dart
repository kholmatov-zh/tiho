class City {
  const City({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.country = '',
    this.region = '',
  });
  final String id, name, country, region;
  final double latitude, longitude;
  String get subtitle =>
      [region, country].where((s) => s.isNotEmpty).toSet().join(', ');
  factory City.fromJson(Map<String, dynamic> json) => City(
    id: json['id'].toString(),
    name: json['name'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    country: json['country'] as String? ?? '',
    region: json['admin1'] as String? ?? '',
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'country': country,
    'admin1': region,
  };
  static const defaults = [
    City(
      id: '524901',
      name: 'Москва',
      latitude: 55.7522,
      longitude: 37.6156,
      country: 'Россия',
    ),
    City(
      id: '498817',
      name: 'Санкт-Петербург',
      latitude: 59.9386,
      longitude: 30.3141,
      country: 'Россия',
    ),
    City(
      id: '1512569',
      name: 'Ташкент',
      latitude: 41.2647,
      longitude: 69.2163,
      country: 'Узбекистан',
    ),
  ];
}

enum WeatherKind { sun, cloud, rain, snow, fog, thunder, unknown }

WeatherKind weatherKind(int code) => switch (code) {
  0 || 1 => WeatherKind.sun,
  2 || 3 => WeatherKind.cloud,
  45 || 48 => WeatherKind.fog,
  >= 51 && <= 67 || >= 80 && <= 82 => WeatherKind.rain,
  >= 71 && <= 77 || 85 || 86 => WeatherKind.snow,
  95 || 96 || 99 => WeatherKind.thunder,
  _ => WeatherKind.unknown,
};
String weatherDescription(int code, {bool isDay = true}) => switch (code) {
  0 => isDay ? 'Солнечно и спокойно' : 'Ясная ночь',
  1 => isDay ? 'Преимущественно ясно' : 'Почти ясная ночь',
  2 => 'Переменная облачность',
  3 => 'Облачно',
  45 || 48 => 'Туман',
  51 || 53 || 55 => 'Морось',
  56 || 57 => 'Ледяная морось',
  61 => 'Небольшой дождь',
  63 => 'Дождь',
  65 => 'Сильный дождь',
  66 || 67 => 'Ледяной дождь',
  71 => 'Небольшой снег',
  73 || 77 => 'Снег',
  75 => 'Сильный снег',
  80 || 81 || 82 => 'Ливневый дождь',
  85 || 86 => 'Снежный ливень',
  95 => 'Гроза',
  96 || 99 => 'Гроза с градом',
  _ => 'Нет данных об облачности',
};

class HourForecast {
  const HourForecast(
    this.time,
    this.temperature,
    this.code,
    this.rain,
    this.isDay,
  );
  final DateTime time;
  final double? temperature;
  final int code;
  final int? rain;
  final bool isDay;
}

class DayForecast {
  const DayForecast(
    this.date,
    this.low,
    this.high,
    this.code,
    this.rain,
    this.sunrise,
    this.sunset,
  );
  final DateTime date;
  final double? low, high;
  final int code;
  final int? rain;
  final DateTime? sunrise, sunset;
}

class WeatherData {
  WeatherData._({
    required this.raw,
    required this.fetchedAt,
    required this.time,
    required this.temperature,
    required this.feelsLike,
    required this.code,
    required this.isDay,
    required this.humidity,
    required this.wind,
    required this.hours,
    required this.days,
  });
  final Map<String, dynamic> raw;
  final DateTime fetchedAt;
  // API timestamps are city-local wall times, not the device timezone.
  final DateTime time;
  final double temperature;
  final double? feelsLike, wind;
  final int code;
  final bool isDay;
  final int? humidity;
  final List<HourForecast> hours;
  final List<DayForecast> days;
  bool get isStale =>
      DateTime.now().toUtc().difference(fetchedAt) >
      const Duration(minutes: 30);
  bool get canUseCache =>
      DateTime.now().toUtc().difference(fetchedAt) <
      const Duration(minutes: 15);
  String get description => weatherDescription(code, isDay: isDay);
  factory WeatherData.fromJson(
    Map<String, dynamic> json, {
    DateTime? fetchedAt,
  }) {
    final current = json['current'] as Map<String, dynamic>;
    final hourly = json['hourly'] as Map<String, dynamic>;
    final daily = json['daily'] as Map<String, dynamic>;
    final time = DateTime.parse(current['time'] as String);
    final temperature = (current['temperature_2m'] as num).toDouble();
    if (!temperature.isFinite) {
      throw const FormatException('Invalid temperature');
    }
    num? at(Map<String, dynamic> map, String key, int i) {
      final values = map[key];
      return values is List && i < values.length && values[i] is num
          ? values[i] as num
          : null;
    }

    DateTime? dateAt(String key, int i) {
      final values = daily[key];
      return values is List && i < values.length && values[i] is String
          ? DateTime.tryParse(values[i] as String)
          : null;
    }

    final hourTimes = hourly['time'] as List;
    final dayTimes = daily['time'] as List;
    if (dayTimes.isEmpty || hourTimes.isEmpty) {
      throw const FormatException('Empty forecast');
    }
    return WeatherData._(
      raw: json,
      fetchedAt: (fetchedAt ?? DateTime.now()).toUtc(),
      time: time,
      temperature: temperature,
      feelsLike: (current['apparent_temperature'] as num?)?.toDouble(),
      code: (current['weather_code'] as num?)?.toInt() ?? -1,
      isDay: current['is_day'] == 1,
      humidity: (current['relative_humidity_2m'] as num?)?.toInt(),
      wind: (current['wind_speed_10m'] as num?)?.toDouble(),
      hours: List.generate(
        hourTimes.length,
        (i) => HourForecast(
          DateTime.parse(hourTimes[i] as String),
          at(hourly, 'temperature_2m', i)?.toDouble(),
          at(hourly, 'weather_code', i)?.toInt() ?? -1,
          at(hourly, 'precipitation_probability', i)?.toInt(),
          at(hourly, 'is_day', i) == 1,
        ),
      ),
      days: List.generate(
        dayTimes.length,
        (i) => DayForecast(
          DateTime.parse(dayTimes[i] as String),
          at(daily, 'temperature_2m_min', i)?.toDouble(),
          at(daily, 'temperature_2m_max', i)?.toDouble(),
          at(daily, 'weather_code', i)?.toInt() ?? -1,
          at(daily, 'precipitation_probability_max', i)?.toInt(),
          dateAt('sunrise', i),
          dateAt('sunset', i),
        ),
      ),
    );
  }
  List<HourForecast> get upcomingHours {
    final floor = DateTime(time.year, time.month, time.day, time.hour);
    return hours.where((h) => !h.time.isBefore(floor)).take(24).toList();
  }

  (String, String) get advice {
    final kind = weatherKind(code);
    if (kind == WeatherKind.thunder) {
      return ('Лучше переждать дома', 'Во время грозы отложите прогулку.');
    }
    if (kind == WeatherKind.snow) {
      return (
        'Город укутался в снег',
        'Тёплая куртка и удобная обувь пригодятся.',
      );
    }
    if (kind == WeatherKind.rain) {
      return (
        'У дождя тоже есть свой ритм',
        'Возьмите зонт. И оставьте время на чашку чая.',
      );
    }
    if ((wind ?? 0) >= 10) {
      return (
        'Сегодня ветрено',
        'Непродуваемая куртка сделает прогулку приятнее.',
      );
    }
    if (temperature < 5) {
      return (
        'Время для тёплого шарфа',
        'Оденьтесь теплее и захватите любимый чай.',
      );
    }
    if (temperature >= 30) {
      return (
        'Побольше тени и прохлады',
        'Возьмите воду и избегайте полуденного солнца.',
      );
    }
    if (!isDay) {
      return (
        'Пусть вечер будет тихим',
        'Немного свежего воздуха — и можно отдыхать.',
      );
    }
    if ((days.first.rain ?? 0) >= 40) {
      return (
        'В планах — немного спонтанности',
        'Сегодня возможны осадки. Захватите зонт.',
      );
    }
    return (
      'Хороший день, чтобы замедлиться',
      temperature < 18
          ? 'Для прогулки пригодится лёгкая куртка.'
          : 'Самое время выйти на неспешную прогулку.',
    );
  }
}

String degrees(num? value) => value == null ? '—' : '${value.round()}°';
String clockTime(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
const monthNames = [
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];
const weekdayNames = [
  'Понедельник',
  'Вторник',
  'Среда',
  'Четверг',
  'Пятница',
  'Суббота',
  'Воскресенье',
];
const shortWeekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
String fullDate(DateTime date) =>
    '${weekdayNames[date.weekday - 1]}, ${date.day} ${monthNames[date.month - 1]}';
String shortDate(DateTime date) => '${date.day} ${monthNames[date.month - 1]}';
