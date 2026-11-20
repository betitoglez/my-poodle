import Flutter
import UIKit
import StoreKit
import Photos

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
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MyPoodlePhotos") {
      PhotoGalleryChannel.register(messenger: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MyPoodlePurchaseQA") {
      PurchaseQAChannel.register(messenger: registrar.messenger())
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

/// Copia un PNG del álbum privado a Fotos con permiso de solo añadir
/// (NSPhotoLibraryAddUsageDescription). No lee la fototeca.
enum PhotoGalleryChannel {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "my_poodle/photos", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "saveToGallery" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let args = call.arguments as? [String: Any],
            let typed = args["bytes"] as? FlutterStandardTypedData,
            !typed.data.isEmpty else {
        result(FlutterError(code: "invalid", message: nil, details: nil))
        return
      }
      let data = typed.data
      let name = args["name"] as? String
      let reply: (Any?) -> Void = { value in DispatchQueue.main.async { result(value) } }
      PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
        guard status == .authorized || status == .limited else {
          reply("denied")
          return
        }
        PHPhotoLibrary.shared().performChanges({
          let options = PHAssetResourceCreationOptions()
          if let name = name { options.originalFilename = "\(name).png" }
          PHAssetCreationRequest.forAsset().addResource(with: .photo, data: data, options: options)
        }) { success, _ in
          reply(success ? "saved" : FlutterError(code: "failed", message: nil, details: nil))
        }
      }
    }
  }
}

/// Herramienta de la beta interna; nunca solicita reembolsos de producción.
enum PurchaseQAChannel {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "my_poodle/purchase_qa", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "requestSandboxRefund" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard #available(iOS 16.0, *) else {
        result(FlutterError(code: "unsupported", message: nil, details: nil))
        return
      }
      Task { @MainActor in
        let productID = "mypoodle.full_version"
        guard let verification = await Transaction.latest(for: productID),
              case .verified(let transaction) = verification,
              transaction.environment == .sandbox,
              transaction.revocationDate == nil else {
          result(FlutterError(code: "sandbox_only", message: nil, details: nil))
          return
        }
        guard let scene = UIApplication.shared.connectedScenes
          .compactMap({ $0 as? UIWindowScene })
          .first(where: { $0.activationState == .foregroundActive }) else {
          result(FlutterError(code: "no_active_scene", message: nil, details: nil))
          return
        }
        do {
          switch try await transaction.beginRefundRequest(in: scene) {
          case .success:
            result("submitted")
          case .userCancelled:
            result("cancelled")
          @unknown default:
            result(FlutterError(code: "unknown_status", message: nil, details: nil))
          }
        } catch {
          result(FlutterError(code: "refund_request", message: nil, details: nil))
        }
      }
    }
  }
}
