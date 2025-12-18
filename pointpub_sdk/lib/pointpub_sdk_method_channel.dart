import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'pointpub_sdk_platform_interface.dart';

/// An implementation of [PointPubSDKPlatform] that uses method channels.
final class MethodChannelPointPubSDK extends PointPubSDKPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('pointpub_sdk');

  @override
  Future<void> checkTrackingAndRequestIfNeeded() async {
    if (Platform.isIOS) {
      await methodChannel.invokeMethod("checkTrackingAndRequestIfNeeded");
    }
  }

  @override
  Future<void> setAppId(String appId) async {
    try {
      return await methodChannel.invokeMethod("setAppId", {'appId': appId});
    } on PlatformException catch (e) {
      throw Exception(e.message);
    }
  }

  @override
  Future<void> setUserId(String userId) async {
    try {
      return await methodChannel.invokeMethod("setUserId", {'userId': userId});
    } on PlatformException catch (e) {
      throw Exception(e.message);
    }
  }

  @override
  Future<void> startOfferWall() async {
    try {
      return await methodChannel.invokeMethod("startOfferWall");
    } on PlatformException catch (e) {
      throw Exception(e.message);
    }
  }

  @override
  Future<Map<String, dynamic>> getVirtualPoint() async {
    try {
      final virtualPoint = await methodChannel.invokeMethod('getVirtualPoint');
      return Map<String, dynamic>.from(virtualPoint);
    } on PlatformException catch (e) {
      throw Exception(e.message);
    }
  }

  @override
  Future<Map<String, dynamic>> spendVirtualPoint(int point) async {
    try {
      final virtualPoint = await methodChannel
          .invokeMethod("spendVirtualPoint", {"point": point});
      return Map<String, dynamic>.from(virtualPoint);
    } on PlatformException catch (e) {
      throw Exception(e.message);
    }
  }

  @override
  Future<String> getCompletedCampaign() async {
    try {
      final completedCampaign =
          await methodChannel.invokeMethod("getCompletedCampaign");
      return completedCampaign;
    } on PlatformException catch (e) {
      throw Exception(e.message);
    }
  }
}
