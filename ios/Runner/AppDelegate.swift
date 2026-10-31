import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "TihoPreferences")!
    let channel = FlutterMethodChannel(name: "com.tiho/preferences", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "read":
        result(UserDefaults.standard.string(forKey: "tiho.state.v1"))
      case "write":
        guard let value = call.arguments as? String else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected JSON string", details: nil))
          return
        }
        UserDefaults.standard.set(value, forKey: "tiho.state.v1")
        result(nil)
      case "openSource":
        guard let value = call.arguments as? String, let url = URL(string: value), url.scheme == "https" else {
          result(FlutterError(code: "INVALID_URL", message: "Expected HTTPS URL", details: nil))
          return
        }
        UIApplication.shared.open(url) { opened in
          result(opened ? nil : FlutterError(code: "OPEN_FAILED", message: "Could not open source", details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
