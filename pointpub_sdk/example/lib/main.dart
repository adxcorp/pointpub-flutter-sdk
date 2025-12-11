import 'package:flutter/material.dart';
import 'dart:async';

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
  final pointpubSdk = PointpubSdk();

  @override
  void initState() {
    super.initState();
    setPointPubSDK();
  }

  @override
  void dispose() {
    pointpubSdk.dispose();
    super.dispose();
  }

  Future<void> setPointPubSDK() async {
    await pointpubSdk.setAppId("APP_17569663893761798");
    await pointpubSdk.setUserId("123456789");
  }

  Future<void> startOfferWall() async {
    await pointpubSdk.startOfferWall();
  }

  Future<void> getVirtualPoint() async {
    final result = await pointpubSdk.getVirtualPoint();
    print('포인트명: ${result["pointName"]}, 남은 포인트: ${result["point"]}');
  }

  Future<void> spendVirtualPoint(int point) async {
    final result = await pointpubSdk.spendVirtualPoint(point);
    print('포인트명: ${result["pointName"]}, 사용 후 남은 포인트: ${result["point"]}');
  }

  Future<void> getCompletedCampaign() async {
    final result = await pointpubSdk.getCompletedCampaign();
    print(result);
  }

  late final List<ActionButton> _buttons = [
    ActionButton(
      label: "오퍼월 시작하기",
      onPressed: () {
        startOfferWall();
      },
    ),
    ActionButton(
      label: "포인트 가져오기",
      onPressed: () {
        getVirtualPoint();
      },
    ),
    ActionButton(
      label: "포인트 사용하기",
      onPressed: () {
        spendVirtualPoint(10);
      },
    ),
    ActionButton(
      label: "완료된 캠페인 가져오기",
      onPressed: () {
        getCompletedCampaign();
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('PointPubSDK Example App'),
        ),
        body: Center(
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: _buttons.length,
            itemBuilder: (context, index) {
              final item = _buttons[index];

              return ElevatedButton(
                onPressed: item.onPressed,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(item.label),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(height: 16),
          ),
        )
      ),
    );
  }
}
