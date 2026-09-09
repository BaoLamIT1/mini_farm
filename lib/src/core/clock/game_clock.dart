abstract class GameClock {
  int nowMs();
}

class SystemClock implements GameClock {
  const SystemClock();

  @override
  int nowMs() => DateTime.now().millisecondsSinceEpoch;
}

/// Áp offset (VD: từ server time) lên đồng hồ hệ thống mà không cần tick timer.
class OffsetGameClock implements GameClock {
  OffsetGameClock({this.offsetMs = 0});

  int offsetMs;

  @override
  int nowMs() => DateTime.now().millisecondsSinceEpoch + offsetMs;
}
