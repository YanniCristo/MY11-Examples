import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../ads/ads_tracker.dart';
import '../rubble/application/rubble_store.dart';

/// Cosa è successo con l'acquisto (per mostrarlo nella schermata).
enum PremiumEvent { purchased, restored, nothingToRestore, error, unavailable }

/// L'acquisto "SmashCrop a vita": un acquisto in-app non consumabile,
/// pagato una volta. Si recupera con "Ripristina acquisti".
class Premium extends ChangeNotifier {
  Premium._();
  static final instance = Premium._();

  /// ID del prodotto da creare uguale in App Store Connect
  /// ("Non-Consumable") e in Google Play Console (prodotto singolo).
  static const productId = 'smashcrop_lifetime';

  ProductDetails? product;
  bool busy = false;
  bool _started = false;
  bool _restoring = false;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  final _events = StreamController<PremiumEvent>.broadcast();
  Stream<PremiumEvent> get events => _events.stream;

  bool get owned => RubbleStore.instance.lifetime;

  /// Prezzo nella valuta del negozio dell'utente (es. "4,99 €"), se noto.
  String? get price => product?.price;

  /// Nel browser non si può comprare: solo nelle app degli store.
  bool get canBuy => !kIsWeb;

  Future<void> start() async {
    if (_started || kIsWeb) return;
    _started = true;
    try {
      final iap = InAppPurchase.instance;
      _sub = iap.purchaseStream.listen(_onPurchases, onError: (_) {});
      if (!await iap.isAvailable()) return;
      final r = await iap.queryProductDetails({productId});
      if (r.productDetails.isNotEmpty) {
        product = r.productDetails.first;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> buy() async {
    if (!canBuy) return _emit(PremiumEvent.unavailable);
    if (product == null) await _retryProduct();
    final p = product;
    if (p == null) return _emit(PremiumEvent.unavailable);
    _setBusy(true);
    try {
      final ok = await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: p),
      );
      if (!ok) _fail();
    } catch (_) {
      _fail();
    }
  }

  Future<void> restore() async {
    if (!canBuy) return _emit(PremiumEvent.unavailable);
    _setBusy(true);
    _restoring = true;
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (_) {
      _restoring = false;
      _fail();
      return;
    }
    // se lo store non trova niente non manda nessuna risposta
    Timer(const Duration(seconds: 6), () {
      if (!_restoring) return;
      _restoring = false;
      _setBusy(false);
      _emit(owned ? PremiumEvent.restored : PremiumEvent.nothingToRestore);
    });
  }

  Future<void> _retryProduct() async {
    try {
      final r = await InAppPurchase.instance.queryProductDetails({productId});
      if (r.productDetails.isNotEmpty) product = r.productDetails.first;
    } catch (_) {}
  }

  Future<void> _onPurchases(List<PurchaseDetails> list) async {
    for (final p in list) {
      if (p.productID == productId) {
        switch (p.status) {
          case PurchaseStatus.purchased:
            _grant(bought: true);
            _emit(PremiumEvent.purchased);
            final d = product;
            if (d != null) {
              unawaited(
                AdsTracker.instance.lifetimePurchase(
                  price: d.rawPrice,
                  currency: d.currencyCode,
                ),
              );
            }
          case PurchaseStatus.restored:
            _grant(bought: false);
            if (_restoring) {
              _restoring = false;
              _emit(PremiumEvent.restored);
            }
          case PurchaseStatus.error:
            _fail();
          case PurchaseStatus.canceled:
            _setBusy(false);
          case PurchaseStatus.pending:
            break;
        }
      }
      if (p.pendingCompletePurchase) {
        try {
          await InAppPurchase.instance.completePurchase(p);
        } catch (_) {}
      }
    }
  }

  void _grant({required bool bought}) {
    _setBusy(false);
    final s = RubbleStore.instance;
    if (s.lifetime && !bought) return;
    s.flag((s) {
      s.lifetime = true;
      // appena comprato si indossa subito Tycoon
      if (bought) s.skinId = 'tycoon';
    });
    notifyListeners();
  }

  void _fail() {
    _setBusy(false);
    _emit(PremiumEvent.error);
  }

  void _setBusy(bool v) {
    if (busy == v) return;
    busy = v;
    notifyListeners();
  }

  void _emit(PremiumEvent e) {
    if (e != PremiumEvent.restored) _setBusy(false);
    _events.add(e);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
