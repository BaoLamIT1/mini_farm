import 'package:flutter/material.dart';

import '../../core/models/crop.dart';
import '../../core/models/plot.dart';
import '../../visual/visual_registry.dart';
import '../theme/farm_theme.dart';

class PlotTile extends StatelessWidget {
  const PlotTile({
    super.key,
    required this.plot,
    required this.cropDef,
    required this.nowMs,
    required this.registry,
    required this.landPrice,
    required this.onTap,
  });

  final Plot plot;
  final CropDef? cropDef;
  final int nowMs;
  final VisualRegistry registry;
  final int landPrice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final state = plot.stateAt(nowMs, cropDef);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _backgroundFor(state),
          borderRadius: BorderRadius.circular(FarmDesignTokens.plotRadius),
          border: state == PlotState.ready
              ? Border.all(color: Colors.amber, width: 3)
              : Border.all(color: Colors.brown.shade200, width: 1),
          boxShadow: state == PlotState.ready
              ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.6), blurRadius: 12, spreadRadius: 1)]
              : null,
        ),
        child: Center(child: _contentFor(context, state)),
      ),
    );
  }

  Color _backgroundFor(PlotState state) {
    switch (state) {
      case PlotState.locked:
        return Colors.grey.shade400;
      case PlotState.empty:
        return Colors.brown.shade100;
      case PlotState.growing:
        return Colors.lightGreen.shade100;
      case PlotState.ready:
        return Colors.lightGreen.shade200;
    }
  }

  Widget _contentFor(BuildContext context, PlotState state) {
    switch (state) {
      case PlotState.locked:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, color: Colors.white70),
            Text('$landPrice', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        );
      case PlotState.empty:
        return Icon(Icons.add, color: Colors.brown.shade300, size: 28);
      case PlotState.growing:
        final def = cropDef!;
        final progress = plot.progressAt(nowMs, def);
        final stage = plot.visualStageAt(nowMs, def);
        final totalMs = def.growDuration.inMilliseconds;
        final elapsedMs = nowMs - plot.plantedAtMs!;
        final remaining = Duration(milliseconds: (totalMs - elapsedMs).clamp(0, totalMs));
        return Stack(
          alignment: Alignment.center,
          children: [
            registry.forCrop(def.id).build(
                  context,
                  cropId: def.id,
                  stage: stage,
                  progress: progress,
                  size: 40,
                ),
            Positioned(
              bottom: 2,
              child: _CountdownBadge(remaining: remaining),
            ),
          ],
        );
      case PlotState.ready:
        final def = cropDef!;
        return registry.forCrop(def.id).build(
              context,
              cropId: def.id,
              stage: def.stageCount - 1,
              progress: 1,
              size: 40,
            );
    }
  }
}

class _CountdownBadge extends StatelessWidget {
  const _CountdownBadge({required this.remaining});

  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);
    String two(int n) => n.toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${two(hours)}:${two(minutes)}:${two(seconds)}',
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}
