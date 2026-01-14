
import os
import UIKit

import Flutter
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

// MARK: - PointPubSDKPlugin

public final class PointPubSDKPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  
  // MARK: - PointPubAPI
  
  enum PointPubAPI: String {
    case checkTrackingAndRequestIfNeeded = "checkTrackingAndRequestIfNeeded"
    case setAppId = "setAppId"
    case setUserId = "setUserId"
    case setCallbackParameter = "setCallbackParameter"
    case startOfferWall = "startOfferWall"
    case getVirtualPoint = "getVirtualPoint"
    case spendVirtualPoint = "spendVirtualPoint"
  }
  
  // MARK: - Constants
  
  private enum ErrorCode {
    static let setAppIdFailed = "SET_APP_ID_FAILED"
    static let setUserIdFailed = "SET_USER_ID_FAILED"
    static let setCallbackParameterFailed = "SET_CALLBACK_PARAMETER_FAILED"
    static let startOfferwallFailed = "START_OFFERWALL_FAILED"
    static let getVirtualPointFailed = "GET_VIRTUAL_POINT_FAILED"
    static let spendVirtualPointFailed = "SPEND_VIRTUAL_POINT_FAILED"
  }
  
  private enum ErrorMessage {
    static let missingAppId = "[PointPub_Plugin] Missing appId: The 'appId' argument was not provided or is empty"
    static let missingUserId = "[PointPub_Plugin] Missing userId: The 'userId' argument was not provided or is empty"
    static let missingCallbackParameter = "[PointPub_Plugin] Missing callback parameter: The 'callback' argument was not provided or is empty"
    static let invalidPresentationContext = "[PointPub_Plugin] Invalid presentation context: rootViewController is nil or not attached to a window. Call startOfferWall after the app’s window and rootViewController are set"
    static let missingPoint = "[PointPub_Plugin] Missing point: The 'point' argument was not provided or is empty. Pass a positive integer value for 'point' to spendVirtualPoint"
  }
    
  // MARK: - Properties
  
  private static let channelName = "pointpub_sdk"
  private static let eventChannelName = "pointpub_sdk/events"
  private final let logName: String = "[PointPub_Plugin]"
  private var eventSink: FlutterEventSink?
  private var pointpubListener: PointPubSDKListener?
  private var appId: String = ""
  private var userId: String = ""
  
  // MARK: - Init
  
  override init() {
    super.init()
    
    setListener()
  }
  
  // MARK: - Register

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
    if pointpubListener == nil {
      pointpubListener = PointPubSDKListener { [weak self] event in
        guard let self else { return }
        switch event {
        case .opened:
          self.eventSink?(["event": "onOpenOfferWall"])
        case .closed:
          self.eventSink?(["event": "onCloseOfferWall"])
        }
      }
    }
    PointPub.delegate = pointpubListener
  }
  
  // MARK: - Method Channel
  
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    os_log("%{public}@ call.method: %{public}@", logName, call.method)

    guard let method = PointPubAPI(rawValue: call.method) else {
      result(FlutterMethodNotImplemented)
      return
    }
    
    switch method {
    case .checkTrackingAndRequestIfNeeded:
      let isTrackingEnabled = PointPub.isTrackingEnabled()
      if !isTrackingEnabled {
        PointPub.requestTrackingPermission { _ in }
      }
      sendResultOnMain(result, value: nil)

    case .setAppId:
      guard let appId: String = extract(call, key: "appId"), !appId.isEmpty else {
        sendErrorOnMain(result, code: ErrorCode.setAppIdFailed, message: ErrorMessage.missingAppId)
        return
      }
      self.appId = appId
      PointPub.setAppId(with: appId)
      sendResultOnMain(result, value: nil)

    case .setUserId:
      guard let userId: String = extract(call, key: "userId"), !userId.isEmpty else {
        sendErrorOnMain(result, code: ErrorCode.setUserIdFailed, message: ErrorMessage.missingUserId)
        return
      }
      self.userId = userId
      PointPub.setUserId(with: userId)
      sendResultOnMain(result, value: nil)

    case .setCallbackParameter:
      guard let callback: String = extract(call, key: "callback"), !callback.isEmpty else {
        sendErrorOnMain(result, code: ErrorCode.setCallbackParameterFailed, message: ErrorMessage.missingCallbackParameter)
        return
      }
      PointPub.setCallbackParameter(with: callback)
      sendResultOnMain(result, value: nil)

    case .startOfferWall:
      guard let presenter = currentRootViewController() else {
        sendErrorOnMain(result, code: ErrorCode.startOfferwallFailed, message: ErrorMessage.invalidPresentationContext)
        return
      }
      
      if let pluginVersion: String = extract(call, key: "pluginVersion"),
         let sdkVersion: String = extract(call, key: "sdkVersion")
      {
        os_log("%{public}@ PointPub Flutter Version: %{public}@, PointPub SDK Version: %{public}@, AppId: %{public}@, UserId: %{public}@", logName, pluginVersion, sdkVersion, appId, userId)
      }
      
      PointPub.startOfferwall(from: presenter)
      sendResultOnMain(result, value: nil)

    case .getVirtualPoint:
      runAsync(result, errorCode: ErrorCode.getVirtualPointFailed) {
        let (pointName, point) = try await PointPub.getVirtualPoint()
        return ["pointName": pointName, "point": point]
      }
      
    case .spendVirtualPoint:
      guard let point: Int = extract(call, key: "point") else {
        sendErrorOnMain(result, code: ErrorCode.spendVirtualPointFailed, message: ErrorMessage.missingPoint)
        return
      }
      runAsync(result, errorCode: ErrorCode.spendVirtualPointFailed) {
        let (pointName, remainingPoint) = try await PointPub.spendVirtualPoint(point: point)
        return ["pointName": pointName, "point": remainingPoint]
      }
    }
  }
  
  // MARK: - EventChannel
  
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    setListener()
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    PointPub.delegate = nil
    return nil
  }
  
  // MARK: - Helpers (Arguments / Results / Presentation)
  
  private func extract<T>(_ call: FlutterMethodCall, key: String) -> T? {
    (call.arguments as? [String: Any])?[key] as? T
  }
  
  private func sendResultOnMain(
    _ result: @escaping FlutterResult,
    value: Any?
  ) {
    Task { @MainActor in
      result(value)
    }
  }
  
  private func sendErrorOnMain(
    _ result: @escaping FlutterResult,
    code: String,
    message: String,
    details: Any? = nil
  ) {
    Task { @MainActor in
      result(FlutterError(code: code, message: message, details: details))
    }
  }
  
  private func runAsync(
    _ result: @escaping FlutterResult,
    errorCode: String,
    operation: @escaping () async throws -> Any
  ) {
    Task {
      do {
        let value = try await operation()
        await MainActor.run { result(value) }
      } catch {
        await MainActor.run {
          result(FlutterError(code: errorCode, message: error.localizedDescription, details: nil))
        }
      }
    }
  }

  private func currentRootViewController() -> UIViewController? {
    UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController
  }
}
