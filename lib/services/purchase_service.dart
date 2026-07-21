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
    this.product,
    this.purchasing = false,
    this.error,
  });

  final bool isActive;
  final bool storeAvailable;
  final ProductDetails? product;
  final bool purchasing;
  final String? error;

  /// Live localized price, falling back to the Jira-specified offer.
  String get priceLabel => product?.price ?? AppConstants.plusFallbackPrice;

  PlusState copyWith({
    bool? isActive,
    bool? storeAvailable,
    ProductDetails? product,
    bool? purchasing,
    String? error,
    bool clearError = false,
  }) =>
      PlusState(
        isActive: isActive ?? this.isActive,
        storeAvailable: storeAvailable ?? this.storeAvailable,
        product: product ?? this.product,
        purchasing: purchasing ?? this.purchasing,
        error: clearError ? null : (error ?? this.error),
      );
}

/// Direct App Store IAP wrapper (no third-party billing, no account).
/// The purchase stream must be observed for the whole app lifetime so
/// renewals/restores land whenever they arrive.
class PurchaseService {
  PurchaseService({
    required this.onEntitlementChanged,
    required this.onStateChanged,
  });

  /// Persists the entitlement (Hive) when a purchase/restore lands.
  final void Function(bool active) onEntitlementChanged;
  final void Function(PlusState Function(PlusState) update) onStateChanged;

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

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
    if (AppConstants.plusProductId.isEmpty) {
      // Product not created in ASC yet — paywall shows store-unavailable.
      debugPrint('PurchaseService: plusProductId is EMPTY; set the exact '
          'ASC product ID in AppConstants before submitting the IAP.');
      onStateChanged((s) => s.copyWith(storeAvailable: false));
      return;
    }
    try {
      final available = await _iap.isAvailable();
      debugPrint('PurchaseService: store available=$available');
      if (!available) {
        onStateChanged((s) => s.copyWith(storeAvailable: false));
        return;
      }
      final response =
          await _iap.queryProductDetails({AppConstants.plusProductId});
      debugPrint('PurchaseService: notFoundIDs=${response.notFoundIDs} '
          'error=${response.error}');
      if (response.productDetails.isEmpty) {
        // Almost always: Paid Apps agreement not Active, product not
        // "Ready to Submit", ID mismatch, or running on the Simulator.
        onStateChanged((s) => s.copyWith(storeAvailable: false));
        return;
      }
      final product = response.productDetails.first;
      onStateChanged(
        (s) => s.copyWith(storeAvailable: true, product: product),
      );
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
    try {
      await _iap.restorePurchases();
    } catch (error) {
      debugPrint('PurchaseService.restore failed: $error');
    } finally {
      onStateChanged((s) => s.copyWith(purchasing: false));
    }
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (purchase.productID == AppConstants.plusProductId) {
            onEntitlementChanged(true);
            onStateChanged(
              (s) => s.copyWith(isActive: true, purchasing: false),
            );
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
