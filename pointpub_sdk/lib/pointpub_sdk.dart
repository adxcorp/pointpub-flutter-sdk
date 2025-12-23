import 'dart:async';
import 'dart:developer';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'pointpub_sdk_platform_interface.dart';
import 'pointpub_sdk_version.dart';

final class PointPubSDK with WidgetsBindingObserver {
  static const EventChannel _eventChannel = EventChannel('pointpub_sdk/events');
  static const String _logName = 'PointPub_Plugin';
  static final PointPubSDK _instance = PointPubSDK._internal();
  static PointPubSDK get instance => _instance;

  StreamSubscription? _subscription;
  VoidCallback? _onOpenCallback;
  VoidCallback? _onCloseCallback;

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
    _onOpenCallback = null;
    _onCloseCallback = null;
  }

  void _onEvent(dynamic event) {
    if (event is Map) {
      final type = event["event"];

      switch (type) {
        case "onOpenOfferWall":
          _onOpenCallback?.call();
        case "onCloseOfferWall":
          _onCloseCallback?.call();
          _onOpenCallback = null;
          _onCloseCallback = null;
        default:
          log("unknown event: $type", name: _logName);
      }
    }
  }

  void _onError(Object error) {
    log("[PointPub] EventChannel error: $error");
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

  Future<void> startOfferWall({VoidCallback? onOpen, VoidCallback? onClose}) {
    _onOpenCallback = onOpen;
    _onCloseCallback = onClose;
    if (Platform.isIOS) {
      return PointPubSDKPlatform.instance
          .startOfferWall(PointPubSDKVersion.plugin, PointPubSDKVersion.ios);
    } else {
      return PointPubSDKPlatform.instance.startOfferWall(
          PointPubSDKVersion.plugin, PointPubSDKVersion.android);
    }
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
