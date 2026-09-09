# mini_farm

Module farm game nhúng vào app Flutter có sẵn — xem `mini_farm_spec.md` cho spec đầy đủ.

## Chạy thử (harness demo)

```bash
fvm flutter run -d chrome   # hoặc -d windows / thiết bị Android/iOS
```

`lib/main.dart` là một app host giả lập: có màn hình chính với `MiniFarmEntryCard`,
tap vào để `Navigator.push(MiniFarm.route(config))` mở màn nông trại thật.

## Nhúng vào app host thật

```dart
import 'package:mini_farm/mini_farm.dart';

final farmConfig = FarmConfig(
  userId: currentUserId,
  appId: 'ten_app_cua_ban', // bắt buộc — tách save theo app
  onAnalytics: (event, props) => myAnalytics.track(event, props),
);

MiniFarmEntryCard(
  config: farmConfig,
  onTap: () => Navigator.of(context).push(MiniFarm.route(farmConfig)),
)
```

Chỉ 4 symbol công khai: `FarmConfig`, `FarmTheme`, `MiniFarmEntryCard`, `MiniFarm`
(xem barrel `lib/mini_farm.dart`). Không import gì từ `src/`.

## Test

```bash
fvm flutter test
```

`test/simulation_test.dart` in ra bảng tiến triển 30 ngày để cân economy mà không cần bấm tay.
