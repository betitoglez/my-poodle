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
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MyPoodleStorage") {
      StorageChannel.register(messenger: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MyPoodle3D") {
      registrar.register(PoodleViewFactory(registrar: registrar), withId: "my_poodle/poodle_3d")
    }
  }
}

/// Directorio privado de partida bajo Application Support, excluido de las
/// copias de seguridad de iCloud. Se reaplica el atributo en cada consulta.
enum StorageChannel {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "my_poodle/storage", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "saveDirectory" else {
        result(FlutterMethodNotImplemented)
        return
      }
      do {
        let base = try FileManager.default.url(
          for: .applicationSupportDirectory, in: .userDomainMask,
          appropriateFor: nil, create: true)
        var dir = base.appendingPathComponent("MyPoodle", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try dir.setResourceValues(values)
        result(dir.path)
      } catch {
        result(FlutterError(code: "storage", message: error.localizedDescription, details: nil))
      }
    }
  }
}
