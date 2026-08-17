import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scanpdf/config/app_config.dart';
import 'package:scanpdf/features/settings/presentation/providers/settings_provider.dart';
import 'package:scanpdf/services/purchase_service.dart';
import 'package:scanpdf/services/analytics_service.dart';

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
      await ref.read(appStateRepositoryProvider).setPlusActive(active);
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

  Future<void> buy() async {
    final product = state.product;
    if (product == null) return;
    await ref.read(analyticsServiceProvider).track('plus_purchase_started');
    await _service?.buy(product);
  }

  Future<void> restore() async {
    await ref.read(analyticsServiceProvider).track('restore_purchases_clicked');
    await _service?.restore();
  }

  Future<void> reloadProduct() => _service?.loadProduct() ?? Future.value();

  Future<void> refreshEntitlement() => _refreshBackendEntitlement();
}
