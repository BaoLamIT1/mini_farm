# Changelog

## v0.1.0 (draft)

- Dựng cây thư mục theo spec §3.2: `core/` (pure Dart), `data/`, `visual/`, `ui/`, `integration/`, `minigame/` (stub).
- `FarmEngine` với plant/harvest/sellAll/buyPlot/buySeed, trả `Result` không throw.
- `crop_catalog.dart` + `land_catalog.dart` theo đúng bảng economy §2.3.
- Lưu trữ `SharedPreferences` + `SaveCodec` (HMAC-SHA256), tự reset khi save hỏng.
- UI chơi được vòng lặp trồng → chín → thu hoạch → bán, bằng `IconCropVisual` (giai đoạn 1, §5.2).
- App demo (`lib/main.dart`) mô phỏng một app host nhúng `MiniFarmEntryCard` + `MiniFarm.route`.
- Test: `economy_test`, `growth_test`, `unlock_test`, `save_codec_test`, `simulation_test` (mô phỏng 30 ngày).
