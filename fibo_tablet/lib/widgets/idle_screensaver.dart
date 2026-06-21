import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fibo_core/theme/space_tokens.dart';

/// Wraps the app and, after [timeout] with no touch, overlays a flip-clock
/// screensaver. Any pointer down wakes it and restarts the idle timer.
class IdleScreensaver extends StatefulWidget {
  const IdleScreensaver({
    super.key,
    required this.child,
    this.timeout = const Duration(minutes: 3),
  });

  final Widget child;
  final Duration timeout;

  @override
  State<IdleScreensaver> createState() => _IdleScreensaverState();
}

class _IdleScreensaverState extends State<IdleScreensaver> {
  Timer? _timer;
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  void _arm() {
    _timer?.cancel();
    _timer = Timer(widget.timeout, () {
      if (mounted) setState(() => _showing = true);
    });
  }

  void _wake() {
    if (_showing) setState(() => _showing = false);
    _arm();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _wake(),
      child: Stack(
        children: [
          widget.child,
          if (_showing)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _wake,
                child: const _FlipClock(),
              ),
            ),
        ],
      ),
    );
  }
}

/// Split-flap style clock screensaver.
class _FlipClock extends StatefulWidget {
  const _FlipClock();

  @override
  State<_FlipClock> createState() => _FlipClockState();
}

class _FlipClockState extends State<_FlipClock> {
  late DateTime _now = DateTime.now();
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ampm = _now.hour >= 12 ? 'PM' : 'AM';
    var h = _now.hour % 12;
    if (h == 0) h = 12;
    final hh = h.toString().padLeft(2, '0');
    final mm = _now.minute.toString().padLeft(2, '0');

    return Material(
      color: const Color(0xFF05070A),
      child: Stack(
        children: [
          const Positioned(top: 28, left: 28, child: _Brand()),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 6, bottom: 12),
                  child: Text(
                    ampm,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _FlipCard(text: hh),
                    const SizedBox(width: 22),
                    _FlipCard(text: mm),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// FIBO logo + wordmark shown on the screensaver (placeholder logo mark).
class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [SpaceColors.accentStart, SpaceColors.accentEnd],
            ),
          ),
          child: const Icon(Icons.hub_rounded, color: Colors.white, size: 19),
        ),
        const SizedBox(width: 10),
        const Text(
          'FIBO',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// A single split-flap digit-pair card.
class _FlipCard extends StatelessWidget {
  const _FlipCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 320,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF12151C),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SpaceColors.stroke),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 200,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          // Split seam across the middle.
          Container(height: 2, color: const Color(0xFF05070A)),
        ],
      ),
    );
  }
}
