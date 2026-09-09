/// Interface để swap engine minigame (Flame hoặc khác) — xem backlog P1.
abstract class MinigameHost {
  /// Trả về số coin người chơi kiếm được.
  Future<int> play();
}
