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
}
