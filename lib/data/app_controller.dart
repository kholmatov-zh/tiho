import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;

import 'models.dart';
import 'weather_api.dart';

class AppController extends ChangeNotifier {
  AppController({
    required this.service,
    required this.readStorage,
    required this.writeStorage,
  });
  final WeatherService service;
  final Future<String?> Function() readStorage;
  final Future<void> Function(String) writeStorage;
  List<City> cities = [...City.defaults];
  String selectedId = City.defaults.first.id;
  ThemeMode themeMode = ThemeMode.system;
  final Map<String, WeatherData> forecasts = {};
  final Map<String, String> errors = {};
  final Map<String, Future<void>> _requests = {};
  final Set<String> loading = {};
  bool restoring = true;
  String? storageError;
  bool _disposed = false;
  Future<void> _saveQueue = Future.value();
  City get selectedCity =>
      cities.firstWhere((c) => c.id == selectedId, orElse: () => cities.first);
  WeatherData? get weather => forecasts[selectedId];
  bool get isLoading => loading.contains(selectedId);
  String? get error => errors[selectedId];
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    try {
      final saved = await readStorage();
      if (_disposed) return;
      if (saved != null) {
        final json = jsonDecode(saved) as Map<String, dynamic>;
        final restored = (json['cities'] as List? ?? [])
            .map((e) => City.fromJson(e as Map<String, dynamic>))
            .toList();
        if (restored.isNotEmpty) cities = restored;
        selectedId = json['selectedId'] as String? ?? cities.first.id;
        if (!cities.any((c) => c.id == selectedId)) {
          selectedId = cities.first.id;
        }
        themeMode = ThemeMode.values.firstWhere(
          (m) => m.name == json['theme'],
          orElse: () => ThemeMode.system,
        );
        final cache = json['cache'] as Map<String, dynamic>? ?? {};
        for (final city in cities) {
          try {
            final entry = cache[city.id] as Map<String, dynamic>?;
            if (entry != null) {
              forecasts[city.id] = WeatherData.fromJson(
                entry['data'] as Map<String, dynamic>,
                fetchedAt: DateTime.parse(entry['fetchedAt'] as String),
              );
            }
          } catch (_) {
            /* An invalid city cache must not prevent startup. */
          }
        }
      }
    } catch (_) {
      storageError = 'Не удалось прочитать сохранённые настройки.';
    }
    if (_disposed) return;
    restoring = false;
    _emit();
    await refreshAll();
  }

  Future<void> refreshCity(City city, {bool force = false}) {
    if (_disposed) return Future.value();
    if (_requests.containsKey(city.id)) return _requests[city.id]!;
    if (!force && forecasts[city.id]?.canUseCache == true) {
      return Future.value();
    }
    final completer = Completer<void>();
    _requests[city.id] = completer.future;
    loading.add(city.id);
    errors.remove(city.id);
    _emit();
    () async {
      try {
        final result = await service.forecast(city);
        if (_disposed || !cities.any((c) => c.id == city.id)) return;
        forecasts[city.id] = result;
        await persist();
      } catch (e) {
        if (!_disposed && cities.any((c) => c.id == city.id)) {
          errors[city.id] = e is WeatherException
              ? e.message
              : 'Не удалось обновить погоду.';
        }
      } finally {
        loading.remove(city.id);
        _requests.remove(city.id);
        completer.complete();
        _emit();
      }
    }();
    return completer.future;
  }

  Future<void> refreshAll({bool force = false}) async {
    await Future.wait([...cities].map((c) => refreshCity(c, force: force)));
  }

  Future<void> selectCity(City city) async {
    selectedId = city.id;
    _emit();
    await persist();
    await refreshCity(city);
  }

  Future<void> addCity(City city) async {
    if (!cities.any((c) => c.id == city.id)) cities = [...cities, city];
    await selectCity(city);
  }

  Future<void> removeCity(City city) async {
    if (cities.length <= 1) return;
    cities = cities.where((c) => c.id != city.id).toList();
    forecasts.remove(city.id);
    errors.remove(city.id);
    if (selectedId == city.id) selectedId = cities.first.id;
    _emit();
    await persist();
  }

  Future<void> setTheme(ThemeMode mode) async {
    themeMode = mode;
    _emit();
    await persist();
  }

  Future<void> persist() {
    final snapshot = jsonEncode({
      'theme': themeMode.name,
      'selectedId': selectedId,
      'cities': cities.map((c) => c.toJson()).toList(),
      'cache': forecasts.map(
        (key, value) => MapEntry(key, {
          'fetchedAt': value.fetchedAt.toIso8601String(),
          'data': value.raw,
        }),
      ),
    });
    _saveQueue = _saveQueue.then((_) async {
      try {
        await writeStorage(snapshot);
        storageError = null;
      } catch (_) {
        storageError = 'Изменения не удалось сохранить на устройстве.';
      }
      _emit();
    });
    return _saveQueue;
  }

  @override
  void dispose() {
    _disposed = true;
    service.close();
    super.dispose();
  }
}
