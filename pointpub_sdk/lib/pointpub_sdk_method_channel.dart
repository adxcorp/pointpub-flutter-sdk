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
    await methodChannel.invokeMethod("checkTrackingAndRequestIfNeeded");
  }

  @override
  Future<void> setAppId(String appId) async {
    await methodChannel.invokeMethod("setAppId", {'appId': appId} );
  }

  @override
  Future<void> setUserId(String userId) async {
    await methodChannel.invokeMethod("setUserId", {'userId': userId} );
  }

  @override
  Future<void> startOfferWall() async {
    await methodChannel.invokeMethod("startOfferWall");
  }

  @override
  Future<Map<String, dynamic>> getVirtualPoint() async {
    final virtualPoint = await methodChannel.invokeMethod("getVirtualPoint");
    return Map<String, dynamic>.from(virtualPoint);
  }

  @override
  Future<Map<String, dynamic>> spendVirtualPoint(int point) async {
    final virtualPoint = await methodChannel.invokeMethod("spendVirtualPoint", { "point": point } );
    return Map<String, dynamic>.from(virtualPoint);
  }

  @override
  Future<String> getCompletedCampaign() async {
    final completedCampaign = await methodChannel.invokeMethod("getCompletedCampaign");
    return completedCampaign;
  }
}
