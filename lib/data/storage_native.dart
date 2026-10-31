import 'package:flutter/services.dart';

class PlatformStorage {
  static const _channel = MethodChannel('com.tiho/preferences');
  Future<String?> read() => _channel.invokeMethod<String>('read');
  Future<void> write(String value) =>
      _channel.invokeMethod<void>('write', value);
  Future<void> openSource(String url) =>
      _channel.invokeMethod<void>('openSource', url);
}
