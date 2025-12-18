import 'package:flutter/material.dart';
import 'point_pub_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PointPub Plugin Example',
      theme: ThemeData(useMaterial3: true),
      home: const PointPubHome(),
    );
  }
}

class ActionItem {
  final String label;
  final VoidCallback onPressed;
  ActionItem({required this.label, required this.onPressed});
}

class PointPubHome extends StatefulWidget {
  const PointPubHome({super.key});

  @override
  State<PointPubHome> createState() => _PointPubHomeState();
}

class _PointPubHomeState extends State<PointPubHome> {
  final PointPubService _service = PointPubService();
  bool _isInitialized = false;
  static final ButtonStyle _buttonStyle = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 20),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  );

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final success = await _service.initialize();
    if (mounted) {
      setState(() => _isInitialized = success);
    }
  }

  List<ActionItem> get _buttons => [
    ActionItem(
      label: '오퍼월 시작하기',
      onPressed: () => _service.startOfferWall(),
    ),
    ActionItem(
      label: '포인트 가져오기',
      onPressed: () => _service.getVirtualPoint(),
    ),
    ActionItem(
      label: '포인트 사용하기',
      onPressed: () => _service.spendVirtualPoint(10),
    ),
    ActionItem(
      label: '완료된 캠페인 가져오기',
      onPressed: () => _service.getCompletedCampaign(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PointPub Demo App')),
      body: SafeArea(
        child: !_isInitialized
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(20),
          child: ListView.separated(
            itemCount: _buttons.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final item = _buttons[index];
              return ElevatedButton(
                onPressed: item.onPressed,
                style: _buttonStyle,
                child: Text(item.label),
              );
            },
          ),
        ),
      ),
    );
  }
}