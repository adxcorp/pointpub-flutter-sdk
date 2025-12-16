
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'pointpub_sdk_platform_interface.dart';

final class PointPubSDK with WidgetsBindingObserver {

  static const EventChannel _eventChannel = EventChannel('pointpub_sdk/events');
  static final PointPubSDK _instance = PointPubSDK._internal();
  factory PointPubSDK() => _instance;
  StreamSubscription? _subscription;

  PointPubSDK._internal() {
    WidgetsBinding.instance.addObserver(this);
    _startListening();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _disposeInternal();
    }
  }

  void _startListening() {
    _subscription ??= _eventChannel.receiveBroadcastStream().listen(
      _onEvent,
      onError: _onError,
    );
  }

  void _disposeInternal() {
    _subscription?.cancel();
    _subscription = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  void _onEvent(dynamic event) {
    if (event is Map) {
      final type = event["event"];

      switch (type) {
        case "onOpenOfferWall":
          print("[PointPub] OfferWall opened");
        case "onCloseOfferWall":
          print("[PointPub] OfferWall closed");
        default:
          print("[PointPub] unknown event: $type");
      }
    }
  }

  void _onError(Object error) {
    print("[PointPub] EventChannel error: $error");
  }

  Future<void> checkTrackingAndRequestIfNeeded() {
    return PointPubSDKPlatform.instance.checkTrackingAndRequestIfNeeded();
  }

  Future<void> setAppId(String appId) {
    return PointPubSDKPlatform.instance.setAppId(appId);
  }

  Future<void> setUserId(String userId) {
    return PointPubSDKPlatform.instance.setUserId(userId);
  }

  Future<void> startOfferWall() {
    return PointPubSDKPlatform.instance.startOfferWall();
  }

  Future<Map<String, dynamic>> getVirtualPoint() {
    return PointPubSDKPlatform.instance.getVirtualPoint();
  }

  Future<Map<String, dynamic>> spendVirtualPoint(int point) {
    return PointPubSDKPlatform.instance.spendVirtualPoint(point);
  }

  Future<String> getCompletedCampaign() {
    return PointPubSDKPlatform.instance.getCompletedCampaign();
  }
}
