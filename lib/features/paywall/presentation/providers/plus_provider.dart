import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:scanpdf/features/settings/presentation/providers/settings_provider.dart';
import 'package:scanpdf/services/purchase_service.dart';

part 'plus_provider.g.dart';

/// Owns the app-lifetime purchase stream (keepAlive) so renewals and
/// restores are observed no matter which screen is open.
@Riverpod(keepAlive: true)
class Plus extends _$Plus {
  PurchaseService? _service;

  @override
  PlusState build() {
    final appState = ref.read(appStateRepositoryProvider);
    final service = PurchaseService(
      onEntitlementChanged: (active) => appState.setPlusActive(active),
      onStateChanged: (update) => state = update(state),
    );
    _service = service;
    ref.onDispose(service.dispose);
    // Fire and forget: product loading updates state via callbacks.
    Future<void>.microtask(service.init);
    return PlusState(isActive: appState.plusActive);
  }

  Future<void> buy() async {
    final product = state.product;
    if (product == null) return;
    await _service?.buy(product);
  }

  Future<void> restore() => _service?.restore() ?? Future.value();

  Future<void> reloadProduct() =>
      _service?.loadProduct() ?? Future.value();
}
