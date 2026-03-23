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
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (glowColor ?? Colors.cyan).withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: borderRadius ?? BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
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
