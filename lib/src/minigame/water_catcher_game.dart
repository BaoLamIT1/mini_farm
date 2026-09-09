import 'minigame_host.dart';

/// Chưa triển khai — thuộc backlog P1, cần thêm dependency `flame` khi bắt đầu (§4.2).
class WaterCatcherGame implements MinigameHost {
  const WaterCatcherGame();

  @override
  Future<int> play() {
    throw UnimplementedError('WaterCatcherGame chưa triển khai (backlog P1).');
  }
}
