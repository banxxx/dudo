import Flutter
import AVFoundation
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var volumePageTurnEventChannel: FlutterEventChannel?
  private var volumePageTurnStreamHandler: VolumePageTurnStreamHandler?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let streamHandler = VolumePageTurnStreamHandler()
    let channel = FlutterEventChannel(
      name: "dudo.reader/volume_page_turn",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setStreamHandler(streamHandler)
    volumePageTurnEventChannel = channel
    volumePageTurnStreamHandler = streamHandler
  }
}

private final class VolumePageTurnStreamHandler: NSObject, FlutterStreamHandler {
  private let audioSession = AVAudioSession.sharedInstance()
  private var eventSink: FlutterEventSink?
  private var volumeObservation: NSKeyValueObservation?
  private var lastVolume: Float?
  private var lastEventTime = Date.distantPast
  private let minimumEventInterval: TimeInterval = 0.12

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    startObserving()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    stopObserving()
    eventSink = nil
    return nil
  }

  private func startObserving() {
    stopObserving()
    lastVolume = audioSession.outputVolume
    try? audioSession.setActive(true, options: [])
    volumeObservation = audioSession.observe(\.outputVolume, options: [.new]) { [weak self] _, change in
      guard let self = self, let nextVolume = change.newValue else { return }
      self.handleVolumeChange(nextVolume)
    }
  }

  private func stopObserving() {
    volumeObservation?.invalidate()
    volumeObservation = nil
    lastVolume = nil
  }

  private func handleVolumeChange(_ nextVolume: Float) {
    guard let eventSink = eventSink else { return }
    let previousVolume = lastVolume ?? nextVolume
    lastVolume = nextVolume

    let delta = nextVolume - previousVolume
    guard abs(delta) > 0.0001 else { return }

    let now = Date()
    guard now.timeIntervalSince(lastEventTime) >= minimumEventInterval else { return }
    lastEventTime = now

    DispatchQueue.main.async {
      eventSink(delta > 0 ? "volumeUp" : "volumeDown")
    }
  }
}
