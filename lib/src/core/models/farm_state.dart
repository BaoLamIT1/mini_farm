import 'plot.dart';

class FarmState {
  final int coins;
  final int totalEarned;
  final List<Plot> plots;
  final Map<String, int> inventory;
  final int lastSeenMs;
  final int schemaVersion;
  final Map<String, int> stats;

  const FarmState({
    required this.coins,
    required this.totalEarned,
    required this.plots,
    required this.inventory,
    required this.lastSeenMs,
    required this.schemaVersion,
    required this.stats,
  });

  factory FarmState.initial({required int nowMs, int startingCoins = 20}) {
    return FarmState(
      coins: startingCoins,
      totalEarned: 0,
      plots: List.generate(9, (i) => Plot(index: i, unlocked: i < 3)),
      inventory: const {},
      lastSeenMs: nowMs,
      schemaVersion: 1,
      stats: const {},
    );
  }

  FarmState copyWith({
    int? coins,
    int? totalEarned,
    List<Plot>? plots,
    Map<String, int>? inventory,
    int? lastSeenMs,
    int? schemaVersion,
    Map<String, int>? stats,
  }) {
    return FarmState(
      coins: coins ?? this.coins,
      totalEarned: totalEarned ?? this.totalEarned,
      plots: plots ?? this.plots,
      inventory: inventory ?? this.inventory,
      lastSeenMs: lastSeenMs ?? this.lastSeenMs,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      stats: stats ?? this.stats,
    );
  }

  Map<String, dynamic> toJson() => {
        'coins': coins,
        'totalEarned': totalEarned,
        'plots': plots.map((p) => p.toJson()).toList(),
        'inventory': inventory,
        'lastSeenMs': lastSeenMs,
        'schemaVersion': schemaVersion,
        'stats': stats,
      };

  factory FarmState.fromJson(Map<String, dynamic> j) => FarmState(
        coins: j['coins'] as int,
        totalEarned: j['totalEarned'] as int,
        plots: (j['plots'] as List)
            .map((p) => Plot.fromJson(Map<String, dynamic>.from(p as Map)))
            .toList(),
        inventory: Map<String, int>.from(j['inventory'] as Map),
        lastSeenMs: j['lastSeenMs'] as int,
        schemaVersion: j['schemaVersion'] as int,
        stats: Map<String, int>.from(j['stats'] as Map),
      );
}
