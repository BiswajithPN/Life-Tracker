import 'dart:ui';
import 'package:flutter/material.dart';

class FloatingGlassCard extends StatelessWidget {
  final Widget child;
  final double width;
  final double? height;
  final Color? glowColor;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;

  const FloatingGlassCard({
    super.key,
    required this.child,
    this.width = double.infinity,
    this.height,
    this.glowColor,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Light mode: white card with subtle shadow & border
    // Dark mode: glassmorphism with blur + low-opacity white tint
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.03)
        : Colors.white.withValues(alpha: 0.85);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : (glowColor ?? const Color(0xFF00FFCC)).withValues(alpha: 0.18);
    final shadowColor = isDark
        ? (glowColor ?? Colors.cyan).withValues(alpha: 0.10)
        : (glowColor ?? Colors.black).withValues(alpha: 0.08);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: isDark ? 20 : 12,
            spreadRadius: isDark ? -5 : 0,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: isDark ? 15 : 0, sigmaY: isDark ? 15 : 0),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: borderRadius ?? BorderRadius.circular(24),
              border: Border.all(
                color: borderColor,
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
