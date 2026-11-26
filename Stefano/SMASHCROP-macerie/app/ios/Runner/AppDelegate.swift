import AdServices
import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // notifiche di SMASH visibili anche con l'app aperta
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "CloudSave") {
      CloudSave.register(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AppleAds") {
      // Apple Ads: il "gettone" di attribuzione (nessun SDK esterno, nessun
      // permesso di tracciamento richiesto)
      let channel = FlutterMethodChannel(name: "smashcrop/apple_ads", binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { call, result in
        guard call.method == "token" else { result(FlutterMethodNotImplemented); return }
        if #available(iOS 14.3, *) {
          result(try? AAAttribution.attributionToken())
        } else {
          result(nil)
        }
      }
      AppleAdsChannel.shared = channel
    }
  }
}

/// Contatore delle macerie nello spazio chiave-valore di iCloud: niente login,
/// segue l'ID Apple dell'utente. Serve la capability iCloud > Key-value storage;
/// senza, i dati restano solo su questo iPhone e l'app funziona lo stesso.
final class CloudSave: NSObject {
  private let channel: FlutterMethodChannel
  private let store = NSUbiquitousKeyValueStore.default
  private static var shared: CloudSave?

  private init(channel: FlutterMethodChannel) {
    self.channel = channel
    super.init()
    NotificationCenter.default.addObserver(
      self, selector: #selector(changed(_:)),
      name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: store)
    store.synchronize()
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "smashcrop/cloud", binaryMessenger: registrar.messenger())
    let instance = CloudSave(channel: channel)
    channel.setMethodCallHandler { call, result in instance.handle(call, result) }
    shared = instance
  }

  private func handle(_ call: FlutterMethodCall, _ result: FlutterResult) {
    let args = call.arguments as? [String: Any]
    guard let key = args?["key"] as? String else { result(nil); return }
    switch call.method {
    case "read":
      result(store.string(forKey: key))
    case "write":
      store.set(args?["value"] as? String, forKey: key)
      store.synchronize()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  @objc private func changed(_ note: Notification) {
    guard let keys = note.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else { return }
    for key in keys {
      if let value = store.string(forKey: key) {
        DispatchQueue.main.async { self.channel.invokeMethod("changed", arguments: value) }
      }
    }
  }
}

/// Tiene vivo il canale di Apple Ads.
enum AppleAdsChannel {
  static var shared: FlutterMethodChannel?
}

