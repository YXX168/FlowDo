import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

/// Fluid animated background using GPU Fragment Shader.
///
/// Ports the exact Mercury Music WebGL shader (simplex noise domain warping)
/// to Flutter's FragmentProgram for GPU-accelerated liquid rendering.
/// Falls back to a CustomPainter approximation if the shader fails to load.
class FluidBackground extends StatefulWidget {
  const FluidBackground({super.key});

  @override
  State<FluidBackground> createState() => _FluidBackgroundState();
}

class _FluidBackgroundState extends State<FluidBackground>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  FragmentShader? _shader;
  bool _shaderLoaded = false;
  bool _animationsDisabled = false;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  Offset _mouse = const Offset(0.5, 0.5);
  Offset _targetMouse = const Offset(0.5, 0.5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycleState =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    );
    _syncAnimationState();
    _loadShader();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animationsDisabled =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_animationsDisabled != animationsDisabled) {
      _animationsDisabled = animationsDisabled;
      _syncAnimationState();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    _syncAnimationState();
  }

  void _syncAnimationState() {
    final shouldAnimate = !_animationsDisabled &&
        _lifecycleState == AppLifecycleState.resumed;
    if (shouldAnimate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!shouldAnimate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  Future<void> _loadShader() async {
    try {
      final program = await FragmentProgram.fromAsset('shaders/fluid.frag');
      _shader = program.fragmentShader();
      if (mounted) setState(() => _shaderLoaded = true);
    } catch (e) {
      // Fallback to CustomPainter if shader fails to compile
      debugPrint('Shader load failed, using fallback: $e');
    }
  }

  void _updateMouse(Offset position, Size size) {
    if (size.width > 0 && size.height > 0) {
      _targetMouse = Offset(
        position.dx / size.width,
        1.0 - position.dy / size.height,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return MouseRegion(
            onHover: (event) => _updateMouse(event.localPosition, size),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
              // Smooth mouse interpolation
              _mouse = Offset(
                _mouse.dx + (_targetMouse.dx - _mouse.dx) * 0.05,
                _mouse.dy + (_targetMouse.dy - _mouse.dy) * 0.05,
              );

              if (_shaderLoaded && _shader != null) {
                return CustomPaint(
                  painter: _ShaderPainter(
                    shader: _shader!,
                    time: _controller.value * 60,
                    size: size,
                    mouse: _mouse,
                  ),
                  size: size,
                );
              }
              // Fallback: animated gradient background
              return CustomPaint(
                painter: _FallbackPainter(_controller.value),
                size: size,
              );
              },
            ),
          );
        },
      ),
    );
  }
}

/// GPU shader painter - runs the exact same GLSL as the original WebGL version.
class _ShaderPainter extends CustomPainter {
  final FragmentShader shader;
  final double time;
  final Size size;
  final Offset mouse;

  _ShaderPainter({
    required this.shader,
    required this.time,
    required this.size,
    required this.mouse,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    shader.setFloat(0, time); // u_time
    // FlutterFragCoord uses the CustomPaint local coordinate space, so these
    // values must remain logical pixels. Multiplying by DPR distorts the UVs.
    shader.setFloat(1, canvasSize.width); // u_resolution.x
    shader.setFloat(2, canvasSize.height); // u_resolution.y
    shader.setFloat(3, mouse.dx); // u_mouse.x
    shader.setFloat(4, mouse.dy); // u_mouse.y
    shader.setFloat(5, 0.0); // u_isLightMode (dark mode)

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & canvasSize, paint);
  }

  @override
  bool shouldRepaint(covariant _ShaderPainter oldDelegate) =>
      oldDelegate.time != time ||
      oldDelegate.size != size ||
      oldDelegate.mouse != mouse ||
      oldDelegate.shader != shader;
}

/// Fallback painter when GPU shader is unavailable.
/// Uses layered radial gradients with additive blending to approximate the fluid effect.
class _FallbackPainter extends CustomPainter {
  final double t;

  _FallbackPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final time = t * 2 * pi;

    // Deep dark base
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

    // Color blobs with domain-warping approximation
    final colors = [
      const Color(0xFFFAF099), // yellow
      const Color(0xFFFA7308), // orange
      const Color(0xFFE62673), // pink
      const Color(0xFF591AB3), // purple
    ];

    final positions = [
      Offset(0.2 + sin(time * 0.32) * 0.12, 0.78 + cos(time * 0.26) * 0.08),
      Offset(0.8 + cos(time * 0.38) * 0.12, 0.86 + sin(time * 0.30) * 0.08),
      Offset(0.7 + sin(time * 0.20) * 0.16, 0.64 + cos(time * 0.44) * 0.09),
      Offset(0.3 + cos(time * 0.26) * 0.16, 0.70 + sin(time * 0.34) * 0.09),
    ];

    final alphas = [0.45, 0.38, 0.35, 0.40];
    final radii = [0.42, 0.40, 0.36, 0.40];

    for (int i = 0; i < 4; i++) {
      // Add noise-like distortion to position
      final noiseX = sin(time * 0.18 + i * 1.7) * 0.05;
      final noiseY = cos(time * 0.25 + i * 2.3) * 0.05;

      final cx = (positions[i].dx + noiseX) * w;
      final cy = (positions[i].dy + noiseY) * h;
      final r = radii[i] * sqrt(w * w + h * h) * 0.5;

      final paint = Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            colors[i].withValues(alpha: alphas[i]),
            colors[i].withValues(alpha: alphas[i] * 0.5),
            colors[i].withValues(alpha: 0),
          ],
          stops: [0.0, 0.4, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));

      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);
    }

    // Keep the top calm and reveal the moving color toward the lower screen.
    final breath = 0.5 + 0.5 * sin(time * 0.55);
    final fadePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF14121B),
          const Color(0xF214121B),
          const Color(0xB314121B),
          const Color(0x4D14121B),
          Colors.transparent,
        ],
        stops: [0.0, 0.24 + breath * 0.03, 0.48, 0.70, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), fadePaint);

    // Vignette
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
  }

  @override
  bool shouldRepaint(covariant _FallbackPainter oldDelegate) =>
      oldDelegate.t != t;
}
