import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_controller.dart';
import 'cities.dart';
import 'components.dart';
import 'forecast.dart';
import 'settings.dart';
import 'theme.dart';
import 'today.dart';

class TihoHome extends StatefulWidget {
  const TihoHome({super.key, required this.controller});
  final AppController controller;
  @override
  State<TihoHome> createState() => _TihoHomeState();
}

class _TihoHomeState extends State<TihoHome> with WidgetsBindingObserver {
  int _tab = 0;
  Timer? _refresh;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh = Timer.periodic(
      const Duration(minutes: 15),
      (_) => unawaited(widget.controller.refreshAll()),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.controller.refreshAll());
    }
  }

  @override
  void dispose() {
    _refresh?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _select(int tab) {
    if (_tab != tab) {
      HapticFeedback.selectionClick();
      setState(() => _tab = tab);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final c = context.colors;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: controller.restoring
                  ? const Center(child: CupertinoActivityIndicator())
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 4, 14, 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: _tab == 0
                                    ? Align(
                                        alignment: Alignment.centerLeft,
                                        child: TextButton.icon(
                                          onPressed: () => _select(2),
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            foregroundColor: c.ink,
                                          ),
                                          icon: Image.asset(
                                            'assets/images/pin.png',
                                            width: 18,
                                            height: 18,
                                            color: context.isDark
                                                ? c.green
                                                : null,
                                          ),
                                          label: Text(
                                            controller.selectedCity.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Text(
                                        'тихо',
                                        style: TextStyle(
                                          fontFamily: 'Lora',
                                          fontSize: 21,
                                          color: c.green,
                                        ),
                                      ),
                              ),
                              IconButton(
                                tooltip: 'Настройки',
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        SettingsPage(controller: controller),
                                  ),
                                ),
                                icon: const Icon(
                                  CupertinoIcons.slider_horizontal_3,
                                  size: 21,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (controller.storageError != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              controller.storageError!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: _tab == 2
                                ? CitiesPage(
                                    key: const ValueKey('cities'),
                                    controller: controller,
                                    onSelected: () => _select(0),
                                  )
                                : _weatherPage(controller),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(24, 10, 24, 14),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 432),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: c.white,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Row(
                  children: List.generate(
                    3,
                    (i) => Expanded(
                      child: Semantics(
                        selected: _tab == i,
                        button: true,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => _select(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: _tab == i ? c.sage : Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              ['Сегодня', 'Прогноз', 'Города'][i],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _tab == i ? c.green : c.muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _weatherPage(AppController controller) {
    final w = controller.weather;
    return RefreshIndicator(
      key: ValueKey('weather-$_tab'),
      color: context.colors.green,
      onRefresh: () =>
          controller.refreshCity(controller.selectedCity, force: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 6, 24, 16),
        children: [
          if (w != null && (controller.error != null || w.isStale)) ...[
            SoftCard(
              color: context.colors.sage,
              padding: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.error ?? 'Показан сохранённый прогноз. Потяните вниз, чтобы обновить.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Обновлено: ${_savedTime(w.fetchedAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (w == null)
            WeatherEmpty(
              loading: controller.isLoading,
              error: controller.error,
              retry: () => unawaited(
                controller.refreshCity(controller.selectedCity, force: true),
              ),
            )
          else if (_tab == 0)
            TodayPage(weather: w, onForecast: () => _select(1))
          else
            ForecastPage(weather: w, city: controller.selectedCity),
          SourceNote(weather: w),
        ],
      ),
    );
  }

  String _savedTime(DateTime date) {
    final d = date.toLocal();
    return '${d.day}.${d.month.toString().padLeft(2, '0')} в ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
