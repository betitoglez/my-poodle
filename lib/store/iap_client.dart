import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

/// Frontera pequeña e inyectable con el plugin oficial. Los objetos nativos
/// solo viven en memoria: no se escriben recibos ni tokens en el guardado.
abstract class IapClient {
  Stream<List<PurchaseDetails>> get purchases;
  Future<bool> isAvailable();
  Future<ProductDetailsResponse> queryProduct(String productId);
  Future<bool> buy(ProductDetails product);
  Future<void> restore();
  Future<void> complete(PurchaseDetails purchase);
  Future<QueryPurchaseDetailsResponse> queryAndroidPurchases();
}

class NativeIapClient implements IapClient {
  // Inicialización perezosa: nunca se toca el singleton desde web/escritorio.
  InAppPurchase get _iap => InAppPurchase.instance;

  @override
  Stream<List<PurchaseDetails>> get purchases => _iap.purchaseStream;
  @override
  Future<bool> isAvailable() => _iap.isAvailable();
  @override
  Future<ProductDetailsResponse> queryProduct(String id) =>
      _iap.queryProductDetails({id});
  @override
  Future<bool> buy(ProductDetails product) => _iap.buyNonConsumable(
    purchaseParam: PurchaseParam(productDetails: product),
  );
  @override
  Future<void> restore() => _iap.restorePurchases();
  @override
  Future<void> complete(PurchaseDetails purchase) =>
      _iap.completePurchase(purchase);
  @override
  Future<QueryPurchaseDetailsResponse> queryAndroidPurchases() => _iap
      .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>()
      .queryPastPurchases();
}
