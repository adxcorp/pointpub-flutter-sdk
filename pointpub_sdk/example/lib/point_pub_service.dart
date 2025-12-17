
import 'dart:async';
import 'dart:io' show Platform;
import 'dart:developer';
import 'package:pointpub_sdk/pointpub_sdk.dart';

class PointPubService {
  final PointPubSDK _sdk = PointPubSDK();
  static const String _logName = '[PointPub_Dart]';

  // 초기화
  Future<bool> initialize() async {
    try {
      if (Platform.isIOS) {
        await _sdk.checkTrackingAndRequestIfNeeded();
        await _sdk.setAppId("APP_17569663893761798");
      } else {
        await _sdk.setAppId("APP_17259408657597018");
      }
      await _sdk.setUserId("123456789");
      log('SDK 초기화 완료', name: _logName);
      return true;
    } catch (e) {
      log('SDK 초기화 실패', name: _logName, error: e);
      return false;
    }
  }

  // 오퍼월 실행
  Future<void> startOfferWall() async {
    await _sdk.startOfferWall();
  }

  // 포인트 조회
  Future<void> getVirtualPoint() async {
    try {
      final result = await _sdk.getVirtualPoint();
      if (result.isNotEmpty) {
        log('포인트명: ${result["pointName"]}, 남은 포인트: ${result["point"]}', name: _logName);
      }
    } catch (e) {
      log('포인트 조회 실패', name: _logName, error: e);
    }
  }

  // 포인트 사용
  Future<void> spendVirtualPoint(int point) async {
    try {
      final result = await _sdk.spendVirtualPoint(point);
      if (result.isNotEmpty) {
        log('포인트명: ${result["pointName"]}, 사용 후 남은 포인트: ${result["point"]}', name: _logName);
      }
    } catch (e) {
      log('포인트 사용 실패', name: _logName, error: e);
    }
  }

  // 완료된 캠페인 조회
  Future<void> getCompletedCampaign() async {
    try {
      final result = await _sdk.getCompletedCampaign();
      log('완료 캠페인: $result', name: _logName);
    } catch (e) {
      log('캠페인 조회 실패', name: _logName, error: e);
    }
  }
}