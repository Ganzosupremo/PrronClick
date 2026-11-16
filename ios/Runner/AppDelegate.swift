import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // "request": asks for the microphone (latency calibration); replies granted or not.
    FlutterMethodChannel(
      name: "prronclick/mic", binaryMessenger: engineBridge.applicationRegistrar.messenger()
    ).setMethodCallHandler { call, result in
      guard call.method == "request" else { return result(FlutterMethodNotImplemented) }
      AVAudioSession.sharedInstance().requestRecordPermission { granted in
        DispatchQueue.main.async { result(granted) }
      }
    }
  }
}
