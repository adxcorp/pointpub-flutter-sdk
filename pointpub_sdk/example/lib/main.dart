import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io' show Platform;

import 'package:pointpub_sdk/pointpub_sdk.dart';
import 'package:pointpub_sdk_example/ActionButton.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final PointPubSDK _pointpubSdk = PointPubSDK();
  final ButtonStyle _buttonStyle = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 20),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );
  late final List<ActionItem> _buttons;

  @override
  void initState() {
    super.initState();
    setActionButtonItems();
    setPointPubSDK();
  }

  @override
  void dispose() {
    _pointpubSdk.dispose();
    super.dispose();
  }

  void setActionButtonItems() {
    _buttons = [
      ActionItem(
        label: '오퍼월 시작하기',
        onPressed: () {
          startOfferWall();
        },
      ),
      ActionItem(
        label: '포인트 가져오기',
        onPressed: () {
          getVirtualPoint();
        },
      ),
      ActionItem(
        label: '포인트 사용하기',
        onPressed: () {
          spendVirtualPoint(10);
        },
      ),
      ActionItem(
        label: '완료된 캠페인 가져오기',
        onPressed: () {
          getCompletedCampaign();
        },
      ),
    ];
  }

  Future<void> setPointPubSDK() async {
    await _pointpubSdk.setAppId("APP_17569663893761798");
    await _pointpubSdk.setUserId("123456789");

    if (Platform.isIOS) {
      await _pointpubSdk.checkTrackingAndRequestIfNeeded();
    }
  }

  Future<void> startOfferWall() async {
    await _pointpubSdk.startOfferWall();
  }

  Future<void> getVirtualPoint() async {
    final result = await _pointpubSdk.getVirtualPoint();
    print('포인트명: ${result["pointName"]}, 남은 포인트: ${result["point"]}');
  }

  Future<void> spendVirtualPoint(int point) async {
    final result = await _pointpubSdk.spendVirtualPoint(point);
    print('포인트명: ${result["pointName"]}, 사용 후 남은 포인트: ${result["point"]}');
  }

  Future<void> getCompletedCampaign() async {
    final result = await _pointpubSdk.getCompletedCampaign();
    print(result);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('PointPubSDK Example App'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView.separated(
            itemCount: _buttons.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final item = _buttons[index];
              return ActionButton(
                label: item.label,
                onPressed: item.onPressed,
                style: _buttonStyle,
              );
            },
          ),
        ),
      ),
    );
  }
}
