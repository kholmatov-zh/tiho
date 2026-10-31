import 'dart:js_interop';

@JS('window.localStorage.getItem')
external String? _read(String key);
@JS('window.localStorage.setItem')
external void _write(String key, String value);
@JS('window.open')
external JSAny? _open(String url, String target, String features);

class PlatformStorage {
  Future<String?> read() async => _read('tiho.state.v1');
  Future<void> write(String value) async => _write('tiho.state.v1', value);
  Future<void> openSource(String url) async {
    _open(url, '_blank', 'noopener,noreferrer');
  }
}
