import 'package:flutter/material.dart';

class VaultWallpaper extends StatelessWidget {
  const VaultWallpaper({super.key, required this.asset, required this.child});
  final String asset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(fit: StackFit.expand, children: [
      Image.asset(asset, fit: BoxFit.cover),
      ColoredBox(color: (dark ? Colors.black : Colors.white).withValues(alpha: dark ? .88 : .90)),
      child,
    ]);
  }
}
