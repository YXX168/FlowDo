import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Animated priority selector with scale + glow transitions.
/// Three dots (high/medium/low) that animate when selected.
class AnimatedPrioritySelector extends StatefulWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const AnimatedPrioritySelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<AnimatedPrioritySelector> createState() =>
      _AnimatedPrioritySelectorState();
}

class _AnimatedPrioritySelectorState extends State<AnimatedPrioritySelector>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
  }

  @override
  void didUpdateWidget(AnimatedPrioritySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: ['high', 'medium', 'low'].map((p) {
        final color = AppTheme.priorityColor(p);
        final isActive = widget.selected == p;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onChanged(p);
          },
          child: AnimatedBuilder(
            animation: _scaleAnim,
            builder: (context, child) {
              final scale = isActive ? 1.0 + _scaleAnim.value * 0.3 : 1.0;
              return Transform.scale(scale: scale, child: child);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(left: 6),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? color : color.withValues(alpha: 0.2),
                border: Border.all(color: color, width: 2),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Animated checkbox with smooth checkmark draw + scale bounce.
class AnimatedTodoCheckbox extends StatefulWidget {
  final bool checked;
  final ValueChanged<bool> onChanged;

  const AnimatedTodoCheckbox({
    super.key,
    required this.checked,
    required this.onChanged,
  });

  @override
  State<AnimatedTodoCheckbox> createState() => _AnimatedTodoCheckboxState();
}

class _AnimatedTodoCheckboxState extends State<AnimatedTodoCheckbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _checkAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _checkAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    if (widget.checked) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(AnimatedTodoCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.checked != widget.checked) {
      if (widget.checked) {
        _controller.forward(from: 0.0);
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onChanged(!widget.checked);
      },
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, _) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: widget.checked
                      ? AppTheme.priorityLow
                      : const Color(0x33FFFFFF),
                  width: 2,
                ),
                color: widget.checked
                    ? AppTheme.priorityLow
                    : Colors.transparent,
                boxShadow: widget.checked
                    ? [
                        BoxShadow(
                          color: AppTheme.priorityLow.withValues(alpha: 0.3),
                          blurRadius: 6,
                        ),
                      ]
                    : [],
              ),
              child: CustomPaint(
                painter: _CheckPainter(_checkAnim.value),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;

  _CheckPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.25, size.height * 0.5);
    path.lineTo(size.width * 0.45, size.height * 0.68);
    path.lineTo(size.width * 0.75, size.height * 0.32);

    final metrics = path.computeMetrics().first;
    final extractedPath = metrics.extractPath(0, metrics.length * progress);
    canvas.drawPath(extractedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Glass submit button with press-scale animation.
class GlassSubmitButton extends StatefulWidget {
  final VoidCallback onPressed;

  const GlassSubmitButton({super.key, required this.onPressed});

  @override
  State<GlassSubmitButton> createState() => _GlassSubmitButtonState();
}

class _GlassSubmitButtonState extends State<GlassSubmitButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        HapticFeedback.mediumImpact();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnim.value, child: child);
        },
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.accent, AppTheme.accentHover],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accent.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}

/// Animated filter tab with sliding indicator.
class AnimatedFilterTab extends StatelessWidget {
  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const AnimatedFilterTab({
    super.key,
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0x1FFFFFFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isActive
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
              ),
              child: Text(label),
            ),
            const SizedBox(width: 5),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: count.toDouble(),
                end: count.toDouble(),
              ),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? AppTheme.textSecondary
                        : AppTheme.textQuaternary,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
