/*
BorderedBox(
  borderRadius: 8,
  outerPadding: const EdgeInsets.only(top: 8),
  innerPadding: const EdgeInsets.fromLTRB(8, 6, 12, 8),
  child: ......

*/
import 'package:flutter/material.dart';

class BorderedBox extends StatelessWidget {
  // --- απαιτούμενο ---
  final Widget child;

  // --- προαιρετικά (με defaults) ---

  final EdgeInsets outerPadding; // π.χ. μόνο top: 8
  final EdgeInsets innerPadding; // π.χ. fromLTRB(8, 6, 12, 8)
  final double borderRadius; // π.χ. 8.0
  final Color? borderColor; // αν δεν δοθεί, πάμε σε Theme

  const BorderedBox({
    super.key,
    required this.child,

    this.outerPadding = const EdgeInsets.all(8),
    this.innerPadding = const EdgeInsets.fromLTRB(8, 8, 12, 8),
    this.borderRadius = 8.0,
    this.borderColor, // nullable → θα ληφθεί από Theme
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: outerPadding,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor ?? cs.outlineVariant),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: outerPadding,
        child: child,
      ),
    );
  }
}
