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
  }) => PlusState(
    isActive: isActive ?? this.isActive,
    storeAvailable: storeAvailable ?? this.storeAvailable,
    product: product ?? this.product,
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
      final response = await _iap.queryProductDetails({
        AppConstants.plusProductId,
      });
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
      final product = response.productDetails.first;
      onStateChanged((s) => s.copyWith(storeAvailable: true, product: product));
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
