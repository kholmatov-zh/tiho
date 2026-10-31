import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/app_controller.dart';
import '../data/models.dart';
import '../data/weather_api.dart';
import 'components.dart';
import 'theme.dart';

class CitiesPage extends StatefulWidget {
  const CitiesPage({
    super.key,
    required this.controller,
    required this.onSelected,
  });
  final AppController controller;
  final VoidCallback onSelected;
  @override
  State<CitiesPage> createState() => _CitiesPageState();
}

class _CitiesPageState extends State<CitiesPage> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  int _generation = 0;
  bool _searching = false;
  String? _error;
  List<City>? _results;
  @override
  void dispose() {
    _generation++;
    _debounce?.cancel();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _query(String query) {
    _debounce?.cancel();
    final generation = ++_generation;
    setState(() {
      _results = null;
      _error = null;
      _searching = query.trim().length >= 2;
    });
    if (!_searching) return;
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final result = await widget.controller.service.search(query);
        if (!mounted || generation != _generation) return;
        setState(() {
          _results = result;
          _searching = false;
        });
      } catch (e) {
        if (!mounted || generation != _generation) return;
        setState(() {
          _searching = false;
          _error = e is WeatherException
              ? e.message
              : 'Не удалось найти город.';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final controller = widget.controller;
    final isQuery = _text.text.trim().length >= 2;
    return RefreshIndicator(
      color: c.green,
      onRefresh: () => controller.refreshAll(force: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 6, 24, 20),
        children: [
          const PageHeading('Свои места', 'Где бы вы ни были — немного тепла.'),
          const SizedBox(height: 24),
          TextField(
            controller: _text,
            focusNode: _focus,
            onChanged: _query,
            textInputAction: TextInputAction.search,
            autocorrect: false,
            decoration: InputDecoration(
              hintText: 'Найти город',
              prefixIcon: const Icon(CupertinoIcons.search, size: 20),
              suffixIcon: _text.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Очистить поиск',
                      onPressed: () {
                        _text.clear();
                        _query('');
                      },
                      icon: const Icon(
                        CupertinoIcons.xmark_circle_fill,
                        size: 18,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          if (_searching)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CupertinoActivityIndicator(),
            )
          else if (_error != null)
            SoftCard(
              child: Column(
                children: [
                  Text(_error!),
                  TextButton(
                    onPressed: () => _query(_text.text),
                    child: const Text('Повторить поиск'),
                  ),
                ],
              ),
            )
          else if (isQuery && _results != null) ...[
            if (_results!.isEmpty)
              const SoftCard(
                child: Text(
                  'Такого места пока не нашли. Попробуйте другое название.',
                ),
              ),
            ..._results!.map(
              (city) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: c.white,
                  borderRadius: BorderRadius.circular(20),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Text(city.name),
                    subtitle: Text(city.subtitle),
                    trailing: Icon(
                      controller.cities.any((c) => c.id == city.id)
                          ? CupertinoIcons.checkmark_circle
                          : CupertinoIcons.plus_circle,
                    ),
                    onTap: () {
                      _focus.unfocus();
                      unawaited(controller.addCity(city));
                      widget.onSelected();
                    },
                  ),
                ),
              ),
            ),
          ] else if (!isQuery) ...[
            ...List.generate(
              controller.cities.length,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _cityCard(controller.cities[i], i),
              ),
            ),
            TextButton.icon(
              onPressed: () => _focus.requestFocus(),
              icon: const Icon(CupertinoIcons.plus, size: 19),
              label: const Text('Добавить место'),
            ),
          ],
          const SourceNote(),
        ],
      ),
    );
  }

  Widget _cityCard(City city, int index) {
    final controller = widget.controller;
    final w = controller.forecasts[city.id];
    final c = context.colors;
    final selected = controller.selectedId == city.id;
    return Material(
      color: [c.sage, c.blue, c.peach][index % 3],
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          unawaited(controller.selectCity(city));
          widget.onSelected();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          city.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selected ? 'Выбранный город' : city.subtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (w != null)
                    Text(
                      degrees(w.temperature),
                      style: TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 40,
                        color: c.ink,
                      ),
                    )
                  else if (controller.loading.contains(city.id))
                    const CupertinoActivityIndicator()
                  else
                    Text(
                      '—',
                      style: TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 36,
                        color: c.ink,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (w != null) ...[
                    WeatherIcon(w.code, size: 22, isDay: w.isDay),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      w == null
                          ? controller.errors[city.id] ?? 'Загружаем погоду…'
                          : '${w.description}${w.isStale || controller.errors[city.id] != null ? ' · сохранено' : ''}',
                      style: TextStyle(fontSize: 12, color: c.ink),
                    ),
                  ),
                  if (controller.cities.length > 1)
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        tooltip: 'Удалить ${city.name}',
                        onPressed: () => _remove(city),
                        icon: Icon(
                          CupertinoIcons.minus_circle,
                          size: 18,
                          color: c.muted,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _remove(City city) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить ${city.name}?'),
        content: const Text('Город всегда можно добавить снова.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Оставить'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await widget.controller.removeCity(city);
  }
}
