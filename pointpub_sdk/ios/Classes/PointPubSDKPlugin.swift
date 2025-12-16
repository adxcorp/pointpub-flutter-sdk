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

// MARK: - PointPubSDKPlugin

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
  
  // MARK: - Constants
  
  private enum ErrorCode {
    static let setAppIdFailed = "SET_APP_ID_FAILED"
    static let setUserIdFailed = "SET_USER_ID_FAILED"
    static let startOfferwallFailed = "START_OFFERWALL_FAILED"
    static let getVirtualPointFailed = "GET_VIRTUAL_POINT_FAILED"
    static let spendVirtualPointFailed = "SPEND_VIRTUAL_POINT_FAILED"
    static let getCompletedCampaignFailed = "GET_COMPLETED_CAMPAIGN_FAILED"
  }
  
  private enum ErrorMessage {
    static let missingAppId = "[PointPub] Missing appId: The 'appId' argument was not provided or is empty"
    static let missingUserId = "[PointPub] Missing userId: The 'userId' argument was not provided or is empty"
    static let invalidPresentationContext = "[PointPub] Invalid presentation context: rootViewController is nil or not attached to a window. Call startOfferWall after the app’s window and rootViewController are set"
    static let missingPoint = "[PointPub] Missing point: The 'point' argument was not provided or is empty. Pass a positive integer value for 'point' to spendVirtualPoint"
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
  
  deinit {
    PointPub.delegate = nil
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
      PointPub.setAppId(with: appId)
      sendResultOnMain(result, value: nil)

    case .setUserId:
      guard let userId: String = extract(call, key: "userId"), !userId.isEmpty else {
        sendErrorOnMain(result, code: ErrorCode.setUserIdFailed, message: ErrorMessage.missingUserId)
        return
      }
      PointPub.setUserId(with: userId)
      sendResultOnMain(result, value: nil)

    case .startOfferWall:
      guard let presenter = currentRootViewController() else {
        sendErrorOnMain(result, code: ErrorCode.startOfferwallFailed, message: ErrorMessage.invalidPresentationContext)
        return
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

    case .getCompletedCampaign:
      runAsync(result, errorCode: ErrorCode.getCompletedCampaignFailed) {
        let jsonString = try await PointPub.getCompletedCampaign()
        return jsonString
      }
    }
  }
  
  // MARK: - EventChannel
  
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    // 이벤트 구독이 시작되었을 때 delegate가 해제되어 있었다면 재설정
    setListener()
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    // 명시적 정리
    PointPub.delegate = nil
    return nil
  }
  
  // MARK: - Helpers (Arguments / Results / Presentation)
  
  // 타입-세이프 인자 추출
  private func extract<T>(_ call: FlutterMethodCall, key: String) -> T? {
    (call.arguments as? [String: Any])?[key] as? T
  }
  
  // 항상 메인에서 result 호출
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
  
  // 공통 비동기 실행 래퍼: 에러를 FlutterError로 변환해 메인에서 반환
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

  // 현재 표시 가능한 루트 VC 획득
  private func currentRootViewController() -> UIViewController? {
    UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController
  }
}
