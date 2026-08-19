import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scanpdf/config/app_config.dart';
import 'package:scanpdf/features/settings/presentation/providers/settings_provider.dart';
import 'package:scanpdf/services/purchase_service.dart';
import 'package:scanpdf/services/analytics_service.dart';
import 'package:scanpdf/core/constants/app_constants.dart';

part 'plus_provider.g.dart';

/// Owns the app-lifetime purchase stream (keepAlive) so renewals and
/// restores are observed no matter which screen is open.
@Riverpod(keepAlive: true)
class Plus extends _$Plus {
  PurchaseService? _service;

  @override
  PlusState build() {
    final appState = ref.read(appStateRepositoryProvider);
    final analytics = ref.read(analyticsServiceProvider);
    analytics.setSubscriptionStatus(appState.plusActive);
    final service = PurchaseService(
      onPurchaseValidated: (purchase) async {
        final active = await _validatePurchase(purchase);
        await appState.setPlusActive(active);
        return active;
      },
      onStateChanged: (update) {
        final previous = state;
        final next = update(previous);
        state = next;
        analytics.setSubscriptionStatus(next.isActive);
        if (!previous.isActive && next.isActive) {
          Future<void>.microtask(
            () => analytics.track('plus_purchase_completed'),
          );
        } else if (previous.error != next.error && next.error != null) {
          Future<void>.microtask(
            () => analytics.track(
              'plus_purchase_failed',
              properties: {'error_code': next.error},
            ),
          );
        }
      },
    );
    _service = service;
    ref.onDispose(service.dispose);
    // Fire and forget: product loading updates state via callbacks.
    Future<void>.microtask(() async {
      await service.init();
      await _refreshBackendEntitlement();
    });
    return PlusState(isActive: appState.plusActive);
  }

  Future<bool> _validatePurchase(PurchaseDetails purchase) async {
    if (!AppConfig.hasSupabase ||
        !BackendRuntime.supabaseReady ||
        Supabase.instance.client.auth.currentUser == null) {
      return true;
    }
    final transactionId = purchase.purchaseID;
    if (transactionId == null || transactionId.isEmpty) {
      throw StateError('StoreKit did not return a transaction identifier.');
    }
    final response = await Supabase.instance.client.functions.invoke(
      'validate_entitlement',
      body: {'transaction_id': transactionId},
    );
    final data = response.data as Map<String, dynamic>?;
    return data?['active'] == true;
  }

  Future<void> _refreshBackendEntitlement() async {
    if (!AppConfig.hasSupabase ||
        !BackendRuntime.supabaseReady ||
        Supabase.instance.client.auth.currentUser == null) {
      return;
    }
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final row = await Supabase.instance.client
          .from('subscriptions')
          .select('status,current_period_end')
          .eq('user_id', userId)
          .maybeSingle();
      final status = row?['status'] as String?;
      final end = DateTime.tryParse(
        row?['current_period_end'] as String? ?? '',
      );
      final active =
          (status == 'active' || status == 'trialing') &&
          (end == null || end.isAfter(DateTime.now()));

      // The schema seeds every new auth user a subscriptions row with
      // status 'free' (handle_new_user trigger), and validate_entitlement may
      // not have written the real status yet. Treating that as authoritative
      // revokes Plus from someone who just paid — and from a guest who bought
      // before signing in. Only an explicit terminal status revokes; anything
      // else leaves the locally verified StoreKit entitlement untouched.
      const revoking = {
        'expired',
        'cancelled',
        'canceled',
        'revoked',
        'refunded',
      };
      final appState = ref.read(appStateRepositoryProvider);
      if (!active && !revoking.contains(status)) {
        // No backend opinion yet — report status but keep the entitlement.
        await ref
            .read(analyticsServiceProvider)
            .track(
              'subscription_status_updated',
              properties: {'status': status ?? 'unknown'},
            );
        return;
      }
      await appState.setPlusActive(active);
      state = state.copyWith(isActive: active);
      ref.read(analyticsServiceProvider).setSubscriptionStatus(active);
      await ref
          .read(analyticsServiceProvider)
          .track(
            'subscription_status_updated',
            properties: {'status': status ?? 'unknown'},
          );
    } catch (_) {
      // Keep last verified entitlement for offline use; restore retries later.
    }
  }

  /// Switches which Plus plan the paywall CTA will buy.
  void selectProduct(String productId) {
    if (!AppConstants.plusProductIds.contains(productId)) return;
    if (state.selectedProductId == productId) return;
    state = state.copyWith(selectedProductId: productId, clearError: true);
  }

  Future<void> buy() async {
    final product = state.selectedProduct;
    if (product == null) return;
    await ref
        .read(analyticsServiceProvider)
        .track('plus_purchase_started', properties: {'product_id': product.id});
    await _service?.buy(product);
  }

  /// Runs a StoreKit restore and returns the outcome as a ready-to-show
  /// message so entry points without an inline error slot (Settings) can
  /// surface it. The same text is left in [PlusState.error] for screens that
  /// render it inline (the paywall).
  Future<String> restore() async {
    await ref.read(analyticsServiceProvider).track('restore_purchases_clicked');
    await _service?.restore();
    return state.error ?? 'Your purchases have been restored.';
  }

  Future<void> reloadProduct() => _service?.loadProduct() ?? Future.value();

  Future<void> refreshEntitlement() => _refreshBackendEntitlement();
}
