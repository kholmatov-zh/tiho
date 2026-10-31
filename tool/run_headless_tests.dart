// A direct engine runner for environments that do not allow localhost sockets.
// Normal development should use `flutter test`.
// ignore_for_file: implementation_imports, depend_on_referenced_packages, avoid_print
import 'dart:io';

import 'package:test_api/src/backend/declarer.dart';
import 'package:test_api/src/backend/invoker.dart';
import 'package:test_api/src/backend/group.dart';
import 'package:test_api/src/backend/test.dart';
import 'package:test_api/src/backend/suite.dart';
import 'package:test_api/src/backend/suite_platform.dart';
import 'package:test_api/src/backend/runtime.dart';

import '../test/weather_test.dart' as weather;
import '../test/app_test.dart' as app;

Future<void> main() async {
  await Invoker.guard(run);
}

Future<void> run() async {
  final declarer = Declarer();
  declarer.declare(() {
    weather.main();
    app.main();
  });
  final suite = Suite(declarer.build(), SuitePlatform(Runtime.vm));
  var failures = 0;
  var passed = 0;
  Future<void> run(Test test) async {
    final live = test.load(suite);
    live.onMessage.listen((m) => print(m.text));
    await live.run();
    if (live.errors.isNotEmpty) {
      failures++;
      print('FAIL: ${test.name}');
      for (final e in live.errors) {
        print(e);
      }
    } else {
      passed++;
      print('PASS: ${test.name}');
    }
    await live.close();
  }

  Future<void> walk(Group group) async {
    if (group.setUpAll != null) await run(group.setUpAll!);
    for (final entry in group.entries) {
      if (entry is Group) {
        await walk(entry);
      } else if (entry is Test) {
        await run(entry);
      }
    }
    if (group.tearDownAll != null) await run(group.tearDownAll!);
  }

  await walk(suite.group);
  print('RESULT: $passed passed, $failures failed');
  exit(failures == 0 ? 0 : 1);
}
