class Inventory {
  const Inventory._();

  static Map<String, int> add(Map<String, int> inv, String cropId, int qty) {
    final next = Map<String, int>.from(inv);
    next[cropId] = (next[cropId] ?? 0) + qty;
    return next;
  }

  static Map<String, int> removeAll(Map<String, int> inv, String cropId) {
    if (!inv.containsKey(cropId)) return inv;
    final next = Map<String, int>.from(inv)..remove(cropId);
    return next;
  }
}
