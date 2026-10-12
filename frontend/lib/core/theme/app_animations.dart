import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_colors.dart';

/// Centralized animation constants and utilities adhering to Material 3 & Apple HIG motion curves.
class AppAnimations {
  // Durations
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration standard = Duration(milliseconds: 300);
  static const Duration medium = Duration(milliseconds: 450);
  static const Duration slow = Duration(milliseconds: 600);

  // Standard curves
  static const Curve easeOutCubic = Curves.easeOutCubic;
  static const Curve easeInOutCubic = Curves.easeInOutCubic;
  static const Curve spring = Curves.easeOutBack;

  /// Check if user has requested reduced motion in their OS accessibility settings
  static bool isReducedMotion(BuildContext context) {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  /// Get effective duration respecting reduced motion
  static Duration getDuration(BuildContext context, Duration defaultDuration) {
    return isReducedMotion(context) ? Duration.zero : defaultDuration;
  }

  /// Custom GoRouter Page Transition: Smooth Fade & Slide-Up
  static CustomTransitionPage<T> pageTransition<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
  }) {
    final reduced = isReducedMotion(context);
    if (reduced) {
      return CustomTransitionPage<T>(
        key: state.pageKey,
        child: child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
      );
    }

    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: standard,
      reverseTransitionDuration: fast,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: easeOutCubic,
        );

        final slideTween = Tween<Offset>(
          begin: const Offset(0.0, 0.04),
          end: Offset.zero,
        ).animate(curvedAnimation);

        final fadeTween = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(curvedAnimation);

        return SlideTransition(
          position: slideTween,
          child: FadeTransition(
            opacity: fadeTween,
            child: child,
          ),
        );
      },
    );
  }
}

/// Shimmer Skeleton Loading Widget
class ShimmerLoading extends StatefulWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final double borderRadius;
  final bool isLoading;

  const ShimmerLoading({
    super.key,
    this.child,
    this.width,
    this.height,
    this.borderRadius = 12.0,
    this.isLoading = true,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.child ??
        Container(
          width: widget.width ?? double.infinity,
          height: widget.height ?? 16.0,
          decoration: BoxDecoration(
            color: const Color(0xFFEBE6DC),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );

    if (!widget.isLoading || AppAnimations.isReducedMotion(context)) {
      return content;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              colors: const [
                Color(0xFFEBE6DC),
                Color(0xFFF9F7F2),
                Color(0xFFEBE6DC),
              ],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: content,
    );
  }
}

/// Animated Entrance Container with Staggered Slide & Fade
class AnimatedEntrance extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delayStep;
  final Duration? delay;

  const AnimatedEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.delayStep = const Duration(milliseconds: 60),
    this.delay,
  });

  @override
  State<AnimatedEntrance> createState() => _AnimatedEntranceState();
}

class _AnimatedEntranceState extends State<AnimatedEntrance> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.medium,
    );

    final curve = CurvedAnimation(parent: _controller, curve: AppAnimations.easeOutCubic);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _slideAnimation = Tween<Offset>(begin: const Offset(0.0, 0.08), end: Offset.zero).animate(curve);

    final effectiveDelay = widget.delay ?? (widget.delayStep * widget.index);
    Future.delayed(effectiveDelay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppAnimations.isReducedMotion(context)) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Animated Price / Count Counter using AnimatedSwitcher
class AnimatedPriceCounter extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final String prefix;

  const AnimatedPriceCounter({
    super.key,
    required this.amount,
    this.style,
    this.prefix = '₹',
  });

  @override
  Widget build(BuildContext context) {
    final text = '$prefix${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}';

    if (AppAnimations.isReducedMotion(context)) {
      return Text(text, style: style);
    }

    return AnimatedSwitcher(
      duration: AppAnimations.fast,
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.25),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: Text(
        text,
        key: ValueKey<String>(text),
        style: style,
      ),
    );
  }
}
