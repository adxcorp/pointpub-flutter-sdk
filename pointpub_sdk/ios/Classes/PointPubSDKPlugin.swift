import Flutter
import UIKit
import PointPubSDK

// MARK: - PointPubSDKListener

fileprivate class PointPubSDKListener: NSObject, PointPubDelegate {
  
  enum OfferWallEvent {
    case opened
    case closed
  }
  
  private let handler: (OfferWallEvent) -> Void
  
  init(handler: @escaping (OfferWallEvent) -> Void) {
    self.handler = handler
  }
  
  func onOpenOfferwall() {
    handler(.opened)
  }
  
  func onCloseOfferwall() {
    handler(.closed)
  }
}

// MARK: - PointpubSdkPlugin

public final class PointPubSDKPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  
  // MARK: - PointPubAPI
  
  enum PointPubAPI: String {
    case checkTrackingAndRequestIfNeeded = "checkTrackingAndRequestIfNeeded"
    case setAppId = "setAppId"
    case setUserId = "setUserId"
    case startOfferWall = "startOfferWall"
    case getVirtualPoint = "getVirtualPoint"
    case spendVirtualPoint = "spendVirtualPoint"
    case getCompletedCampaign = "getCompletedCampaign"
  }
  
  // MARK: - Properties
  
  private static let channelName = "pointpub_sdk"
  private static let eventChannelName = "pointpub_sdk/events"
  private var eventSink: FlutterEventSink?
  private var pointpubListener: PointPubSDKListener?
  
  // MARK: - Init
  
  override init() {
    super.init()
    
    setListener()
  }
  
  // MARK: - Regist
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger()
    )
    let eventChannel = FlutterEventChannel(
      name: eventChannelName,
      binaryMessenger: registrar.messenger()
    )

    let instance = PointPubSDKPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    eventChannel.setStreamHandler(instance)
  }
  
  private func setListener() {
    pointpubListener = PointPubSDKListener { [weak self] event in
      guard let self = self else { return }
      switch event {
      case .opened:
        self.eventSink?(["event": "onOpenOfferWall"])
        
      case .closed:
        self.eventSink?(["event": "onCloseOfferWall"])
      }
    }
    PointPub.delegate = pointpubListener
  }
  
  // MARK: - Method Channel
  
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let method = PointPubAPI(rawValue: call.method)
    switch method {
    case .checkTrackingAndRequestIfNeeded:
      let isTrackingEnabled = PointPub.isTrackingEnabled()
      if !isTrackingEnabled {
        PointPub.requestTrackingPermission { _ in }
      }
    case .setAppId:
      if let args = call.arguments as? [String: Any], let appId = args["appId"] as? String {
        PointPub.setAppId(with: appId)
      }
      result(nil)
    case .setUserId:
      if let args = call.arguments as? [String: Any], let userId = args["userId"] as? String {
        PointPub.setUserId(with: userId)
      }
      result(nil)
    case .startOfferWall:
      guard let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
            let rootViewController = keyWindow.rootViewController
      else {
        result(nil)
        return
      }
      if !PointPub.isTrackingEnabled() {
        PointPub.requestTrackingPermission { _ in
          PointPub.startOfferwall(from: rootViewController)
        }
      }
      PointPub.startOfferwall(from: rootViewController)
      result(nil)
    case .getVirtualPoint:
      Task {
        do {
          let (pointName, point) = try await PointPub.getVirtualPoint()
          result(["pointName": pointName, "point": point])
        } catch {
          result(error.localizedDescription)
        }
      }
    case .spendVirtualPoint:
      Task {
        do {
          let (pointName, point) = try await PointPub.spendVirtualPoint(point: 10)
          result(["pointName": pointName, "point": point])
        } catch {
          result(error.localizedDescription)
        }
      }
    case .getCompletedCampaign:
      Task {
        do {
          let jsonString = try await PointPub.getCompletedCampaign()
          result(jsonString)
        } catch {
          result(error.localizedDescription)
        }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  // MARK: - EventChannel
  
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
      self.eventSink = events
      return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
      self.eventSink = nil
      return nil
  }
}
