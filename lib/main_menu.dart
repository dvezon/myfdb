import 'package:flutter/material.dart';
import 'mywidgets.dart';

/// Απλό κύριο μενού με τέσσερις επιλογές.
/// Κάθε κάρτα συνδέεται σε μια named route μέσω [Navigator.pushNamed].

/// // ---------------- Route names ----------------
const String routeAppointments = '/appointments';
const String routeLeaves = '/leaves';
const String routeLogbook = '/logbook';
const String routeSettings = '/settings';

class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = <_MenuEntry>[
      const _MenuEntry('Διαχείριση ραντεβού', '/appointments'),
      const _MenuEntry('Διαχείριση Αδειών', '/leaves'),
      const _MenuEntry('Καταγραφή ημερολογίου συμβάντων', '/logbook'),
      const _MenuEntry('Ρυθμίσεις', '/settings'),
    ];

    return BorderedBox(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) => _MenuCard(entry: entries[index]),
      ),
    );
  }
}

/// Εσωτερικό μοντέλο για κάθε επιλογή μενού
class _MenuEntry {
  final String title;
  final String route;
  const _MenuEntry(this.title, this.route);
}

/// Κάρτα που αντιπροσωπεύει μια επιλογή του μενού
class _MenuCard extends StatelessWidget {
  final _MenuEntry entry;
  const _MenuCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => Navigator.pushNamed(context, entry.route),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Center(
            child: Text(
              entry.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
