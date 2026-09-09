import 'package:flutter/material.dart';

import 'package:mini_farm/mini_farm.dart';

void main() {
  runApp(const HostDemoApp());
}

/// App mẫu mô phỏng một "app host" nhúng module mini_farm — dùng để tự chơi
/// thử trong lúc chưa có app công ty thật để tích hợp (xem spec §8, tuần 1).
class HostDemoApp extends StatelessWidget {
  const HostDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini Farm — Host Demo',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
      home: const HostHomeScreen(),
    );
  }
}

class HostHomeScreen extends StatefulWidget {
  const HostHomeScreen({super.key});

  @override
  State<HostHomeScreen> createState() => _HostHomeScreenState();
}

class _HostHomeScreenState extends State<HostHomeScreen> {
  late final FarmConfig _farmConfig = FarmConfig(
    userId: 'demo_user_1',
    appId: 'host_demo',
    onAnalytics: (event, props) => debugPrint('[analytics] $event $props'),
    onReward: (payload) async => RewardResult.ok(),
  );

  @override
  void initState() {
    super.initState();
    // Tiện ích cho dev/QA trên web: mở thẳng màn nông trại qua ?open=farm,
    // không phải điểm nhúng thật (host app luôn dùng MiniFarmEntryCard.onTap).
    if (Uri.base.queryParameters['open'] == 'farm') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).push(MiniFarm.route(_farmConfig));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Công Ty (demo)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Đây là màn hình chính của app host giả lập.'),
            const SizedBox(height: 16),
            MiniFarmEntryCard(
              config: _farmConfig,
              onTap: () => Navigator.of(context).push(MiniFarm.route(_farmConfig)),
            ),
          ],
        ),
      ),
    );
  }
}
