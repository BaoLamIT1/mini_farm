class LandCatalog {
  const LandCatalog._();

  // Index 0..8 ↔ Ô số 1..9 trong spec. Ô 0-2 mở sẵn (giá 0).
  static const List<int> plotPrice = [
    0,
    0,
    0,
    500,
    2000,
    8000,
    30000,
    100000,
    300000,
  ];

  static int priceFor(int index) => plotPrice[index];

  static int get plotCount => plotPrice.length;
}
