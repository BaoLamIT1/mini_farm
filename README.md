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

### Xoay ngang

`FarmScreen` tự khoá xoay ngang (`landscapeLeft`/`landscapeRight`) khi mở và trả về
dọc khi đóng. Để hoạt động đúng, app host phải khai báo landscape là hướng được hỗ
trợ: Android không giới hạn `android:screenOrientation` ở Activity đang push màn
này; iOS cần `UISupportedInterfaceOrientations` trong `Info.plist` có
`UIInterfaceOrientationLandscapeLeft`/`Right` (mặc định project Flutter đã có sẵn).
Nếu app host khoá dọc ở mức OS, lệnh xoay của module sẽ không có tác dụng.

## Thiết kế bản đồ (Map Editor)

Vị trí 9 ô đất + vật trang trí (nhà, cây, hàng rào) là data trong
`assets/farm_layout.json` (lưới ô vuông `gridCols × gridRows`, mỗi ô đất/vật
trang trí neo vào 1 ô lưới) — không hardcode trong widget.

Để tự sắp xếp lại bằng kéo-thả thay vì gõ tay toạ độ:

```bash
fvm flutter run -d chrome
# rồi mở http://localhost:xxxxx/?open=editor
# hoặc bấm nút "Map Editor (dev)" ở màn hình demo (chỉ hiện khi build debug)
```

Kéo từng ô đất (đánh số 1–9) hoặc vật trang trí — tự snap theo lưới. Long-press
vật trang trí để xoá, nút `+` ở AppBar để thêm (chọn icon có sẵn). Xong bấm
"Xuất JSON" → "Sao chép" → dán đè vào `assets/farm_layout.json` → hot restart
(`R`) để `FarmScreen` load lại layout mới. Nếu file JSON hỏng hoặc thiếu, game
tự rơi về `FarmLayout.defaultLayout` chứ không crash.

## Test

```bash
fvm flutter test
```

`test/simulation_test.dart` in ra bảng tiến triển 30 ngày để cân economy mà không cần bấm tay.
