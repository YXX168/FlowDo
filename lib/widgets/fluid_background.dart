import 'dart:math';
import 'package:flutter/material.dart';

/// Fluid animated background that replicates the Mercury Music login page's
/// WebGL shader effect using Flutter's CustomPainter.
///
/// Draws multiple animated color blobs (yellow, orange, pink, purple) that
/// move in circular paths, blended with smoothstep gradients over a dark base.
class FluidBackground extends StatefulWidget {
  const FluidBackground({super.key});

  @override
  State<FluidBackground> createState() => _FluidBackgroundState();
}

class _FluidBackgroundState extends State<FluidBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _FluidPainter(_controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _FluidPainter extends CustomPainter {
  final double t;

  _FluidPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Base background gradient
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF2D293A),
          const Color(0xFF14121B),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Time-based animation factor (0..1 mapped to 0..2pi * cycles)
    final time = t * 2 * pi;

    // Color blobs: each has a color, position function, and radius
    final blobs = <_Blob>[
      _Blob(
        color: const Color(0x80FAF099), // yellow-ish
        x: 0.2 + sin(time * 0.32) * 0.12,
        y: -0.1 + cos(time * 0.26) * 0.11 + 0.5,
        radius: 0.35,
      ),
      _Blob(
        color: const Color(0x80FA7308), // orange
        x: 0.8 + cos(time * 0.38) * 0.12,
        y: -0.1 + sin(time * 0.30) * 0.11 + 0.5,
        radius: 0.40,
      ),
      _Blob(
        color: const Color(0x80E62673), // pink
        x: 0.7 + sin(time * 0.20) * 0.16,
        y: 0.30 + cos(time * 0.44) * 0.11 + 0.5,
        radius: 0.32,
      ),
      _Blob(
        color: const Color(0x80591AB3), // purple
        x: 0.3 + cos(time * 0.26) * 0.16,
        y: 0.40 + sin(time * 0.34) * 0.11 + 0.5,
        radius: 0.36,
      ),
    ];

    // Draw each blob as a radial gradient
    for (final blob in blobs) {
      final cx = blob.x * w;
      final cy = (1.0 - blob.y) * h; // flip Y
      final r = blob.radius * w * 0.9;

      final paint = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            blob.color,
            blob.color.withValues(alpha: 0),
          ],
          stops: [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));

      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);
    }

    // Vertical breath fade - darken bottom portion
    final breath = 0.5 + 0.5 * sin(time * 0.55);
    final fadePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.transparent,
          Color(0xD914121B),
          Color(0xFF14121B),
        ],
        stops: [0.0, 0.38 + breath * 0.06, 0.66, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), fadePaint);

    // Vignette overlay
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.bottomLeft,
        radius: 1.3,
        colors: [
          Colors.transparent,
          Colors.transparent,
          Color(0x6B14121B),
          Color(0xD114121B),
        ],
        stops: [0.0, 0.38, 0.66, 0.86],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), vignettePaint);

    // Subtle grain effect using random dots
    final random = Random(42);
    final grainPaint = Paint()..color = Colors.white.withValues(alpha: 0.015);
    for (int i = 0; i < 200; i++) {
      final x = random.nextDouble() * w;
      final y = random.nextDouble() * h;
      canvas.drawCircle(Offset(x, y), 0.5, grainPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FluidPainter oldDelegate) => true;
}

class _Blob {
  final Color color;
  final double x;
  final double y;
  final double radius;

  _Blob({
    required this.color,
    required this.x,
    required this.y,
    required this.radius,
  });
}
