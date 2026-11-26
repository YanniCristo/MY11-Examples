import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../app/strings.dart';
import '../ads/ads_tracker.dart';
import '../rubble/application/rubble_store.dart';
import '../rubble/domain/rubble_math.dart';

/// Notifiche di SMASH.
///
/// - **Locali** (sempre, senza server): tre promemoria programmati
///   dall'app, che si spostano in avanti ogni volta che la si usa. Così
///   arrivano solo a chi non apre l'app da un po'.
/// - **Push** (Firebase Cloud Messaging): partono solo quando in AdsConfig ci
///   sono i codici veri di Firebase. I messaggi si scrivono dalla console di
///   Firebase; ogni telefono è iscritto agli argomenti `tutti` e `lang_<lingua>`.
///
/// Il permesso si chiede una volta sola, dopo il primo file salvato (non
/// all'apertura, quando quasi tutti dicono di no). Nel browser niente.
class Notifications {
  Notifications._();
  static final instance = Notifications._();

  static bool get _native => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool _push = false;
  AppLifecycleListener? _life;

  /// Promemoria: dopo quanti giorni senza aprire l'app, alle 18:30.
  static const _days = [2, 6, 14];

  RubbleStore get _s => RubbleStore.instance;

  Future<void> start() async {
    if (!_native || _ready) return;
    try {
      tzdata.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_smash'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('notifiche: $e');
      return;
    }
    // quando l'app va in secondo piano i promemoria ripartono da adesso,
    // con i chili aggiornati
    _life = AppLifecycleListener(onPause: () => unawaited(reschedule()));
    _s.addListener(_onStore);
    _lastNotify = _s.notify;
    await reschedule();
    if (_s.notify && _s.notifyAsked) unawaited(_startPush());
  }

  bool _lastNotify = true;
  void _onStore() {
    if (_s.notify == _lastNotify) return;
    _lastNotify = _s.notify;
    unawaited(reschedule());
    if (_s.notify) {
      unawaited(askPermission());
    } else {
      unawaited(_stopPush());
    }
  }

  /// Chiede il permesso (una volta sola, poi decide l'utente nelle
  /// impostazioni del telefono). Si chiama dopo il primo salvataggio.
  Future<void> askPermission() async {
    if (!_ready || !_s.notify) return;
    final first = !_s.notifyAsked;
    if (first) _s.flag((s) => s.notifyAsked = true);
    try {
      if (Platform.isIOS) {
        await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      } else {
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      }
    } catch (_) {}
    await reschedule();
    await _startPush();
  }

  /// Cancella i promemoria e li riprogramma da adesso.
  Future<void> reschedule() async {
    if (!_ready) return;
    try {
      await _plugin.cancelAllPendingNotifications();
      if (!_s.notify || !_s.notifyAsked) return;
      final texts = _texts();
      for (var i = 0; i < _days.length; i++) {
        await _plugin.zonedSchedule(
          id: 100 + i,
          scheduledDate: _at(_days[i]),
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: texts[i].$1,
          body: texts[i].$2,
        );
      }
    } catch (e) {
      debugPrint('notifiche: $e');
    }
  }

  List<(String, String)> _texts() {
    final next = _s.nextEvolution;
    final hungry = next == null
        ? S.notifHungryBody
        : S.notifHungryNext(
            RubbleMath.format(
              RubbleMath.missing(_s.kg, next),
              comma: S.decimalComma,
            ),
            next.name,
          );
    return [
      (S.notifHungryTitle, hungry),
      (S.notifPunchTitle, S.notifPunchBody),
      (S.notifBoredTitle, S.notifBoredBody),
    ];
  }

  /// Fra [days] giorni alle 18:30, ora del telefono.
  static tz.TZDateTime _at(int days) {
    final now = DateTime.now();
    final d = DateTime(now.year, now.month, now.day + days, 18, 30);
    return tz.TZDateTime.from(d.toUtc(), tz.UTC);
  }

  NotificationDetails get _details => NotificationDetails(
    android: AndroidNotificationDetails(
      'smash_reminders',
      S.notifChannel,
      importance: Importance.defaultImportance,
      icon: 'ic_stat_smash',
      color: const Color(0xFFE5172F),
    ),
    iOS: const DarwinNotificationDetails(),
  );

  // --- push (Firebase Cloud Messaging) ----------------------------------------

  Future<void> _startPush() async {
    if (_push || !AdsTracker.instance.firebaseReady) return;
    try {
      final m = FirebaseMessaging.instance;
      // con l'app aperta: su iPhone la mostra il sistema, su Android la
      // mostriamo noi
      await m.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      FirebaseMessaging.onMessage.listen((msg) {
        final n = msg.notification;
        if (n == null || !Platform.isAndroid) return;
        _plugin.show(
          id: msg.hashCode,
          title: n.title,
          body: n.body,
          notificationDetails: _details,
        );
      });
      await m.subscribeToTopic('tutti');
      await m.subscribeToTopic('lang_${S.lang.name}');
      _push = true;
    } catch (e) {
      debugPrint('push: $e');
    }
  }

  Future<void> _stopPush() async {
    if (!_push) return;
    try {
      final m = FirebaseMessaging.instance;
      await m.unsubscribeFromTopic('tutti');
      await m.unsubscribeFromTopic('lang_${S.lang.name}');
    } catch (_) {}
    _push = false;
  }

  @visibleForTesting
  void dispose() {
    _life?.dispose();
    _s.removeListener(_onStore);
  }
}
