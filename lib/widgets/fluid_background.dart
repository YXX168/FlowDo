import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

/// Fluid animated background replicating Mercury Music's WebGL shader.
///
/// Uses layered radial gradients with [BlendMode.plus] for additive color
/// blending, creating a genuine "liquid light" feel. Multiple animated blobs
/// with different speeds, sizes and Lissajous movement patterns overlap and
/// blend additively, producing the flowing liquid effect.
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
      duration: const Duration(seconds: 20),
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
    final time = t * 2 * pi;

    // ---- Layer 0: Deep dark base ----
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF2D293A),
          const Color(0xFF1A1726),
          const Color(0xFF14121B),
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // ---- Layer 1: Large soft color blobs (additive blending) ----
    // These are the "liquid" bodies - large, slow, heavily blurred
    final liquidBlobs = <_Blob>[
      // Yellow - top left, slow drift
      _Blob(
        color: const Color(0xFFFAF099),
        cx: 0.15 + sin(time * 0.15) * 0.08 + cos(time * 0.07) * 0.05,
        cy: 0.25 + cos(time * 0.12) * 0.06,
        radius: 0.55,
        alpha: 0.35,
      ),
      // Orange - right side, medium drift
      _Blob(
        color: const Color(0xFFFA7308),
        cx: 0.85 + cos(time * 0.18) * 0.10 + sin(time * 0.09) * 0.04,
        cy: 0.35 + sin(time * 0.14) * 0.08,
        radius: 0.50,
        alpha: 0.30,
      ),
      // Pink - center-right, flowing
      _Blob(
        color: const Color(0xFFE62673),
        cx: 0.60 + sin(time * 0.10) * 0.12,
        cy: 0.55 + cos(time * 0.22) * 0.10,
        radius: 0.48,
        alpha: 0.28,
      ),
      // Purple - left-bottom, slow rise
      _Blob(
        color: const Color(0xFF591AB3),
        cx: 0.25 + cos(time * 0.13) * 0.10,
        cy: 0.70 + sin(time * 0.17) * 0.08,
        radius: 0.52,
        alpha: 0.32,
      ),
      // Blue fringe - bottom right
      _Blob(
        color: const Color(0xFF4A88FF),
        cx: 0.75 + sin(time * 0.11) * 0.08,
        cy: 0.80 + cos(time * 0.19) * 0.06,
        radius: 0.45,
        alpha: 0.20,
      ),
      // Hot pink accent - center, fast small
      _Blob(
        color: const Color(0xFFFF2D6F),
        cx: 0.45 + cos(time * 0.25) * 0.07,
        cy: 0.40 + sin(time * 0.28) * 0.05,
        radius: 0.30,
        alpha: 0.25,
      ),
    ];

    // Draw liquid blobs with additive blending
    for (final blob in liquidBlobs) {
      final cx = blob.cx * w;
      final cy = blob.cy * h;
      // Make radius proportional to screen diagonal for consistent look
      final r = blob.radius * sqrt(w * w + h * h) * 0.5;

      final paint = Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            blob.color.withValues(alpha: blob.alpha),
            blob.color.withValues(alpha: blob.alpha * 0.5),
            blob.color.withValues(alpha: 0),
          ],
          stops: [0.0, 0.4, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));

      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);
    }

    // ---- Layer 2: Flowing wave distortion (simulated with shifted blobs) ----
    // Create a second pass of smaller, faster blobs that add "flow" energy
    for (int i = 0; i < 4; i++) {
      final phase = time * (0.3 + i * 0.08);
      final cx = (0.2 + i * 0.2 + sin(phase) * 0.15) * w;
      final cy = (0.3 + cos(phase * 0.7 + i) * 0.2 + i * 0.05) * h;
      final r = 0.25 * sqrt(w * w + h * h) * 0.5;

      final colors = [
        const Color(0xFFFAF099),
        const Color(0xFFFA7308),
        const Color(0xFFE62673),
        const Color(0xFF591AB3),
      ];
      final paint = Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            colors[i].withValues(alpha: 0.15),
            colors[i].withValues(alpha: 0),
          ],
          stops: [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);
    }

    // ---- Layer 3: Breath fade (vertical) ----
    final breath = 0.5 + 0.5 * sin(time * 0.55);
    final fadePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.transparent,
          const Color(0x9914121B),
          const Color(0xE614121B),
          const Color(0xFF14121B),
        ],
        stops: [0.0, 0.30 + breath * 0.05, 0.60, 0.85, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), fadePaint);

    // ---- Layer 4: Vignette ----
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.9,
        colors: [
          Colors.transparent,
          Colors.transparent,
          const Color(0x3314121B),
          const Color(0x9914121B),
        ],
        stops: [0.0, 0.4, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), vignettePaint);

    // ---- Layer 5: Film grain ----
    final random = Random(42 + (t * 60).toInt());
    final grainPaint = Paint()..color = Colors.white.withValues(alpha: 0.012);
    for (int i = 0; i < 150; i++) {
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
  final double cx;
  final double cy;
  final double radius;
  final double alpha;

  _Blob({
    required this.color,
    required this.cx,
    required this.cy,
    required this.radius,
    required this.alpha,
  });
}
