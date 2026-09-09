/// Tách sẵn cho i18n v2 (spec §1.2) — v1 chỉ tiếng Việt.
class FarmStrings {
  const FarmStrings._();

  static const entryTitle = 'Nông Trại Mini';
  static const entrySubtitle = 'Trồng cây, thu hoạch, kiếm xu';
  static const shopTitle = 'Chọn hạt giống';
  static const harvest = 'Thu hoạch';
  static const sell = 'Bán tất cả';
  static const offlineTitle = 'Trong lúc bạn đi vắng';
  static const offlineOk = 'Tuyệt!';
  static const emptyInventory = 'Kho trống';

  static const errorMessages = {
    'invalid_plot': 'Ô đất không hợp lệ',
    'invalid_crop': 'Cây không hợp lệ',
    'crop_locked': 'Cây chưa mở khoá',
    'plot_locked': 'Ô đất chưa mở khoá',
    'plot_occupied': 'Ô đang có cây',
    'not_enough_coins': 'Không đủ xu',
    'plot_empty': 'Ô đất trống',
    'not_ready': 'Cây chưa chín',
    'no_inventory': 'Không có gì để bán',
    'already_unlocked': 'Ô đã mở khoá',
    'invalid_count': 'Số lượng không hợp lệ',
  };

  static String errorFor(String code) => errorMessages[code] ?? 'Có lỗi xảy ra';

  static const cropLabels = {
    'radish': 'Củ cải',
    'tomato': 'Cà chua',
    'corn': 'Ngô',
    'pumpkin': 'Bí đỏ',
    'grape': 'Nho',
    'dragonfruit': 'Thanh long',
  };

  static String cropLabel(String cropId) => cropLabels[cropId] ?? cropId;
}
