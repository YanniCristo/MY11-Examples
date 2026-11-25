import 'dart:async';
import 'dart:convert';
import 'dart:io' show ContentType, HttpClient, Platform;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiktok_events_sdk/tiktok_events_sdk.dart';

import 'ads_config.dart';

/// Misura delle campagne pubblicitarie: Meta, TikTok, Google (Firebase) e
/// Apple Ads. Un solo punto per tutti: l'app chiama [event] e qui si manda
/// a ogni piattaforma attiva.
///
/// - Nel browser non fa nulla.
/// - Ogni piattaforma con i codici ancora segnaposto resta spenta.
/// - Su iPhone si chiede prima il permesso di tracciamento (ATT): senza,
///   Meta e TikTok ricevono solo dati anonimi.
/// - Nulla di ciò che l'utente taglia esce mai dal telefono: si mandano solo
///   nomi di eventi ("primo taglio"...).
class AdsTracker {
  AdsTracker._();
  static final AdsTracker instance = AdsTracker._();

  static bool get _native => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  bool _started = false;
  bool _meta = false, _tiktok = false;
  FirebaseAnalytics? _ga;
  FacebookAppEvents? _fb;

  /// All'avvio, dopo che la prima schermata è comparsa.
  Future<void> start() async {
    if (!_native || _started) return;
    _started = true;
    var tracking = !Platform.isIOS;
    if (Platform.isIOS) tracking = await _askTracking();

    await _safe('Firebase', () async {
      if (!AdsConfig.firebase) return;
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: Platform.isIOS
              ? AdsConfig.firebaseIosApiKey
              : AdsConfig.firebaseAndroidApiKey,
          appId: Platform.isIOS
              ? AdsConfig.firebaseIosAppId
              : AdsConfig.firebaseAndroidAppId,
          messagingSenderId: AdsConfig.firebaseSenderId,
          projectId: AdsConfig.firebaseProjectId,
        ),
      );
      _ga = FirebaseAnalytics.instance;
      await _ga!.setAnalyticsCollectionEnabled(true);
    });

    await _safe('Meta', () async {
      if (!AdsConfig.meta) return;
      final fb = FacebookAppEvents();
      await fb.initializeSdk();
      // su iPhone il consenso lo legge l'SDK stesso dalla richiesta ATT
      await fb.setAdvertiserIdCollectionEnabled(tracking);
      await fb.activateApp();
      _fb = fb;
      _meta = true;
    });

    await _safe('TikTok', () async {
      if (!AdsConfig.tiktok) return;
      await TikTokEventsSdk.initSdk(
        androidAppId: AdsConfig.tiktokAndroidAppId,
        tikTokAndroidId: AdsConfig.tiktokAndroidId,
        iosAppId: AdsConfig.tiktokIosAppId,
        tiktokIosId: AdsConfig.tiktokIosId,
        isDebugMode: kDebugMode,
        iosOptions: TikTokIosOptions(disableTracking: !tracking),
      );
      _tiktok = true;
    });

    if (Platform.isIOS) unawaited(_appleAds());
  }

  /// Richiesta di tracciamento di Apple, una volta sola (poi iOS ricorda).
  Future<bool> _askTracking() async {
    try {
      var s = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (s == TrackingStatus.notDetermined) {
        // Apple vuole l'app già attiva sullo schermo
        await Future<void>.delayed(const Duration(milliseconds: 800));
        s = await AppTrackingTransparency.requestTrackingAuthorization();
      }
      return s == TrackingStatus.authorized;
    } catch (_) {
      return false;
    }
  }

  /// Apple Ads: chiede ad Apple se l'installazione arriva da una campagna e
  /// lo segna in Firebase (una volta sola). Non serve il permesso ATT.
  Future<void> _appleAds() async {
    await _safe('Apple Ads', () async {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('ads_apple_done') ?? false) return;
      final token = await const MethodChannel('smashcrop/apple_ads')
          .invokeMethod<String>('token');
      if (token == null) return;
      // Apple consiglia di aspettare qualche secondo prima di chiedere
      await Future<void>.delayed(const Duration(seconds: 5));
      final client = HttpClient();
      try {
        final req = await client.postUrl(
          Uri.parse('https://api-adservices.apple.com/api/v1/'),
        );
        req.headers.contentType = ContentType.text;
        req.write(token);
        final res = await req.close();
        if (res.statusCode != 200) return;
        final body = await res.transform(utf8.decoder).join();
        final m = jsonDecode(body) as Map<String, dynamic>;
        await prefs.setBool('ads_apple_done', true);
        if (m['attribution'] == true) {
          await _ga?.logEvent(
            name: 'apple_ads_install',
            parameters: {
              'campaign_id': '${m['campaignId'] ?? ''}',
              'ad_group_id': '${m['adGroupId'] ?? ''}',
              'keyword_id': '${m['keywordId'] ?? ''}',
            },
          );
        }
      } finally {
        client.close();
      }
    });
  }

  // --- eventi ---------------------------------------------------------------

  /// Primo taglio fatto (l'utente ha capito l'app).
  void firstCut() => _once('first_cut');

  /// Primo file salvato o condiviso (l'app gli è servita davvero).
  void firstSave() => _once('first_save');

  /// Prima evoluzione di SMASH (utente affezionato).
  void firstEvolution() => _once('first_evolution');

  /// Acquisto a vita: il valore vero per le campagne.
  Future<void> lifetimePurchase({
    required double price,
    required String currency,
  }) async {
    if (!_native) return;
    await _safe('acquisto', () async {
      await _ga?.logPurchase(
        currency: currency,
        value: price,
        items: [AnalyticsEventItem(itemId: 'lifetime', itemName: 'lifetime')],
      );
      if (_meta) await _fb?.logPurchase(amount: price, currency: currency);
      if (_tiktok) {
        await TikTokEventsSdk.logEvent(
          event: TikTokEvent(eventName: 'Purchase'),
        );
      }
    });
  }

  Future<void> _once(String name) async {
    if (!_native) return;
    await _safe(name, () async {
      final prefs = await SharedPreferences.getInstance();
      final key = 'ads_ev_$name';
      if (prefs.getBool(key) ?? false) return;
      await prefs.setBool(key, true);
      await _ga?.logEvent(name: name);
      if (_meta) await _fb?.logEvent(name: name);
      if (_tiktok) {
        await TikTokEventsSdk.logEvent(event: TikTokEvent(eventName: name));
      }
    });
  }

  Future<void> _safe(String what, Future<void> Function() f) async {
    try {
      await f();
    } catch (e) {
      if (kDebugMode) debugPrint('pubblicità ($what): $e');
    }
  }
}
