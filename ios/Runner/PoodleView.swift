import Flutter
import UIKit
import WebKit

final class PoodleViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger
  private let directory: URL?

  init(registrar: FlutterPluginRegistrar) {
    messenger = registrar.messenger()
    let key = registrar.lookupKey(forAsset: "assets/wardrobe_live/index.html")
    directory = Bundle.main.url(forResource: key, withExtension: nil)?.deletingLastPathComponent()
  }

  func create(withFrame frame: CGRect, viewIdentifier id: Int64, arguments args: Any?)
    -> FlutterPlatformView
  {
    PoodleView(frame: frame, id: id, messenger: messenger, directory: directory)
  }
}

private final class PoodleAssets: NSObject, WKURLSchemeHandler {
  static let scheme = "mypoodle-asset"
  static let index = URL(string: "mypoodle-asset://local/index.html")!
  private let directory: URL?
  private let mimeTypes = ["html": "text/html", "js": "text/javascript", "glb": "model/gltf-binary"]

  init(directory: URL?) {
    self.directory = directory
  }

  func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
    guard let url = task.request.url, url.host == Self.index.host, let directory else {
      task.didFailWithError(URLError(.fileDoesNotExist))
      return
    }
    let path = String(url.path.dropFirst())
    guard path.range(of: #"^[A-Za-z0-9._/-]+$"#, options: .regularExpression) != nil,
      !path.contains(".."),
      let type = mimeTypes[url.pathExtension],
      let data = try? Data(contentsOf: directory.appendingPathComponent(path), options: .mappedIfSafe),
      let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: [
        "Content-Type": type,
        "Content-Length": String(data.count),
        "Access-Control-Allow-Origin": "*",
      ])
    else {
      task.didFailWithError(URLError(.fileDoesNotExist))
      return
    }
    task.didReceive(response)
    task.didReceive(data)
    task.didFinish()
  }

  func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}
}

private final class PoodleMessages: NSObject, WKScriptMessageHandler {
  weak var owner: PoodleView?

  func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
    if message.frameInfo.isMainFrame {
      owner?.receive(message.body)
    }
  }
}

private final class PoodleView: NSObject, FlutterPlatformView, WKNavigationDelegate {
  private let web: WKWebView
  private let channel: FlutterMethodChannel
  private var configuration: String?
  private var ready = false
  private let coordinateCounts = [
    "bowlBounds": 4, "bathTargets": 16, "vetTargets": 6, "groomTargets": 6, "sleepBounds": 4,
  ]

  init(frame: CGRect, id: Int64, messenger: FlutterBinaryMessenger, directory: URL?) {
    let messages = PoodleMessages()
    let settings = WKWebViewConfiguration()
    settings.websiteDataStore = .nonPersistent()
    settings.setURLSchemeHandler(PoodleAssets(directory: directory), forURLScheme: PoodleAssets.scheme)
    settings.userContentController.add(messages, name: "poodle")
    settings.userContentController.addUserScript(WKUserScript(source: """
      const sendPoodle = (method, values = []) =>
        window.webkit.messageHandlers.poodle.postMessage({method, values});
      window.PoodleHost = {
        ready: () => sendPoodle("ready"),
        rendered: () => sendPoodle("rendered"),
        failed: () => sendPoodle("failed"),
        motionSound: event => sendPoodle("motionSound", [event]),
        bowlBounds: (...bounds) => sendPoodle("bowlBounds", bounds),
        bathTargets: json => sendPoodle("bathTargets", JSON.parse(json)),
        vetTargets: json => sendPoodle("vetTargets", JSON.parse(json)),
        groomTargets: json => sendPoodle("groomTargets", JSON.parse(json)),
        sleepBounds: json => sendPoodle("sleepBounds", JSON.parse(json))
      };
      """, injectionTime: .atDocumentStart, forMainFrameOnly: true))
    web = WKWebView(frame: frame, configuration: settings)
    channel = FlutterMethodChannel(name: "my_poodle/3d/\(id)", binaryMessenger: messenger)
    super.init()
    messages.owner = self
    web.navigationDelegate = self
    web.isOpaque = false
    web.backgroundColor = .clear
    web.underPageBackgroundColor = .clear
    web.scrollView.backgroundColor = .clear
    web.scrollView.contentInsetAdjustmentBehavior = .never
    web.isUserInteractionEnabled = false
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterMethodNotImplemented)
        return
      }
      self.handle(call, result: result)
    }
    web.load(URLRequest(url: PoodleAssets.index))
  }

  func view() -> UIView { web }

  deinit {
    channel.setMethodCallHandler(nil)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "configure":
      if let value = json(call.arguments) {
        configuration = value
        execute("configure(\(value))")
      }
    case "pet", "front":
      execute("\(call.method)()")
    case "petAt":
      guard ready, let point = call.arguments as? [Double], point.count == 2,
        point.allSatisfy({ (0.0...1.0).contains($0) }), let value = json(point)
      else {
        result(0)
        return
      }
      web.evaluateJavaScript("window.poodle.petAt(\(value))") { value, _ in
        result((value as? NSNumber)?.intValue ?? 0)
      }
      return
    case "rotate", "feed", "bath", "vet", "groom", "sleep", "walk", "orchard", "frisbee":
      if let value = json(call.arguments) { execute("\(call.method)(\(value))") }
    default:
      result(FlutterMethodNotImplemented)
      return
    }
    result(nil)
  }

  private func json(_ value: Any?) -> String? {
    guard let value, let data = try? JSONSerialization.data(withJSONObject: value, options: .fragmentsAllowed)
    else { return nil }
    return String(data: data, encoding: .utf8)
  }

  private func execute(_ command: String) {
    if ready { web.evaluateJavaScript("window.poodle.\(command)") }
  }

  func receive(_ body: Any) {
    guard let payload = body as? [String: Any], let method = payload["method"] as? String else { return }
    switch method {
    case "ready":
      ready = true
      if let configuration { execute("configure(\(configuration))") }
    case "rendered":
      channel.invokeMethod("ready", arguments: nil)
    case "failed":
      fail()
    case "motionSound":
      if ready, let values = payload["values"] as? [Int], values.count == 1,
        let event = values.first, (0...1).contains(event)
      {
        channel.invokeMethod("motionSound", arguments: event)
      }
    default:
      guard ready, let count = coordinateCounts[method], let values = payload["values"] as? [Double],
        values.count == count, values.allSatisfy(\.isFinite)
      else { return }
      channel.invokeMethod(method, arguments: values)
    }
  }

  private func fail() {
    ready = false
    channel.invokeMethod("failed", arguments: nil)
  }

  func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    fail()
  }

  func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
    fail()
  }
}
