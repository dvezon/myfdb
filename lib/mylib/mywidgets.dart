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

class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final ColorScheme cs;
  final void Function(String)? onChanged; //  προαιρετικό

  const MyTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.cs,
    this.onChanged, //  δεν είναι required
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged, //  περνάμε το callback, αν υπάρχει
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: cs.primary),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: cs.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: cs.primary, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: cs.outlineVariant),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
      ),
    );
  }
}

class AppsDiscriptionHead extends StatelessWidget {
  const AppsDiscriptionHead({super.key});

  @override
  Widget build(BuildContext context) {
    final myColor = Theme.of(context).colorScheme.primary;
    double myFondSize = 20;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Εφαρμογή:\n',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: myColor,
              fontSize: 14, //myFondSize,
            ),
          ),
          Text(
            'Οργάνωσης και Υποστήριξης',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: myColor,
              fontSize: myFondSize,
            ),
          ),
          Text(
            'της Διοίκησης Σχολικής Μονάδας',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: myColor,
              fontSize: myFondSize,
            ),
          ),
        ],
      ),
    );
  }
}

class AppsDiscriptionTail extends StatelessWidget {
  const AppsDiscriptionTail({super.key});

  @override
  Widget build(BuildContext context) {
    final myColor = Theme.of(context).colorScheme.primary;
    double myFondSize = 14;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'του μεταταπτυχιακού φοιτητή',
            style: TextStyle(
              // fontWeight: FontWeight.bold,
              color: myColor,
              fontSize: myFondSize,
            ),
          ),
          Text(
            'Βεζονιαράκη Δημήτρη',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: myColor,
              fontSize: myFondSize,
            ),
          ),
          Text(
            'Επιβλέπον Καθηγητής',

            style: TextStyle(
              //fontWeight: FontWeight.bold,
              color: myColor,
              fontSize: myFondSize,
            ),
          ),
          Text(
            'Τσιλίκας Νικόλαος',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: myColor,
              fontSize: myFondSize,
            ),
          ),
        ],
      ),
    );
  }
}
