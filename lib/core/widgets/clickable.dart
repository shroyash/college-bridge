import 'package:flutter/material.dart';

class Clickable extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final HitTestBehavior behavior;

  const Clickable({
    super.key,
    required this.child,
    required this.onTap,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: behavior,
        onTap: onTap,
        child: child,
      ),
    );
  }
}

