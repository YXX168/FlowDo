import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/todo.dart';
import '../theme/app_theme.dart';

// ============================================================
// Animated Priority Selector
// Three large dots with elastic bounce + glow pulse + ripple
// ============================================================
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
  late AnimationController _bounceCtrl;
  late AnimationController _glowCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = CurvedAnimation(
      parent: _bounceCtrl,
      curve: Curves.elasticOut,
    );

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(
      parent: _glowCtrl,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(AnimatedPrioritySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      _bounceCtrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: TodoPriority.values.map((p) {
        final color = AppTheme.priorityColor(p);
        final isActive = widget.selected == p;
        return Semantics(
          button: true,
          selected: isActive,
          label: '${AppTheme.priorityLabel(p)}优先级',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onChanged(p);
            },
            child: AnimatedBuilder(
            animation: Listenable.merge([_scaleAnim, _glowAnim]),
            builder: (context, child) {
              final scale = isActive ? 1.0 + _scaleAnim.value * 0.35 : 1.0;
              final glowAlpha = isActive ? 0.3 + _glowAnim.value * 0.3 : 0.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  margin: const EdgeInsets.only(left: 2),
                  width: 36,
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Glow ring
                      if (isActive)
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withValues(alpha: glowAlpha),
                          ),
                        ),
                      // Main dot
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive ? color : color.withValues(alpha: 0.15),
                          border: Border.all(
                            color: color,
                            width: isActive ? 0 : 2,
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.6),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : [],
                        ),
                      ),
                      // Inner highlight
                      if (isActive)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ============================================================
// Animated Category Chip
// ============================================================
class AnimatedCategoryChip extends StatelessWidget {
  final String category;
  final bool isSelected;
  final VoidCallback onTap;

  const AnimatedCategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.categoryColor(category);
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${AppTheme.categoryLabel(category)}分类',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : const Color(0x0DFFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : const Color(0x14FFFFFF),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppTheme.categoryIcon(category),
              size: 14,
              color: isSelected ? color : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : AppTheme.textSecondary,
              ),
              child: Text(AppTheme.categoryLabel(category)),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

// ============================================================
// Animated Checkbox with draw + bounce + glow
// ============================================================
class AnimatedTodoCheckbox extends StatefulWidget {
  final bool checked;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;

  const AnimatedTodoCheckbox({
    super.key,
    required this.checked,
    required this.onChanged,
    this.activeColor,
  });

  @override
  State<AnimatedTodoCheckbox> createState() => _AnimatedTodoCheckboxState();
}

class _AnimatedTodoCheckboxState extends State<AnimatedTodoCheckbox>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _checkAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _checkAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    );
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
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
    final activeColor = widget.activeColor ?? AppTheme.priorityLow;
    return Semantics(
      button: true,
      checked: widget.checked,
      label: widget.checked ? '标记为未完成' : '标记为已完成',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onChanged(!widget.checked);
        },
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.checked
                      ? activeColor
                      : const Color(0x33FFFFFF),
                  width: 2,
                ),
                color: widget.checked
                    ? activeColor
                    : Colors.transparent,
                boxShadow: widget.checked
                    ? [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.4 * _glowAnim.value),
                          blurRadius: 8,
                          spreadRadius: 0,
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
          ),
        ),
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
    path.moveTo(size.width * 0.22, size.height * 0.52);
    path.lineTo(size.width * 0.42, size.height * 0.72);
    path.lineTo(size.width * 0.78, size.height * 0.30);

    final metrics = path.computeMetrics().first;
    final extractedPath = metrics.extractPath(0, metrics.length * progress);
    canvas.drawPath(extractedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ============================================================
// Glass Submit Button with press-scale + glow + shimmer
// ============================================================
class GlassSubmitButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const GlassSubmitButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<GlassSubmitButton> createState() => _GlassSubmitButtonState();
}

class _GlassSubmitButtonState extends State<GlassSubmitButton>
    with TickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late AnimationController _glowCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut),
    );

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(
      parent: _glowCtrl,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !widget.isLoading,
      label: '添加待办事项',
      child: GestureDetector(
        onTapDown: widget.isLoading ? null : (_) => _pressCtrl.forward(),
        onTapUp: widget.isLoading
            ? null
            : (_) {
                _pressCtrl.reverse();
                HapticFeedback.mediumImpact();
                widget.onPressed();
              },
        onTapCancel: () => _pressCtrl.reverse(),
        child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnim, _glowAnim]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.accent, AppTheme.accentHover],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.4 + _glowAnim.value * 0.2),
                    blurRadius: 12 + _glowAnim.value * 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
            ),
          );
        },
        ),
      ),
    );
  }
}

// ============================================================
// Animated Filter Tab with sliding indicator
// ============================================================
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
    return Semantics(
      button: true,
      selected: isActive,
      label: '$label，$count 项',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedScale(
        scale: isActive ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 38),
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: [
                      AppTheme.accent.withValues(alpha: 0.25),
                      AppTheme.accentHover.withValues(alpha: 0.15),
                    ],
                  )
                : null,
            color: isActive ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isActive
                ? Border.all(color: AppTheme.accent.withValues(alpha: 0.4), width: 1)
                : Border.all(color: Colors.transparent, width: 1),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 13,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: isActive
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                ),
                child: Text(label),
              ),
              const SizedBox(width: 5),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.7, end: 1.0),
                duration: const Duration(milliseconds: 200),
                builder: (context, scale, child) {
                  return Transform.scale(scale: scale, child: child);
                },
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 22,
                    minHeight: 18,
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.accent.withValues(alpha: 0.3)
                        : const Color(0x14FFFFFF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? AppTheme.textPrimary
                          : AppTheme.textQuaternary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

// ============================================================
// Staggered List Item Animation
// ============================================================
class StaggeredListItem extends StatefulWidget {
  final int index;
  final Widget child;

  const StaggeredListItem({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  State<StaggeredListItem> createState() => _StaggeredListItemState();
}

class _StaggeredListItemState extends State<StaggeredListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slideOffset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    final delay = (widget.index * 0.08).clamp(0.0, 0.4);
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(delay, 1.0, curve: Curves.easeOut),
      ),
    );
    _slideOffset = Tween<Offset>(
      begin: const Offset(-0.3, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(delay, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
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
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: FractionalTranslation(
            translation: _slideOffset.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

// ============================================================
// Animated Counter (number rolling)
// ============================================================
class AnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle? style;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, val, _) {
        return Text(
          '$val',
          style: (style ?? const TextStyle()).copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
      },
    );
  }
}

// ============================================================
// Animated Progress Bar with shimmer
// ============================================================
class AnimatedProgressBar extends StatefulWidget {
  final double progress;
  final Color? color;

  const AnimatedProgressBar({
    super.key,
    required this.progress,
    this.color,
  });

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.statDone;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: widget.progress),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: Stack(
              children: [
                // Background
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0x0FFFFFFF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Fill
                FractionallySizedBox(
                  widthFactor: value.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.7)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
                // Shimmer overlay
                if (value > 0.01)
                  AnimatedBuilder(
                    animation: _shimmerCtrl,
                    builder: (context, _) {
                      final shimmerPos = _shimmerCtrl.value;
                      return FractionallySizedBox(
                        widthFactor: value.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: LinearGradient(
                              begin: Alignment(shimmerPos * 2 - 1, 0),
                              end: Alignment(shimmerPos * 2, 0),
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// Shimmer Text for branding
// ============================================================
class ShimmerText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerText({
    super.key,
    required this.text,
    required this.style,
    this.baseColor = const Color(0x59FFFFFF),
    this.highlightColor = const Color(0xFFFFFFFF),
  });

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
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
        return ShaderMask(
          shaderCallback: (bounds) {
            final pos = _controller.value;
            return LinearGradient(
              begin: Alignment(pos * 2 - 1, 0),
              end: Alignment(pos * 2 + 0.5, 0),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
            ).createShader(bounds);
          },
          child: Text(widget.text, style: widget.style),
        );
      },
    );
  }
}
