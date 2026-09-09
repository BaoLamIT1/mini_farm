import 'package:flutter/material.dart';

/// Overlay "+coin bay lên" khi thu hoạch. Tự gỡ khi animation xong.
void showHarvestBurst(BuildContext context, {required int coins}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _HarvestBurstWidget(
      coins: coins,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _HarvestBurstWidget extends StatefulWidget {
  const _HarvestBurstWidget({required this.coins, required this.onDone});

  final int coins;
  final VoidCallback onDone;

  @override
  State<_HarvestBurstWidget> createState() => _HarvestBurstWidgetState();
}

class _HarvestBurstWidgetState extends State<_HarvestBurstWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rise;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onDone();
      })
      ..forward();
    _rise = Tween<double>(begin: 0, end: -80).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fade = Tween<double>(begin: 1, end: 0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0)));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Positioned(
        top: size.height / 2 + _rise.value,
        left: 0,
        right: 0,
        child: Opacity(
          opacity: _fade.value,
          child: Center(
            child: Text(
              '+${widget.coins}',
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
