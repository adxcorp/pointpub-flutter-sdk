import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'pointpub_sdk_method_channel.dart';

abstract class PointpubSdkPlatform extends PlatformInterface {
  /// Constructs a PointpubSdkPlatform.
  PointpubSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static PointpubSdkPlatform _instance = MethodChannelPointpubSdk();

  /// The default instance of [PointpubSdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelPointpubSdk].
  static PointpubSdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PointpubSdkPlatform] when
  /// they register themselves.
  static set instance(PointpubSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> setAppId(String appId) {
    throw UnimplementedError('setAppId() has not been implemented.');
  }

  Future<void> setUserId(String userId) {
    throw UnimplementedError('setUserId() has not been implemented.');
  }

  Future<void> startOfferWall() {
    throw UnimplementedError('startOfferWall() has not been implemented.');
  }

  Future<Map<String, dynamic>> getVirtualPoint() {
    throw UnimplementedError('getVirtualPoint() has not been implemented.');
  }

  Future<Map<String, dynamic>> spendVirtualPoint(int point) {
    throw UnimplementedError('spendVirtualPoint() has not been implemented.');
  }

  Future<String> getCompletedCampaign() {
    throw UnimplementedError('getCompletedCampaign() has not been implemented.');
  }
}
