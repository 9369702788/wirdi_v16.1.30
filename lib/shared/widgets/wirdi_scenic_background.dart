import 'package:flutter/material.dart';

/// Decorative scenic layer used by the Wirdi visual redesign.
/// It sits behind the existing content, so application logic and services
/// are not changed.
class WirdiScenicBackground extends StatelessWidget {
  final Widget child;
  final String asset;
  final double height;
  final double opacity;

  const WirdiScenicBackground({
    super.key,
    required this.child,
    required this.asset,
    this.height = 300,
    this.opacity = 0.90,
  });

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).scaffoldBackgroundColor;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: background),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: height,
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity,
              child: Image.asset(
                asset,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: height + 70,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.04),
                    background.withValues(alpha: 0.52),
                    background,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
