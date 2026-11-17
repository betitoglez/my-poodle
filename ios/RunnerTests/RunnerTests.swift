import Flutter
import StoreKit
import StoreKitTest
import XCTest

/// Ejecutar solo en un simulador dedicado: prueba StoreKit → plugin → Dart →
/// derecho persistido. No necesita cuenta ni hace cargos reales.
@available(iOS 17.0, *)
final class RunnerTests: XCTestCase {
  private let productID = "mypoodle.full_version"

  @MainActor
  private func waitForState(_ state: String, timeout: TimeInterval = 20) async throws {
    let base = try FileManager.default.url(
      for: .applicationSupportDirectory, in: .userDomainMask,
      appropriateFor: nil, create: false)
    let url = base.appendingPathComponent("MyPoodle/entitlement.json")
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
      if let data = try? Data(contentsOf: url),
         let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
         json["state"] as? String == state,
         json["source"] as? String == "store" {
        XCTAssertEqual(json["full"] as? Bool, state == "purchased")
        return
      }
      try await Task.sleep(for: .milliseconds(100))
    }
    XCTFail("No se persistió el estado \(state) desde StoreKit")
    throw NSError(domain: "MyPoodle.StoreKitTest", code: 1)
  }

  @MainActor
  func testStoreKitPurchaseAndRefundReachFlutter() async throws {
    #if targetEnvironment(simulator)
    let url = try XCTUnwrap(Bundle(for: RunnerTests.self).url(
      forResource: "MyPoodle", withExtension: "storekit"))
    let session = try SKTestSession(contentsOf: url)
    session.resetToDefaultState()
    session.disableDialogs = true
    session.clearTransactions()
    defer { session.clearTransactions() }
    // Permitir que el host Flutter termine de arrancar y escuche la tienda.
    try await Task.sleep(for: .seconds(3))
    let transaction = try await session.buyProduct(identifier: productID)
    try await waitForState("purchased")
    try session.refundTransaction(identifier: UInt(transaction.id))
    try await waitForState("revoked")
    #else
    throw XCTSkip("Usar un simulador dedicado; no ejecutar sobre partidas reales")
    #endif
  }
}
