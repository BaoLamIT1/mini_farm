# Mini Farm — Technical Spec & Roadmap

> **Trạng thái:** Draft v0.1 — dùng để review nội bộ và tự chỉnh sửa
> **Loại dự án:** R&D, module game nhúng vào các app Flutter có sẵn của công ty
> **Nhân lực:** 1 dev (không có artist ở giai đoạn đầu)
> **Cập nhật lần cuối:** _(điền khi sửa)_

---

## 1. Mục tiêu & phạm vi

### 1.1 Mục tiêu R&D

| # | Mục tiêu | Cách đo |
|---|---|---|
| G1 | Chứng minh Flutter + Flame làm được game casual có chất lượng ship được | Có build chạy 60 FPS trên máy Android 2GB RAM |
| G2 | Chứng minh module nhúng được vào app production mà không gây rủi ro | App size delta < 8 MB, không crash mới, cold start không đổi |
| G3 | Đo được người dùng có quan tâm hay không | Entry CTR, penetration %, D7 return, session/ngày |
| G4 | Tái sử dụng được cho nhiều app | Nhúng app thứ 2 chỉ cần sửa config, **không sửa code module** |

### 1.2 Ngoài phạm vi (v1)

- Backend riêng, tài khoản riêng, đồng bộ cloud
- Thưởng có giá trị tiền thật (voucher, point quy đổi)
- Social: bạn bè, thăm nông trại, leaderboard
- Ads (AdMob/AppLovin)
- Đa ngôn ngữ (v1 chỉ tiếng Việt, nhưng string phải tách file)
- Phân bón, thời tiết, vật nuôi, chế biến

### 1.3 Nguyên tắc thiết kế xuyên suốt

1. **Core logic là pure Dart.** `lib/src/core/` không được import `package:flutter`. Toàn bộ economy chạy được trong unit test, không cần widget test, không cần thiết bị.
2. **Mọi thứ có thể đổi phải nằm sau interface.** Asset, thời gian, lưu trữ, analytics, thưởng — 4 interface, 4 điểm thay thế.
3. **Số ít dependency nhất có thể.** Mỗi package thêm vào là một nguy cơ xung đột version với 10 app host. Xem §4.3.
4. **Nhúng trước, làm game sau.** Đường dây tích hợp phải chạy từ tuần 1 khi game còn là màn hình trắng.

---

## 2. Game design

### 2.1 Core loop

```
     ┌──────────────────────────────────────────────┐
     │                                              │
     ▼                                              │
  Mua hạt  ──►  Trồng  ──►  Chờ chín  ──►  Thu hoạch ──►  Bán
  (coin−)      (plot busy)   (offline OK)    (inventory+)   (coin+)
     ▲                                              │
     └──────────────────────────────────────────────┘

  Tích lũy coin ──►  Mở khoá hạt tier cao hơn (lãi/phút cao hơn)
                ──►  Mua thêm ô đất (thông lượng cao hơn)
```

**Hai trục tiến triển:**
- **Chiều sâu (tier hạt):** lãi/phút tăng, nhưng thời gian chờ dài hơn và vốn lớn hơn
- **Chiều rộng (số ô đất):** nhân thông lượng, không đổi lãi/phút

Người chơi luôn phải chọn: dồn coin mua hạt xịn hay mua thêm đất. Đây là quyết định tạo ra engagement, giữ nguyên trong mọi version.

### 2.2 Cảm giác cần đạt (v1 phải có)

- Chạm ô đất → phản hồi tức thì < 50ms, có haptic
- Thu hoạch → coin bay lên HUD + số nhảy + âm thanh
- Cây chín → có chỉ dấu nổi bật (glow / bounce), thấy được từ xa
- Mở app sau khi đóng → thấy ngay "cây đã chín trong lúc bạn đi vắng"

Đây là tuần 5 trong timeline. **Không được cắt.** Khác biệt giữa demo được duyệt và demo bị bỏ nằm hết ở đây.

### 2.3 Bảng economy (v1) — cân sẵn, đưa vào code dạng data

| Tier | Cây | Giá hạt | Thời gian chín | Số quả | Giá bán/quả | Doanh thu | Lợi nhuận | Lãi/phút | Mở khoá khi |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---|
| 1 | Củ cải | 10 | 1 phút | 2 | 8 | 16 | +6 | 6,0 | Mặc định |
| 2 | Cà chua | 50 | 5 phút | 3 | 30 | 90 | +40 | 8,0 | Tổng thu 200 |
| 3 | Ngô | 200 | 15 phút | 3 | 110 | 330 | +130 | 8,7 | Tổng thu 1.000 |
| 4 | Bí đỏ | 800 | 1 giờ | 3 | 500 | 1.500 | +700 | 11,7 | Tổng thu 5.000 |
| 5 | Nho | 3.000 | 4 giờ | 4 | 1.500 | 6.000 | +3.000 | 12,5 | Tổng thu 25.000 |
| 6 | Thanh long | 10.000 | 12 giờ | 4 | 5.500 | 22.000 | +12.000 | 16,7 | Tổng thu 120.000 |

**Ô đất** (grid 3×3, tối đa 9 ô):

| Ô số | Giá | Ghi chú |
|---:|---:|---|
| 1–3 | 0 | Có sẵn khi bắt đầu |
| 4 | 500 | |
| 5 | 2.000 | |
| 6 | 8.000 | |
| 7 | 30.000 | |
| 8 | 100.000 | |
| 9 | 300.000 | Ô cuối của v1 |

**Kiểm tra nhịp tiến triển** (3 ô, trồng củ cải liên tục, lãi 18/phút):
- Ô thứ 4 (500 coin): ~28 phút chơi tích cực
- Cà chua mở ở tổng thu 200: ~4 phút → người chơi thấy tiến bộ rất sớm ✅
- Ngô mở ở 1.000: ~15 phút ✅

Nhịp này cố tình nhanh ở đầu để demo "cảm" được trong 5 phút đầu — vì người review demo (bao gồm lãnh đạo) sẽ chỉ chơi 5 phút.

> ⚠️ **Toàn bộ số trong bảng này phải nằm trong `crop_catalog.dart` dạng data thuần, không hardcode rải rác trong UI.** Sau này đưa lên Remote Config chỉ cần thay nguồn đọc.

### 2.4 Offline growth

Cây tiếp tục lớn khi app đóng. Đây là móc kéo người quay lại mỗi ngày, và là chỉ số D1/D7 mà bạn cần đo.

- Lưu `plantedAtEpochMs` cho mỗi ô
- Khi mở app: `progress = (now - plantedAt) / growDuration`, clamp 0..1
- Không cần tick timer khi app đóng, không cần notification (v2)

**Chống đổi giờ máy** (v1, mức rẻ):
- Lấy timestamp từ header `Date` của bất kỳ HTTP response nào app host đã gọi → truyền vào qua `FarmConfig.serverTime`
- Nếu không có → dùng giờ máy nhưng **chỉ cho phép thời gian tiến, không lùi**: lưu `lastSeenAt`, nếu `now < lastSeenAt` thì coi như `now = lastSeenAt`
- v1 thưởng không có giá trị tiền → cheat không gây thiệt hại thật. Nêu rõ trong doc để security không bị bất ngờ.

---

## 3. Kiến trúc

### 3.1 Sơ đồ layer

```
┌─────────────────────────────────────────────────────┐
│  APP HOST (app công ty, đã là Flutter)              │
│  import 'package:mini_farm/mini_farm.dart';         │
└───────────────┬─────────────────────────────────────┘
                │ FarmConfig (userId, theme, callbacks)
┌───────────────▼─────────────────────────────────────┐
│  integration/   ← ranh giới công khai duy nhất      │
│  FarmConfig · AnalyticsSink · RewardBridge          │
└───────────────┬─────────────────────────────────────┘
                │
┌───────────────▼──────────┐   ┌──────────────────────┐
│  ui/  (Flutter widgets)  │◄──┤  visual/             │
│  farm_screen, plot_tile  │   │  CropVisual abstract │
│  seed_shop, coin_hud     │   │  icon│sprite│rive    │
└───────────────┬──────────┘   └──────────────────────┘
                │                ┌────────────────────┐
                │                │  minigame/ (Flame) │
                │                │  optional          │
                ▼                └────────────────────┘
┌─────────────────────────────────────────────────────┐
│  core/  ★ PURE DART — KHÔNG import package:flutter  │
│  models · config(catalog) · engine · clock          │
│  100% unit-testable                                 │
└───────────────┬─────────────────────────────────────┘
                │ FarmRepository (interface)
┌───────────────▼─────────────────────────────────────┐
│  data/  SharedPreferences impl · save_codec (HMAC)  │
└─────────────────────────────────────────────────────┘
```

### 3.2 Cây thư mục đầy đủ

```
mini_farm/
├── pubspec.yaml
├── README.md                        # cách nhúng, 20 dòng
├── CHANGELOG.md
├── analysis_options.yaml
│
├── assets/
│   ├── sprites/
│   │   ├── crops/                   # v2: crop_{id}_stage{n}.png
│   │   ├── ui/                      # nút, khung, coin
│   │   └── atlas/                   # v2: atlas đóng gói + .json
│   ├── rive/                        # v3: crops.riv, effects.riv
│   └── audio/                        # v1: 4 file wav ngắn
│
├── lib/
│   ├── mini_farm.dart               # ★ barrel — export ĐÚNG 6 symbol
│   └── src/
│       │
│       ├── core/                    # ★ PURE DART
│       │   ├── models/
│       │   │   ├── crop.dart            # CropDef, CropTier
│       │   │   ├── plot.dart            # Plot, PlotState enum
│       │   │   ├── farm_state.dart      # immutable snapshot
│       │   │   └── inventory.dart
│       │   ├── config/
│       │   │   ├── crop_catalog.dart    # ★ bảng §2.3, data-only
│       │   │   └── land_catalog.dart
│       │   ├── engine/
│       │   │   ├── farm_engine.dart     # ★ mọi mutation đi qua đây
│       │   │   ├── growth_calculator.dart
│       │   │   └── unlock_rules.dart
│       │   ├── clock/
│       │   │   └── game_clock.dart      # interface + SystemClock
│       │   └── persistence/
│       │       ├── farm_repository.dart # interface
│       │       └── save_codec.dart      # json ↔ FarmState + HMAC
│       │
│       ├── data/
│       │   └── prefs_farm_repository.dart
│       │
│       ├── visual/                  # ★ lớp đổi asset không sửa UI
│       │   ├── crop_visual.dart         # abstract
│       │   ├── icon_crop_visual.dart    # v1
│       │   ├── sprite_crop_visual.dart  # v2
│       │   ├── rive_crop_visual.dart    # v3
│       │   └── visual_registry.dart     # ★ map cropId → visual
│       │
│       ├── ui/
│       │   ├── farm_screen.dart
│       │   ├── entry_card.dart          # widget host app đặt ở home
│       │   ├── widgets/
│       │   │   ├── plot_tile.dart
│       │   │   ├── plot_grid.dart
│       │   │   ├── seed_shop_sheet.dart
│       │   │   ├── coin_hud.dart
│       │   │   ├── harvest_burst.dart   # particle
│       │   │   └── offline_report_dialog.dart
│       │   ├── theme/
│       │   │   └── farm_theme.dart       # màu, radius, text style
│       │   └── strings/
│       │       └── farm_strings.dart     # tách sẵn cho i18n v2
│       │
│       ├── minigame/                # optional, chỉ chỗ này dùng Flame
│       │   ├── water_catcher_game.dart
│       │   └── minigame_host.dart       # interface để swap
│       │
│       └── integration/
│           ├── farm_config.dart         # ★ host app truyền vào
│           ├── analytics_sink.dart
│           └── reward_bridge.dart
│
└── test/
    ├── economy_test.dart
    ├── growth_test.dart
    ├── unlock_test.dart
    ├── save_codec_test.dart
    └── simulation_test.dart         # ★ mô phỏng 30 ngày, in ra bảng
```

### 3.3 Barrel file — mặt tiếp xúc phải nhỏ

```dart
// lib/mini_farm.dart
library mini_farm;

export 'src/integration/farm_config.dart'
    show FarmConfig, FarmTheme, RewardPayload, RewardResult;
export 'src/integration/analytics_sink.dart' show AnalyticsSink;
export 'src/ui/entry_card.dart' show MiniFarmEntryCard;
export 'src/mini_farm_launcher.dart' show MiniFarm;
```

**Không export gì khác.** App host không được thấy `FarmEngine`, `FarmState`, `CropDef`. Ranh giới hẹp là điều kiện để bạn refactor bên trong mà 10 app không vỡ.

### 3.4 API công khai

```dart
class MiniFarm {
  /// Mở game. Gọi từ onTap của entry card hoặc từ deeplink.
  static Route<void> route(FarmConfig config);

  /// Cho host app hỏi trạng thái để badge trên entry card
  /// (VD: "3 cây đã chín") — KHÔNG lộ FarmState ra ngoài.
  static Future<FarmBadge> badge(String userId);
}

class FarmConfig {
  final String userId;
  final String appId;                  // ★ bắt buộc, để tách data theo app

  final FarmTheme theme;               // màu + logo + tên tiền tệ
  final Map<String, String>? copyOverride;

  /// Host app tự đẩy vào analytics của nó
  final void Function(String event, Map<String, Object?> props) onAnalytics;

  /// v1 có thể trả RewardResult.ok() ngay, không cần backend
  final Future<RewardResult> Function(RewardPayload)? onReward;

  /// Trả giờ server nếu host app có. null → fallback local monotonic
  final Future<DateTime?> Function()? serverTime;

  /// Optional: host app bắn event để game thưởng coin
  /// (VD: user xem sản phẩm → +5 coin)
  final Stream<HostAppEvent>? hostEvents;

  const FarmConfig({...});
}
```

Nhúng vào app host chỉ còn:

```dart
// Trong home screen của app công ty
MiniFarmEntryCard(
  config: _farmConfig,
  onTap: () => Navigator.of(context).push(MiniFarm.route(_farmConfig)),
)
```

### 3.5 Data model (core)

```dart
// core/models/crop.dart
class CropDef {
  final String id;              // 'radish', 'tomato', ...
  final int tier;
  final int seedPrice;
  final Duration growDuration;
  final int yieldCount;
  final int sellPricePerUnit;
  final int stageCount;         // ★ số stage hình ảnh, mặc định 5
  final int unlockAtTotalEarned;

  const CropDef({...});

  int get revenue => yieldCount * sellPricePerUnit;
  int get profit  => revenue - seedPrice;
  double get profitPerMinute => profit / growDuration.inSeconds * 60;
}

// core/models/plot.dart
enum PlotState { locked, empty, growing, ready }

class Plot {
  final int index;              // 0..8
  final bool unlocked;
  final String? cropId;
  final int? plantedAtMs;

  PlotState stateAt(int nowMs, CropDef? def) { ... }
  double progressAt(int nowMs, CropDef def) { ... }
  int visualStageAt(int nowMs, CropDef def) =>
      (progressAt(nowMs, def) * (def.stageCount - 1)).floor();
}

// core/models/farm_state.dart — IMMUTABLE
class FarmState {
  final int coins;
  final int totalEarned;        // dùng cho unlock
  final List<Plot> plots;
  final Map<String, int> inventory;
  final int lastSeenMs;
  final int schemaVersion;      // ★ bắt buộc, để migrate save
  final Map<String, int> stats; // harvestCount, plantCount...

  FarmState copyWith({...});
  Map<String, dynamic> toJson();
  factory FarmState.fromJson(Map<String, dynamic> j);
}
```

### 3.6 Engine — điểm mutation duy nhất

```dart
// core/engine/farm_engine.dart
class FarmEngine {
  FarmEngine(this._state, this._clock, this._catalog);

  FarmState get state => _state;

  /// Gọi khi mở app. Trả về báo cáo để hiện dialog "trong lúc bạn đi vắng".
  OfflineReport syncOffline();

  Result<void> plant(int plotIndex, String cropId);
  Result<HarvestOutcome> harvest(int plotIndex);
  Result<int> sellAll(String cropId);
  Result<void> buyPlot(int plotIndex);
  Result<void> buySeed(String cropId, int count);

  List<CropDef> unlockedCrops();
}
```

Mọi hành động trả `Result` (ok / error có mã), **không throw**. UI đọc mã lỗi để hiện toast đúng ("không đủ coin", "ô đang có cây", "chưa mở khoá").

Lợi ích thật của thiết kế này: `simulation_test.dart` có thể chạy 30 ngày chơi trong vài chục ms và in ra bảng để bạn cân số — không cần bấm tay trên máy.

---

## 4. Tech stack

### 4.1 Nền

| Thành phần | Chọn | Lý do |
|---|---|---|
| Flutter SDK | **Khớp chính xác với app host** | Module không được ép app host nâng SDK |
| Dart | theo Flutter | |
| Ngôn ngữ | Dart | |
| Kiến trúc state | `ValueNotifier` / `ChangeNotifier` thuần | Không kéo Riverpod/Bloc vào — app host có thể đang dùng cái khác, và state game rất đơn giản |

### 4.2 Dependency

| Package | Version | Dùng ở đâu | Bắt buộc? |
|---|---|---|---|
| `flame` | `^1.35.0` | chỉ `minigame/` | Có thể lược ở v1 |
| `rive` | latest | `visual/rive_*` | v3 |
| `shared_preferences` | latest | `data/` | Có (nhưng app host chắc chắn đã có) |
| `crypto` | latest | `save_codec` HMAC | Có (rất phổ biến, ít khả năng xung đột) |

**Hết. Bốn package.**

### 4.3 Nguyên tắc dependency (quan trọng khi nhúng ~10 app)

Mỗi package thêm vào module là một khả năng `pub get` của app host báo version conflict — và bạn sẽ là người phải giải quyết, nhân 10 lần.

Quy tắc:
1. Dùng constraint rộng (`^`), không pin cứng
2. **Không** thêm: state management lib, DI lib, HTTP client, i18n lib, icon pack
3. Icon v1: dùng `Icons.*` của Material (đã có sẵn, 0 byte thêm), không dùng `lucide_icons`
4. Audio v1: `SystemSound` + haptic, hoặc lược hẳn; `audioplayers` chỉ thêm khi thật cần
5. Trước khi thêm bất kỳ package: tự hỏi "10 app host có sẵn cái này chưa?"

### 4.4 Công cụ

- **Aseprite** — vẽ sprite khi tới v2 (rẻ, ~$20, có bản build free từ source)
- **Rive** (rive.app) — animation cây, có free tier
- **Kenney.nl** — asset CC0 miễn phí thương mại, không cần credit → dùng cho v2 làm tạm
- **Google Sheets** — cân economy trước khi code (§2.3)
- **Flutter DevTools** — Performance overlay + size analysis

---

## 5. Chiến lược asset — 3 giai đoạn, đổi không sửa UI

Đây là phần trả lời trực tiếp yêu cầu "trước mắt icon đơn giản, sau thêm Rive/sprite".

### 5.1 Abstraction

```dart
// visual/crop_visual.dart
abstract class CropVisual {
  /// stage: 0..stageCount-1 ; progress: 0..1
  Widget build(
    BuildContext context, {
    required String cropId,
    required int stage,
    required double progress,
    required double size,
  });

  /// Preload (atlas / .riv). v1 no-op.
  Future<void> warmUp() async {}
}
```

```dart
// visual/visual_registry.dart
class VisualRegistry {
  final CropVisual fallback;
  final Map<String, CropVisual> overrides;

  const VisualRegistry({required this.fallback, this.overrides = const {}});

  CropVisual forCrop(String cropId) => overrides[cropId] ?? fallback;
}
```

**Điểm mấu chốt:** `VisualRegistry` cho phép **migrate từng cây một**. Khi có Rive cho cà chua, bạn thêm 1 dòng override, 5 cây còn lại vẫn icon. Không có big-bang migration.

```dart
// v1
VisualRegistry(fallback: IconCropVisual());

// giữa v2 — cà chua đã có sprite, còn lại vẫn icon
VisualRegistry(
  fallback: IconCropVisual(),
  overrides: {'tomato': SpriteCropVisual(atlas)},
);

// v3
VisualRegistry(
  fallback: SpriteCropVisual(atlas),
  overrides: {'dragonfruit': RiveCropVisual('assets/rive/crops.riv')},
);
```

`plot_tile.dart` chỉ gọi `registry.forCrop(id).build(...)` và **không bao giờ biết** asset là gì.

### 5.2 Giai đoạn 1 — Icon (Tuần 1–4)

```dart
class IconCropVisual implements CropVisual {
  static const _icons = {
    'radish':      Icons.grass,
    'tomato':      Icons.local_florist,
    'corn':        Icons.eco,
    'pumpkin':     Icons.spa,
    'grape':       Icons.wine_bar,
    'dragonfruit': Icons.filter_vintage,
  };

  @override
  Widget build(context, {required cropId, required stage, required progress, required size}) {
    // stage 0 → mầm nhỏ mờ ; stage 4 → to, đậm, có bounce
    final t = stage / 4;
    return Opacity(
      opacity: 0.45 + 0.55 * t,
      child: Icon(_icons[cropId], size: size * (0.35 + 0.65 * t)),
    );
  }
}
```

Chi phí: **0 file asset, 0 byte**. Trông vẫn có logic (nhỏ→to, mờ→đậm) chứ không trông vỡ. Đủ để test core loop và đưa demo nội bộ.

### 5.3 Giai đoạn 2 — Sprite (v2)

**Hợp đồng asset** — đưa nguyên phần này cho artist/freelancer:

| Quy cách | Giá trị |
|---|---|
| Số stage mỗi cây | **5** (0 = hạt/mầm, 4 = chín) |
| Kích thước mỗi frame | **256 × 256 px** |
| Format | PNG-32, nền trong suốt |
| Pivot | **bottom-center** (gốc cây chạm đáy frame) |
| Vùng an toàn | chừa 16px viền, không vẽ sát biên |
| Tên file | `crop_{cropId}_stage{n}.png` — VD `crop_tomato_stage3.png` |
| Atlas | tối đa **2048 × 2048**, kèm `atlas.json` (TexturePacker JSON hash) |
| Ngân sách dung lượng | toàn bộ assets < **5 MB** sau nén webp |

Thêm: `plot_soil.png`, `plot_locked.png`, `coin.png`, `ready_glow.png`.

Nén: convert sang **WebP** lossy q80 (giảm ~60–70% so PNG), trừ asset cần alpha sắc nét.

### 5.4 Giai đoạn 3 — Rive (v3)

**Hợp đồng Rive:**

| Quy cách | Giá trị |
|---|---|
| File | **1 file duy nhất** `assets/rive/crops.riv` chứa mọi cây (giảm số lần load) |
| Artboard | 1 artboard/cây, tên đúng `cropId` |
| State machine | tên **`growth`** ở mọi artboard |
| Input `stage` | Number, 0–4 |
| Input `harvest` | Trigger |
| Input `ready` | Boolean (bật loop glow) |

```dart
class RiveCropVisual implements CropVisual {
  // giữ 1 RiveFile duy nhất, tạo StateMachineController theo artboard
  // set input 'stage' khi stage đổi — KHÔNG rebuild widget
}
```

Lợi thế: đổi stage = set 1 number, không export lại frame nào. Đây là lý do Rive đáng dùng cho cây hơn sprite sheet.

### 5.5 Kiểm soát dung lượng

Chạy trước mỗi lần xin merge:

```bash
flutter build appbundle --release --analyze-size
```

Ngưỡng tự đặt: **delta < 8 MB**. Vượt → dùng deferred component (Play dynamic feature) để tải assets khi user mở game lần đầu.

---

## 6. Lưu trữ

### 6.1 Key và tách theo app

```
mini_farm.v1.{appId}.{userId}   →  JSON đã ký
```

`appId` trong key là bắt buộc: cùng một người dùng ở 2 app công ty phải có 2 nông trại riêng (hoặc chung — nhưng đó là quyết định sản phẩm, và tách trước thì gộp sau dễ hơn ngược lại).

### 6.2 Save codec

```dart
// { "v": 1, "d": {...state...}, "h": "<hmac-sha256 của d>" }
class SaveCodec {
  String encode(FarmState s);
  FarmState? decode(String raw);   // null nếu hỏng/sai HMAC → reset an toàn
}
```

Secret HMAC: hằng số trong code + `userId`. **Không chống được reverse engineering** — và không cần, vì v1 không có giá trị tiền thật. Chỉ chặn người sửa file JSON bằng tay. Ghi rõ giới hạn này trong doc để không ai hiểu sai.

### 6.3 Migration

`schemaVersion` có từ ngày đầu. Khi đổi cấu trúc:

```dart
FarmState _migrate(Map<String, dynamic> j) {
  var v = j['v'] as int;
  if (v == 1) { /* v1→v2 */ v = 2; }
  return FarmState.fromJson(j);
}
```

Decode fail → **reset sạch, không crash**. Người chơi mất nông trại tệ hơn crash rất nhiều lần, nhưng crash trong app production của công ty thì tệ hơn cả hai.

---

## 7. Analytics

### 7.1 Event (đúng 12, không hơn)

Mọi event tự động kèm: `app_id`, `user_id`, `farm_level` (= tier cao nhất mở khoá), `session_id`.

| Event | Property | Trả lời câu hỏi |
|---|---|---|
| `farm_entry_impression` | `screen` | Entry card có được thấy? |
| `farm_entry_tap` | — | CTR bao nhiêu? |
| `farm_first_open` | — | Penetration |
| `farm_open` | `days_since_first`, `hours_since_last` | D1/D7/D30 return |
| `farm_tutorial_step` | `step`, `completed` | Rơi ở bước nào |
| `farm_plant` | `crop_id`, `plot_index` | Cây nào được trồng |
| `farm_harvest` | `crop_id`, `coins_gained` | Loop có hoàn thành? |
| `farm_sell` | `crop_id`, `qty`, `coins` | |
| `farm_buy_plot` | `plot_index`, `price` | Có ai mở đất không |
| `farm_unlock_crop` | `crop_id`, `minutes_since_first` | Nhịp tiến triển thật vs thiết kế |
| `farm_offline_report` | `hours_away`, `ready_count` | Offline hook có hiệu lực? |
| `farm_session_end` | `duration_ms`, `actions_count` | Session length |

### 7.2 Chỉ số dẫn xuất

| Chỉ số | Công thức | Ngưỡng "đáng làm tiếp" |
|---|---|---|
| Entry CTR | `entry_tap / entry_impression` | > 5% |
| Penetration | `unique farm_open / DAU app` | > 8% |
| D7 return | mở lại ở ngày 7 / cohort | > 15% |
| Session/user/ngày | | > 1,5 |
| Loop completion | `harvest / plant` | > 80% |
| Tutorial completion | | > 70% |

### 7.3 Holdout — 2 giờ code, giá trị bảo hiểm rất lớn

```dart
bool showFarmEntry(String userId) =>
    (sha1(userId + 'farm_holdout_v1').codeUnits.last % 100) >= 10;
```

10% user không thấy entry card. **Chưa cần dùng ngay**, nhưng nếu 2 tháng nữa có người hỏi "game này có làm app dính hơn không", bạn có câu trả lời thay vì phải chạy lại thí nghiệm mất 2 tháng.

Với 10–20k DAU/app, một app là đủ cỡ mẫu.

---

## 8. Timeline

Giả định **full-time**. Part-time (~50%) thì nhân 1,8.

### Tuần 0 — Chuẩn bị (2–3 ngày)

- [ ] Cân bảng economy §2.3 trên Google Sheets, tự chơi thử bằng tay 10 phút
- [ ] Chốt app host đầu tiên: **chọn app có release cadence nhanh nhất và owner dễ nói chuyện nhất**, không phải app DAU cao nhất
- [ ] Hỏi owner app đó: chu kỳ release, quy trình review PR, ngưỡng app size chấp nhận được
- [ ] Xin bật feature flag (tên: `mini_farm_enabled`)

### Tuần 1 — Nhúng trước, game sau

Mục tiêu: **màn hình trắng ghi "Mini Farm" chạy trong build app thật**.

| Ngày | Việc |
|---|---|
| 1 | `flutter create --template=package mini_farm`, cây thư mục §3.2 (file rỗng), analysis_options |
| 2 | `integration/`: FarmConfig, FarmTheme, AnalyticsSink, RewardBridge |
| 3 | `MiniFarmEntryCard` + `MiniFarm.route` → màn hình placeholder |
| 4 | Publish git package, thêm vào app host qua `git:` ref, sau feature flag |
| 5 | Verify: analytics ra đúng dashboard công ty, reward callback về đúng app, đo app size delta |

**DoD tuần 1:** có PR mở ở app host, số app size delta thật trong tay, event `farm_entry_tap` nhìn thấy trên dashboard.

> Làm ngược thứ tự này là quyết định quan trọng nhất của cả timeline. Khâu xin merge vào app production chậm và ngoài tầm kiểm soát của bạn — khởi động nó ở tuần 1, không phải tuần 6.

### Tuần 2 — Core pure Dart

| Ngày | Việc |
|---|---|
| 1 | models: CropDef, Plot, FarmState, Inventory |
| 2 | `crop_catalog.dart` + `land_catalog.dart` (bảng §2.3) |
| 3 | FarmEngine: plant / harvest / sell / buyPlot / buySeed, trả `Result` |
| 4 | GrowthCalculator + syncOffline + GameClock (monotonic guard) |
| 5 | SaveCodec + HMAC + migration + `prefs_farm_repository` |

**DoD tuần 2:** `flutter test` xanh, `simulation_test` in ra bảng 30 ngày. **Chưa có một pixel nào.**

```
$ flutter test test/simulation_test.dart
Day  1: coins=142    tier=2  plots=3  harvests=18
Day  3: coins=1.240  tier=3  plots=4  harvests=61
Day  7: coins=8.910  tier=4  plots=5  harvests=143
...
```

Nhìn bảng này bạn sẽ phát hiện lỗi cân bằng trong 5 phút — thứ mà bấm tay trên máy mất 3 ngày.

### Tuần 3 — UI nông trại

| Ngày | Việc |
|---|---|
| 1 | `visual/`: CropVisual abstract, IconCropVisual, VisualRegistry |
| 2 | `plot_tile.dart` + `plot_grid.dart` (3×3, trạng thái locked/empty/growing/ready) |
| 3 | `coin_hud.dart` + `seed_shop_sheet.dart` |
| 4 | Nối UI ↔ FarmEngine qua ChangeNotifier; xử lý mã lỗi → toast |
| 5 | `offline_report_dialog.dart` ("Trong lúc bạn đi vắng: 3 cây đã chín") |

**DoD tuần 3:** chơi được trọn vòng lặp trồng → chín → bán → mua hạt, bằng icon.

### Tuần 4 — Tiến triển + tutorial

| Ngày | Việc |
|---|---|
| 1 | Unlock rules + màn hình mở khoá cây mới (có ăn mừng) |
| 2 | Mua ô đất + trạng thái ô locked |
| 3 | Tutorial 3 bước (trồng → thu → bán). Không hơn 3 bước. |
| 4 | 12 event analytics §7.1 + holdout bucket |
| 5 | Empty state, error state, xử lý save hỏng, back button |

**DoD tuần 4:** người khác cầm máy chơi 5 phút mà không cần bạn giải thích.

### Tuần 5 — Juice (tuần quan trọng nhất, không được cắt)

| Ngày | Việc |
|---|---|
| 1 | `harvest_burst`: coin bay lên HUD, số nhảy, scale bounce |
| 2 | Chỉ dấu cây chín: glow pulse + bounce; haptic khi chạm |
| 3 | Chuyển cảnh, animation mở sheet, animation coin counter (tween không nhảy số) |
| 4 | Âm thanh (4 file: tap, harvest, coin, unlock) + toggle tắt |
| 5 | Polish theme, dark mode, kiểm tra với `FarmTheme` của 2 app khác nhau |

Bài kiểm tra của tuần 5: **thu hoạch 20 lần liên tiếp có còn thấy sướng không?** Nếu không, quay lại ngày 1.

### Tuần 6 — QA + release

| Ngày | Việc |
|---|---|
| 1 | Test thiết bị: Android 2GB RAM, iPhone cũ; DevTools performance overlay |
| 2 | Verify từng event bắn đúng property; `--analyze-size` |
| 3 | Sửa bug; test đổi giờ hệ thống; test kill app giữa lúc trồng |
| 4 | README cách nhúng, PR lên app host, nhờ review |
| 5 | Bật flag cho nội bộ (team + 1 nhóm nhỏ) |

**DoD tuần 6:** module chạy trong build production sau flag, dashboard có data.

### Tuần 7–10 — Quan sát

- Tuần 7: nội bộ, sửa bug gấp
- Tuần 8: bật 5% traffic
- Tuần 9: bật 20%
- Tuần 10: **lấy số của tuần 9–10 làm số chính thức**

> ⚠️ Đừng chốt số ở tuần đầu tiên. Novelty effect làm số tuần 1 đẹp giả rồi tụt. Số tuần 3–4 sau khi bật mới là số thật.

---

## 9. Backlog sau v1

| Ưu tiên | Tính năng | Ghi chú |
|---|---|---|
| P0 | Sprite thật thay icon | §5.3 |
| P0 | Notification "cây đã chín" | Đòn bẩy retention lớn nhất; cần quyền + policy công ty |
| P1 | Phân bón (giảm thời gian chín) | Sink coin đầu tiên; là chỗ gắn rewarded ads sau này |
| P1 | Nhiệm vụ ngày + streak | Đòn bẩy daily return |
| P1 | Mini-game kiếm coin (Flame) | Interface đã có ở `minigame/` |
| P2 | Rive animation | §5.4 |
| P2 | Backend + đồng bộ cloud | Bắt buộc trước khi thưởng có giá trị tiền |
| P2 | Thưởng thật (voucher/point) | Cần server-authoritative + audit |
| P3 | Ads (rewarded: x2 thu hoạch, tăng tốc) | Chỉ sau khi engagement đã chứng minh |
| P3 | Social: thăm nông trại, leaderboard | Hố scope, để cuối |
| P3 | i18n | String đã tách sẵn ở `ui/strings/` |

---

## 10. Rủi ro

| Rủi ro | Mức | Xử lý |
|---|---|---|
| Không có artist → trông rẻ tiền → bị đánh giá thấp | **Cao** | Icon + juice tốt trông có chủ ý hơn sprite dở. Tuần 5 bù cho thiếu art. |
| Owner app host không cho merge | **Cao** | Khởi động ở tuần 1; sau feature flag; đưa số size + crash |
| App size vượt ngưỡng | Trung bình | WebP + atlas; deferred component nếu cần |
| Trượt scope (tự thêm feature) | **Cao** | §1.2 là hợp đồng với chính mình. Ý mới → ghi vào §9, không code. |
| Xung đột dependency với app host | Trung bình | §4.3 — chỉ 4 package, constraint rộng |
| Novelty effect làm đọc sai data | Trung bình | Chốt số ở tuần 3–4, không tuần 1 |
| Cheat save file | Thấp (v1) | HMAC; v1 không có giá trị tiền |
| Không đủ cỡ mẫu để đo lift | Thấp | 10–20k DAU/app là đủ; đã có holdout |

---

## 11. Definition of Done cho v1

- [ ] `flutter test` xanh, coverage `src/core/` > 80%
- [ ] `src/core/` không có dòng nào import `package:flutter` (verify bằng grep trong CI)
- [ ] 60 FPS trên Android 2GB RAM (performance overlay không có thanh đỏ)
- [ ] App size delta < 8 MB (số thật từ `--analyze-size`)
- [ ] 12 event analytics verify từng cái trên dashboard
- [ ] Nhúng được vào **app thứ 2** chỉ bằng sửa `FarmConfig`, không sửa file nào trong `lib/src/`
- [ ] README nhúng được trong 10 phút bởi dev khác
- [ ] Save hỏng → reset êm, không crash
- [ ] Đổi giờ hệ thống về quá khứ → không lỗi

---

## 12. Chỗ để bạn điền

### Cần xác nhận
- [ ] Flutter version của app host: `________`
- [ ] App host đầu tiên: `________` — DAU: `________`
- [ ] Ngưỡng app size owner chấp nhận: `________ MB`
- [ ] Hệ analytics công ty đang dùng: `________`
- [ ] Có API trả server time không: `________`

### Ghi chú riêng
_(chỗ trống)_

### Thay đổi so với draft này
| Ngày | Thay đổi | Lý do |
|---|---|---|
| | | |
