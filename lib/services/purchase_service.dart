import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:scanpdf/core/constants/app_constants.dart';

/// Live paywall state derived from the store + persisted entitlement.
@immutable
class PlusState {
  const PlusState({
    this.isActive = false,
    this.storeAvailable = false,
    this.products = const [],
    this.selectedProductId = AppConstants.plusDefaultProductId,
    this.purchasing = false,
    this.error,
  });

  final bool isActive;
  final bool storeAvailable;

  /// Every Plus product StoreKit returned, in the order the paywall shows
  /// them (weekly first, then monthly).
  final List<ProductDetails> products;

  /// Which product the CTA will buy. Always one of
  /// [AppConstants.plusProductIds]; may not be loaded yet.
  final String selectedProductId;

  final bool purchasing;
  final String? error;

  ProductDetails? productFor(String id) {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  /// The product the CTA buys, or null when the store has not loaded it.
  ProductDetails? get selectedProduct => productFor(selectedProductId);

  /// Live localized price for [id], falling back to the published offer copy
  /// until StoreKit responds.
  String priceLabelFor(String id) =>
      productFor(id)?.price ?? AppConstants.fallbackPriceFor(id);

  /// Live localized price of the selected product.
  String get priceLabel => priceLabelFor(selectedProductId);

  PlusState copyWith({
    bool? isActive,
    bool? storeAvailable,
    List<ProductDetails>? products,
    String? selectedProductId,
    bool? purchasing,
    String? error,
    bool clearError = false,
  }) => PlusState(
    isActive: isActive ?? this.isActive,
    storeAvailable: storeAvailable ?? this.storeAvailable,
    products: products ?? this.products,
    selectedProductId: selectedProductId ?? this.selectedProductId,
    purchasing: purchasing ?? this.purchasing,
    error: clearError ? null : (error ?? this.error),
  );
}

/// Direct App Store IAP wrapper. Guest purchases stay device-local; signed-in
/// purchases are also validated by the backend entitlement service.
/// The purchase stream must be observed for the whole app lifetime so
/// renewals/restores land whenever they arrive.
class PurchaseService {
  PurchaseService({
    required this.onPurchaseValidated,
    required this.onStateChanged,
  });

  /// Validates a StoreKit purchase. Guest mode persists locally; signed-in
  /// mode verifies the transaction through the App Store Server API function.
  final Future<bool> Function(PurchaseDetails purchase) onPurchaseValidated;
  final void Function(PlusState Function(PlusState) update) onStateChanged;

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _sawRestorablePurchase = false;

  Future<void> init() async {
    _subscription = _iap.purchaseStream.listen(
      _handlePurchases,
      onError: (Object error) {
        onStateChanged((s) => s.copyWith(purchasing: false));
        debugPrint('purchaseStream error: $error');
      },
    );
    await loadProduct();
  }

  Future<void> loadProduct() async {
    try {
      final available = await _iap.isAvailable();
      debugPrint('PurchaseService: store available=$available');
      if (!available) {
        onStateChanged((s) => s.copyWith(storeAvailable: false));
        return;
      }
      final response = await _iap.queryProductDetails(
        AppConstants.plusProductIds,
      );
      debugPrint(
        'PurchaseService: notFoundIDs=${response.notFoundIDs} '
        'error=${response.error}',
      );
      if (response.productDetails.isEmpty) {
        // Almost always: Paid Apps agreement not Active, product not
        // "Ready to Submit", ID mismatch, or running on the Simulator.
        onStateChanged((s) => s.copyWith(storeAvailable: false));
        return;
      }
      // Show weekly first, monthly second, regardless of StoreKit's order.
      const order = [
        AppConstants.plusWeeklyProductId,
        AppConstants.plusMonthlyProductId,
      ];
      final products = [...response.productDetails]
        ..sort((a, b) => order.indexOf(a.id).compareTo(order.indexOf(b.id)));
      onStateChanged((s) {
        // Keep the user's choice when it is still purchasable; otherwise fall
        // back to the default, then to whatever the store did return.
        final ids = products.map((p) => p.id).toSet();
        final selected = ids.contains(s.selectedProductId)
            ? s.selectedProductId
            : ids.contains(AppConstants.plusDefaultProductId)
            ? AppConstants.plusDefaultProductId
            : products.first.id;
        return s.copyWith(
          storeAvailable: true,
          products: products,
          selectedProductId: selected,
        );
      });
    } catch (error) {
      debugPrint('PurchaseService.loadProduct failed: $error');
      onStateChanged((s) => s.copyWith(storeAvailable: false));
    }
  }

  Future<void> buy(ProductDetails product) async {
    onStateChanged((s) => s.copyWith(purchasing: true, clearError: true));
    try {
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (error) {
      debugPrint('PurchaseService.buy failed: $error');
      onStateChanged(
        (s) => s.copyWith(
          purchasing: false,
          error: 'Purchase could not be started.',
        ),
      );
    }
  }

  Future<void> restore() async {
    onStateChanged((s) => s.copyWith(purchasing: true, clearError: true));
    _sawRestorablePurchase = false;
    try {
      await _iap.restorePurchases();
      if (!_sawRestorablePurchase) {
        // StoreKit reports restored transactions on purchaseStream before
        // restorePurchases completes; allow a short grace window for the
        // events to be delivered before concluding nothing was restorable.
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      if (!_sawRestorablePurchase) {
        onStateChanged(
          (s) => s.copyWith(
            error: 'No previous purchase was found for this Apple ID.',
          ),
        );
      }
    } catch (error) {
      debugPrint('PurchaseService.restore failed: $error');
      onStateChanged(
        (s) => s.copyWith(
          error:
              'Purchases could not be restored. Check your connection and try again.',
        ),
      );
    } finally {
      onStateChanged((s) => s.copyWith(purchasing: false));
    }
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (AppConstants.plusProductIds.contains(purchase.productID)) {
            _sawRestorablePurchase = true;
            try {
              final active = await onPurchaseValidated(purchase);
              onStateChanged(
                (s) => s.copyWith(
                  isActive: active,
                  purchasing: false,
                  error: active
                      ? null
                      : 'The subscription could not be verified.',
                  clearError: active,
                ),
              );
            } catch (error) {
              debugPrint('PurchaseService validation failed: $error');
              onStateChanged(
                (s) => s.copyWith(
                  purchasing: false,
                  error:
                      'Purchase received, but secure verification is temporarily unavailable. Restore when online.',
                ),
              );
            }
          }
        case PurchaseStatus.error:
          onStateChanged(
            (s) => s.copyWith(
              purchasing: false,
              error: 'Purchase failed. You have not been charged.',
            ),
          );
        case PurchaseStatus.canceled:
          onStateChanged((s) => s.copyWith(purchasing: false));
        case PurchaseStatus.pending:
          onStateChanged((s) => s.copyWith(purchasing: true));
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
