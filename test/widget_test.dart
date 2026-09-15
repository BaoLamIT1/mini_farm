import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mini_farm/main.dart';
import 'package:mini_farm/mini_farm.dart';
import 'package:mini_farm/src/ui/farm_screen.dart';

void main() {
  testWidgets('Host demo shows entry card and opens the farm', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const HostDemoApp());

    expect(find.text('Nông Trại Mini'), findsOneWidget);

    await tester.tap(find.byType(MiniFarmEntryCard));
    // Màn nông trại có ticker 1s chạy suốt vòng đời (§2.4 offline growth),
    // nên dùng pump() có thời hạn thay vì pumpAndSettle() (sẽ không bao giờ settle).
    await tester.pump(); // xử lý tap
    await tester.pump(const Duration(milliseconds: 300)); // xong animation chuyển màn
    await tester.pump(const Duration(milliseconds: 50)); // xong Future load save

    expect(find.byType(FarmScreen), findsOneWidget);
  });

  testWidgets('opening the farm locks landscape, leaving it restores portrait', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(const HostDemoApp());
    await tester.tap(find.byType(MiniFarmEntryCard));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 50));

    final orientationCalls = calls.where((c) => c.method == 'SystemChrome.setPreferredOrientations');
    expect(orientationCalls.last.arguments, ['DeviceOrientation.landscapeLeft', 'DeviceOrientation.landscapeRight']);

    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300)); // 2 nhịp — transition quay lại lâu hơn transition đi tới

    final afterLeaving = calls.where((c) => c.method == 'SystemChrome.setPreferredOrientations');
    expect(afterLeaving.last.arguments, ['DeviceOrientation.portraitUp', 'DeviceOrientation.portraitDown']);
  });
}
